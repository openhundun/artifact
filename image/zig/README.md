```sh
docker buildx build \
    --file 0.16.dockerfile \
    --platform linux/amd64,linux/arm64 \
    --output type=oci,dest=zig-0.16.tar \
    --build-arg ZIG_URL_AMD64=http://192.168.8.8:8080/zig-x86_64-linux-0.16.0.tar.xz \
    --build-arg ZIG_URL_ARM64=http://192.168.8.8:8080/zig-aarch64-linux-0.16.0.tar.xz \
    .
```

```sh
skopeo copy --all oci-archive:zig-0.16.tar docker://ghcr.io/openhundun/zig:0.16
```
