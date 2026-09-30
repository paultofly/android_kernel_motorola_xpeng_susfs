# 摩托罗拉 S30 (xpeng, 5.4 非 GKI) ReSukiSU + SUSFS 2.3 适配记录

本仓库在 `5.4.302-s3rxc32.33-8-25` 基础上，移植 SUSFS（2.3.0）并启用 Re:Kernel 与
DroidSpaces 支持，完成内核 Image 与 boot.img 编译。

## 一、移植来源 commit

| 来源仓库 | 分支/commit | 移植内容 |
|---|---|---|
| simonpunk/susfs4ksu | `gki-android12-5.10` (SUSFS v2.3.0) | **核心源**：`fs/susfs.c`、`include/linux/susfs.h`、`include/linux/susfs_def.h`、`50_add_susfs_in_gki-android12-5.10.patch`（24 个文件补丁） |
| LuoJuly/android_kernel_motorola_sm7325 | `lineage-23.2-SUSFS`（5.4 lineage 参考） | 5.4 结构适配范式：`__do_execve_file`/`do_faccessat`/`vfs_statx_fd` 钩子位置、KABI 补齐（f05b8df8）、Re:Kernel binder/signal 钩子（b68efe6b, b133a190）、DroidSpaces 配置（8b6309cd, 9d1f8197） |
| AstideLabs/android_kernel_xiaomi_sm8250 | `android16-aptusitu`（4.19 旧内核适配参考） | 旧内核差异点提示：5.4 无 `bprm_execve`（用 `exec_binprm`）、`struct kstat` 无 `mnt_id`、fsnotify 旧签名；以及 ReSukiSU panic 修复思路（SRCU 锁包裹 open_redirect） |
| LuoJuly/android_kernel_motorola_sm7325 | commit `2fa1be6d5a63` | SUSFS + ReSukiSU 内联钩子整体结构、Droidspaces/Re-Kernel 支持形态 |

## 二、主要修改点

### 2.1 SUSFS 核心（官方 2.3.0，5.4 适配）
- 新增 `fs/susfs.c`（SUSFS_VERSION = "v2.3.0"），`fs/Makefile` 注册 `susfs.o`。
- **fsnotify 回调回退为 5.4 旧签名** `handle_event(group,inode,mask,data,data_type,qstr,cookie,iter)`（官方 2.3 是 5.9+ 的 `handle_inode_event`）。
- `include/linux/susfs_def.h` 补 `#include <linux/cred.h>`、`<linux/sched.h>`（否则 `current_uid().val` 无法解析）。

### 2.2 内联钩子（CONFIG_KSU_SUSFS）
- `fs/exec.c`：`__do_execve_file` 中 `ksu_handle_execveat`/`_sucompat`/`post`（extern 需声明在函数定义**之前**——5.4 该函数早于原补丁落点，已前移）。
- `fs/open.c` `do_faccessat`：`ksu_handle_faccessat` + SUS_PATH 拦截。
- `fs/stat.c`：`vfs_getattr_nosec` 的 SUS_KSTAT 标记/伪装；`vfs_statx_fd` 内 init_rc 钩子（5.4 无 `vfs_fstat` 独立函数，用 `vfs_statx_fd`）；去掉 `mnt_id` 成员（5.4 `struct kstat` 无此成员）。
- `fs/read_write.c`：`ksu_handle_sys_read(fd,&buf,&count)`（ReSukiSU main 3 参数签名）。
- `kernel/sys.c`：`ksu_handle_setresuid`（`__sys_setresuid` 内）+ `susfs_spoof_uname`（2.3 用 static_key）。
- `kernel/reboot.c`：`ksu_handle_sys_reboot` 带 `orig_flow`。
- `drivers/input/input.c`：`ksu_handle_input_handle_event`。
- `fs/namei.c`、`fs/namespace.c`、`fs/readdir.c`、`fs/statfs.c`、`fs/super.c`、`fs/proc/*`、`mm/memory.c`、`kernel/kallsyms.c`、`security/selinux/{avc,hooks,selinuxfs}.c`：官方 2.3 补丁 + 手工处理 5.4 冲突。

