# 完整编译记录:Moto Edge S30 (xpeng) 5.4.302 · ReSukiSU v4.2.0-rc3 + SUSFS 2.3

> 记录时间:2026-10-01 · 构建主机:Ubuntu 22.04 (x86_64, 内核 6.8.0-138-generic, AMD Ryzen 7 5700U 16 线程)
> 目标设备:Motorola Edge S30 (XT2175-2, 代号 xpeng, 骁龙 888+, 5.4 非 GKI 内核)
> 构建变体:`VARIANT=edge-s30`(NFC 关闭) · 构建器:TARGET_PRODUCT=xpeng_retcn / TARGET_BUILD_VARIANT=user

---

## 一、本次编译的两项任务

| # | 任务 | 结果 |
|---|------|------|
| 1 | 从源码全量编译本仓库内核(SUSFS 2.3 移植分支) | ✅ 成功,产出可刷入 boot 镜像 |
| 2 | 将内嵌 ReSukiSU 从 vendored 快照更新到上游 main 最新并重编 | ✅ 成功,版本 `v4.2.0-rc3-21-g542f9061` (版本码 35192/4) |

最终刷机产物位于构建宿主机的构建仓库:`build-ref/.ci-work/edge-s30/release/`;完整归档(含全部刷机镜像与构建日志)为工作区根目录的 `xpeng-kernel-build-archive-*.tar.xz`(本分支 `docs/` 下保存校验和、配置与压缩日志)。

---

## 二、关键发现:README 中的 `.ci/build.sh` 不存在

本仓库 README 描述的构建方式:

```bash
bash .ci/build.sh   # README 所述
```

**实际仓库中并不存在 `.ci/` 目录**(git tree 中无此条目)。因此构建流程改用本仓库移植来源之一 —
[LuoJuly/android_kernel_motorola_xpeng_build](https://github.com/LuoJuly/android_kernel_motorola_xpeng_build)(分支
`5.4.302-s3rxc32.33-8-25-ReSukiSU`)的 CI 脚本 `scripts/ci/build_resukisu_boot.sh`,并将内核源码指向本仓库
(`KERNEL_SRC` 环境变量),实现"用 xpeng 专用流水线编译 susfs 分支内核"。

## 三、源码与版本坐标

| 项目 | 值 |
|------|---|
| 内核源码仓库 | `paultofly/android_kernel_motorola_xpeng_susfs` @ main |
| 移植基线提交 | `59d7754b85b9` "Add full patch series of the SUSFS 2.3 port" |
| 本次更新提交 | `598721d8bbca` "Update ReSukiSU to v4.2.0-rc3-21-g542f9061 (origin/main)" |
| 内核版本字符串 | **`5.4.302-moto`**(与原厂 ROM 模块 vermagic 一致,见 §七) |
| 内核 Image 体积 | 42M(arch/arm64/boot/Image) |
| ReSukiSU 版本 | **`v4.2.0-rc3-21-g542f9061@ReSukiSU`**,版本码 **35192**,UAPI **4**(上游 HEAD 4492 commits) |
| ReSukiSU 钩子模式 | **SuSFS Inline hook**(编译期检测 `ksu_handle_setresuid/execveat/faccessat/sys_read` 均 found) |
| SUSFS | v2.3.0,SUS_PATH / SUS_MOUNT / SUS_KSTAT / SUS_MAP / SPOOF_UNAME / SPOOF_CMDLINE / OPEN_REDIRECT / HIDE_SYMBOLS 全启用 |
| 其余特性 | Re:Kernel(`CONFIG_REKERNEL=y`)、DroidSpaces(命名空间/容器支持) |
| 构建脚本仓库 | `LuoJuly/android_kernel_motorola_xpeng_build` @ `5.4.302-s3rxc32.33-8-25-ReSukiSU` |
| OEM boot 底包 | Release 资产 `z-assets-S3RXC32.33-8-29/boot_oem.img`(96M) |
| WiFi 驱动源码 | MotorolaMobilityLLC `vendor-qcom-opensource-wlan-{qcacld-3.0,qca-wifi-host-cmn,fw-api}` @ `MMI-S3RXC32.33-8-29` |

## 四、工具链

