ARG IMAGE_REGISTRY="ghcr.io"

FROM ${IMAGE_REGISTRY}/openhundun/ubuntu:24
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
ENV SCCACHE_DIR="/data/sccache"
ENV PATH="/usr/lib/llvm-21/bin:${PATH}"
RUN \
    curl -fsSL -o /etc/apt/keyrings/llvm-snapshot.asc "https://apt.llvm.org/llvm-snapshot.gpg.key" && \
    tee /etc/apt/sources.list.d/llvm.sources > /dev/null <<EOF
Types: deb
URIs: http://mirrors.cernet.edu.cn/llvm-apt/noble
Suites: llvm-toolchain-noble-21
Components: main
Signed-By: /etc/apt/keyrings/llvm-snapshot.asc
EOF
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends ccache clang-21 cmake lld-21 llvm-21 make mold ninja-build pkg-config sccache && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists && \
    rm -rf /var/cache/apt/archives
RUN \
    ln -sfn /usr/lib/llvm-21/bin/clang /usr/local/bin/cc && \
    ln -sfn /usr/lib/llvm-21/bin/ld.lld /usr/local/bin/ld
