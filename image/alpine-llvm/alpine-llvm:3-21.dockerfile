ARG IMAGE_REGISTRY="ghcr.io"

FROM ${IMAGE_REGISTRY}/openhundun/alpine:3
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
ENV SCCACHE_DIR="/data/sccache"
ENV PATH="/usr/lib/llvm21/bin:${PATH}"
RUN apk add --no-cache ccache clang21 cmake gcc lld21 llvm21 make mold ninja-build pkgconf sccache
RUN \
    ln -sfn /usr/lib/llvm21/bin/clang /usr/local/bin/cc && \
    ln -sfn /usr/bin/ld.lld /usr/local/bin/ld && \
    ln -sfn /usr/lib/ninja-build/bin/ninja /usr/local/bin/ninja