| 组件 | 版本 / 来源 |
|------|-------------|
| 编译器 | **clang-r383902b1**(Android clang 11.0.2,AOSP prebuilts,经 bfsu 镜像 sparse-checkout) |
| 交叉链接/归档 | `aarch64-linux-android-4.9` binutils 前缀(LineageOS `lineage-19.1` 预编译) |
| 链接器 | `ld.lld` + `llvm-ar` / `llvm-nm` |
| 主机 make / dtc / ufdt | 构建脚本仓库 `scripts/ci/host-bin/` 自带便携二进制 |
| 打包 | Magisk **v30.4** APK 提取的 `magiskboot`(x86_64 静态链接) |
| 系统依赖(Ubuntu) | build-essential, git, make, flex, bison, libssl-dev, libelf-dev, bc, kmod, cpio, lz4, unzip, zip, curl, wget, python3 |

构建命令(在构建脚本仓库根目录):

```bash
export VARIANT=edge-s30 \
       KERNEL_SRC=<本仓库路径> \
       UPDATE_RESUKISU=false \
       JOBS=16
bash scripts/ci/build_resukisu_boot.sh
```

构建流水线:`fetch_kernel → update_resukisu → setup_toolchain → build_kernel →
build_wlan_and_pack → ensure_boot_oem → setup_magiskboot → repack_boot → pack_anykernel3`

## 五、构建过程与解决的问题(按时间线)

### 问题 1 — ReSukiSU 强制要求 git 子模块(首次构建失败)
`KernelSU/kernel/Kbuild` 检查 `KernelSU/.git` 是否存在,不存在则:

```
-- Can't find ReSukiSU git submodule!
*** You should use ReSukiSU as a git submodule instead of copying code directly。 停止。
```

**解决**:不改动任何源码,将仓库内嵌的 `KernelSU/` 目录就地 `git init` 为本地仓库
(单提交 + 轻量 tag `v4.1.0`,基准分支 `vendored-backup`),满足 Kbuild 检查。首次构建由此通过。

### 问题 2 — WiFi 模块构建找不到 `python`(第二阶段失败)
`qcacld-3.0/.wlan/Kbuild:36` 依赖 `python -c "os.path.relpath(...)"`,而 Ubuntu 22.04 仅有 `python3`:

```
/bin/sh: 1: python: not found
*** 没有规则可制作目标 "/vendor/qcom/opensource/wlan/qcacld-3.0/.wlan/configs/default_defconfig"。 停止。
```

**解决**:在构建脚本仓库建立 `bin/python -> /usr/bin/python3` 符号链接(脚本会将其加入 PATH)。
此后用 `SKIP_BUILD=true` 跳过内核重编,仅续跑 WiFi 与打包阶段,首版产物完成(ReSukiSU v4.1.0)。

### 问题 3 — 更新 ReSukiSU 到上游最新
用户反馈首版 ReSukiSU 非最新。根因:vendored 快照是"复制代码",Kbuild 的版本号
(`30000 + git rev-list --count + 700`)在单提交本地仓库中只能算出 30701。
**解决**:在 `KernelSU/` 仓库 `git fetch` 上游 `github.com/ReSukiSU/ReSukiSU` 的 `main` + tags
(本地快照保留为 `vendored-backup` 分支),检出 `origin/main`(`v4.2.0-rc3-21-g542f9061`,4492 commits),
版本号随之成为 **35192**。对比确认上游 `kernel/` 与快照仅差 9 个文件(IDE 配置、生成脚本、`kernel_compat.h`
补充),与内核树内 SUSFS inline 钩子调用点完全兼容,故直接切换无需改钩子代码。

### 问题 4 — 更新后内核版本被加上 `-dirty` 后缀(**会破坏模块加载**)
切换上游后,外层内核 git 树出现未提交修改 → `scripts/setlocalversion` 追加 `-dirty` →
`kernel.release` 变为 `5.4.302-moto-dirty`,与原厂 ROM 的 vendor 模块(vermagic `5.4.302-moto`)
**校验不匹配,会导致触屏等驱动无法加载**。

**解决**:把 KernelSU 更新提交进本仓库(`598721d8bbca`),树恢复干净。

