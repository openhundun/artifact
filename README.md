# openhundun artifact

构建产物与打包源码的归档仓库。

## 结构

| 目录     | 内容                                         |
| -------- | -------------------------------------------- |
| `deb/`   | Debian/Ubuntu 软件包源码（可自行构建出 deb） |
| `image/` | 容器镜像相关构建文件                         |
| `chart/` | Helm chart（预留）                           |

## deb

- `rtl8852bu-dkms/` — RTL8852BU/RTL8832BU USB Wi-Fi 6 网卡 DKMS 驱动包，安装即编译、内核升级自动重编。预编译 deb 见 [GitHub Releases](https://github.com/openhundun/artifact/releases)，构建见其目录内 README。
