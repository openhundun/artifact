# image

## OS

| `nix:2.35.2`      | `alpine:3`        | `debian:13`       | `ubuntu:24`       | 描述                   |
| ----------------- | ----------------- | ----------------- | ----------------- | ---------------------- |
| `bashInteractive` | (自带)            | (自带)            | (自带)            | 交互式 shell           |
| `bzip2`           | (自带)            | (自带)            | (自带)            | bzip2 压缩             |
| `cacert`          | `ca-certificates` | `ca-certificates` | `ca-certificates` | TLS 根证书与 CA bundle |
| `coreutils`       | (自带)            | (自带)            | (自带)            | ls / cp 等基础工具     |
| `curl`            | `curl`            | `curl`            | `curl`            | HTTP/HTTPS 客户端      |
| `file`            | `file`            | `file`            | `file`            | 文件类型识别           |
| `findutils`       | (自带)            | (自带)            | (自带)            | find / xargs           |
| `gawk`            | (自带)            | (自带)            | (自带)            | awk 实现               |
| `git`             | `git`             | `git`             | `git`             | 版本控制               |
| `gnugrep`         | (自带)            | (自带)            | (自带)            | grep                   |
| `gnused`          | (自带)            | (自带)            | (自带)            | sed                    |
| `gnutar`          | (自带)            | (自带)            | (自带)            | tar                    |
| `gzip`            | (自带)            | (自带)            | (自带)            | gzip 压缩              |
| `iproute2`        | `iproute2`        | `iproute2`        | `iproute2`        | ip / ss 等网络配置     |
| `iputils`         | `iputils`         | `iputils-ping`    | `iputils-ping`    | ping 等网络探测        |
| `jq`              | `jq`              | `jq`              | `jq`              | JSON 处理              |
| `libgcc`          | `libstdc++`       | `libstdc++6`      | `libstdc++6`      | C++ 运行时             |
| `lsof`            | `lsof`            | `lsof`            | `lsof`            | 查看打开的文件         |
| `netcat-openbsd`  | `netcat-openbsd`  | `netcat-openbsd`  | `netcat-openbsd`  | TCP/UDP 连接工具       |
| `openssl`         | `openssl`         | `openssl`         | `openssl`         | TLS 工具与库           |
| `patch`           | `patch`           | `patch`           | `patch`           | 应用补丁               |
| `procps`          | `procps-ng`       | `procps`          | `procps`          | ps / top 等进程工具    |
| `tzdata`          | `tzdata`          | `tzdata`          | `tzdata`          | 时区数据库             |
| `unzip`           | `unzip`           | `unzip`           | `unzip`           | zip 解压               |
| `xz`              | `xz`              | `xz-utils`        | `xz-utils`        | xz 压缩                |
| `zip`             | `zip`             | `zip`             | `zip`             | zip 压缩               |

## Toolchain

| toolchain | `nix:2.35.2`                                          | `alpine:3`                                                                                                            | `debian:13` | `ubuntu:24`                                                                                                         |
| --------- | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------- |
| `llvm`    | (暂无)                                                | `ccache` + `clang21` + `cmake` + `gcc` + `lld21` + `llvm21` + `make` + `mold` + `ninja-build` + `pkgconf` + `sccache` | (暂无)      | `ccache` + `clang-21` + `cmake` + `lld-21` + `llvm-21` + `make` + `mold` + `ninja-build` + `pkg-config` + `sccache` |
| `zig`     | (暂无)                                                | `zig=0.16.0-r1`                                                                                                       | (暂无)      | (ZIP)                                                                                                               |
| `rust`    | (暂无)                                                | `rustup`                                                                                                              | (暂无)      | `COPY --from=docker.io/rust`                                                                                        |
| `go`      | `go_1_27`                                             | (暂无)                                                                                                                | (暂无)      | `COPY --from=docker.io/library/golang`                                                                              |
| `python`  | `python313` / `python314`                             | (暂无)                                                                                                                | (暂无)      | (ZIP)                                                                                                               |
| `uv`      | `uv`                                                  | (暂无)                                                                                                                | (暂无)      | `COPY --from=ghcr.io/astral-sh/uv`                                                                                  |
| `bun`     | `bun`                                                 | (暂无)                                                                                                                | (暂无)      | `COPY --from=docker.io/oven/bun`                                                                                    |
| `jdk`     | `jdk8_headless` / `jdk21_headless` / `jdk25_headless` | (暂无)                                                                                                                | (暂无)      | `COPY --from=docker.io/library/eclipse-temurin`                                                                     |
| `maven`   | (暂无)                                                | (暂无)                                                                                                                | (暂无)      | `COPY --from=docker.io/library/maven`                                                                               |