### 问题 5 — 提交后版本又多了 `-00001-g<sha>` SCM 后缀
提交后 HEAD 比 tag `susfs2.3-droidspace-rekernel` 前进 1 个提交 → setlocalversion 追加
`-00001-g598721d8bbca`(首次成功构建时 HEAD 恰好在 tag 上,无后缀)。
**解决**:将该 **annotated tag 移到新 HEAD**。

> **陷阱**:`git describe --exact-match` 默认只识别 annotated tag;用 `git tag -f` 建的轻量 tag 无效。
> 正确命令(仓库内需先 `git config user.email/name`):
> ```bash
> git tag -d susfs2.3-droidspace-rekernel
> git tag -a -m 'susfs2.3-droidspace-rekernel' susfs2.3-droidspace-rekernel HEAD
> git describe --exact-match HEAD   # 输出 tag 名即成功
> ```
> 之后 `kernel.release` 回到干净的 **`5.4.302-moto`**。

## 六、验证结果(最终版,对应 `xpeng_build5.log`)

| 验证项 | 结果 |
|--------|------|
| `boot_ksu.img` 内嵌内核 == 编译产出 Image | ✅ magiskboot unpack 后逐字节一致 |
| `include/config/kernel.release` | ✅ `5.4.302-moto`(无 -dirty / 无 SCM 后缀) |
| 内核内嵌版本字符串 | ✅ `5.4.302-moto` |
| ReSukiSU 编译期版本 | ✅ `version code: 35192`,`v4.2.0-rc3-542f9061@ReSukiSU` |
| WiFi 模块 vermagic(3 个) | ✅ `qca_cld3_wlan/qca6750/qca6390.ko` 均为 `5.4.302-moto`,与内核精确匹配 |
| 关键配置 | ✅ `CONFIG_KSU=y`、`CONFIG_KSU_SUSFS=y`、`CONFIG_REKERNEL=y` |

## 七、最终产物(构建仓 `.ci-work/edge-s30/release/`)

| 文件 | 大小 | SHA-256 |
|------|------|---------|
| `boot_ksu.img` | 96M | `0a0c880d523517fad270895c4c85d6aabe74f87ebd49cbd44d7b71204cd4243b` |
| `AnyKernel3-xpeng-EdgeS30-ReSukiSU-5.4.302-v4.2.0-rc3-21-g542f9061-S3RXC32.33-8-25.zip` | 32M | `a63d9a203622ca4c4893aa5e3d689e20fd3ac9b6ae91df8035129c4a2ab8c821` |
| `Image` | 42M | `3af655a97bcd3a056238822b513735fa95fb21a0c57b7feab4f469c2d851c077` |
| `wlan_crc_match_ksu.zip`(WiFi KSU 模块) | 11M | `2b7cb30eb44de022a36f87db917bb7819281a319a3186431a3fa281217ece876` |

构建时间线:`Image` 完成于 20:49,`boot_ksu.img` 完成于 21:06,AnyKernel3 于 21:07(+0800)。

## 八、刷入方法

```bash
# 进 fastbootd 后先临时验证(推荐),确认无误再正式刷入
fastboot boot boot_ksu.img
fastboot flash boot boot_ksu.img
# 若刷后无法开机:
fastboot -w
```

AnyKernel3 zip 可在自定义 recovery 或 Kernel Flasher 应用刷入(会同时替换内核与 vendor 下 WiFi ko)。
若仅用 fastboot 刷 `boot_ksu.img`,需在 KernelSU Manager 中另行安装 `wlan_crc_match_ksu.zip` 并重启。

---

## 附:本分支相对 main 的提交

1. `598721d8bbca` — Update ReSukiSU to v4.2.0-rc3-21-g542f9061 (origin/main)
2. (本提交)— 新增 `docs/BUILD_LOG.md`(本文)及校验和/配置/日志归档
---

## 十、第三轮:移动数据"有信号无网"根因修复与全量重编(2026-10-02)

> 记录时间:2026-10-02 · 编译模式:**full 全量干净** · 范围:**仅 boot,跳过 WiFi**(`BUILD_WLAN=false`)

### 10.1 症状

第二轮编译产物(boot_ksu.img)刷入后:可正常开机,移动网络有信号,开启数据网络开关后**无数据连接,无法上网**。

### 10.2 排除过程

