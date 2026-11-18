# rime-tune 0.3.1 · 银河麒麟 V10 arm64

Rime 输入法配置中心（RimeTune），Tauri 1 桌面应用。

- 成品：`rime-tune_0.3.1_arm64.deb`（2.0 MB）
- 安装位置：`/usr/bin/rime-tune`，菜单项「RimeTune」
- 依赖：`libwebkit2gtk-4.0-37`、`libgtk-3-0`
- 符号基线：最高 `GLIBC_2.30`

    sudo dpkg -i rime-tune_0.3.1_arm64.deb

比 ProxyPin、nomacs 省事：Tauri 应用依赖系统 WebKitGTK，不需要自带运行时，所以包只有 2 MB。

## 构建方式

不交叉编译，直接用 GitHub Actions 的**原生 arm64 runner**。

工作流：`.github/workflows/kylin-arm64-deb.yml`，要点：

```yaml
runs-on: ubuntu-24.04-arm
container:
  image: node:20-bullseye
```

选 Debian 11（bullseye）容器是为了对齐麒麟 V10：glibc 2.31、WebKitGTK 4.0。在 bullseye 里链接出来的产物，到 glibc 2.28 的麒麟上不会遇到高版本符号。

完整源码与工作流在单独仓库：<https://github.com/Eyzer/RimeTune-kylin-v10>（分支 `kylin-v10`）。本目录的 `patches/RimeTune-kylin-v10.patch` 是相对上游 `harry10086/RimeTune` 的全部改动，17 个文件，可直接 `git apply` 复现。

## 为跑通构建改了什么

上游没有 Linux arm64 的 CI，改动集中在构建链与 Linux 适配：

| 改动 | 原因 |
| --- | --- |
| 新增 `kylin-arm64-deb.yml` 工作流 | 上游无 arm64 构建 |
| 软件源改 `archive.debian.org` + `Acquire::Check-Valid-Until=false` | bullseye-security 已进归档，`deb.debian.org` 上的包全部 404 |
| `Cargo.toml` 加 `[features] custom-protocol = ["tauri/custom-protocol"]` | Tauri 1 release 构建必需，缺了会起不来 |
| `[[bin]] name` 改成与 package name 一致（`rimetune`） | Tauri 1 CLI 要求二进制名与包名对齐，否则找不到待重命名的文件 |
| 修正产物重命名后的校验步骤 | Tauri 1 bundler 会把二进制重命名为 `rime-tune`，按旧名检查会误报失败 |
| Linux 下解析 Rime 用户目录，并通过 fcitx5/ibus 重载 | 麒麟上 Rime 走 fcitx5，上游只处理了 macOS/Windows 的路径与重载方式 |

## 已知问题

- `Depends` 里是 WebKitGTK **4.0**。若目标系统只装了 4.1（`libwebkit2gtk-4.1-0`），apt 会报依赖不满足；麒麟 V10 自带 4.0，正常。
- 需要系统已装 fcitx5-rime 或 ibus-rime，否则能打开界面但重载无效。
- 只在 kylin-v10 分支产出，未做 x86_64 与 macOS 的同步验证。

## 许可

RimeTune 为开源项目，许可见上游仓库。本目录只放成品与补丁。
