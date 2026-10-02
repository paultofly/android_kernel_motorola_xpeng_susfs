# xpeng (moto edge s30) 5.4.302 ReSukiSU 内核 — 移动数据修复版

**设备**: Motorola edge s30 (xpeng, SM8350/lahaina)  
**基线**: MMI S3RXC32.33-8-25 / Android 12, kernel 5.4.302  
**内核标识**: `5.4.302-moto` (ReSukiSU v4.2.0-rc3 + SUSFS)

## 本版修复: 移动数据「有信号无网络」

### 症状
开机正常、移动网络有信号、打开数据开关后无数据连接、无法上网。

### 根因
`/vendor/lib/modules/rmnet_core.ko` 是为 stock 5.4.210 内核编译的厂商模块,
在本内核上加载失败:

```
rmnet_core: disagrees about version of symbol rtnl_link_register
rmnet_core: Unknown symbol rtnl_link_register (err -22)
```

- `rmnet_ipa0` 接口由 IPA3(内建)创建 → 接口存在、有信号
- 但移动数据 QMAP 数据面在 `rmnet_core` 里 → 加载失败 → RX/TX 全 0、无网络

### 修复
将树内 `techpack/datarmnet/core` 的 `rmnet_core`/`rmnet_ctl` 从 `obj-m` 改为 `obj-y`
直接编入 vmlinux, 绕开厂商模块的符号版本校验。
(`rmnet_offload`/`rmnet_shs` 保持模块化, 为可选硬件加速, 其厂商版加载失败不影响基本上网)

## 本版包含的特性 (2026-10-02 更新: BBRv3+Brutal 已恢复)

| 特性 | 状态 | 说明 |
|------|------|------|
| ReSukiSU v4.2.0-rc3 + SUSFS | ✅ | root 方案 |
| USER_NS (用户命名空间) | ✅ | DroidSpaces 等容器需要 |
| NoMount 路径重定向 | ✅ | 默认空转, 无用户载荷时无行为 |
| LZ4K 压缩算法 | ✅ | 华为 LZ4K/LZ4KD, 惰性(无调用方) |
| TCP 拥塞控制 | **BBRv3 默认** | BBRv3 backport + TCP Brutal; fq 编入(非默认 qdisc) |
| rmnet_core/ctl | ✅ 内建 | 移动数据修复 |
| WiFi | ✅ | 厂商 qca_cld3 模块(vermagic 匹配 5.4.302-moto) |

## 刷入

```bash
fastboot flash boot boot_ksu.img
```

或用 AnyKernel3 zip 在 recovery 刷入(同时替换 vendor WiFi 模块)。

## 验证(刷入后)

```bash
uname -r                        # 5.4.302-moto
cat /proc/net/dev | grep rmnet  # 开数据后 RX/TX 应增长
```

dmesg 中可能出现 vendor `rmnet_core.ko` insmod 失败的日志 —— 属预期噪音
(内核已内建 rmnet_core, 旧模块无需加载), 不影响功能。

## 校验值 (SHA-256)

```
aed924c94f80358ca526ae3ccdf9dfa224eccbfa7cf06ba920402be9a3f21b08  Image
75346dac61466c6660113a9d35cef6a55cbe1caa8e9f5e0ca4420b4ad7b5f672  boot_ksu.img
```

## 源码

- 分支: `resukisu-v4.2.0-rc3-update`
- 修复提交: `159a741fc7e9` (rmnet 内建)
- 完整根因分析: `docs/BUILD_LOG.md` §11
- 特性移植说明: `docs/FEATURE_PORTS.md`

完整构建记录与归档见仓库 docs/ 与 build-snapshots/。