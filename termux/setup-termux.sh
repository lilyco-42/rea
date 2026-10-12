#!/bin/bash
#
# setup-termux.sh - 在 Termux (Android) 上一键安装 REA 及它的完整外部工具链。
# 用法: bash setup-termux.sh [--with-deskop-tools]
#
# 注意:
#   - REA 需要 Node.js >= 22.19 / 24 (>=24.11) / 26+，Termux 仓库的 nodejs 直接满足。
#   - 桌面 IDE 类工具 (Hopper / IDA / Ghidra) 是 PC 端 GUI 应用，无法在 Termux 内安装；
#     需要在一台 PC/服务器上运行，然后让 Termux 里的 REA 通过 SSH/网络桥接调用。
#   - 若你只要分析 APK/二进制，下列 Termux 包 + pip 工具已足够。
set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

log()  { printf '\033[1;36m[rea]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[rea]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[rea]\033[0m %s\n' "$*" >&2; exit 1; }

command -v termux-info >/dev/null 2>&1 || die "这只能在 Termux 里运行（$0 依赖 \$PREFIX=$PREFIX）。"

# ---- 1. 基础运行时（失败即停） -----------------------------------------------
log "更新 Termux 软件源（pkg update/upgrade）…"
pkg update -y >/dev/null 2>&1 || { warn "pkg update 失败，继续尝试安装（可能只是源网络抖动）。"; }
pkg upgrade -y >/dev/null 2>&1 || warn "pkg upgrade 失败，继续。"
pkg install -y nodejs npm git openssh >/dev/null && log "基础运行时 OK (node=$(node -v))" \
  || die "安装基础包 (nodejs/npm/git/openssh) 失败。"

# ---- 2. 常备小工具（可失败，不致命） ----------------------------------------
ESSENTIAL="curl wget jq tar zip unzip binutils coreutils findutils sed grep ripgrep silversearcher-ag nmap openssl-tool ca-certificates"
for p in $ESSENTIAL; do
  pkg install -y "$p" >/dev/null 2>&1 && continue
  warn "跳过可选包: $p"
done

# ---- 3. REA 逆向工具链（Termux 有现成包的部分）-------------------------------
TOOLS="apktool jadx adb aapt aapt2 sqlite file"   # aapt2 可能不存在，会跳过
for p in $TOOLS; do
  pkg install -y "$p" >/dev/null 2>&1 && log "工具 OK: $p" || warn "跳过可选工具: $p"
done

# ---- 4. Python 侧逆向工具 ----------------------------------------------------
log "安装 Python 工具 (pwntools / frida-tools / objection)…"
pkg install -y python >/dev/null 2>&1 || warn "python 安装失败，跳过 pip 工具。"
if command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
  PIPP="$PREFIX/bin/pip"
  "$PIPP" install -q --upgrade pip >/dev/null 2>&1 || true
  "$PIPP" install -q pwntools frida-tools objection 2>/dev/null \
    && log "pip 工具 OK (pwntools/frida-tools/objection)" \
    || warn "pip 安装部分失败，请手动检查（可能需要: termux-packages 里有 libc-binutils 依赖）。"
else
  warn "pip 不可用，跳过 pwntools/frida-tools/objection。"
fi

# ---- 5. 浏览器抓包（可选，占空间大）-----------------------------------------
# REA 的 web 分析会用到 Chromium 与 mitmproxy；Termux 可装 chromium，
# mitmproxy 用 pip 安装。默认跳过，避免下载过重。
if [[ "${1:-}" == "--with-web-tools" ]]; then
  log "安装 web 分析工具 (chromium/mitmproxy) — 体积较大…"
  pkg install -y chromium >/dev/null 2>&1 && log "chromium OK" || warn "chromium 安装失败。"
  "$PREFIX/bin/pip" install -q mitmproxy 2>/dev/null && log "mitmproxy OK" \
    || warn "mitmproxy 安装失败（pip 包体积大，易超时）。"
else
  warn "跳过 web 工具 (chromium/mitmproxy)。需要时重跑: bash setup-termux.sh --with-web-tools"
fi

# ---- 6. 桌面 IDE 提示 --------------------------------------------------------
cat <<'EOF'

[rea] 桌面逆向 IDE 说明:
  Hopper / IDA Pro / Ghidra 均为 PC 端 GUI 工具，Termux 装不了。
  用法: 在 PC/服务器装好对应工具，REA 会通过进程/spawn 或 SSH 桥接调用它们。
  Termux 侧可独立完成: APK 静态分析(apktool/jadx)、动态调试(frida/objection)、
  原生二进制分析(binutils/pwntools)、ADB 巡检(adb)。

完成。接下来安装 REA 本体:
  bash <(curl -L https://github.com/lilyco-42/rea/releases/latest/download/install-rea.sh)
或者先测一遍本机能力:
  rea doctor
EOF