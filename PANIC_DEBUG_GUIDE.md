# 内核 panic 排查指南（黑屏反复重启）

刷入新 boot.img 后黑屏 + 反复重启 = 内核 panic。需要抓到 panic 日志才能精确定位。

## 方法一：pstore / last_kmsg（推荐）

刷入能启动的旧版 boot.img 后（或用 TWRP/Recovery），执行：

```bash
# 方式 A: 有 root 的 recovery 或已 root 的系统
adb shell
su
cat /proc/last_kmsg > /sdcard/last_kmsg.txt
# 或
cat /sys/fs/pstore/console-ramoops* > /sdcard/pstore.txt
# 或
dmesg | grep -i "panic\|bug\|call trace\|oops" > /sdcard/dmesg_panic.txt
```

然后把 `/sdcard/last_kmsg.txt` 发给我。

## 方法二：串口日志（最有效但需硬件）

通过 USB 串口或 UART 抓 boot 日志，能看到完整的 panic Call Trace。

## 方法三：fastboot 日志

```bash
# 重启到 fastboot，用能启动的 boot 临时启动
fastboot boot boot_old_working.img
# 系统启动后立即抓
adb shell cat /proc/last_kmsg
```

## 需要的信息

找到类似以下的关键行即可定位：
```
Call trace:
 ... 
 [<...>] function_name+0x.../0x...
```
把 Call trace 中最后几个函数名发给我即可。

---

## 本次已修复的问题（v2 修复版）

对比 sm7325 参考版本，将 `fs/exec.c` 的 exec hook 从官方 2.3 的
`is_su_session` + `post_execveat` 变体回退为 **sm7325 保守变体**：
- 去掉 `is_su_session` 赋值（`is_su_session = !ksu_handle_execveat(...)`）
- 去掉 `ksu_handle_post_execveat_sucompat` post hook
- `no_su` 门禁改为 `umounted` 门禁（与 sm7325 一致）

**原因**：5.4 的 `__do_execve_file` 用 `exec_binprm()` 而非 5.10 的 `bprm_execve()`，
post hook 在 `exec_binprm` 之后调用时 bprm/argv 已失效，且官方 2.3 的
`no_su` 门禁在启动期会拦截 init/system_server 的 exec 提权路径。