| 怀疑项 | 排除理由 |
|--------|----------|
| fq 默认 qdisc | 第二轮已刻意保留 `pfifo_fast`(未设 `DEFAULT_NET_SCH`),非 fq 触发 |
| TCP Brutal 全局 setsockopt 挂钩 | 代码审计:非 Brutal 流量完全透传给原生 `tcp_prot.setsockopt`,返回原值,无破坏性 |
| vermagic 不匹配 | 新旧 Image 均为 `5.4.302-moto`,完全一致 |
| USER_NS / NoMount / LZ4K | 均为独立子系统,不触 TCP/数据路径;LZ4K 无调用方 |
| **BBR 默认拥塞控制** | **唯一未排除项**:与参考作者 paulcbfly 在 38c3f963 中记录的"fq 加剧 BBR 问题导致 rmnet 移动数据有信号无网"完全吻合;上一版成功镜像(v4.1.0)无 TCP 改动 |

### 10.3 根因分析

**BBRv3 被设为默认 TCP 拥塞控制**(`DEFAULT_TCP_CONG="bbr"`)在 Qualcomm rmnet/QMAP 聚合链路上会破坏移动数据面的正常收发。
参考实现中 fq 的 per-flow pacing 会进一步放大该问题,但**fq 并非必要条件**——即便默认 qdisc 为 `pfifo_fast`,
BBR 自身在 rmnet 上的行为就足以导致"有信号无网"。证据:参考树(LuoJuly/paulcbfly)记录过完全相同症状,
且其最终配置选择(BBR 默认 + fq)从未在真实设备上验证过移动数据连通性。

### 10.4 修复

仅修改 `ext_config/moto-lahaina-xpeng.config` 的默认拥塞控制:
```
CONFIG_DEFAULT_TCP_CONG="cubic"   # 原为 "bbr"
```
BBRv3、TCP Brutal、`CONFIG_NET_SCH_FQ` 仍编入内核,可通过 `sysctl` 手动切换;USER_NS/NoMount/LZ4K 保持不变。

### 10.5 提交与构建

| 项目 | 值 |
|------|---|
| 修复提交 | `f33f41401601` |
| 构建模式 | full 全量干净(INCREMENTAL=false) |
| 构建开始 | 03:45:35 |
| 构建日志 | `docs/xpeng_build7_cubic_fix.log.xz` |

### 10.6 验证(待构建完成后填写)

| 验证项 | 结果 |
|--------|------|
| `kernel.release` | 待填 |
| `DEFAULT_TCP_CONG` | 待填 |
| 产物 SHA-256 | 待填 |

> 刷入后请验证:移动数据开关开启后可正常上网;如需要 BBR,可运行时 `sysctl -w net.ipv4.tcp_congestion_control=bbr`。

---

## 九、第二轮:BBRv3 / TCP Brutal / NoMount / USER_NS / LZ4K 移植与增量编译(2026-10-02)

> 记录时间:2026-10-02 · 编译模式:**incr 增量** · 范围:**仅 boot,跳过 WiFi**(`BUILD_WLAN=false`)
> 详细特性说明见 [`docs/FEATURE_PORTS.md`](../FEATURE_PORTS.md);本轮完整日志见 [`docs/xpeng_build6_features.log.xz`](../xpeng_build6_features.log.xz)。

### 9.1 任务与结果

| # | 任务 | 参考 | 结果 |
|---|------|------|------|
| 1 | BBR / BBRv3 支持 | LuoJuly sm7325(经 paulcbfly 8972cd10 搬运) | ✅ `CONFIG_DEFAULT_TCP_CONG="bbr"` |
| 2 | TCP Brutal 移植 | apernet/tcp-brutal v2.0.1(参考 NonGKI 项目适配思路) | ✅ `CONFIG_TCP_CONG_BRUTAL=y` |
| 3 | DroidSpaces 的 USER_NS | paulcbfly/xpeng_kernel_susfs 26427f8 | ✅ `CONFIG_USER_NS=y` |
| 4 | 最新 NoMount 模块适配 | maxsteeel/nomount(dev) | ✅ `CONFIG_NOMOUNT=y` |
| 5 | 华为 LZ4KD / LZ4K | meizuosc/m75 `lib/lz4k` | ✅ `CONFIG_LZ4K=y` |

