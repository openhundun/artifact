FROM docker.io/library/debian:13-slim AS base
RUN \
    sed -i 's|deb.debian.org|mirrors.ustc.edu.cn|g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates ccache cmake curl file git make ninja-build pkg-config unzip xz-utils zip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists && \
    rm -rf /var/cache/apt/archives

FROM base AS builder
ARG TARGETARCH
ARG ZIG_URL_AMD64="https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz"
ARG ZIG_URL_ARM64="https://ziglang.org/download/0.16.0/zig-aarch64-linux-0.16.0.tar.xz"
RUN \
    ZIG_URL="$(case "${TARGETARCH}" in amd64) echo "${ZIG_URL_AMD64}";; arm64) echo "${ZIG_URL_ARM64}";; *) exit 1;; esac)" && \
    mkdir -p /opt/zig && \
    curl "${ZIG_URL}" -fsSL -o /tmp/zig.tar.xz && \
    tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components 1 --no-same-owner && \
    rm -rf /tmp/zig.tar.xz

FROM base AS runtime
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
COPY --from=builder /opt/zig /opt/zig
ENV \
    TZ="Asia/Shanghai" \
    TIME_STYLE="+%Y-%m-%d %H:%M:%S" \
    PATH="/opt/zig:${PATH}"
CMD ["zig", "version"]