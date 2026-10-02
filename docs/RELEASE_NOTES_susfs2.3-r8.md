# xpeng 5.4.302 ReSukiSU — SUSFS v2.3 完整修复 (r8)

## 版本信息

| 项目 | 值 |
|------|-----|
| 内核版本 | 5.4.302-moto |
| ReSukiSU 版本 | v4.1.0-59c99fdf (paulcbfly 配套版) |
| SUSFS 版本 | v2.3.0 |
| 编译日期 | 2026-10-02 |
| Tag | `susfs2.3-droidspace-rekernel-r8` |
| Release | https://github.com/paultofly/android_kernel_motorola_xpeng_susfs/releases/tag/susfs2.3-droidspace-rekernel-r8 |

## 修复历程

| 版本 | 问题 | 方案 | 结果 |
|------|------|------|------|
| r4 | DSH-Adapt SUSFS 部分隐藏（目录可见，内容隐藏） | 复制 paulcbfly 22 文件 | 黑屏重启 |
| r5 | 回退后重试 | 只复制 8 文件 + ReSukiSU v4.2.0 | 黑屏重启 |
| r6 | 修复 lookup_open/lookup_slow found_sus_path | 修补 DSH-Adapt patch | 部分隐藏未改善 |
| r7 | 保留 ReSukiSU + paulcbfly 8 文件 | 混搭 | 黑屏重启 |
| **r8** | **paulcbfly 完整套装** | **KernelSU v4.1.0 + 22 文件全量替换** | **✅ 正常开机，SUSFS 隐藏生效** |

## 关键发现

1. **paulcbfly 的 KernelSU v4.1.0 没有 `susfs_set_current_proc_umounted()`**：
   - `TIF_PROC_UMOUNTED` 不会被设置
   - `susfs_is_current_proc_umounted_app()` 永远返回 false
   - 但 SUSFS **仍然生效**——因为 paulcbfly 的 `namei.c` 改动不依赖 `susfs_is_current_proc_umounted_app()`，而是直接检查 `inode->i_state` 的 `AS_FLAGS_SUS_PATH` 位

2. **与 ReSukiSU v4.2.0-rc3 不兼容的原因**：
   - ReSukiSU v4.2.0 的 `setuid_hook.c` 有 `handle_zygote_next_setresuid`，与 paulcbfly 的 `namei.c` 改动冲突
   - 导致 VFS 层死锁/崩溃 → 黑屏重启

3. **paulcbfly 的适配方式**：
   - 不依赖 `TIF_PROC_UMOUNTED`，直接通过 `i_state` 标志隐藏
   - 所有非 root 进程（uid != 0）都看不到标记路径
   - root 进程（uid == 0）正常可见

## 包含功能

### SUSFS v2.3.0
- ✅ `sus_path`：路径隐藏（目录 + 内容，非 root 不可见）
- ✅ `sus_mount`：挂载隐藏
- ✅ `sus_kstat`：stat 欺骗
- ✅ `spoof_uname`：uname 欺骗
- ✅ `spoof_cmdline_or_bootconfig`：cmdline 欺骗
- ✅ `open_redirect`：open 重定向
- ✅ `sus_map`：内存映射隐藏
- ✅ `enable_log`：内核日志

### 其他功能
- ✅ BBRv3 + TCP Brutal（默认 bbr）
- ✅ rmnet 内建修复（移动数据正常）
- ✅ Re:Kernel
- ✅ DroidSpaces
- ✅ NoMount
- ✅ LZ4K

## 验证方法

```bash
# 1. 确认 SUSFS 初始化
adb shell 'su 0 dmesg | grep "susfs is initialized"'
# 预期: "susfs is initialized! version: v2.3.0"

# 2. 测试路径隐藏
adb shell 'su 0 mkdir -p /data/local/tmp/susfs_test'
adb shell 'su 0 ksu_susfs add_sus_path /data/local/tmp/susfs_test'
adb shell 'su 0 ls /data/local/tmp/susfs_test'    # root: 可见
adb shell 'ls /data/local/tmp/susfs_test'          # 非 root: 不可见（目录本身隐藏）

# 3. 查看当前 sus_path 列表
adb shell 'su 0 ksu_susfs show sus_path'
```

## 文件清单

| 文件 | 大小 | SHA-256 |
|------|------|---------|
| `boot_resukisu_rekernel_droidspaces_nomount_lz4k_bbrv3_susfsfix_r8.img` | 96 MB | `96273975…f1d0f` |
| `AK3_Xpeng_rekernel_droidspaces_nomount_lz4k_bbrv3_susfsfix_r8.zip` | 32 MB | `02656e3c…23664` |
| `Image` | 42 MB | `cca0df14…b672` |
| `SHA256SUMS_r8.txt` | 340 B | — |

## 已知限制

1. **KernelSU 版本较旧**（v4.1.0-1332）：
   - 无 `susfs_set_current_proc_umounted()`
   - 无 `handle_zygote_next_setresuid`
   - 但 SUSFS 核心功能（路径隐藏）正常工作

2. **与 ReSukiSU v4.2.0 不兼容**：
   - 如需 v4.2.0 功能，需等待 paulcbfly 更新或手动适配

3. **WiFi 模块**：
   - 本包不包含 qca_cld3 WiFi 模块
   - 需单独刷入 `wlan_crc_match_*.zip` 或编译时 `BUILD_WLAN=true`

## 源码

- 仓库：https://github.com/paultofly/android_kernel_motorola_xpeng_susfs
- 分支：`resukisu-v4.2.0-rc3-update`
- Tag：`susfs2.3-droidspace-rekernel-r8`
- Commit：`5d7f1c6c49e5`

## 致谢

- **paulcbfly**：5.4.302 SUSFS v2.3 完整适配（https://github.com/paulcbfly/android_kernel_motorola_xpeng）
- **simonpunk**：SUSFS 原作者（https://gitlab.com/simonpunk/susfs4ksu）
- **ReSukiSU**：KernelSU 修改版（https://github.com/ReSukiSU/ReSukiSU）
