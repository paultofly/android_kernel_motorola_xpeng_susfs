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

**方式一：GitHub Actions 模块化构建（推荐）**

仓库内置可配置工作流 [`.github/workflows/build-modular.yml`](.github/workflows/build-modular.yml)：
在 GitHub 网页 **Actions → 模块化构建 xpeng 5.4.302 ReSukiSU (Edge S30) → Run workflow**，
勾选需要的模块即可（可任意组合）：

| 输入 | 默认 | 说明 |
|------|------|------|
| `build_round` | 自动 | 编译轮次 N。**留空 = 自动从 GitHub 获取**：扫描已有 `-r<N>` 标签取最大值 +1（如已有 r8 → 本次 r9）；也可手动填数字覆盖 |
| `enable_susfs` | ✅ | SUSFS v2.3（路径/挂载/KSTAT 隐藏、uname/cmdline 欺骗、open 重定向） |
| `enable_rekernel` | ✅ | Re:Kernel（冻结 App 的 Binder/Signal 感知） |
| `enable_droidspaces` | ✅ | DroidSpaces 容器（USER_NS / IPC_NS / PID_NS 等） |
| `enable_nomount` | ✅ | NoMount（对 App 隐藏挂载） |
| `enable_bbrv3` | ✅ | BBRv3 + TCP Brutal（默认拥塞控制 bbr） |
| `enable_lz4k` | ✅ | LZ4K 压缩算法 |
| `build_wlan` | ❌ | 编译 WiFi 模块（qca_cld3）。**不推荐**：通用预编译模块即可 |
| `update_resukisu` | ❌ | 更新 KernelSU 到最新 main（会破坏 r8 验证过的组合，慎用） |

产物命名规则（`<模块组合>` 按实际勾选拼接，顺序 rekernel→droidspaces→nomount→lz4k→bbrv3→susfs；全不选则为 `base`）：

- `boot_resukisu_<模块组合>_r<N>.img` — boot 镜像
- `AK3_Xpeng_<模块组合>_r<N>.zip` — AnyKernel3 刷机包
- `Image`、`SHA256SUMS_r<N>.txt`

每次运行**新建 Release + 新 tag**（`resukisu-<模块组合>-r<N>`），发布页面自动列出**支持/不支持**的模块表。
若算出的 tag 已存在会**拒绝构建**（绝不覆盖已发布版本）。轮次全局递增，与历史 `susfs2.3-*-r8` 等标签共用计数器。

> ⚙️ 模块开关实现：[`.ci/apply_module_config.sh`](.ci/apply_module_config.sh) 按选择改写
> `arch/arm64/configs/vendor/ext_config/moto-lahaina-xpeng.config` 并提交到 HEAD
> （保证 vermagic 仍为 `5.4.302-moto`，vendor 模块兼容）。
> 注意：SUSFS 是 KernelSU hook 方式三选一之一，禁用时会自动改用 Manual Hook。

**方式二：本地构建（开发用）**

```bash
# 依赖：bison flex bc libssl-dev libelf-dev cpio python3 git
git clone https://github.com/LuoJuly/android_kernel_motorola_xpeng_build.git build
cd build

# 可选：先注入模块选择（默认全开）
KERNEL_SRC=/path/to/kernel bash /path/to/kernel/.ci/apply_module_config.sh

VARIANT=edge-s30 KERNEL_SRC=/path/to/kernel BUILD_WLAN=false \
  UPDATE_RESUKISU=false bash scripts/ci/build_resukisu_boot.sh
```

产物：`build/.ci-work/edge-s30/release/boot_ksu.img`。

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

**Option 1: GitHub Actions modular build (recommended)**

The repo ships a configurable workflow [`.github/workflows/build-modular.yml`](.github/workflows/build-modular.yml).
On GitHub: **Actions → 模块化构建 xpeng 5.4.302 ReSukiSU (Edge S30) → Run workflow**, then tick the modules you want (any combination):

| Input | Default | Description |
|-------|---------|-------------|
| `build_round` | auto | Build round N. **Leave empty = auto from GitHub**: scans existing `-r<N>` tags and takes max + 1 (e.g. r8 exists → this run is r9); a number overrides it |
| `enable_susfs` | ✅ | SUSFS v2.3 (path/mount/kstat hiding, uname/cmdline spoof, open redirect) |
| `enable_rekernel` | ✅ | Re:Kernel (binder/signal awareness for frozen apps) |
| `enable_droidspaces` | ✅ | DroidSpaces containers (USER_NS / IPC_NS / PID_NS …) |
| `enable_nomount` | ✅ | NoMount (hide mounts from apps) |
| `enable_bbrv3` | ✅ | BBRv3 + TCP Brutal (default congestion control `bbr`) |
| `enable_lz4k` | ✅ | LZ4K compression |
| `build_wlan` | ❌ | Build WiFi modules (qca_cld3). **Not recommended** — the generic prebuilt works |
| `update_resukisu` | ❌ | Update KernelSU to latest main (breaks the r8-verified set; use with care) |

Artifact naming (`<modules>` reflects what was selected, order rekernel→droidspaces→nomount→lz4k→bbrv3→susfs; `base` if none):

- `boot_resukisu_<modules>_r<N>.img` — boot image
- `AK3_Xpeng_<modules>_r<N>.zip` — AnyKernel3 flashable zip
- `Image`, `SHA256SUMS_r<N>.txt`

Each run creates a **new Release + new tag** (`resukisu-<modules>-r<N>`); the release page lists which modules are supported/unsupported.
If the computed tag already exists the build is **rejected** (published releases are never overwritten). The counter is global and continuous with legacy tags like `susfs2.3-*-r8`.

> ⚙️ How it works: [`.ci/apply_module_config.sh`](.ci/apply_module_config.sh) rewrites
> `arch/arm64/configs/vendor/ext_config/moto-lahaina-xpeng.config` from the selected modules and commits it to HEAD
> (keeps vermagic `5.4.302-moto` so vendor modules stay compatible).
> Note: SUSFS is one of the three KernelSU hook modes; disabling it switches to Manual Hook automatically.

**Option 2: local build (development)**

```bash
git clone https://github.com/LuoJuly/android_kernel_motorola_xpeng_build.git build
cd build

# optional: inject module selection (all enabled by default)
KERNEL_SRC=/path/to/kernel bash /path/to/kernel/.ci/apply_module_config.sh

VARIANT=edge-s30 KERNEL_SRC=/path/to/kernel BUILD_WLAN=false \
  UPDATE_RESUKISU=false bash scripts/ci/build_resukisu_boot.sh
```

Output: `build/.ci-work/edge-s30/release/boot_ksu.img`.

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
