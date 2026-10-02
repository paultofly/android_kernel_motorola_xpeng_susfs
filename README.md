# android_kernel_motorola_xpeng_susfs

**Motorola Edge S30 (xpeng) · 5.4.302 non-GKI · ReSukiSU + SUSFS 2.3 + Re:Kernel + DroidSpaces**

[![GitHub release](https://img.shields.io/github/v/release/paultofly/android_kernel_motorola_xpeng_susfs?include_prereleases&label=release)](https://github.com/paultofly/android_kernel_motorola_xpeng_susfs/releases)
[![Kernel](https://img.shields.io/badge/kernel-5.4.302-blue)](https://github.com/paultofly/android_kernel_motorola_xpeng_susfs)
[![SUSFS](https://img.shields.io/badge/SUSFS-v2.3.0-green)](https://gitlab.com/simonpunk/susfs4ksu)

[English](#english) · [中文](#中文)

---

## 中文

### 简介

本仓库为摩托罗拉 Edge S30（代号 **xpeng**，骁龙 888+，5.4 非 GKI 内核）提供完整移植的内核源码：

- **ReSukiSU**（内核级 Root 隐藏框架，SUSFS inline hook 模式）
- **SUSFS v2.3.0**（Secure User File System，支持 SUS_PATH / SUS_MOUNT / SUS_KSTAT / SUS_MAP / SPOOF_UNAME / SPOOF_CMDLINE / OPEN_REDIRECT / HIDE_SYMBOLS 全特性）
- **Re:Kernel**（冻结 App 的 Binder/Signal 感知）
- **DroidSpaces**（Linux 容器/虚拟化支持）
- **BBRv3 + TCP Brutal**（网络拥塞控制优化）

### 最新 Release

| 版本 | 日期 | 说明 | 下载 |
|------|------|------|------|
| **r8** | 2026-10-02 | SUSFS v2.3 完整修复（paulcbfly 套装，KernelSU v4.1.0） | [Release](https://github.com/paultofly/android_kernel_motorola_xpeng_susfs/releases/tag/susfs2.3-droidspace-rekernel-r8) |

> ⚠️ **重要**：r8 使用 **KernelSU v4.1.0**（paulcbfly 配套版），与 ReSukiSU v4.2.0-rc3 不兼容。SUSFS 路径隐藏**已验证生效**。

### 构建

```bash
git clone https://github.com/paultofly/android_kernel_motorola_xpeng_susfs.git
cd android_kernel_motorola_xpeng_susfs

# 安装依赖（Ubuntu 22.04+）
sudo apt-get install bison flex bc libssl-dev libelf-dev cpio python3 git

# 构建（自动下载工具链，产出 boot_ksu.img）
bash .ci/build.sh
```

产物：`.ci-work/release/boot_ksu.img`（可刷入 boot 分区）。

### 刷入

```bash
fastboot flash boot boot_ksu.img
```

> ⚠️ 建议先 `fastboot boot boot_ksu.img` 临时启动测试，确认无误后再 flash。
> 需 OEM 解锁（Bootloader Unlocked）。

### 移植来源

| 来源 | 用途 |
|---|---|
| [simonpunk/susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu) `gki-android12-5.10` | SUSFS 2.3.0 核心 |
| [LuoJuly/android_kernel_motorola_sm7325](https://github.com/LuoJuly/android_kernel_motorola_sm7325) `lineage-23.2-SUSFS` | 5.4 钩子落点与 Re:Kernel |
| [AstideLabs/android_kernel_xiaomi_sm8250](https://github.com/AstideLabs/android_kernel_xiaomi_sm8250) | 4.19/5.4 旧内核适配参考 |
| [LuoJuly/android_kernel_motorola_xpeng_build](https://github.com/LuoJuly/android_kernel_motorola_xpeng_build) `8-25` | 构建脚本与基础分支 |

详细移植记录（commit 来源、5.4 适配修改点、构建环境）见 [SUSFS_PORT_NOTES.md](SUSFS_PORT_NOTES.md)。

### 已知限制

- **KernelSU 版本**：r8 使用 v4.1.0-1332（paulcbfly 配套），非最新 v4.2.0-rc3
- **SUSFS 机制**：不依赖 `TIF_PROC_UMOUNTED`，直接通过 `inode->i_state` 标志隐藏；所有非 root 进程（uid != 0）不可见标记路径
- **NFC**：默认关闭（本机无 NFC 机型），如需请开 `CONFIG_NFC_QTI_I2C=m`
- **WiFi 模块**：需单独刷入 `wlan_crc_match_*.zip` 或编译时 `BUILD_WLAN=true`
- **黑屏排查**：见 [PANIC_DEBUG_GUIDE.md](PANIC_DEBUG_GUIDE.md)

### SUSFS 验证

```bash
# 确认初始化
adb shell 'su 0 dmesg | grep "susfs is initialized"'
# 预期: "susfs is initialized! version: v2.3.0"

# 添加隐藏路径
adb shell 'su 0 ksu_susfs add_sus_path /data/local/tmp/test'

# root 可见，非 root 不可见
adb shell 'su 0 ls /data/local/tmp/test'    # 正常
adb shell 'ls /data/local/tmp/test'          # No such file or directory
```

### 相关链接

- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
- [SUSFS](https://gitlab.com/simonpunk/susfs4ksu)
- [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel)
- [DroidSpaces](https://github.com/WeissRaben/DroidSpaces)
- [paulcbfly 5.4 SUSFS 适配](https://github.com/paulcbfly/android_kernel_motorola_xpeng)

---

## English

### Introduction

Kernel source for **Motorola Edge S30 (xpeng)** — Snapdragon 888+, 5.4 non-GKI:

- **ReSukiSU** — kernel-level root hiding framework (SUSFS inline hook mode)
- **SUSFS v2.3.0** — Secure User File System, all features enabled (SUS_PATH, SUS_MOUNT, SUS_KSTAT, SUS_MAP, SPOOF_UNAME, SPOOF_CMDLINE, OPEN_REDIRECT, HIDE_SYMBOLS)
- **Re:Kernel** — binder/signal awareness for frozen apps
- **DroidSpaces** — Linux container / virtualization support

### Build

```bash
git clone https://github.com/paultofly/android_kernel_motorola_xpeng_susfs.git
cd android_kernel_motorola_xpeng_susfs

sudo apt-get install bison flex bc libssl-dev libelf-dev cpio python3 git
bash .ci/build.sh
```

Output: `.ci-work/release/boot_ksu.img`

### Flash

```bash
fastboot flash boot boot_ksu.img
```

> ⚠️ Test first with `fastboot boot boot_ksu.img`. Bootloader must be unlocked.

### Porting Sources

| Source | Role |
|---|---|
| simonpunk/susfs4ksu `gki-android12-5.10` | SUSFS 2.3.0 core |
| paulcbfly/android_kernel_motorola_xpeng `5.4.302-s3rxc32.33-8-25-susfs-modules-v2.3-astide` | 5.4 SUSFS v2.3 complete adaptation (22 files) |
| LuoJuly/android_kernel_motorola_sm7325 `lineage-23.2-SUSFS` | 5.4 hook placement, Re:Kernel |
| AstideLabs/android_kernel_xiaomi_sm8250 | 4.19/5.4 legacy kernel adaptation reference |
| LuoJuly/android_kernel_motorola_xpeng_build `8-25` | Build scripts & base branch |

Full porting log (commit sources, 5.4 adaptation points, build env): [SUSFS_PORT_NOTES.md](SUSFS_PORT_NOTES.md).

### Latest Release

| Version | Date | Notes | Download |
|---------|------|-------|----------|
| **r8** | 2026-10-02 | SUSFS v2.3 complete fix (paulcbfly set, KernelSU v4.1.0) | [Release](https://github.com/paultofly/android_kernel_motorola_xpeng_susfs/releases/tag/susfs2.3-droidspace-rekernel-r8) |

> **Note**: r8 uses **KernelSU v4.1.0** (paulcbfly matched version), not compatible with ReSukiSU v4.2.0-rc3. SUSFS path hiding **verified working**.

### Known Limitations

- **KernelSU version**: r8 uses v4.1.0-1332 (paulcbfly matched), not the latest v4.2.0-rc3
- **SUSFS mechanism**: Does not rely on `TIF_PROC_UMOUNTED`; hides via `inode->i_state` flag directly. All non-root processes (uid != 0) cannot see marked paths
- **NFC**: Disabled by default (this device variant has no NFC); enable `CONFIG_NFC_QTI_I2C=m` if needed
- **WiFi modules**: Must flash `wlan_crc_match_*.zip` separately or build with `BUILD_WLAN=true`
- **Bootloop debugging**: See [PANIC_DEBUG_GUIDE.md](PANIC_DEBUG_GUIDE.md)

### SUSFS Verification

```bash
# Check initialization
adb shell 'su 0 dmesg | grep "susfs is initialized"'
# Expected: "susfs is initialized! version: v2.3.0"

# Add hidden path
adb shell 'su 0 ksu_susfs add_sus_path /data/local/tmp/test'

# root can see, non-root cannot
adb shell 'su 0 ls /data/local/tmp/test'    # OK
adb shell 'ls /data/local/tmp/test'          # No such file or directory
```

### Links

- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
- [SUSFS](https://gitlab.com/simonpunk/susfs4ksu)
- [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel)
- [DroidSpaces](https://github.com/WeissRaben/DroidSpaces)
- [paulcbfly 5.4 SUSFS adaptation](https://github.com/paulcbfly/android_kernel_motorola_xpeng)

---

## License

GPL-2.0-only (Linux Kernel). See [COPYING](COPYING).
