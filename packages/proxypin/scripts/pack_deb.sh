#!/bin/bash
# Repack the arm64 Flutter bundle as a Kylin V10 deb, mirroring upstream /opt/proxypin layout.
#
# Font fix: the Flutter Linux engine resolves text by fontconfig family NAME and loads no
# /etc/fonts configuration of its own (verified via strace: it never opens fonts.conf or
# conf.d entries, it only walks /usr/share/fonts). Typography requests the family "Roboto",
# which does not exist on Kylin, so CJK glyph lookup fails and every Chinese character renders
# as tofu. Shipping a CJK face whose family name IS "Roboto" makes that lookup succeed.
set -eu
W=/mnt/c/Users/Administrator/Desktop/backup/code/arm
SRC=/opt/pp/proxypin-main/build/linux/arm64/release/bundle
FONT_CJK=/opt/ppfont/RobotoCJK.ttf
FONT_WQY=/opt/ppfont/x/usr/share/fonts/truetype/wqy/wqy-microhei.ttc
PKG=/opt/pp-deb
VER=1.4.0+kylin4
DEB="$W/proxypin_${VER}_arm64.deb"

[ -f "$SRC/ProxyPin" ] || { echo "MISSING_BUNDLE $SRC"; exit 1; }
[ -f "$FONT_CJK" ] || { echo "MISSING_FONT $FONT_CJK"; exit 1; }
[ -f "$FONT_WQY" ] || { echo "MISSING_FONT $FONT_WQY"; exit 1; }
rm -rf "$PKG" "$DEB"
mkdir -p "$PKG/DEBIAN" "$PKG/opt/proxypin" "$PKG/usr/share/applications" \
         "$PKG/usr/share/doc/proxypin" "$PKG/usr/share/fonts/truetype/proxypin"
cp -a "$SRC/." "$PKG/opt/proxypin/"
chmod 0755 "$PKG/opt/proxypin/ProxyPin"
install -m 0644 "$FONT_CJK" "$PKG/usr/share/fonts/truetype/proxypin/Roboto-CJK.ttf"
install -m 0644 "$FONT_WQY" "$PKG/usr/share/fonts/truetype/proxypin/wqy-microhei.ttc"
install -m 0644 /opt/pp/proxypin-main/linux/proxy-pin.desktop "$PKG/usr/share/applications/proxy-pin.desktop"

SIZE=$(du -sk "$PKG" | cut -f1)
cat > "$PKG/DEBIAN/control" <<CTRL
Package: proxypin
Version: $VER
Architecture: arm64
Maintainer: wanghongenpin <wanghongenpin@gmail.com>
Homepage: https://github.com/wanghongenpin/proxypin
Installed-Size: $SIZE
Section: net
Priority: optional
Depends: ca-certificates, libgtk-3-0, fontconfig
Description: ProxyPin HTTP(S) traffic capture (Kylin V10 / arm64)
 Open source free HTTP(S) traffic capture and rewrite tool, full platform.
 This build targets Kylin V10 aarch64 with a glibc 2.28 baseline and
 bundles a CJK font registered as the "Roboto" family so Chinese text
 renders correctly instead of showing tofu boxes.
CTRL
chmod 0644 "$PKG/DEBIAN/control"

cat > "$PKG/DEBIAN/postinst" <<'PINST'
#!/bin/sh
set -e
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f >/dev/null 2>&1 || true
fi
exit 0
PINST
chmod 0755 "$PKG/DEBIAN/postinst"

cat > "$PKG/DEBIAN/postrm" <<'PRM'
#!/bin/sh
set -e
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f >/dev/null 2>&1 || true
fi
exit 0
PRM
chmod 0755 "$PKG/DEBIAN/postrm"

cat > "$PKG/usr/share/doc/proxypin/README.kylin" <<'DOC'
ProxyPin 银河麒麟 V10 arm64 移植版
上游：https://github.com/wanghongenpin/proxypin

启动：应用菜单 ProxyPin，或 /opt/proxypin/ProxyPin
要求：X11 会话（Wayland 下系统代理/窗口相关能力可能异常）
数据目录：用户主目录下应用配置目录，卸载不清除
本包针对 glibc 2.28 基线构建。

字体说明：
Flutter Linux 引擎按字体族名查找字形，且不加载 /etc/fonts 配置，
而上游界面默认请求 Roboto 族。麒麟系统无该族，故中文全部显示为方块。
本包内置文泉驿微米黑（GPLv3 + 字体嵌入例外），其族名注册为 Roboto，
从而让引擎直接命中中文字形；同时保留原名副本供系统其他组件使用。
卸载本包后字体会一并移除，系统字体不受影响。
DOC
chmod 0644 "$PKG/usr/share/doc/proxypin/README.kylin"

dpkg-deb --build --root-owner-group "$PKG" "$DEB"
ls -lh "$DEB"
