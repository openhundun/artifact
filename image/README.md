# image

## 命名与文件

- 文件路径固定为 `image/<name>/<name>:<tag>.dockerfile`,目录名与文件名一致。
- tag 规则:`<家族>-<语言>:<系统版本>-<语言版本>[-<工具版本>]`,例 `ubuntu-jdk:24-21`、`debian-jdk-maven:13-21-3.9`、`nix-python-uv:2.35.2-3.14-latest`。
- 工具在 nixpkgs 里只有一个版本、无法选择时,该字段写 `latest`(表示这一维随 nixpkgs 快照走,不承诺版本号;当前是 uv、bun)。
- 系统版本用大版本:`alpine:3`、`debian:13`、`ubuntu:24`、`nix:2.35.2`(与官方 tag 区分)。
- 组合镜像尽量继承自我们自己的镜像(`FROM ghcr.io/openhundun/...`),不重复安装基座已有的内容。

## 基础镜像包对照

所有条目都显式写进安装列表(幂等,便于统一增删)。

| 能力              | alpine(apk)          | debian / ubuntu(apt)       |
| ----------------- | -------------------- | -------------------------- |
| 根证书            | `ca-certificates`    | `ca-certificates`          |
| HTTP 客户端       | `curl`               | `curl`                     |
| 文件类型识别      | `file`               | `file`                     |
| Git               | `git`                | `git`                      |
| 路由 / 套接字     | `iproute2`           | `iproute2`                 |
| 连通性 ping       | `iputils`            | `iputils-ping`             |
| JSON 处理         | `jq`                 | `jq`                       |
| C++ 运行时        | `libstdc++`          | `libstdc++6`               |
| 打开的文件 / 端口 | `lsof`               | `lsof`                     |
| 端口探测 netcat   | `netcat-openbsd`     | `netcat-openbsd`           |
| 加解密 / 证书 CLI | `openssl`            | `openssl`                  |
| 进程工具          | `procps-ng`          | `procps`                   |
| 时区数据          | `tzdata`             | `tzdata`                   |
| 解压 / 压缩       | `unzip`、`xz`、`zip` | `unzip`、`xz-utils`、`zip` |

## 派生镜像包对照

| 镜像族        | alpine                                                           | debian / ubuntu                                                                                                                        |
| ------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `*-llvm`      | `ccache clang21 cmake gcc lld21 llvm21 make ninja-build pkgconf` | `ccache clang-21 cmake lld-21 llvm-21 make ninja-build pkg-config`(debian 的 `clang-21`/`lld-21`/`llvm-21` 来自 `trixie-backports` 源) |
| `*-llvm-zig`  | `zig=0.16.0-r1`(继承 `alpine-llvm`)                              | 继承 `debian-llvm` + 官方 zig tar 解到 `/opt/zig`                                                                                      |
| `*-python`    | 无                                                               | 官方 `python-build-standalone` 的 `install_only_stripped` tar 解到 `/opt/python`(与 `*-llvm-zig` 的 zig 同法)                          |
| `*-python-uv` | 无                                                               | 继承 `*-python` + `COPY --from=ghcr.io/astral-sh/uv:0.12.8 /uv /uvx` 到 `/usr/local/bin`                                               |
| `*-jdk`       | 无                                                               | `COPY --from=eclipse-temurin:<version>-jdk`                                                                                            |
| `*-jdk-maven` | 无                                                               | `COPY --from=maven:3.9.16-eclipse-temurin-<version>` + `settings.xml`                                                                  |
| `*-go`        | 无                                                               | `COPY --from=golang:<version>`                                                                                                         |

- alpine 家族只保留 `alpine:3`、`*-llvm`、`*-llvm-zig`,其余语言族只在 debian / ubuntu 上提供。
- `*-python` 的 `python-build-standalone` 锁定 release tag `20260825`(CPython `3.13.15` / `3.14.7`),URL 按 `TARGETARCH` 在 `PYTHON_URL_AMD64` / `PYTHON_URL_ARM64` 间选择;该发行版自带 OpenSSL / SQLite / Tcl-Tk 等,运行期不依赖发行版库,但不含 `dbm.gnu`(`dbm.ndbm` 与 `dbm.dumb` 正常)。
- `settings.xml` 为仓库根 `settings.xml` 原文,heredoc 写入 `/opt/maven/conf/settings.xml`(阿里云镜像 + 关闭 http blocker)。
- `nix-*` 不采用继承,由 `image/nix/flake.nix` 以 nix 语言组合。

## 书写约定

