# Retag-only wrapper around the upstream APIPark image so the lazycat
# CI pipeline (lpk-build → lzc-cli appstore copy-image) can mirror it.
#
# Pinned by sha256 digest for reproducibility. Bump by re-resolving with:
#   TOKEN=$(curl -fsSL 'https://auth.docker.io/token?service=registry.docker.io&scope=repository:apipark/apipark:pull' | jq -r .token)
#   curl -sSI "https://registry-1.docker.io/v2/apipark/apipark/manifests/v1.9.6-beta-amd64" \
#     -H "Authorization: Bearer $TOKEN" \
#     -H "Accept: application/vnd.docker.distribution.manifest.v2+json" | grep -i digest
FROM apipark/apipark:v1.9.6-beta-amd64@sha256:e5e08f841ec74e0066ac6de71e14704010bb215925671744fa2bc1e1e236d673
