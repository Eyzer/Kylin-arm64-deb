# Kylin-arm64-deb

自编译的银河麒麟 V10（aarch64）应用安装包集合，附构建脚本与移植记录。

系统基线：glibc 2.28，架构 arm64，目标桌面为 GTK3 / X11 会话。

## 包清单

| 包 | 版本 | 体积 | 说明 |
| --- | --- | --- | --- |
| [ProxyPin](packages/proxypin) | 1.4.0+kylin4 | 12 MB | HTTP(S) 抓包与改写工具，Flutter 桌面版，已修复中文方块 |
| [rime-tune](packages/rime-tune) | 0.3.1 | 2.0 MB | Rime 输入法配置中心，Tauri 1 应用，依赖系统 WebKitGTK |
| [nomacs](packages/nomacs) | 3.17.2295-4 | 40 MB | 图像查看器，自带 Qt 5.15 运行时，隔离系统 Qt |

安装（以 ProxyPin 为例）：

    sudo dpkg -i packages/proxypin/proxypin_1.4.0+kylin4_arm64.deb
    sudo apt-get -f install

各包的启动方式、依赖与已知问题见各自的 README。

## 目录约定

    packages/<应用名>/
        <应用名>_<版本>_arm64.deb   成品
        README.md                   该包的移植说明、依赖与已知问题
        screenshots/                实机或模拟环境截图
        patches/                    相对上游的补丁
        scripts/                    交叉编译、打包、验证脚本

## 三种构建路子

三个包正好代表三种做法，按依赖复杂度选：

1. **交叉编译 + 自带引擎**（ProxyPin）：x86_64 主机上用官方 Flutter SDK 的 x64 工具链，配 aarch64 sysroot 与 arm64 版 `gen_snapshot`，产出 linux-arm64 产物。麻烦在引擎不做交叉编译，得手工补齐缓存与工具链补丁。
2. **原生 arm64 runner 构建**（rime-tune）：GitHub Actions 的 `ubuntu-24.04-arm` + Debian 11 容器，产物天然对齐麒麟的 glibc 与 WebKitGTK 版本，最省心，前提是有可用的 arm64 CI。
3. **交叉编译 + 自带运行时**（nomacs）：依赖 Qt 的应用不能指望目标机的 Qt 版本对得上，把整套 Qt 与递归依赖打进 `/opt`，`Depends` 只留 libc6。

共同的一条：**产物符号基线不高于 glibc 2.28**。拿 `readelf --version-info` 逐个查
`GLIBC_x.y`，超了就得换更旧的构建环境重来。

脚本里的绝对路径（`/opt/kylinroot`、`/opt/pp`、`/srv/arm64` 等）是当时的构建环境，复现时按自己的目录调整。

## 许可

各包版权归其上游项目所有，遵循上游许可。本仓库只包含构建脚本、补丁与说明。
ProxyPin 包内置文泉驿微米黑（GPLv3 + 字体嵌入例外）。
