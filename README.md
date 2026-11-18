# Kylin-arm64-deb

自编译的银河麒麟 V10（aarch64）应用安装包集合，附构建脚本与移植记录。

系统基线：glibc 2.28，架构 arm64，桌面依赖 GTK3，目标为 X11 会话。

## 包清单

| 包 | 版本 | 体积 | 说明 |
| --- | --- | --- | --- |
| ProxyPin | 1.4.0+kylin4 | 12 MB | HTTP(S) 抓包与改写工具，Flutter 桌面版，已修复中文方块 |

安装：

    sudo dpkg -i packages/proxypin/proxypin_1.4.0+kylin4_arm64.deb
    sudo apt-get -f install

启动：应用菜单里的 ProxyPin，或命令行 /opt/proxypin/ProxyPin。

## 目录约定

    packages/<应用名>/
        <应用名>_<版本>_arm64.deb   成品
        README.md                   该包的移植说明、依赖与已知问题
        screenshots/                实机或模拟环境截图
        scripts/                    交叉编译、补丁、打包、验证脚本

## 通用做法

交叉编译在 x86_64 主机上完成：用官方 Flutter SDK 的 x64 工具链，配合 aarch64
系统根（sysroot）与 gen_snapshot 的 arm64 版本，产出 linux-arm64 产物，再按
FHS 打包成 deb。所有包都保证不高于 glibc 2.28 的符号基线。

脚本里的绝对路径（/opt/kylinroot、/opt/pp 等）是当时的构建环境，复现时按自己
的目录调整即可。

## 许可

各包版权归其上游项目所有，遵循上游许可。本仓库只包含构建脚本、补丁与说明。
内置字体为文泉驿微米黑（GPLv3 + 字体嵌入例外）。
