FROM ghcr.io/openhundun/ubuntu:24
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
ENV PATH="/usr/lib/llvm-21/bin:${PATH}"
RUN \
    curl -fsSL -o /etc/apt/trusted.gpg.d/llvm.asc "https://apt.llvm.org/llvm-snapshot.gpg.key" && \
    tee /etc/apt/sources.list.d/llvm.sources > /dev/null <<EOF
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/llvm-apt/noble/
Suites: llvm-toolchain-noble-21
Components: main
Signed-By: /etc/apt/trusted.gpg.d/llvm.asc
EOF
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends ccache clang-21 cmake lld-21 llvm-21 make ninja-build pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists && \
    rm -rf /var/cache/apt/archives
