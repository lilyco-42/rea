# REA · Termux 适配版

这个分支在 [morluto/rea](https://github.com/morluto/rea) 6.4.0 基础上，做了「Termux 一键化」：

- `.github/workflows/termux-release.yml` — 只构建 release 产物（不再跑上游那堆真机/GUI 验证矩阵）
- `setup-termux.sh` — 在 Termux 里 `pkg` 装齐 REA 的外部工具链（apktool/jadx/adb/frida-tools/pwntools…）
- `install-rea.sh` — 从本 fork 的 GitHub Release 拉取并安装 REA

## 快速开始（Android + Termux）

```bash
# 1) 装工具链（apktool/jadx/adb/frida/pwntools…，--with-web-tools 可加 chromium/mitmproxy）
bash setup-termux.sh

# 2) 装 REA 本体（从 GitHub Release 下载）
bash install-rea.sh

# 3) 用起来
rea --help
rea doctor          # 检查本机工具链可用性
rea analyze apk /path/to/app.apk   # 示例：APK 静态分析（依赖 apktool/jadx）
```

也可以不装工具链，只用 npm 包：
```bash
pkg install -y nodejs npm
npm i -g "https://github.com/lilyco-42/rea/releases/latest/download/rea-agents-6.4.0.tgz"
```

## Release 产物

| 资产 | 说明 |
|---|---|
| `rea-agents-<ver>.tgz` | 官方 npm 打包产物，`npm i -g` 直接装 |
| `rea-termux-<ver>.tar.gz` | 便携包，解压到 `$PREFIX/lib/rea` 配合系统 node 运行 |
| `install-rea.sh` | 一键安装脚本（从 latest release 下载） |
| `setup-termux.sh` | Termux 工具链一键安装 |
| `version.txt` | 当前版本号 |

## Termux 能力边界

Termux 内可独立完成：APK 静态分析（apktool/jadx/aapt）、动态调试（frida/objection）、
原生二进制分析（binutils/pwntools）、ADB 巡检（adb）、爬虫/抓包（chromium/mitmproxy）。

桌面工具（Hopper / IDA Pro / Ghidra）是 PC 端 GUI 应用，需要在 PC 上运行，
Termux 侧的 REA 通过 spawn/SSH 桥接调用。

## 重新构建/手动触发

到 Actions 页面 → `termux-release` → Run workflow，或改 `termux/**`、`package.json` 后 push 到 main。
产物落为 Release `v<ver>-termux`。