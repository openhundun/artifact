# openhundun artifact

构建产物与打包源码的归档仓库。

## 结构

| 目录     | 内容                                         |
| -------- | -------------------------------------------- |
| `deb/`   | Debian/Ubuntu 软件包源码（可自行构建出 deb） |
| `image/` | 容器镜像相关构建文件                         |
| `chart/` | Helm chart（预留）                           |

## deb

- `rtl8852bu/` — RTL8852BU/RTL8832BU USB Wi-Fi 6 网卡驱动（上游 [morrownr/rtl8852bu-20250826](https://github.com/morrownr/rtl8852bu-20250826)），包目录自包含：`cd deb/rtl8852bu && ./sh.sh` 构建，包名/版本号自动取自上游 `dkms.conf`，安装即编译、内核升级自动重编

预编译 deb 见 [GitHub Releases](https://github.com/openhundun/artifact/releases)。
