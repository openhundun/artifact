FROM ghcr.io/openhundun/alpine:3
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
ENV PATH="/usr/lib/llvm21/bin:${PATH}"
RUN \
    apk add --no-cache ccache clang21 cmake gcc lld21 llvm21 make ninja-build pkgconf && \
    ln -sfn /usr/bin/ld.lld /usr/bin/ld && \
    ln -sfn /usr/lib/ninja-build/bin/ninja /usr/bin/ninja
