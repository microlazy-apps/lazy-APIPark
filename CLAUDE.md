# lazy-APIPark — project context for Claude Code

懒猫微服 lpk wrapper for [APIParkLab/APIPark](https://github.com/APIParkLab/APIPark).

## Architecture

**Retag-only main image + 3 pre-mirrored dependencies** (multi-service stack).

`docker/Dockerfile` is a single-line `FROM apipark/apipark:v1.9.6-beta-amd64@sha256:...`
so the lazycat-ci `lpk-build.yml` reusable can mirror it into the
lazycat registry as `${LAZYCAT_IMAGE}`. No upstream source vendoring,
no patches.

The three dependency images (MySQL 8, Redis 7-alpine, InfluxDB 2.7-alpine)
were pre-mirrored once via `lzc-cli appstore copy-image
docker.io/library/<image>:<tag>` and the resulting
`registry.lazycat.cloud/lee/library/...` URLs are hardcoded in
`lazycat/lzc-manifest.template.yml`.

To re-mirror (e.g. for a security update or arch bump):

```sh
lzc-cli appstore copy-image docker.io/library/mysql:8.0
lzc-cli appstore copy-image docker.io/library/redis:7.4-alpine
lzc-cli appstore copy-image docker.io/library/influxdb:2.7-alpine
# update the resulting URLs in lzc-manifest.template.yml
```

## Bumping the upstream apipark image

```sh
TOKEN=$(curl -fsSL 'https://auth.docker.io/token?service=registry.docker.io&scope=repository:apipark/apipark:pull' | jq -r .token)
curl -sSI "https://registry-1.docker.io/v2/apipark/apipark/manifests/v1.9.6-beta-amd64" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
  | grep -i digest
```

Update the `@sha256:...` line in `docker/Dockerfile`.

## Service wiring

| Env var            | Source                       |
|--------------------|------------------------------|
| MYSQL_*            | service `mysql`, root user   |
| REDIS_ADDR/PWD     | service `redis`              |
| ADMIN_PASSWORD     | deploy param `ADMIN_PASSWORD`|
| MYSQL_ROOT_PASSWORD| `stable_secret`               |
| REDIS_PASSWORD     | `stable_secret`               |
| INFLUXDB_*         | `stable_secret`               |

InfluxDB is initialized in setup mode (`DOCKER_INFLUXDB_INIT_MODE=setup`)
on first boot with org=apipark, bucket=apinto.

## Release flow

1. `git tag v0.0.1 && git push --tags` — release.yml runs.
   `publish-appstore` step **fails** on first release (app not yet
   registered) — that's expected. The `.lpk` is still attached to the
   GitHub Release.
2. `gh release download v0.0.1 -p '*.lpk'` →
   `scp` to maolv → `lpk-manager install …` → smoke-test.
3. Capture real screenshots + extract real upstream brand icon.
4. Bump to v0.0.2 and run `bootstrap-app.yml` with no `app_id` to
   register in the appstore.

## Known limitations

- v0.0.1 ships **without** apinto-gateway, NSQ, Loki, Grafana. APIPark's
  console / AI Service / portal flows work; downstream API gateway
  proxying through Apinto needs to be added in a later iteration.
- Resource floor: APIPark + MySQL + Redis + InfluxDB needs ~3 GB RAM.