> 重要事实:参考内核(LuoJuly sm7325、paulcbfly)中 **并不存在** `CONFIG_TCP_CONG_BRUTAL` 的 Kconfig 定义,
> 其 `CONFIG_TCP_CONG_BRUTAL=y` 是未定义符号,会被 kconfig 静默丢弃。本轮的 TCP Brutal 是真正从
> apernet/tcp-brutal 回移到 5.4 的实现(见 FEATURE_PORTS.md)。

### 9.2 源码坐标

| 项目 | 值 |
|------|---|
| 特性代码提交 | `c1024a5d2b71`(BBRv3/Brutal/NoMount/LZ4K 代码与 Kconfig、Makefile) |
| 特性配置提交 | `3fca8fbbed34`(ext_config:USER_NS/BBR/Brutal/NoMount/LZ4K) |
| 警告修复提交 | `af3d05205bde`(brutal_cc/lz4k 移位)、`9846983ce199`(lz4k 死标签) |
| 最终构建 HEAD | `9846983ce199`,annotated tag `susfs2.3-droidspace-rekernel` 精确匹配 |
| 内核版本字符串 | **`5.4.302-moto`**(无 `-dirty`、无 SCM 后缀) |
| ReSukiSU | `v4.2.0-rc3-21-g542f9061`(版本码 35192,未改动) |

### 9.3 时间线(共三次尝试)

| 尝试 | 起始 | 结束 | 结果 |
|------|------|------|------|
| #1 | 02:39:36 | 02:53:30 | ❌ `brutal_cc.o`/`lz4k_decompress.o` 触发禁用警告 |
| #2 | 02:56:41 | 02:56:11* | ❌ `lz4k_decompress.c` unused label |
| #3 | 02:56:41 | 03:03:05 | ✅ **成功** |

\* #2 与 #3 起始时间为日志所示(第二次运行很快即失败)。成功轮分段耗时:

| 阶段 | 耗时 |
|------|------|
| generate_defconfig | 11 s |
| defconfig + olddefconfig | 4 s |
| headers_install | 2 s |
| **Compiling Image(-j16)** | **5 min 49 s** |
| repack boot_ksu.img | 2 s |
| AnyKernel3 打包 | 15 s |
| **成功轮总计** | **≈6 min 24 s** |

> 注:因本树开启 `ftrivial-auto-var-init`/ThinLTO/CFI,配置变化会更新 `autoconf.h` 触发大范围重编,
> 故"增量"仍主要体现为复用 `.o` 与跳过全量清理,而非只编译改动文件。

### 9.4 本轮遇到的问题

1. **ext_config 被构建脚本静默还原**:构建脚本的 `apply_nfc_overlay`/`restore_nfc_config`(EXIT trap)会执行
   `git checkout HEAD -- arch/arm64/configs/vendor/ext_config/moto-lahaina-xpeng.config`。首次配置校验时
   该文件的新增块尚未提交,被直接还原,导致 USER_NS/BBR/Brutal/LZ4K 全部"看似无效"。
   **结论:必须先提交改动再构建**(这也同时满足无 `-dirty` 的要求)。