- 禁止注释;`ARG` / `ENV` 每行一个变量,值加双引号。
- 指令顺序:`FROM` → `LABEL` → `ARG` → `COPY --from` → `ENV` → `RUN`。
- 每个镜像在 `FROM` 之后紧跟一行 `LABEL org.opencontainers.image.source="https://github.com/openhundun/artifact"`,只写这一个键、值加双引号;ghcr 靠它把 package 关联到 `github.com/openhundun/artifact`。依赖 `ARG` 取值的 label 需另议(目前没有)。
- 不写 `CMD` / `ENTRYPOINT`:默认命令一律继承基座(`alpine` 链 `/bin/sh`,`debian` 链 `bash`,`ubuntu` 链 `/bin/bash`),组合镜像不挑其中某一个工具当默认。
- 多个 `ENV` 时按字段名字典序升序排列,`PATH` 固定放最后一个(避免 `*_HOME` 之类变量被字典序挤乱)。
- 多命令 `RUN` 折行:首行仅 `RUN \`,后续命令 4 空格缩进,行尾 `&& \`,末行不带。
- 选项一律前置(`curl -fsSL -o <file> "<url>"`、`tar -C <dir> --strip-components 1 --no-same-owner -xJf <archive>`),不保留 `--retry` 等重试参数;curl 写法以 `image/ubuntu-llvm-zig/ubuntu-llvm-zig:24-21-0.16.dockerfile` 为模板。
- `sed` 统一用 `|` 作分隔符:`sed -i 's|old|new|g'`。
- 安装列表按字典序;heredoc 正文不得改动,结束标记顶格。
- 每个镜像在支持下游复用的前提下尽量瘦身。

## 镜像内源

| 变量                            | 值                                                                | 生效范围                  |
| ------------------------------- | ----------------------------------------------------------------- | ------------------------- |
| `PIP_INDEX_URL`                 | `https://mirrors.ustc.edu.cn/pypi/simple`                         | `*-python`、`*-python-uv` |
| `PIP_DISABLE_PIP_VERSION_CHECK` | `1`                                                               | `*-python`、`*-python-uv` |
| `PYTHONFAULTHANDLER`            | `1`                                                               | `*-python`、`*-python-uv` |
| `PYTHONDONTWRITEBYTECODE`       | `1`                                                               | `*-python`、`*-python-uv` |
| `UV_DEFAULT_INDEX`              | `https://mirrors.ustc.edu.cn/pypi/simple`                         | `*-python-uv`             |
| `UV_PYTHON_INSTALL_MIRROR`      | `https://registry.npmmirror.com/-/binary/python-build-standalone` | `*-python-uv`             |

- `uv python install` 默认从 `https://github.com/astral-sh/python-build-standalone/releases/download` 取 `python-build-standalone`;`UV_PYTHON_INSTALL_MIRROR` 对这段前缀做**整段替换**,最终 URL 为 `<mirror>/<release-tag>/cpython-<版本>%2B<tag>-<triplet>-install_only_stripped.tar.gz`,所以值必须写到 repo 层。
- npmmirror 全量同步该项目的历史 tag(118 个,`20181218` 起),与 GitHub 资产字节一致;USTC 的 `github-release` 虽同构,但只保留最新一次 release,对旧 tag 返回 `302` 回源 GitHub,uv 会静默跟随 —— 表现为安装成功却不走镜像,故不采用。
- 备选值:`https://mirror.nju.edu.cn/github-release/astral-sh/python-build-standalone`(同样全量同步,实测端到端可用)。
- 不设 `PYTHONPYCACHEPREFIX`,改用 `PYTHONDONTWRITEBYTECODE=1` 从源头杜绝 `__pycache__` 在项目目录里扩散;两者性能实测持平(常用 import 集 5 次总耗时 906.8ms vs 899.9ms),但"不写"语义更稳、无落点假设。代价是每个进程重编译 stdlib(67ms vs 470ms 量级),长活容器拿不到"写一次、后续进程都命中"的收益 —— 已知并接受。
- 不做构建期 `compileall`:镜像保持不携带字节码(自带 3 个陈旧 pyc 从不被读取),避免 +16.3MB 落盘 / +6.4MB 层压缩,也避免与 `PYTHONDONTWRITEBYTECODE=1` 的语义纠缠。
- `PYTHONDONTWRITEBYTECODE=1` 只约束运行时的隐式字节码写入(项目目录实测 0 个 `__pycache__`);`pip install` 与 `python -m venv` 走显式编译,仍会在 venv 的 `site-packages` 内写字节码(实测 52–63 个),这是已知且接受的边界。
- `PIP_INDEX_URL` 实测有效:`pip config debug` 显示它来自 `env_var` 且无任何 pip.conf 竞争;反向对照(指向不存在主机)会硬失败而非回退 pypi.org;venv 内继承。注意 **uv 不读 `PIP_INDEX_URL`**,`*-python-uv` 依赖 `UV_DEFAULT_INDEX`。
- uv 侧用 `UV_DEFAULT_INDEX` 而非已废弃的 `UV_INDEX_URL`:实测两者同时设置时 `UV_DEFAULT_INDEX` 获胜、单独设置行为等价,属面向未来的等价切换。不设 `UV_LINK_MODE`:官方默认 `clone`→`hardlink`,实测硬链接产出的 venv 用 `cp -a` 复制后是完全独立的普通文件(新 inode)、`rm -rf` cache 后仍可 import,而 `copy` 模式在保留 cache 时多占 58.4 MiB。
- 不设 `PYTHONUTF8` / `PYTHONCOERCECLOCALE` / `PYTHONNOUSERSITE`:实测默认行为已正确(`utf8_mode=1`、`LC_CTYPE=C.UTF-8`、`sys.path` 无用户站点目录)。不设 `PYTHONWARNINGS` / `PYTHONHASHSEED` / `PYTHONSAFEPATH` / `PYTHONIOENCODING` / `PYTHONPATH` / `PYTHONHOME`:这些会把应用层策略强加给下游,实测可致崩溃或功能破坏。

