# rtl8852bu-dkms

morrownr/rtl8852bu 上游驱动打包为 **DKMS deb**：安装即编译，内核升级自动重编，任意 Debian/Ubuntu 架构通用（`Architecture: all`，编译发生在目标机）。仓库自包含（固件随仓），`build.sh` 一条命令出包，产物不入仓。

## 仓库布局

```
rtl8852bu-dkms/
├── README.md              # 本文档
├── build.sh               # 构建入口（拉源码 → 打补丁 → 组装 → dpkg-deb）
├── debian/                # Debian 打包元数据（Policy §4.1 官方布局）
│   ├── control            # 包元数据（必需字段）
│   ├── postinst           # 安装钩子：对所有已装内核逐个 build/install
│   └── prerm              # 卸载钩子：dkms remove
├── dkms.conf             # → /usr/src/rtl8852bu-<ver>/dkms.conf（DKMS 必需；路径带版本号，归动态注入层）
└── rootfs/               # 模拟 rootfs 静态片段（FHS 树，build.sh 整树并入 $ROOT）
    └── etc/usb_modeswitch.d/0bda:1a2b        # → /etc/usb_modeswitch.d/0bda:1a2b
    └── lib/firmware/rtl8852b/rtl8852bfw_rom.bin  # → /lib/firmware/rtl8852b/
```

`rootfs/` 直接以 `/` 为根按 FHS 摆放（路径即目标路径，零映射）；唯一例外是 `dkms.conf`——目标路径带构建期版本号，由 build.sh 动态注入。

## 包内容

| 路径                                        | 内容                                               |
| ------------------------------------------- | -------------------------------------------------- |
| `/usr/src/rtl8852bu-20250826/`              | 上游驱动源码（已打 `__DATE__` patch）+ `dkms.conf` |
| `/lib/firmware/rtl8852b/rtl8852bfw_rom.bin` | 固件（内核 rtw89 固件改名，实测可用；源=`rootfs/lib/firmware/rtl8852b/`）|
| `/etc/usb_modeswitch.d/0bda:1a2b`           | Realtek 驱动光盘 → 无线模式切换规则（源=`rootfs/etc/usb_modeswitch.d/0bda:1a2b`）|

## 构建

```bash
apt install git dpkg-dev
./build.sh
```

脚本步骤：取源码（默认 `git clone` 上游；网络不通时 `SRC=src.tar.gz` 离线源，tar 内需含 `rtl8852bu-20250826/` 顶层目录）→ `__DATE__` patch → 组装 → `dpkg-deb --build`。可覆盖变量：`OUT=`（产物目录）、`SRC=`（离线源）。固件无变量——由 `rootfs/lib/firmware/` 静态承载（整树复制）。

## 安装

```bash
sudo apt install ./rtl8852bu-dkms_20250826-1_all.deb
```

**升级/重装**（同版本号内容更新时 `apt install` 会静默跳过，必须强制重装）：

```bash
sudo apt install --reinstall ./rtl8852bu-dkms_20250826-1_all.deb   # 或
sudo dpkg -i ./rtl8852bu-dkms_20250826-1_all.deb
```

postinst 自动：清旧版本 DKMS 注册 → 遍历 `/lib/modules/*/build` 对**所有已装 headers 的内核**逐个 build+install（实测 -4 的 `dkms autoinstall` 对非运行内核静默跳过，不可依赖）→ `depmod`。linux-headers 全缺时跳过构建，下次内核安装时由 dkms 钩子补编。插卡即用。

## 卸载

```bash
sudo apt remove rtl8852bu-dkms
```

prerm 自动 `dkms remove`，固件/规则一并移除。

## 兼容性

- **内核**：5.15 ~ 7.1（上游官方 5.15-6.14，社区 6.15-7.1）
- **系统**：Debian 12/13、Ubuntu 22.04+
- **设备**：RTL8852BU / RTL8832BU 全系（绿联 CM499、TP-Link TX20U、COMFAST CF-943AX 等），`0bda:b832` 直接绑定

## 实测记录

| 平台                                | 内核                | 结果                                                                                                                                                    |
| ----------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Debian 13 (vm-013, arm64)           | 6.12.101 + 6.12.105 | -5 安装即双内核 build/install ✓，modprobe 后 `wlx6c1ff73c3a7e` 接口生成，hostapd AP 实跑；apt 内核升级事务中 AUTOINSTALL 自动为 105 补编（-2 时代实测） |
| Debian 13 (j1900, amd64, Bay Trail) | 6.12.101 + 6.12.105 | -5 安装即双内核 build/install ✓（各 ~6min），modeswitch→b832，模块自载，hostapd AP 实跑（生产主路由）                                                   |
| Ubuntu 26.04 (ubuntu-026, arm64)    | 7.0.0-30-generic    | build/install ✓（验证上游 7.1 适配覆盖 7.0），modprobe ✓                                                                                                |

## 版本

| 版本       | 变更                                                                                                                                     |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| 20250826-1 | 版本号策略：**统一 revision=1**，内容演进不 bump 版本（release 覆盖上传）；历史变更见下 |
| 20250826-5 | postinst 显式遍历 `/lib/modules/*/build` 逐内核构建；build.sh 增 `SRC=` 离线源                                                           |
| 20250826-4 | postinst 改 `dkms autoinstall`（对非运行内核静默跳过，未达预期，被 -5 取代）                                                             |
| 20250826-3 | 补回一行 `Description` + 匿名 `Maintainer`（`root <root@localhost>`）：缺这两字段 dpkg-query 每次解析 status 库都告警，污染整机 apt 输出 |
| 20250826-2 | Depends 增加 `bc`（Realtek Makefile 硬依赖）；仓库自包含（固件入仓）；control 精简；modprobe.conf 移出包（零生效配置）                   |
| 20250826-1 | 初版                                                                                                                                     |

升级版本号需同步 3 处：`build.sh`（`REV`）、`debian/control`（`Version`）、`dkms.conf`（`PACKAGE_VERSION`，仅上游快照号变化时）；`postinst`/`prerm` 里的 `20250826` 跟 `dkms.conf` 走。

## 坑（维护时注意）

1. **`__DATE__/__TIME__` patch 必打**：内核 kbuild 对 OOT 模块强制 `-Werror=date-time`，上游未修
2. **dkms.conf 必须用上游写法**：`MAKE="kernelver=$kernelver ./dkms-make.sh"`；裸 `make` 会 `include /common.mk` 失败
3. **bc 已入 Depends**：Realtek Makefile 用 bc 做内核版本比较
4. **Debian 的 usb-modeswitch-data 无 `0bda:1a2b` 规则**：必须随包自带
5. **USB3 模式默认不开**：`rtw_switch_usb_mode=1` 裸机可提 USB 吞吐，但 Parallels/VMware 直通下丢设备；要开用 `modprobe 8852bu rtw_switch_usb_mode=1` 临时传参或自建 `/etc/modprobe.d/` 文件
6. **安装必须 `apt install ./deb`**（解析依赖）；`dpkg -i` 会留 broken 状态
7. **Ubuntu 无 `linux-headers-arm64` meta**：Recommends 三选一 `linux-headers-generic | amd64 | arm64`
8. **已发布版本号永不改内容**：改打包就 bump revision，同号重装 apt 会拒
