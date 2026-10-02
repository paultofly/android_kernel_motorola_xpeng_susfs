#!/usr/bin/env bash
# 生成 RELEASE_NOTES.md (纯 bash, 无转义)。在 release 目录运行。
# 用法: MODULES=rekernel_susfs BUILD_ROUND=9 ENABLE_*=<true|false> BUILD_WLAN=<bool> \
#       BOOT_IMG=... AK3_ZIP=... bash gen_release_notes.sh
set -euo pipefail

M="${MODULES:-base}"
R="${BUILD_ROUND:-0}"
on() { [ "$1" = "true" ] && echo "✅ 支持" || echo "❌ 不支持"; }
if [ "${BUILD_WLAN:-false}" = "true" ]; then
  WIFI="✅ 已编译"
else
  WIFI="⚠️ 未编译 (刷通用预编译 wlan_crc_match_*.zip)"
fi

{
  echo "# xpeng 5.4.302 ReSukiSU — ${M} (r${R})"
  echo
  echo "## 模块支持"
  echo
  echo "| 模块 | 状态 |"
  echo "|------|------|"
  echo "| SUSFS v2.3 (路径/挂载/KSTAT隐藏等) | $(on "${ENABLE_SUSFS:-true}") |"
  echo "| Re:Kernel | $(on "${ENABLE_REKERNEL:-true}") |"
  echo "| DroidSpaces (容器) | $(on "${ENABLE_DROIDSPACES:-true}") |"
  echo "| NoMount | $(on "${ENABLE_NOMOUNT:-true}") |"
  echo "| BBRv3 + TCP Brutal (默认 bbr) | $(on "${ENABLE_BBRV3:-true}") |"
  echo "| LZ4K | $(on "${ENABLE_LZ4K:-true}") |"
  echo "| NFC | ❌ 不支持 (本机型无 NFC) |"
  echo "| WiFi 模块 (qca_cld3) | ${WIFI} |"
  echo
  echo "## 文件"
  echo
  echo "| 文件 | 说明 |"
  echo "|------|------|"
  echo "| \`${BOOT_IMG}\` | boot 镜像 (\`fastboot flash boot\`) |"
  echo "| \`${AK3_ZIP}\` | AnyKernel3 刷机包 (recovery 刷入) |"
  echo "| \`Image\` | 原始内核镜像 |"
  echo "| \`SHA256SUMS_r${R}.txt\` | 校验和 |"
  echo
  echo "## 验证"
  echo
  echo "\`\`\`bash"
  echo "adb shell 'cat /proc/version'   # 5.4.302-moto"
  echo "\`\`\`"
} > RELEASE_NOTES.md

if [ "${ENABLE_SUSFS:-true}" = "true" ]; then
  {
    echo
    echo "### SUSFS 验证"
    echo "\`\`\`bash"
    echo "adb shell 'su 0 dmesg | grep \"susfs is initialized\"'"
    echo "adb shell 'su 0 ksu_susfs add_sus_path /data/local/tmp/test'"
    echo "adb shell 'ls /data/local/tmp/test'   # 非 root: No such file or directory"
    echo "\`\`\`"
  } >> RELEASE_NOTES.md
fi

echo "[+] RELEASE_NOTES.md 生成完成"
