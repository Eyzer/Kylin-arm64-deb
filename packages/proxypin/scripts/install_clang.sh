#!/bin/bash
# Debian bullseye's clang package drags in libc6-i386, whose version conflicts
# with the installed libc6. Unpack the clang debs without registering them in
# dpkg, then expose /usr/bin/clang for Flutter's native-assets probe.
set -eu
D=/opt/clangdl
R=/opt/clang
rm -rf "$D" "$R"
mkdir -p "$D" "$R"
cd "$D"
apt-get download clang-11 libclang1-11 libclang-common-11-dev libclang-cpp11 libllvm11 llvm-11-runtime 2>&1 | tail -3
for f in "$D"/*.deb; do dpkg-deb -x "$f" "$R"; done
[ -d /usr/lib/llvm-11 ] || ln -s "$R/usr/lib/llvm-11" /usr/lib/llvm-11
for so in "$R"/usr/lib/x86_64-linux-gnu/*.so*; do
  [ -e "$so" ] || continue
  ln -sf "$so" /usr/lib/x86_64-linux-gnu/
done
ln -sf "$R/usr/bin/clang-11" /usr/bin/clang
ln -sf "$R/usr/bin/clang++-11" /usr/bin/clang++
/usr/bin/clang --version | head -2
