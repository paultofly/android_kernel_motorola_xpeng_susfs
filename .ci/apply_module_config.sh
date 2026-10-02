#!/usr/bin/env bash
# 模块化构建: 按 ENABLE_* 环境变量向 ext_config 注入模块选择。
# 用法: ENABLE_SUSFS=true ENABLE_REKERNEL=true ... bash .ci/apply_module_config.sh
#
# 原理: 构建脚本 build_resukisu_boot.sh 的 apply_nfc_overlay 会在构建前
#   git checkout HEAD -- ext_config 恢复该文件。本脚本注入后 commit 到 HEAD,
#   使"恢复"恰好保留注入配置; 并打本地 tag 保证 git describe 精确匹配,
#   vermagic 保持 5.4.302-moto (vendor 模块 vermagic 兼容)。
set -euo pipefail

CFG=arch/arm64/configs/vendor/ext_config/moto-lahaina-xpeng.config
[ -f "$CFG" ] || { echo "[!] missing $CFG (请在 kernel 树根目录运行)"; exit 1; }

bool() { [ "${!1:-true}" = "true" ]; }   # 默认 true
disable() { sed -i "s/^CONFIG_$1=y$/# CONFIG_$1 is not set/" "$CFG"; }

if ! bool ENABLE_SUSFS; then
  for s in KSU_SUSFS KSU_SUSFS_SUS_PATH KSU_SUSFS_SUS_MOUNT KSU_SUSFS_SUS_KSTAT \
           KSU_SUSFS_SPOOF_UNAME KSU_SUSFS_ENABLE_LOG KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
           KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG KSU_SUSFS_OPEN_REDIRECT KSU_SUSFS_SUS_MAP; do
    disable $s
  done
  # SUSFS 是 KernelSU choice "KernelSU Hooking Method" 的选项之一
  # (KSU_TRACEPOINT_HOOK / KSU_MANUAL_HOOK / KSU_SUSFS)。禁用 SUSFS 后 choice 会
  # 回退到默认 KSU_TRACEPOINT_HOOK, 而 TP hook 不兼容 5.4 GKI 1.0 (编译报错)。
  # 必须显式选择 Manual Hook。
  sed -i 's/^CONFIG_KSU_TRACEPOINT_HOOK=y$/# CONFIG_KSU_TRACEPOINT_HOOK is not set/' "$CFG"
  sed -i 's/^CONFIG_KSU_MANUAL_HOOK=y$//' "$CFG"
  sed -i '/^# CONFIG_KSU_MANUAL_HOOK is not set$/d' "$CFG"
  if ! grep -q '^CONFIG_KSU_MANUAL_HOOK=y' "$CFG"; then
    printf '\n# SUSFS disabled: use Manual Hook (GKI 1.0 compatible)\nCONFIG_KSU_MANUAL_HOOK=y\n# CONFIG_KSU_TRACEPOINT_HOOK is not set\n' >> "$CFG"
  fi
fi
bool ENABLE_REKERNEL     || disable REKERNEL
bool ENABLE_NOMOUNT      || disable NOMOUNT
bool ENABLE_LZ4K         || disable LZ4K
if ! bool ENABLE_DROIDSPACES; then
  for s in USER_NS IPC_NS PID_NS POSIX_MQUEUE TMPFS_POSIX_ACL TMPFS_XATTR \
           NETFILTER_XT_MATCH_ADDRTYPE IP_NF_TARGET_REJECT NETFILTER_XT_TARGET_LOG \
           NETFILTER_XT_MATCH_RECENT IP_SET IP_SET_HASH_IP IP_SET_HASH_NET NETFILTER_XT_SET; do
    disable $s
  done
fi
if ! bool ENABLE_BBRV3; then
  for s in TCP_CONG_ADVANCED TCP_CONG_BBR DEFAULT_BBR TCP_CONG_BRUTAL NET_SCH_FQ; do
    disable $s
  done
  # BBR 不再默认时回退 cubic, 避免 DEFAULT_TCP_CONG="bbr" 悬空
  sed -i 's/^CONFIG_DEFAULT_TCP_CONG="bbr"$/CONFIG_DEFAULT_TCP_CONG="cubic"/' "$CFG"
fi

echo "[+] 注入后 ext_config 模块状态:"
grep -E '^(CONFIG_|# CONFIG_)(KSU_SUSFS|REKERNEL|NOMOUNT|LZ4K|USER_NS|TCP_CONG_BBR|DEFAULT_BBR|TCP_CONG_BRUTAL)' "$CFG" | head -25

# commit + 本地 tag (vermagic 稳定)
git config user.email "${GIT_USER_EMAIL:-ci@resukisu.local}"
git config user.name  "${GIT_USER_NAME:-resukisu-ci}"
# 只暂存 ext_config (不用 git add -A: 避免误纳入无关未跟踪文件)
git add "$CFG"
git commit -m "ci: module selection [${MODULES:-manual}] r${BUILD_ROUND:-0}" || true
git tag -a -f -m ci susfs2.3-droidspace-rekernel HEAD >/dev/null
git describe --tags --exact-match