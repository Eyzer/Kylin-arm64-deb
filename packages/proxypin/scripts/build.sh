#!/bin/bash
# Cross-build ProxyPin for Kylin V10 arm64 (glibc 2.28 baseline from /opt/kylinroot).
set -eu
# Each WSL invocation has its own mount namespace: register binfmt in THIS shell.
mount -t binfmt_misc none /proc/sys/fs/binfmt_misc 2>/dev/null || true
update-binfmts --enable qemu-aarch64 2>/dev/null || true
# linux-arm64-release ships an aarch64 gen_snapshot; run it under qemu-user.
export QEMU_LD_PREFIX=/opt/kylinroot
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export PATH=/opt/flutter-sdk/bin:/root/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
export RUSTUP_DIST_SERVER=https://rsproxy.cn
export RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup
# clang/gcc cross builds need the Debian multiarch include dir explicitly.
export CPATH=/opt/kylinroot/usr/include/aarch64-linux-gnu
export LIBRARY_PATH=/opt/kylinroot/usr/lib/aarch64-linux-gnu
export FLUTTER_SUPPRESS_ANALYTICS=true
export PKG_CONFIG_SYSROOT_DIR=/opt/kylinroot
export PKG_CONFIG_LIBDIR=/opt/kylinroot/usr/lib/aarch64-linux-gnu/pkgconfig:/opt/kylinroot/usr/share/pkgconfig
cd /opt/pp/proxypin-main
flutter config --enable-linux-desktop --no-analytics
flutter pub get
flutter build linux --release --target-platform linux-arm64 --target-sysroot /opt/kylinroot
echo BUILD_DONE
ls -lh build/linux/arm64/release/bundle/ | head -20