## 构建与推送

发布走 GitHub Actions:`.github/workflows/publish.yaml` 手动触发,选发布分组(`all` / `alpine` / `debian` / `ubuntu` / `nix`),在自托管 runner 上构建并推送。

- **分组即家族名前缀**:`debian` 覆盖 `debian`、`debian-go`、`debian-jdk`、`debian-jdk-maven` …;`alpine`、`ubuntu` 同理。nix 家族是独立一组,镜像清单由 flake 实时枚举。
- **可见性**:workflow 用 `GITHUB_TOKEN` 推送,**包由 workflow 创建时继承仓库可见性(public)并自动关联仓库**,不需要任何 label / annotation。已经存在的包不会因此改变可见性;把包删掉、再由 workflow 重建,就会变成 public(实测)。
- **凭据隔离**:runner 上只拷 `/root/.docker/buildx`(builder 定义),不拷 `config.json`(那份存着本机 PAT),所以 CI 登录不会覆盖本机凭据。
- **重推流量**:包删除后 registry 仍保留底层 blob,实测重推一个 625.3 MiB 的包上行 0.0 MiB。

手工发布(需要本机已有 registry 凭据):

```sh
IMAGE_REGISTRY=ghcr.io/openhundun bash image/sh.sh list debian                         # 看分组包含哪些镜像
IMAGE_REGISTRY=ghcr.io/openhundun bash image/sh.sh publish debian                      # 分组
IMAGE_REGISTRY=ghcr.io/openhundun bash image/sh.sh publish ubuntu-llvm-zig             # 单个家族
IMAGE_REGISTRY=ghcr.io/openhundun bash image/sh.sh publish ubuntu-llvm-zig:24-21-0.16  # 单个镜像
IMAGE_REGISTRY=ghcr.io/openhundun bash image/nix/sh.sh publish all                     # nix 家族
```

`list` / `build` / `publish` 都接受同样的选择器;`build` 只写构建缓存、不推送。`IMAGE_REGISTRY` 缺省 `ghcr.io/openhundun`,`BUILDX_BUILDER` 缺省 `multiarch`,`PLATFORMS` 缺省 `linux/amd64,linux/arm64`。

**从 CLI 推送而不经过 workflow 时,必须让 index 携带 `org.opencontainers.image.source` 才会关联仓库** —— Dockerfile 里的 config `LABEL` 无效。对照实测(同一 Dockerfile、同一 builder、同一凭据,唯一变量是该 flag):只写 `LABEL`、或再叠加 `--provenance`、或改成单架构,三种都不关联;加上 `--annotation "index:org.opencontainers.image.source=…"` 的立刻关联成功。`image/sh.sh` 与 `image/nix/sh.sh` 都已把该 annotation 写进各自的推送路径。

- builder `multiarch` 内配置了 `ghcr.io` → `192.168.100.101:3000` 的镜像映射,因此 Dockerfile 里保留最终形态的 `FROM ghcr.io/openhundun/...`,测试期自动命中 gitea。
- 推送目标:gitea `192.168.100.101:3000/openhundun`(构建解析用)+ zot `192.168.100.101:5000/private`(交付,带 Trivy CVE 扫描);正式发布推 `ghcr.io/openhundun`。
- `all` 按基础镜像在前、派生镜像在后的顺序推送。
