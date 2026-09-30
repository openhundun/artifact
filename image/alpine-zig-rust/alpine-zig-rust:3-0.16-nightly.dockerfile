FROM ghcr.io/openhundun/alpine:3
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
ARG TARGETARCH
ENV CARGO_HOME="/usr/local/cargo"
ENV PATH="/usr/local/cargo/bin:${PATH}"
ENV RUSTUP_HOME="/usr/local/rustup"
ENV RUSTUP_DIST_SERVER="https://mirrors.ustc.edu.cn/rust-static"
ENV RUSTUP_UPDATE_ROOT="https://mirrors.ustc.edu.cn/rust-static/rustup"
ENV SCCACHE_DIR="/data/sccache"
RUN \
    TARGET="$(case "${TARGETARCH}" in amd64) echo "x86_64-unknown-linux-musl";; arm64) echo "aarch64-unknown-linux-musl";; *) exit 1;; esac)" && \
    apk add --no-cache rustup sccache zig=0.16.0-r1 && \
    rustup-init -y --default-host "${TARGET}" --default-toolchain nightly --no-modify-path --profile minimal && \
    rustup target add x86_64-unknown-linux-musl aarch64-unknown-linux-musl
RUN tee /usr/local/cargo/config.toml > /dev/null <<EOF
[net]
git-fetch-with-cli = true
[registries]
ustc = { index = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/" }
[source]
crates-io = { replace-with = "ustc" }
ustc      = { registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/" }
EOF
RUN cargo install cargo-zigbuild