### 2.3 5.4 专属修复
- `security/selinux/selinuxfs.c`：`fake_status` 访问改用独立 `fake_status_mutex`（5.4 的 `selinux_state` 无 `status_lock`）。
- `fs/namei.c` `lookup_fast`：补 `is_nd_state_lookup_last_and_open_last` 声明；`path_openat` 移除未用变量。
- `fs/proc/task_mmu.c`：`show_smap_vma` 返回 void，去掉 `return 0;`。
- `fs/readdir.c`：补 `compat_getdents_callback.sb` 与 `compat_filldir` 的 `struct inode *inode` 声明。
- `fs/proc/task_mmu.c` 保留 2.3 的 `susfs_srcu_open_redirect` SRCU 锁调用（对应 ReSukiSU panic 修复）。

### 2.4 Re:Kernel（CONFIG_REKERNEL）
- 新增 `drivers/rekernel/{rekernel.c,rekernel.h,Kconfig,Makefile}`（源自 sm7325）。
- `drivers/android/binder.c`：`rekernel_binder_transaction(reply, t, target_node, tr)`（5.4 trace 点为 3 参数）。
- `drivers/Kconfig`/`drivers/Makefile` 挂载。
- `kernel/signal.c` 已有 `rekernel_report` 钩子。

### 2.5 KABI（DroidSpaces 需要，无 ABI 检查）
- `include/linux/sched.h`：`sysvsem/sysvshm` 由 `ANDROID_KABI_USE(6)` / `_ANDROID_KABI_REPLACE(RESERVE7;8)` 承载。
- `include/linux/sched/user.h`：`mq_bytes` 由 `ANDROID_KABI_USE(1)` 承载。

### 2.6 defconfig（`arch/arm64/configs/vendor/ext_config/moto-lahaina-xpeng.config`）
- ReSukiSU：`CONFIG_KSU=y` + `CONFIG_KSU_SUSFS*` 全特性（SUS_PATH/SUS_MOUNT/SUS_KSTAT/SPOOF_UNAME/ENABLE_LOG/HIDE_SYMBOLS/SPOOF_CMDLINE_OR_BOOTCONFIG/OPEN_REDIRECT/SUS_MAP）。
- 移除旧的 `CONFIG_KSU_MANUAL_HOOK*`。
- Re:Kernel：`CONFIG_REKERNEL=y`。
- DroidSpaces：`CONFIG_POSIX_MQUEUE/IPC_NS/PID_NS/DEVTMPFS`、`NETFILTER_XT_MATCH_ADDRTYPE/RECENT/LOG`、`IP_SET + HASH_IP + HASH_NET + NETFILTER_XT_SET`、`TMPFS_POSIX_ACL/XATTR`。
  - 注：本 5.4 树无统一 `NETFILTER_XT_TARGET_REJECT`，改用等效的 `CONFIG_IP_NF_TARGET_REJECT=y`（iptables REJECT，5.4 符号）。
  - `CONFIG_SYSVIPC` 保持禁用（Android FCM v7 要求）。

## 三、编译环境（无 sudo / 无系统 gcc 下的自举）
- 工具链：repo 内 `toolchains/clang-repo/clang-r383902b1` + `toolchains/gcc49`（wrapper shebang 已修 python3）。
- host 工具：`scripts/ci/host-bin/{make,dtc,ufdt_apply_overlay}`。
- host 工具缺失补齐（解压到 `glibc-prefix/`、`host-tools/`）：libc6-dev、libgcc-11-dev、linux-libc-dev（提供 x86 uapi `asm/errno.h` 等）、libssl-dev/libssl3、flex、bison、m4、libsigsegv2；`libc.so` 链接脚本改为本地 `libc_nonshared.a`；HOSTCC 用 `-idirafter` 补 glibc 头，`-B/-L` 补 crt/lib。
- bison 需 `BISON_PKGDATADIR` 与 `M4` 指向解压前缀。

## 四、构建产物
- `out/target/product/generic/obj/kernel/msm-5.4/arch/arm64/boot/Image`（42 MB，含 123 个 KSU/SUSFS 符号）
- `.ci-work/release/boot_ksu.img` / `boot.img`（96 MB，用 magiskboot 将新 Image 注入官方 `boot_oem.img` v3 header）
- **编译耗时**：45 分 37 秒（完整 defconfig→Image）

## 五、验证
- `CONFIG_KSU=y`、`CONFIG_KSU_SUSFS=y` 及全部子特性已在 `.config` 生效。
- `System.map` 含 `susfs_init`、`susfs_add_sus_path`、`rekernel_binder_transaction`、`rekernel_report` 等符号。
- 提交见分支 `susfs-2.3-adaptation`（`xpeng/kernel/msm-5.4`）。
