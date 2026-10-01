# 特性移植记录:BBRv3 / TCP Brutal / NoMount / USER_NS / LZ4K

> 记录时间:2026-10-02 · 内核:Moto Edge S30 (xpeng) 5.4.302 非 GKI (lahaina/sm8350)
> 基线:ReSukiSU v4.2.0-rc3-21-g542f9061 + SUSFS 2.3(分支 resukisu-v4.2.0-rc3-update)
> 本次编译模式:incr(增量) · 仅 boot,跳过 WiFi(BUILD_WLAN=false)

---

## 一、任务清单与结果

| # | 任务 | 参考 | 结果 |
|---|------|------|------|
| 1 | 添加 BBR / BBRv3 支持 | LuoJuly sm7325 分支(paulcbfly 8972cd10 搬运) | ✅ `CONFIG_DEFAULT_TCP_CONG="bbr"` |
| 2 | 移植 TCP Brutal | apernet/tcp-brutal v2.0.1(参考 JackA1ltman/NonGKI_Kernel_Build_2nd 的适配思路) | ✅ `CONFIG_TCP_CONG_BRUTAL=y` |
| 3 | 开启 DroidSpaces 需要的 USER_NS | paulcbfly/xpeng_kernel_susfs 26427f8 | ✅ `CONFIG_USER_NS=y` |
| 4 | 适配最新 NoMount 模块 | maxsteeel/nomount(dev) | ✅ `CONFIG_NOMOUNT=y` |
| 5 | 移植华为 LZ4KD / LZ4K 压缩算法 | meizuosc/m75 lib/lz4k | ✅ `CONFIG_LZ4K=y` |

> 说明:任务 1/2 合并为"TCP 拥塞控制"一组;任务清单中"BBR,BRUTAL"即 BBRv3 + TCP Brutal。

## 二、TCP 拥塞控制(BBRv3 + TCP Brutal)

### 2.1 BBRv3
- 文件:`net/ipv4/tcp_bbr.c`(重写,1174 → 1672 行)、`net/ipv4/tcp_rate.c`(198 → 225 行)、`include/net/tcp.h`。
- 来源:paulcbfly/xpeng_kernel_susfs 提交 `8972cd10cc71`("Add Re:Kernel / DroidSpaces / BBGuard / BBRv3 module support"),
  其 BBRv3 代码搬自 LuoJuly 的 sm7325 分支(b133a190、f05b8df8、8b6309cd、41952b45、8bb2555c、899d1212、f4ef3d3c)。
- 已核对:该提交对 `include/net/tcp.h` / `tcp_rate.c` 的改动**仅与 BBRv3 有关**,无其它无关侵入。
- 必要结构(5.4 已具备):`struct tcp_skb_cb` 的 TSO/ECN 字段、`struct rate_sample` 新字段、`tcp_stamp32_us_delta()`。
- 配置:`CONFIG_TCP_CONG_ADVANCED=y`、`CONFIG_TCP_CONG_BBR=y`、`CONFIG_DEFAULT_BBR=y`、`CONFIG_DEFAULT_TCP_CONG="bbr"`。

### 2.2 TCP Brutal(重要:参考实现并未真正实现它)
- 事实核查:LuoJuly sm7325 全部分支与 paulcbfly/xpeng_kernel_susfs 中**都不存在** `tcp_brutal.c` 或 `CONFIG_TCP_CONG_BRUTAL` 的 Kconfig 定义;
  paulcbfly 的提交信息本身写明 "skip CONFIG_TCP_ECN / CONFIG_TCP_CONG_BRUTAL (no such symbols)"。
  即参考内核里 `CONFIG_TCP_CONG_BRUTAL=y` 是一个**未定义符号**,会被 kconfig 静默丢弃。因此不能照抄,必须真正移植。
