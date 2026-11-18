#!/bin/bash
set -e
SRC=/opt/nomacs-src/ImageLounge
BUILD=$SRC/build
SYS=/srv/arm64/usr/lib/aarch64-linux-gnu
PKG=/opt/nomacs-bundle
N=$PKG/opt/nomacs
LIB=$N/lib
PLG=$N/plugins
VER=3.17.2295-4

rm -rf $PKG
mkdir -p $PKG/DEBIAN $PKG/usr/bin $LIB $PLG $N/bin/translations
mkdir -p $PKG/usr/share/applications $PKG/usr/share/metainfo $PKG/usr/share/doc/nomacs

echo "[1/7] 主程序与核心库"
cp $BUILD/nomacs $N/bin/nomacs.bin 2>/dev/null || { mkdir -p $N/bin; cp $BUILD/nomacs $N/bin/nomacs.bin; }
chmod 755 $N/bin/nomacs.bin
cp $BUILD/libnomacsCore.so.3.17.0 $LIB/libnomacsCore.so.3
ln -sf libnomacsCore.so.3 $LIB/libnomacsCore.so

echo "[2/7] Qt 插件"
cp -a $SYS/qt5/plugins/. $PLG/

echo "[3/7] 递归收集私有运行库"
python3 - "$SYS" "$LIB" "$PLG" "$BUILD" <<'PY'
import os, re, sys, shutil, subprocess
sysroot, outdir, plugdir, build = sys.argv[1:5]
ROOTS = [sysroot, '/srv/arm64/lib/aarch64-linux-gnu', '/srv/arm64/usr/lib']
EXCLUDE = {
 'libc.so.6','libm.so.6','libpthread.so.0','libdl.so.2','librt.so.1',
 'libnsl.so.1','libutil.so.1','libresolv.so.2','libanl.so.1',
 'ld-linux-aarch64.so.1','libthread_db.so.1','libmemusage.so','libpcprofile.so',
 'libSegFault.so','libBrokenLocale.so.1','libcrypt.so.1','libnomacsCore.so.3',
}
def needed(p):
    try:
        out = subprocess.check_output(['aarch64-linux-gnu-readelf','-d',p], text=True, stderr=subprocess.DEVNULL)
    except Exception:
        return []
    return re.findall(r'\(NEEDED\)\s+Shared library:\s*\[([^\]]+)\]', out)

seeds = [build+'/nomacs', build+'/libnomacsCore.so.3.17.0']
for root, dirs, files in os.walk(plugdir):
    for f in files:
        if f.endswith('.so'):
            seeds.append(os.path.join(root,f))

queue = []
for s in seeds:
    queue.extend(needed(s))
done, missing = set(), set()
while queue:
    name = queue.pop(0)
    if name in done or name in EXCLUDE:
        continue
    done.add(name)
    src = next((os.path.join(r, name) for r in ROOTS if os.path.exists(os.path.join(r, name))), None)
    if not src:
        missing.add(name); continue
    real = os.path.realpath(src)
    shutil.copy2(real, os.path.join(outdir, name), follow_symlinks=True)
    for n in needed(real):
        if n not in done:
            queue.append(n)
print('私有库数量:', len(done)-len(missing))
print('未在 sysroot 找到(交给系统):', sorted(missing))
PY

echo "[4/7] 中文语言包 (简体/繁体 + Qt 标准对话框)"
cp /opt/nomacs-l10n/*.qm $N/bin/translations/
ls -1 $N/bin/translations/

echo "[5/7] 桌面/图标/文档 复用已有包"
if [ -d /opt/nomacs-deb/usr/share ]; then
  cp -a /opt/nomacs-deb/usr/share/. $PKG/usr/share/
else
  cp $SRC/xgd-data/org.nomacs.ImageLounge.desktop $PKG/usr/share/applications/
  [ -f $SRC/build/xgd-data/org.nomacs.ImageLounge.appdata.xml ] && cp $SRC/build/xgd-data/org.nomacs.ImageLounge.appdata.xml $PKG/usr/share/metainfo/
fi

echo "[6/7] 启动脚本"
cat > $PKG/usr/bin/nomacs <<'RUN'
#!/bin/sh
N=/opt/nomacs
export LD_LIBRARY_PATH="$N/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="$N/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="$N/plugins/platforms"
exec "$N/bin/nomacs.bin" "$@"
RUN
chmod 755 $PKG/usr/bin/nomacs

echo "[7/7] control 与打包"
cat > $PKG/DEBIAN/control <<'CTRL'
Package: nomacs
Version: 3.17.2295-4
Architecture: arm64
Maintainer: WorkBuddy Build <noreply@workbuddy.example>
Homepage: https://nomacs.org
Section: graphics
Priority: optional
Depends: libc6 (>= 2.29)
Description: nomacs 图像查看器 (自带 Qt 运行库与中文语言包)
 自带完整 Qt 5.15 运行库与插件，与系统 Qt 完全隔离，
 避免银河麒麟 V10 自带 Qt 版本较低导致的符号缺失。
 内置简体中文、繁体中文及 Qt 标准对话框中文翻译，
 在 设置 - 语言 中选择即可切换。
 安装位置 /opt/nomacs，通过 /usr/bin/nomacs 启动。
CTRL
cat > $PKG/DEBIAN/postinst <<'PST'
#!/bin/sh
set -e
if [ "$1" = "configure" ]; then
  command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications 2>/dev/null || true
fi
exit 0
PST
chmod 755 $PKG/DEBIAN/postinst

dpkg-deb --build --root-owner-group $PKG /opt/nomacs_${VER}_arm64.deb
echo "=== DONE ==="
ls -lh /opt/nomacs_${VER}_arm64.deb
