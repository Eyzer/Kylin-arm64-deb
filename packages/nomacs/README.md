# nomacs 3.17.2295-4 · 银河麒麟 V10 arm64

图像查看器。自带整套 Qt 5.15 运行库与插件，与系统 Qt 完全隔离。

- 成品：`nomacs_3.17.2295-4_arm64.deb`（40 MB）
- 安装位置：`/opt/nomacs`，启动入口 `/usr/bin/nomacs`
- 依赖：仅 `libc6 (>= 2.29)`

    sudo dpkg -i nomacs_3.17.2295-4_arm64.deb

## 为什么自带 Qt

麒麟 V10 自带的 Qt 版本较低。用 Debian 11（Qt 5.15）编译出来的程序直接依赖系统 Qt 会报符号未定义，例如：

    symbol lookup error: undefined symbol: _ZN11QPushButton9hitButtonERK6QPoint, version Qt_5

Qt 的次要版本之间存在符号导出差异，靠改 Depends 解决不了。所以这里把 sysroot 里的 Qt5 库、qt5 插件目录，以及递归解析出的全部依赖（约 135 个库）一起打进 `/opt/nomacs/lib` 与 `/opt/nomacs/plugins`，启动脚本负责设好环境变量：

```sh
N=/opt/nomacs
export LD_LIBRARY_PATH="$N/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$N/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="$N/plugins/platforms"
exec "$N/bin/nomacs.bin" "$@"
```

这样 `Depends` 只剩 libc6，麒麟上不会因为缺某个 Qt 组件而装不上，也不会被系统的低版本 Qt 顶掉。

## 中文界面

交叉编译时 `ENABLE_TRANSLATIONS=OFF`，所以 `.qm` 需要单独生成。`.qm` 与架构无关，用宿主机的 `lrelease` 编译即可：

    ./scripts/make_translations.sh /opt/nomacs-src/ImageLounge ./out

会产出 `nomacs_zh_CN.qm`、`nomacs_tw_zh.qm`，再从 `qttranslations5-l10n` 取 `qt_zh_CN.qm`（Qt 标准对话框的翻译）。三个文件放到 `/opt/nomacs/bin/translations/`，程序会扫 `applicationDirPath()` 及其 `translations` 子目录。

**装完需要手动切语言**：设置 → 语言 → 简体中文。上游把默认语言写死为 `en`（`DkSettings.cpp`），已有配置的用户升级后不会自动切换。

## 构建方式

x86_64 主机 + Debian 11 aarch64 sysroot（Qt 5.15）交叉编译：

    cmake -S ImageLounge -B ImageLounge/build \
      -DCMAKE_SYSROOT=/srv/arm64 \
      -DCMAKE_BUILD_TYPE=Release \
      -DENABLE_TRANSLATIONS=OFF
    cmake --build ImageLounge/build -j$(nproc)

脚本：

| 文件 | 作用 |
| --- | --- |
| `scripts/bundle.sh` | 从构建目录与 sysroot 组装自包含包体，递归收集运行库，写 DEBIAN 控制信息 |
| `scripts/verify.sh` | 校验自带 Qt 是否导出 `hitButton`，并检查全部 ELF 的 NEEDED 是否闭包 |
| `scripts/make_translations.sh` | 生成中文语言包 |

`bundle.sh` 里的 `SRC`、`SYS`、`PKG` 是当时的构建路径（`/opt/nomacs-src/ImageLounge`、`/srv/arm64`、`/opt/nomacs-bundle`），复现时按自己的目录改。

## 已知问题

- 依赖基线 `libc6 >= 2.29`，低于此版本的发行版需要重编。
- 托盘图标、打印等插件走的是打包进来的 Qt 插件，若目标机的打印服务缺失，打印功能不可用（不影响看图）。
- 首次启动会扫描图片目录，大目录下首屏稍慢，属正常现象。

## 许可

nomacs 采用 GPLv3，随包附带的 Qt 库为 LGPLv3。详见包内 `/usr/share/doc/nomacs/copyright`。
