ARG IMAGE_REGISTRY="ghcr.io"

FROM --platform=${BUILDPLATFORM} ghcr.io/rust-cross/cargo-zigbuild:latest AS czb
ENV RUSTUP_DIST_SERVER="https://mirrors.cernet.edu.cn/rustup"
ENV RUSTUP_UPDATE_ROOT="https://mirrors.cernet.edu.cn/rustup/rustup"
RUN tee /usr/local/cargo/config.toml > /dev/null <<EOF
[net]
git-fetch-with-cli = true
[registries]
cernet = { index = "sparse+https://mirrors.cernet.edu.cn/crates.io-index/" }
[source]
crates-io = { replace-with = "cernet" }
cernet    = { registry = "sparse+https://mirrors.cernet.edu.cn/crates.io-index/" }
EOF
RUN rustup target add x86_64-unknown-linux-musl aarch64-unknown-linux-musl
RUN cargo install --force cargo-zigbuild
RUN \
    cd "$(ls -d /usr/local/cargo/registry/src/*/cargo-zigbuild-* | head -1)" && \
    cargo zigbuild --release --target x86_64-unknown-linux-musl && \
    cargo zigbuild --release --target aarch64-unknown-linux-musl && \
    mkdir -p /out/amd64 && \
    mkdir -p /out/arm64 && \
    cp target/x86_64-unknown-linux-musl/release/cargo-zigbuild /out/amd64/cargo-zigbuild && \
    cp target/aarch64-unknown-linux-musl/release/cargo-zigbuild /out/arm64/cargo-zigbuild

FROM ${IMAGE_REGISTRY}/openhundun/alpine-llvm-zig:3-21-0.16 AS runtime
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
ARG TARGETARCH
ENV CARGO_HOME="/usr/local/cargo"
ENV RUSTUP_HOME="/usr/local/rustup"
ENV RUSTUP_DIST_SERVER="https://mirrors.cernet.edu.cn/rustup"
ENV RUSTUP_UPDATE_ROOT="https://mirrors.cernet.edu.cn/rustup/rustup"
ENV PATH="/usr/local/cargo/bin:${PATH}"
COPY --from=docker.io/rustlang/rust:nightly-alpine /usr/local/cargo/bin /usr/local/cargo/bin
COPY --from=docker.io/rustlang/rust:nightly-alpine /usr/local/rustup /usr/local/rustup
COPY --from=czb /usr/local/cargo/config.toml /usr/local/cargo/config.toml
COPY --from=czb "/out/${TARGETARCH}/cargo-zigbuild" /usr/local/cargo/bin/cargo-zigbuild
RUN rustup target add x86_64-unknown-linux-musl aarch64-unknown-linux-musl
