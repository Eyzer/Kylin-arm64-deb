#!/bin/bash
# Build the QuickJS C bridge for aarch64 (upstream only ships an x64 .so).
set -e
Q=/opt/qjs/quickjs-c-bridge-master/cxx
O=/opt/qjs-objs
R=/opt/kylinroot
rm -rf "$O"
mkdir -p "$O"
V=$(cat "$Q/quickjs/VERSION")
COMMON=(--sysroot="$R" -O2 -fPIC -D_GNU_SOURCE "-DCONFIG_VERSION=\"$V\"" -I"$Q" -I"$Q/quickjs")
for c in cutils.c libregexp.c libunicode.c quickjs.c; do
  aarch64-linux-gnu-gcc "${COMMON[@]}" -c "$Q/quickjs/$c" -o "$O/${c%.c}.o"
done
aarch64-linux-gnu-g++ "${COMMON[@]}" -std=c++17 -DFLUTTER_PLUGIN_IMPL \
  -c "$Q/libfastdev_quickjs_runtime.cpp" -o "$O/runtime.o"
aarch64-linux-gnu-g++ --sysroot="$R" -shared \
  -o "$O/libquickjs_c_bridge_plugin.so" "$O"/*.o \
  -lm -ldl -lpthread -Wl,--allow-shlib-undefined
readelf -h "$O/libquickjs_c_bridge_plugin.so" | grep Machine
ls -lh "$O/libquickjs_c_bridge_plugin.so"
