FROM ghcr.io/openhundun/ubuntu-llvm:24-21
ARG TARGETARCH
ARG ZIG_URL_AMD64="https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz"
ARG ZIG_URL_ARM64="https://ziglang.org/download/0.16.0/zig-aarch64-linux-0.16.0.tar.xz"
ENV PATH="/opt/zig:${PATH}"
RUN \
    ZIG_URL="$(case "${TARGETARCH}" in amd64) echo "${ZIG_URL_AMD64}";; arm64) echo "${ZIG_URL_ARM64}";; *) exit 1;; esac)" && \
    mkdir -p /opt/zig && \
    curl -fsSL -o /tmp/zig.tar.xz "${ZIG_URL}" && \
    tar -C /opt/zig --strip-components 1 --no-same-owner -xJf /tmp/zig.tar.xz && \
    rm -rf /tmp/zig.tar.xz
CMD ["zig", "version"]