- 实际来源:[apernet/tcp-brutal](https://github.com/apernet/tcp-brutal) v2.0.1,内联进内核树:
  | 文件 | 作用 |
  |------|------|
  | `net/ipv4/brutal.h` | 公开结构 `struct brutal`、常量、`brutal_get_sock()` |
  | `net/ipv4/brutal_cc.c` | 拥塞控制算法 `brutal`(注册 `tcp_congestion_ops`) |
  | `net/ipv4/brutal_sockopt.c` | 与用户态的 socket 参数通道(`TCP_BRUTAL_PARAMS` / setsockopt) |
  | `net/ipv4/brutal_rules.c` | procfs 规则表(`/proc/sys/net/ipv4/tcp_brutal_*`) |
- **向 5.4 回移的改动**:
  1. `sockptr_t optval` → `char __user *optval`(3 处签名,含 v4/v6 的 tcp_setsockopt);
     对应的 `copy_from_sockptr()` → `copy_from_user()`(5.4 的 `struct proto.setsockopt` 仍是 user 指针)。
  2. `struct proc_ops`(5.6+)→ 版本门控;5.4 走 `struct file_operations`(`owner/open/read/write/llseek/release`)。
  3. `mul_u64_u64_div_u64()`(5.10+)在内核树中缺失 → 在 `brutal_cc.c` 内本地实现
     `brutal_mul_u64_u64_div_u64()`(`div64_u64_rem` + 组合)并在 5.4 下以宏别名。
  4. 版本门槛由 `< KERNEL_VERSION(4,9,0)` 下调为 `< KERNEL_VERSION(5,4,0)`(即支持 5.4+)。
- 容量核对:`ICSK_CA_PRIV_SIZE` 在本树为 `13 * sizeof(u64)` = 104 字节,`struct brutal` ≈ 96 字节,**放得下**。
- Kconfig/Makefile:`net/ipv4/Kconfig` 新增 `config TCP_CONG_BRUTAL`(tristate, default m);
  `net/ipv4/Makefile` 新增 `tcp_brutal.o`(`brutal_cc.o + brutal_sockopt.o + brutal_rules.o`)。
- 配置:`CONFIG_TCP_CONG_BRUTAL=y`。

### 2.3 默认 qdisc 的取舍(移动数据安全)
参考实现最终把 `fq` 设为默认 qdisc(`CONFIG_DEFAULT_NET_SCH="fq"` / `NET_SCH_DEFAULT=y` / `DEFAULT_FQ=y`),
但**同一作者在提交 `38c3f96304a0` 中明确记录**:fq 的 per-flow pacing 与 rmnet QMAP 聚合不兼容,
会导致移动数据"有信号但无网",并因此回退。综合取舍:
- 本树**保留 MMI 基线的 `pfifo_fast` 默认 qdisc**(不设置 `DEFAULT_NET_SCH`),以保护移动数据;
- `CONFIG_NET_SCH_FQ=y` 仍然编入,BBR 仍为默认拥塞算法;需要时可运行时 `sysctl -w net.core.default_qdisc=fq`。
- 说明:BBRv3 在 fq 下更能发挥 pacing 效果,但"能开机、能上网"优先。

## 三、NoMount(路径重定向)
- 来源:[maxsteeel/nomount](https://github.com/maxsteeel/nomount)(dev 分支)的 `kernel/src/`。
- 做法:直接把 `nomount.c`(1710 行)、`nomount.h`、`Kconfig`、`Makefile` 放入本树 `fs/nomount/`(参考 NonGKI 项目用符号链接方式,这里改为**实体文件**以便提交);
  并在 `fs/Makefile` 增加 `obj-$(CONFIG_NOMOUNT) += nomount/`、在 `fs/Kconfig` 末尾增加 `source "fs/nomount/Kconfig"`。
- 配置:`CONFIG_NOMOUNT=y`。

## 四、DroidSpaces:USER_NS
- 参考:paulcbfly/xpeng_kernel_susfs 提交 `26427f8c9cbcbf426c20a4ad99027ef360ad9d2e`
  (其做法是在构建脚本的 `ENABLE_DROIDSPACES` 符号列表中补上 `USER_NS`)。
- 原理:DroidSpaces 创建容器需要 user namespace;本树此前已有 IPC_NS/PID_NS/POSIX_MQUEUE 等,
  **唯独缺 `CONFIG_USER_NS`**。`USER_NS` 位于 `init/Kconfig` 的 `if NAMESPACES` 块内(本树 `CONFIG_NAMESPACES=y`,满足前置)。
- 配置:`CONFIG_USER_NS=y`。

## 五、华为 LZ4K / LZ4KD
- 来源:meizuosc/m75 内核树 `lib/lz4k/`(`lz4k_compress.c` 287 行、`lz4k_decompress.c` 442 行)、`include/linux/lz4k.h`。
- 做法:放入本树 `lib/lz4k/` + `include/linux/lz4k.h`;`lib/Makefile` 增加 `obj-$(CONFIG_LZ4K) += lz4k/`;
  `lib/Kconfig` 增加 `config LZ4K`(bool)。
- 说明:LZ4K 是华为在 LZ4 基础上扩大窗口并丰富匹配编码的变体,压缩率优于 LZ4、解压速度接近 LZ4;
  主要供 zram/压缩文件系统等选择使用。配置:`CONFIG_LZ4K=y`。

## 六、构建脚本的两处改造(为满足增量编译)
在 `build-ref/scripts/ci/build_resukisu_boot.sh` 中新增两个开关(默认关闭,不影响原有全量流程):
- `INCREMENTAL=true`:跳过 `rm -rf "$OUT_DIR"`,复用已有 `.o/.a`,实现真正的增量编译。
- `CONFIG_ONLY=true`:在 `olddefconfig` 之后、`headers_install` 之前打印关键符号并退出,用于快速校验配置。

### 重要陷阱:构建脚本会强制 `git checkout` ext_config
`apply_nfc_overlay` 与 `restore_nfc_config`(EXIT trap)都会执行
`git -C "$KERNEL_DIR" checkout HEAD -- arch/arm64/configs/vendor/ext_config/moto-lahaina-xpeng.config`。
因此**对 ext_config 的任何未提交改动都会在构建开始/结束时被静默还原**。正确流程:**先提交改动,再构建**
(同时满足 `kernel.release` 无 `-dirty` 的要求)。

## 七、最终配置(校验通过)
```
CONFIG_USER_NS=y            # DroidSpaces
CONFIG_NAMESPACES=y
CONFIG_TCP_CONG_ADVANCED=y
CONFIG_TCP_CONG_BBR=y
CONFIG_DEFAULT_BBR=y
CONFIG_DEFAULT_TCP_CONG="bbr"
CONFIG_TCP_CONG_BRUTAL=y
CONFIG_NET_SCH_FQ=y         # 编入但不设为默认(default qdisc 仍为 pfifo_fast)
CONFIG_NOMOUNT=y
CONFIG_LZ4K=y
```
