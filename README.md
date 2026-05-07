# lazy-APIPark

懒猫微服 (LazyCat MicroServer) lpk wrapper for [APIParkLab/APIPark](https://github.com/APIParkLab/APIPark).

> APIPark 是云原生 AI&API 网关，统一管理 OpenAI/Claude/Gemini/DeepSeek/通义千问 等 100+ 大模型 API。

## What this repo does

It repackages the official upstream image
[`apipark/apipark:v1.9.6-beta-amd64`](https://hub.docker.com/r/apipark/apipark)
into a lazycat appstore lpk and bundles the three storage dependencies
APIPark needs (MySQL 8 / Redis 7 / InfluxDB 2.7) so end users can
install it with one click.

This wrapper does **not** modify upstream code or configuration.

## Architecture

| Service  | Image                                                          | Purpose                |
|----------|----------------------------------------------------------------|------------------------|
| main     | `${LAZYCAT_IMAGE}` (mirrored upstream `apipark/apipark`)       | APIPark console + API  |
| mysql    | `registry.lazycat.cloud/lee/library/mysql:af58d7dde530c490`     | App metadata (MySQL 8) |
| redis    | `registry.lazycat.cloud/lee/library/redis:5213762bb18e770c`     | Cache / sessions       |
| influxdb | `registry.lazycat.cloud/lee/library/influxdb:36de52d2217a8b26`  | Call metrics           |

CI's `lpk-build.yml` mirrors the main image into the lazycat registry.
The three dependency images are pre-mirrored once via
`lzc-cli appstore copy-image` and pinned by digest in the manifest.

## Release

```sh
git tag v0.0.1 && git push origin v0.0.1
```

`release.yml` builds the lpk, attaches it to a GitHub Release, and
attempts `lzc-cli appstore publish` (this last step fails on the very
first release until `bootstrap-app.yml` has registered the app — that
failure is expected for v0.0.1).

## Initial appstore registration

Once v0.0.1 has been validated on a real lazycat box (icon + screenshots
+ container behaviour), bump to v0.0.2 and run the
**Bootstrap appstore (manual)** workflow with no `app_id` — it creates
the app record and submits the first review.

## Upstream

- Project: <https://github.com/APIParkLab/APIPark>
- License: Apache-2.0
- Docker Hub: <https://hub.docker.com/r/apipark/apipark>
