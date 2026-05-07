#!/bin/sh
# Lazycat-flavored apipark entrypoint.
#
# Replaces upstream's docker_run.sh because:
# (1) Its `wait_for_apipark` polls the local apipark for 30s under
#     `set -e` — on a busy box, MySQL migrations regularly take longer
#     than 30s and the container exits before apipark finishes booting.
# (2) Lazycat's `depends_on` is service-up-only, not health-gated, so
#     apipark may start while MySQL is still initialising its data dir
#     on first boot. We wait for the dependent TCP ports here.
# (3) Upstream's "Init=true" branch tries to bootstrap influxdb / apinto
#     / loki, none of which we ship in this wrapper.
set -eu
cd /apipark

mkdir -p "${ERROR_DIR:-work/logs}"

cat > config.yml <<EOF
mysql:
  user_name: ${MYSQL_USER_NAME}
  password: ${MYSQL_PWD}
  ip: ${MYSQL_IP}
  port: ${MYSQL_PORT}
  db: ${MYSQL_DB}
redis:
  user_name: ${REDIS_USER_NAME:-}
  password: ${REDIS_PWD}
  addr:
EOF

OLD_IFS="$IFS"
IFS=","
for s in $REDIS_ADDR; do
  echo "    - $s" >> config.yml
done
IFS="$OLD_IFS"

cat >> config.yml <<EOF
nsq:
  addr: ${NSQ_ADDR}
  topic_prefix: ${NSQ_TOPIC_PREFIX}
port: 8288
error_log:
  dir: ${ERROR_DIR}
  file_name: ${ERROR_FILE_NAME}
  log_level: ${ERROR_LOG_LEVEL}
  log_expire: ${ERROR_EXPIRE}
  log_period: ${ERROR_PERIOD}
EOF

echo "=== rendered /apipark/config.yml ==="
cat config.yml
echo "===================================="

# Wait for dependent services. nc is provided by busybox (apipark image is alpine).
wait_for_port() {
  host=$1
  port=$2
  label=$3
  attempts=0
  while ! nc -z "$host" "$port" >/dev/null 2>&1; do
    attempts=$((attempts + 1))
    if [ "$attempts" -ge 60 ]; then
      echo "[entrypoint] giving up waiting for $label ($host:$port) after 60 attempts"
      exit 1
    fi
    echo "[entrypoint] waiting for $label ($host:$port)... attempt $attempts"
    sleep 2
  done
  echo "[entrypoint] $label ($host:$port) is ready"
}

wait_for_port "${MYSQL_IP}" "${MYSQL_PORT}" "mysql"
# REDIS_ADDR may be a comma list; only the first endpoint matters for the gate.
REDIS_HEAD=$(echo "$REDIS_ADDR" | cut -d',' -f1)
REDIS_HOST=$(echo "$REDIS_HEAD" | cut -d':' -f1)
REDIS_PORT=$(echo "$REDIS_HEAD" | cut -d':' -f2)
wait_for_port "$REDIS_HOST" "$REDIS_PORT" "redis"
NSQ_HOST=$(echo "$NSQ_ADDR" | cut -d':' -f1)
NSQ_PORT=$(echo "$NSQ_ADDR" | cut -d':' -f2)
wait_for_port "$NSQ_HOST" "$NSQ_PORT" "nsq"

# Foreground — log everything to stdout for `docker logs`.
exec ./apipark
