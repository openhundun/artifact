ARG IMAGE_REGISTRY="ghcr.io"

FROM ${IMAGE_REGISTRY}/openhundun/ubuntu:24
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
COPY --from=docker.io/oven/bun:1.4 /usr/local/bin/bun /usr/local/bin/bun
RUN ln -sfn /usr/local/bin/bun /usr/local/bin/bunx
RUN tee /root/.bunfig.toml > /dev/null <<EOF
[install]
linker   = "hoisted"
lockfile = { save = false }
registry = { url = "https://registry.npmmirror.com" }
EOF
