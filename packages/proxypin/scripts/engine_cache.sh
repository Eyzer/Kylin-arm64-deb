#!/bin/bash
# The SDK only ships x64 Linux engine artifacts. Seed the arm64 dirs from the
# engine commit we already downloaded, reusing arch-independent headers.
set -eu
E=/opt/flutter-sdk/bin/cache/artifacts/engine
C=/opt/flutter-sdk/bin/cache
rm -rf "$E/linux-arm64" "$E/linux-arm64-release"
cp -a "$E/linux-x64" "$E/linux-arm64"
cp -a "$E/linux-x64-release" "$E/linux-arm64-release"
cp -rf /tmp/a64art/. "$E/linux-arm64/"
cp -f /tmp/arm64rel/gen_snapshot /tmp/arm64rel/libflutter_linux_gtk.so "$E/linux-arm64-release/"
V=$(cat /opt/flutter-sdk/bin/internal/engine.version)
printf '%s\n' "$V" > "$C/linux-sdk.stamp"
printf '%s\n' "$V" > "$C/engine.stamp"
echo CACHE_OK "$V"
ls "$E/linux-arm64-release" | head
