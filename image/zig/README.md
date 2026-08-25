```sh
sudo podman build \
    --file 0.15.dockerfile \
    --manifest ghcr.io/openhundun/zig:0.15 \
    --platform linux/amd64,linux/arm64 \
    --build-arg ZIG_URL_AMD64=http://192.168.8.8:8080/zig-x86_64-linux-0.15.2.tar.xz \
    --build-arg ZIG_URL_ARM64=http://192.168.8.8:8080/zig-aarch64-linux-0.15.2.tar.xz \
    .
```

```sh
sudo podman manifest push --all ghcr.io/openhundun/zig:0.15
```
