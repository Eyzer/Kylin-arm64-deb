# ProxyPin 银河麒麟 V10 arm64

上游：https://github.com/wanghongenpin/proxypin
版本：1.4.0（上游 main 分支，2026-11 构建）
成品：proxypin_1.4.0+kylin4_arm64.deb（12 MB）
安装路径：/opt/proxypin
依赖：ca-certificates、libgtk-3-0、fontconfig

## 截图

中文界面：screenshots/zh-CN.png
英文界面：screenshots/en-US.png

## 移植中解决的问题

### 1. 中文全部显示为方块（核心问题）

现象：界面英文数字正常，中文一律方块。

根因：Flutter Linux 引擎按 fontconfig 的**字体族名**查找字体，但它**不加载
/etc/fonts 下的任何配置**（不打开 fonts.conf，也不读 conf.d），只遍历
/usr/share/fonts 目录。上游 Material Typography 在 Linux 平台写死请求族名
"Roboto"，麒麟系统没有这个族，字形回退直接失败，于是所有汉字变成 .notdef 方块。

用系统命令跟踪进程打开的文件可以确认：引擎全程没有打开过字体配置文件，只扫描
字体目录。因此以下做法全部无效：

- 安装中文字体到系统（引擎扫得到文件，但按名找不到族）
- 在 /etc/fonts/conf.d 里加 alias，把 Roboto 指向中文字体
- 用 FONTCONFIG_FILE 给进程指定私有配置
- 在 deb 里附带字体并用 fontconfig 规则做回退

有效做法：把中文字体的族名改成 Roboto，让引擎按名直接命中。

    python3 scripts/make_roboto_cjk_font.py wqy-microhei.ttc Roboto-CJK.ttf

生成的单文件 ttf 装到 /usr/share/fonts/truetype/proxypin/Roboto-CJK.ttf，同时
保留原名副本 wqy-microhei.ttc 供系统其他组件使用。装完执行 fc-cache -f。

注意：若目标系统已安装真正的 Roboto 字体包，可能与之同名冲突，导致仍取到没有
中文字形的原版。遇到这种情况先移除系统 Roboto 包。

### 2. Rust 库依赖 glibc 2.29 / 2.30 符号

code_forge 插件的 Rust 产物要求 GLIBC_2.29 与 GLIBC_2.30，超出 2.28 基线，
在麒麟上无法加载。处理方式是把版本需求降级：把 .so 中对应版本字符串改写为
GLIBC_2.17，并同步修正 .gnu.version_r 的 ELF 哈希与 .gnu.version 索引，
否则动态链接器会报版本哈希不匹配。

### 3. QuickJS 插件只有 x86 版本

flutter_js 依赖的 libquickjs_c_bridge_plugin.so 上游只提供 x64。用
scripts/build_quickjs.sh 从 quickjs-c-bridge 源码交叉编译 arm64 版本后替换。

### 4. 编译期零碎问题

- 上游 CMakeLists 带 -Wall -Werror，新编译器告警直接变错误，去掉 -Werror。
- flutter_js 的 linux/CMakeLists.txt 把编译器写死为 gcc/g++，需改成
  aarch64-linux-gnu-gcc / g++。
- 链接期报 __nanosleep_nocancel 等 glibc 私有符号未定义，加
  -Wl,--allow-shlib-undefined 放行。
- Dart VM 在 qemu-user 下启动报 stack bounds 失败，运行验证时必须以
  -R 0x100000000 保留地址空间。

## 构建流程

1. 准备 aarch64 sysroot（本项目用 Debian buster，glibc 2.28）到 /opt/kylinroot。
2. scripts/download_sdk.py 下载并解压官方 Flutter SDK 的 x64 版本。
3. scripts/engine_cache.sh 补齐 linux-arm64 引擎产物（arm64 版 gen_snapshot 与
   libflutter_linux_gtk.so）到 SDK 缓存目录。
4. scripts/patch_flutter.py 给 flutter_tools 打交叉编译补丁（允许指定
   target-platform 与 sysroot）。
5. scripts/install_clang.sh 手工解包安装 clang（软件源依赖损坏时使用）。
6. scripts/build.sh 执行 flutter build linux --release --target-platform
   linux-arm64 --target-sysroot /opt/kylinroot。
7. scripts/build_quickjs.sh 交叉编译 QuickJS 桥接库，替换产物目录中的 x64 版本。
8. scripts/pack_deb.sh 生成 deb（含字体与 postinst 的 fc-cache）。
9. scripts/verify.sh 在 sysroot 里以 Xvfb + qemu 启动验证。

## 验证方式

在 x86 主机上用 Xvfb 起虚拟屏，用 qemu-user 运行 arm64 产物，再用 xwd 抓窗口：

    qemu-aarch64-static -R 0x100000000 -L /opt/kylinroot \
      -E DISPLAY=127.0.0.1:99 -E LANG=zh_CN.UTF-8 \
      /opt/kylinroot/opt/proxypin/ProxyPin

    DISPLAY=127.0.0.1:99 xwd -id <窗口ID> -silent > shot.xwd
    python3 scripts/xwd2png.py shot.xwd shot.png

抓根窗口在无合成器环境下只能得到黑图，必须按窗口 ID 抓。

## 已知限制

- 仅验证 X11 会话。Wayland 下系统代理设置与窗口相关能力可能异常。
- 未在麒麟真机跑过完整功能回归，验证覆盖启动、界面渲染、字体、插件加载。
- 托盘图标依赖系统 libappindicator，缺失时托盘不显示，不影响主窗口。
