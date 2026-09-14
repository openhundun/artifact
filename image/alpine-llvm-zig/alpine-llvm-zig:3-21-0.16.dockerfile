FROM ghcr.io/openhundun/alpine-llvm:3-21
RUN apk add --no-cache zig=0.16.0-r1
CMD ["zig", "version"]
