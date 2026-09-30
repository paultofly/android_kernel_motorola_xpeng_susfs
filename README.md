# android_kernel_motorola_xpeng_susfs

**Motorola Edge S30 (xpeng) · 5.4.302 non-GKI · ReSukiSU + SUSFS 2.3 + Re:Kernel + DroidSpaces**

[English](#english) · [中文](#中文)

---

## 中文

### 简介

本仓库为摩托罗拉 Edge S30（代号 **xpeng**，骁龙 888+，5.4 非 GKI 内核）提供完整移植的内核源码：

- **ReSukiSU**（内核级 Root 隐藏框架，SUSFS inline hook 模式）
- **SUSFS v2.3.0**（Secure User File System，支持 SUS_PATH / SUS_MOUNT / SUS_KSTAT / SUS_MAP / SPOOF_UNAME / SPOOF_CMDLINE / OPEN_REDIRECT / HIDE_SYMBOLS 全特性）
- **Re:Kernel**（冻结 App 的 Binder/Signal 感知）
- **DroidSpaces**（Linux 容器/虚拟化支持）

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

- NFC 默认关闭（本机无 NFC 机型），如需请开 `CONFIG_NFC_QTI_I2C=m`
- SUSFS 隐藏路径需在真机用 [ksu_susfs](https://gitlab.com/simonpunk/susfs4ksu) 工具验证
- 黑屏反复重启排查见 [PANIC_DEBUG_GUIDE.md](PANIC_DEBUG_GUIDE.md)

### 相关链接

- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
- [SUSFS](https://gitlab.com/simonpunk/susfs4ksu)
- [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel)
- [DroidSpaces](https://github.com/WeissRaben/DroidSpaces)

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
| LuoJuly/android_kernel_motorola_sm7325 `lineage-23.2-SUSFS` | 5.4 hook placement, Re:Kernel |
| AstideLabs/android_kernel_xiaomi_sm8250 | 4.19/5.4 legacy kernel adaptation reference |
| LuoJuly/android_kernel_motorola_xpeng_build `8-25` | Build scripts & base branch |

Full porting log (commit sources, 5.4 adaptation points, build env): [SUSFS_PORT_NOTES.md](SUSFS_PORT_NOTES.md).

### Known Limitations

- NFC disabled by default (this device variant has no NFC); enable `CONFIG_NFC_QTI_I2C=m` if needed
- Verify SUSFS hiding with the [ksu_susfs](https://gitlab.com/simonpunk/susfs4ksu) userspace tool
- Bootloop debugging: [PANIC_DEBUG_GUIDE.md](PANIC_DEBUG_GUIDE.md)

### Links

- [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
- [SUSFS](https://gitlab.com/simonpunk/susfs4ksu)
- [Re:Kernel](https://github.com/Sakion-Team/Re-Kernel)
- [DroidSpaces](https://github.com/WeissRaben/DroidSpaces)

---

## License

GPL-2.0-only (Linux Kernel). See [COPYING](COPYING).
