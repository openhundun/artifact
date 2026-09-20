FROM ghcr.io/openhundun/alpine-llvm:3-21
LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"
RUN apk add --no-cache zig=0.16.0-r1