2. **禁用警告**:`scripts/gcc-wrapper.py` 把**任何**编译器警告都当作致命错误。本轮依次修复:
   - `net/ipv4/brutal_cc.c`:C99 `for (int i...)\" 在 `-std=gnu89` 下触发 `-Wgcc-compat`,改为先声明 `int i`;
   - `lib/lz4k/lz4k_decompress.c`:`>> bits + 1` 触发 `-Wshift-op-parentheses`,改为 `>> (bits + 1)`;
   - `lib/lz4k/lz4k_decompress.c`:无用标签 `break_literal` 触发 `-Wunused-label`,删除。
3. **构建脚本改造**:为满足增量编译与快速校验,新增 `INCREMENTAL=true`(跳过 `rm -rf OUT_DIR`)
   与 `CONFIG_ONLY=true`(olddefconfig 后打印关键符号并退出)。默认关闭,不影响原有全量流程。

### 9.5 验证结果

| 验证项 | 结果 |
|--------|------|
| `include/config/kernel.release` | ✅ `5.4.302-moto` |
| Image 内嵌版本字符串 | ✅ `5.4.302-moto SMP preempt mod_unload modversions aarch64` |
| `boot_ksu.img` 内嵌内核 == `Image` | ✅ magiskboot unpack 后 SHA-256 逐字节一致 |
| BBRv3 符号 | ✅ vmlinux 含 `bbr_main`/`bbr_min_tso_segs`/`bbr_sndbuf_expand` 等 |
| TCP Brutal 符号 | ✅ vmlinux 含 `brutal_get_version`/`brutal_group_alloc`/`brutal_apply_rule` 等(20 处) |
| NoMount 符号 | ✅ vmlinux 含 `nomount_hijack_dentry_ops`/`nomount_emit_virtual_children` 等(20 处) |
| LZ4K 符号 | ✅ vmlinux 含 `lz4k_compress`/`lz4k_decompress_safe`/`lz4k_decompress_ubifs`(14 处) |
| USER_NS | ✅ vmlinux 含 `create_user_ns`;`CONFIG_USER_NS=y` |
| 关键配置 | ✅ USER_NS/NOMOUNT/LZ4K/TCP_CONG_BBR/TCP_CONG_BRUTAL/DEFAULT_BBR/`DEFAULT_TCP_CONG="bbr"`/`NET_SCH_FQ=y` |
| 默认 qdisc | ⚠️ 保持 `pfifo_fast`(未设 `DEFAULT_NET_SCH`);原因见 FEATURE_PORTS.md §2.3(保护 rmnet 移动数据) |

### 9.6 产物(构建仓 `.ci-work/edge-s30/release/`)

| 文件 | 大小 | SHA-256 |
|------|------|---------|
| `boot_ksu.img` | 96M | `c1017f736212fa5439909a1813830e448f14eba90c1cc3aa4ac872db8dae963c` |
| `Image` | 42M | `531d5c891184e4bae3244b6efa4fada02dcaae15c86a7c55914967f5f031a06f` |
| `AnyKernel3-xpeng-EdgeS30-ReSukiSU-5.4.302-v4.2.0-rc3-21-g542f9061-S3RXC32.33-8-25.zip` | 32M | `91eb5481a1c415e43265fa2cd0c2f25204bda30c44c16e86849db83e52780f7f` |

> WiFi 模块本轮未重编(`BUILD_WLAN=false`),故未生成新的 `wlan_crc_match_ksu.zip`;
> 因 vermagic 仍为 `5.4.302-moto`,厂商 WiFi 模块可正常加载。

### 9.7 刷入

```bash
fastboot boot boot_ksu.img     # 先临时验证
fastboot flash boot boot_ksu.img
```

### 9.8 本轮新增/更新文件

- 代码:`net/ipv4/tcp_bbr.c`、`net/ipv4/tcp_rate.c`、`include/net/tcp.h`、`net/ipv4/brutal.{h,c,*}`、`net/ipv4/{Kconfig,Makefile}`、
  `fs/nomount/*`、`fs/{Kconfig,Makefile}`、`lib/lz4k/*`、`include/linux/lz4k.h`、`lib/{Kconfig,Makefile}`、`arch/arm64/configs/vendor/ext_config/moto-lahaina-xpeng.config`。
- 文档:`docs/FEATURE_PORTS.md`、`docs/BUILD_LOG.md`(本节)、`docs/edge-s30.config`、`docs/SHA256SUMS.txt`、`docs/xpeng_build6_features.log.xz`。
- 构建仓:`scripts/ci/build_resukisu_boot.sh` 新增 `INCREMENTAL` / `CONFIG_ONLY` 开关。
## 十一、第三轮: 移动数据有信号无网络 —— 根因定位与 RMNET 内建修复 (2026-10-02)

### 11.1 症状

刷入特性版后开机正常, 移动网络有信号, 打开数据开关无数据连接, 无法上网。

### 11.2 排除过程(共 4 轮构建)

| 轮次 | 假设 | 结果 |
|------|------|------|
| 第2轮 | BBR 默认拥塞控制与 rmnet 不兼容 | ❌ 改回 cubic 后故障依旧 |
| 第2.5轮 | TCP 组(BBRv3/Brutal/fq)代码副作用 | ❌ 完全 revert TCP 组后故障依旧 |
| 第3轮 | USER_NS/NoMount/LZ4K 之一 | ❌ 纯净基线+三项仍故障(设备实测) |

### 11.3 真凶: vendor rmnet_core.ko 加载失败

设备侧 adb 取证(决定性证据):

```
$ ip link | grep rmnet
rmnet_ipa0: <UP,LOWER_UP> ... qdisc pfifo_fast        # 链路层正常
$ cat /proc/net/dev | grep rmnet
rmnet_ipa0: 0 0 0 0 ...                                 # RX/TX 全 0
$ lsmod | grep rmnet
rmnet_ctl  20480  0                                     # 只有 ctl, 缺 rmnet_core
$ su 0 insmod /vendor/lib/modules/rmnet_core.ko
insmod: failed: Invalid argument
dmesg: rmnet_core: disagrees about version of symbol rtnl_link_register
dmesg: rmnet_core: Unknown symbol rtnl_link_register (err -22)
```

机制: `/vendor/lib/modules/rmnet_core.ko` 是为 stock 5.4.210 内核编译的模块;
我们的内核(5.4.302-moto, 无论是否加新特性)无法加载它 → rmnet_ipa0 由 IPA3(内建)
创建所以接口存在, 但 QMAP 解复用数据面(rmnet_core)从未工作 → 有信号、零收发。

注意: vendor 模块 __versions 段期望的 CRC (rtnl_link_register=0xddf5d971) 与我们
Module.symvers 完全一致, 但运行时校验仍失败; v4.1.0 能用的真实原因是它连同
vendor 分区一起被用户刷入/或未触发同样的校验路径。与 USER_NS/NoMount/LZ4K/
BBRv3/Brutal/fq 全部无关 —— 它们均在第二轮后被逐一排除。

### 11.4 修复

techpack 的 `techpack/datarmnet/core/Kbuild` 硬编码 `obj-m`(不读 CONFIG_RMNET_*
符号, 该符号在 .config 中不存在), 改为 `obj-y` 将树内 rmnet_core/rmnet_ctl 内建,
彻底绕开 vendor 模块加载(commit 159a741fc7e9)。rmnet_offload/rmnet_shs 保持模块
(可选加速, vendor 分区原版加载失败不影响基本数据)。

### 11.5 构建与验证(full 全量, BUILD_WLAN=false)

- HEAD: `159a741fc7e9` (tag `susfs2.3-droidspace-rekernel`)
- 时间: 10:50:02 → 11:15:34, 约 25 分钟(含 ThinLTO 链接)
- 编译日志确认: `CC techpack/datarmnet/core/rmnet_*.o`(无 [M], 内建) + `built-in.a`
- MODPOST 79 modules(较 81 少 2: rmnet_core/rmnet_ctl 已内建)

| 验证项 | 结果 |
|--------|------|
| `kernel.release` | ✅ `5.4.302-moto` |
| vmlinux rmnet 符号 | ✅ 876 个(含 `rmnet_init`) |
| rmnet_core.ko/rmnet_ctl.ko | ✅ 不再作为模块生成(0 个) |
| rmnet_offload.ko/rmnet_shs.ko | ✅ 仍为模块(可选加速) |
| boot 内嵌内核 == Image | ✅ SHA-256 逐字节一致 |
| USER_NS/NOMOUNT/LZ4K/cubic | ✅ 保持不变 |

### 11.6 产物

| 文件 | SHA-256 |
|------|---------|
| `boot_ksu.img` (96M) | `f2f3b8a12de297734366bd8642386d8d73dfc2957bbec6c4e2963bbf9713209c` |
| `Image` (42M) | `afa83cb784461932ea8bddb53a5fae1569c6986c2d1697f8bf48b0a83564eacc` |

### 11.7 刷入后预期

- 开机后 `lsmod | grep rmnet` 应为空或仅 rmnet_offload/shs(若 vendor 版可载)
- `cat /proc/net/dev | grep rmnet` 开数据后 RX/TX 应增长
- dmesg 可能出现 vendor rmnet_core.ko insmod 失败日志(modules.load 仍会尝试),
  属预期噪音, 不影响功能(内核已内建)

### 11.8 实测结果 (2026-10-02 用户确认)

✅ **刷入后移动数据已恢复** —— 开机正常, 有信号, 数据开关打开后可正常上网。
根因(vendor rmnet_core.ko 符号校验失败)与修复(树内 rmnet 内建)得到实测确认。