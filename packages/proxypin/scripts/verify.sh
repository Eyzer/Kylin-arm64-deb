#!/bin/bash
# Install the deb payload into the arm64 sysroot and smoke-launch it under Xvfb.
W=/mnt/c/Users/Administrator/Desktop/backup/code/arm
DEB="$W/proxypin_1.4.0+kylin1_arm64.deb"
mount -t binfmt_misc none /proc/sys/fs/binfmt_misc 2>/dev/null || true
update-binfmts --enable qemu-aarch64 2>/dev/null || true
rm -rf /opt/ppverify
mkdir -p /opt/ppverify
dpkg-deb -x "$DEB" /opt/ppverify
rm -rf /opt/kylinroot/opt/proxypin
mkdir -p /opt/kylinroot/opt
cp -a /opt/ppverify/opt/proxypin /opt/kylinroot/opt/
echo INSTALLED

# Host Xvfb with TCP so the chroot can reach it without bind-mounting the socket.
if ! pgrep -f 'Xvfb :99' >/dev/null; then
  Xvfb :99 -screen 0 1280x800x24 -listen tcp >/tmp/pp-xvfb.log 2>&1 &
  sleep 2
fi
echo XVFB_READY

cd /opt/kylinroot
# qemu-user needs reserved guest VA space or Dart VM's stack probe aborts.
timeout 25 qemu-aarch64-static -R 0x100000000 -L /opt/kylinroot \
  -E DISPLAY=127.0.0.1:99 -E HOME=/root \
  /opt/proxypin/ProxyPin > /tmp/pp-run.log 2>&1 &
RUN=$!
sleep 10
if kill -0 "$RUN" 2>/dev/null; then echo PROCESS_ALIVE; else echo PROCESS_EXITED; fi
echo ---run-log---
tail -30 /tmp/pp-run.log
