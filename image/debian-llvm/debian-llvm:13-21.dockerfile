FROM ghcr.io/openhundun/debian:13
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
ENV PATH="/usr/lib/llvm-21/bin:${PATH}"
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends ccache clang-21 cmake file lld-21 llvm-21 make ninja-build pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists && \
    rm -rf /var/cache/apt/archives
