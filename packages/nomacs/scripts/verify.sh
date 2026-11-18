#!/bin/bash
LIB=/opt/nomacs-bundle/opt/nomacs/lib
echo "=== 自带 Qt 是否提供 hitButton ==="
aarch64-linux-gnu-nm -D $LIB/libQt5Widgets.so.5 | grep hitButton || echo "符号不存在"
echo "=== 依赖闭环校验 ==="
python3 - <<'PY'
import os, re, subprocess
LIB='/opt/nomacs-bundle/opt/nomacs/lib'
ROOT='/opt/nomacs-bundle/opt/nomacs'
EXCLUDE={'libc.so.6','libm.so.6','libpthread.so.0','libdl.so.2','librt.so.1',
 'libnsl.so.1','libutil.so.1','libresolv.so.2','libanl.so.1',
 'ld-linux-aarch64.so.1','libthread_db.so.1','libmemusage.so','libpcprofile.so',
 'libSegFault.so','libBrokenLocale.so.1','libcrypt.so.1'}
have=set(os.listdir(LIB))
files=[]
for d,_,fs in os.walk(ROOT):
    for f in fs:
        if f.endswith('.so') or '.so.' in f or f=='nomacs.bin':
            files.append(os.path.join(d,f))
pat=re.compile(r'\(NEEDED\)\s+Shared library:\s*\[([^\]]+)\]')
missing={}
for p in files:
    out=subprocess.run(['aarch64-linux-gnu-readelf','-d',p],capture_output=True,text=True).stdout
    for n in pat.findall(out):
        if n not in have and n not in EXCLUDE:
            missing.setdefault(n,[]).append(os.path.basename(p))
print('被校验的 ELF 数量:', len(files))
print('私有库数量:', len(have))
print('未解析依赖:', sorted(missing) if missing else '无')
PY
echo "=== 包控制信息 ==="
dpkg-deb -I /opt/nomacs_3.17.2295-3_arm64.deb | grep -E "Package|Version|Architecture|Depends"
echo "=== 模拟器实跑 ==="
Q=$(command -v qemu-aarch64-static || command -v qemu-aarch64 || true)
if [ -z "$Q" ]; then echo "无 qemu,跳过"; else
  mkdir -p /srv/arm64/opt
  ln -sfn /opt/nomacs-bundle/opt/nomacs /srv/arm64/opt/nomacs
  $Q -L /srv/arm64 \
    -E LD_LIBRARY_PATH=/opt/nomacs/lib \
    -E QT_PLUGIN_PATH=/opt/nomacs/plugins \
    -E QT_QPA_PLATFORM_PLUGIN_PATH=/opt/nomacs/plugins/platforms \
    -E QT_QPA_PLATFORM=offscreen \
    /opt/nomacs/bin/nomacs.bin --help 2>&1 | head -25
fi
