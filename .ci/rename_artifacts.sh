#!/usr/bin/env bash
# 重命名产物为规范命名, 并生成 SHA256SUMS。在 release 目录运行。
# 用法: BOOT_IMG=... AK3_ZIP=... BUILD_ROUND=9 bash rename_artifacts.sh
set -euo pipefail
: "${BOOT_IMG:?}"; : "${AK3_ZIP:?}"; : "${BUILD_ROUND:?}"
cp -f boot_ksu.img "$BOOT_IMG"
AK3_SRC=$(ls AnyKernel3*.zip 2>/dev/null | head -1)
[ -n "$AK3_SRC" ] && cp -f "$AK3_SRC" "$AK3_ZIP"
{
  sha256sum "$BOOT_IMG"
  [ -n "$AK3_SRC" ] && sha256sum "$AK3_ZIP"
  sha256sum Image
} > "SHA256SUMS_r${BUILD_ROUND}.txt"
ls -lh
cat "SHA256SUMS_r${BUILD_ROUND}.txt"
