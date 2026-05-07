#!/bin/sh
# Lazycat-flavored apipark entrypoint.
#
# Upstream's docker_run.sh forks apipark, then `wait_for_apipark` polls
# /api/v1/account/login for 30s and exits with `set -e` if it does not
# become reachable in time. On a busy/cold lazycat box, MySQL migrations
# regularly take longer than 30s, so the container exits before the
# binary finishes coming up.
#
# Upstream also kicks off "Init=true" auto-bootstrap of influxdb / apinto
# / loki, none of which we ship in this wrapper.
#
# This rewrite generates the same config.yml then `exec`s the apipark
# binary in the foreground — no race, no spurious 30s timeout.
set -e
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
  user_name: ${REDIS_USER_NAME}
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

# Foreground — log everything to stdout for `docker logs`.
exec ./apipark
