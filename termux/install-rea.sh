#!/bin/bash
#
# install-rea.sh - 从 lilyco-42/rea 的 GitHub Release 安装 REA（Termux 专用版）。
# 用法:
#   bash install-rea.sh                 # 安装最新 release
#   bash install-rea.sh --version 6.4.0 # 指定版本
#   REA_VERSION=6.4.0 bash install-rea.sh
#
# 产物说明（全部来自 GitHub Release，本脚本只做取用）:
#   rea-agents-<ver>.tgz      官方 npm 打包产物（纯 JS + 可选原生模块），Termux 可直接装
#   rea-termux-<ver>.tar.gz   便携包：解压即有 dist/skills/scripts，配合系统 node 直接跑
set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
RELEASE_BASE="https://github.com/lilyco-42/rea/releases/latest/download"

VERSION="${REA_VERSION:-}"
while (($# > 0)); do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --prefix)  PREFIX="$(realpath "$2")"; shift 2 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

log() { printf '\033[1;36m[rea]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[rea]\033[0m %s\n' "$*" >&2; exit 1; }

command -v node >/dev/null 2>&1 || die "未找到 node。请先运行: bash setup-termux.sh"
command -v npm  >/dev/null 2>&1 || die "未找到 npm。请先运行: bash setup-termux.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---- 解析最新版本号 ----------------------------------------------------------
if [[ -z "$VERSION" ]]; then
  log "解析最新 release 版本…"
  VERSION="$(curl -fsSL --retry 3 "$RELEASE_BASE/version.txt" 2>/dev/null || true)"
  if [[ -z "$VERSION" ]]; then
    log "curl(install-rea.sh) 拿不到版本，退回 GitHub API…"
    VERSION="$(curl -fsSL --retry 3 "https://api.github.com/repos/lilyco-42/rea/releases/latest" \
      | sed -n 's/.*"tag_name": *"v\([^"]*\)".*/\1/p' | head -1)"
  fi
  [[ -n "$VERSION" ]] || die "无法确定最新版本号，可用 --version 指定。"
fi
log "目标版本: $VERSION"

# ---- 安装方式 A: npm 全局安装（首选，会注册 `rea` 命令）----------------------
log "下载 rea-agents-$VERSION.tgz …"
TGZ="$TMP/rea-agents-$VERSION.tgz"
curl -fL --retry 3 --output "$TGZ" "$RELEASE_BASE/rea-agents-$VERSION.tgz" \
  || die "下载失败: $RELEASE_BASE/rea-agents-$VERSION.tgz"
log "npm 安装 → \$PREFIX/lib/node_modules/rea-agents"
npm install -g "$TGZ"
npm ls -g rea-agents >/dev/null 2>&1 || warn "npm 全局安装校验失败，请检查上方输出。"

# ---- 安装方式 B: 便携包（可选，供 node_modules 缺失/离线场景）----------------
if [[ "${1:-}" == "--portable" ]] || true; then
  PORTABLE_DIR="$PREFIX/lib/rea"
  log "同步便携包到 $PORTABLE_DIR …"
  curl -fL --retry 3 --output "$TMP/rea-termux-$VERSION.tar.gz" \
    "$RELEASE_BASE/rea-termux-$VERSION.tar.gz" || warn "便携包下载失败，跳过（npm 版已可用）。"
  if [[ -f "$TMP/rea-termux-$VERSION.tar.gz" ]]; then
    mkdir -p "$PORTABLE_DIR"
    tar -xzf "$TMP/rea-termux-$VERSION.tar.gz" -C "$PORTABLE_DIR"
    ln -sf "$PORTABLE_DIR/scripts/rea.mjs" "$PREFIX/bin/rea-node" 2>/dev/null || true
  fi
fi

# ---- 收尾 --------------------------------------------------------------------
if command -v rea >/dev/null 2>&1; then
  log "安装完成。运行: rea --help   |   诊断: rea doctor"
else
  warn "`rea` 未进入 PATH，请检查 npm 全局 bin (npm config get prefix/bin)。"
fi