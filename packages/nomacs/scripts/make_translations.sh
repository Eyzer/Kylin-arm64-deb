#!/bin/bash
# 重新生成 nomacs 的中文语言包（.qm）。
#
# 交叉编译时 ENABLE_TRANSLATIONS 为 OFF，所以 .qm 不会随构建产出，
# 需要单独用宿主机的 lrelease 编译。.qm 与架构无关，可直接复用。
#
# 依赖：qtbase5-dev-tools（提供 lrelease）、qttranslations5-l10n（提供 qt_zh_CN.qm）
# 用法：./make_translations.sh /opt/nomacs-src/ImageLounge /out/translations
set -e

SRC=${1:?源码目录 ImageLounge 的路径}
OUT=${2:-$SRC/build/translations}
LRELEASE=${LRELEASE:-lrelease}

mkdir -p "$OUT"

echo "[1/2] 上游界面翻译"
# nomacs_zh_CN.ts -> nomacs_zh_CN.qm；nomacs_tw_zh.ts -> nomacs_tw_zh.qm
for ts in "$SRC"/translations/nomacs_zh_CN.ts "$SRC"/translations/nomacs_tw_zh.ts; do
    [ -f "$ts" ] || { echo "缺少 $ts"; continue; }
    "$LRELEASE" "$ts" -qm "$OUT/$(basename "${ts%.ts}").qm"
done

echo "[2/2] Qt 标准对话框翻译"
# 文件对话框、按钮等由 Qt 自带翻译提供，从发行版的语言包取
QTQM=$(find /usr/share/qt5/translations /usr/share/qt4/translations -name qt_zh_CN.qm 2>/dev/null | head -1)
if [ -n "$QTQM" ]; then
    cp "$QTQM" "$OUT/qt_zh_CN.qm"
else
    echo "未找到 qt_zh_CN.qm，请安装 qttranslations5-l10n"
fi

ls -l "$OUT"
echo "把 $OUT 下的 .qm 放到 /opt/nomacs/bin/translations/ 即可（程序会扫 applicationDirPath 及其 translations 子目录）。"
