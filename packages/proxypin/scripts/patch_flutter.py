"""Enable x64->arm64 Linux cross-build in the local Flutter 3.44.9 SDK.

Flutter ships the cross-build CMake plumbing but blocks it in the command layer
(issue 74929). Swap the hardcoded clang for the already-installed GNU aarch64
cross compiler, drop the guard, and force the tool snapshot to rebuild.
"""
import pathlib

sdk = pathlib.Path('/opt/flutter-sdk')

cmd = sdk / 'packages/flutter_tools/lib/src/commands/build_linux.dart'
s = cmd.read_text()
guard = """    // TODO(fujino): https://github.com/flutter/flutter/issues/74929
    if (_operatingSystemUtils.hostPlatform == HostPlatform.linux_x64 &&
        targetPlatform == TargetPlatform.linux_arm64) {
      throwToolExit(
        'Cross-build from Linux x64 host to Linux arm64 target is not currently supported.',
      );
    }
"""
assert guard in s, 'cross-build guard not found (SDK layout changed)'
cmd.write_text(s.replace(guard, ''))

build = sdk / 'packages/flutter_tools/lib/src/linux/build_linux.dart'
t = build.read_text()
cc = "environment: <String, String>{'CC': 'clang', 'CXX': 'clang++'},"
assert cc in t, 'compiler env not found'
build.write_text(t.replace(
    cc,
    "environment: <String, String>{'CC': 'aarch64-linux-gnu-gcc', 'CXX': 'aarch64-linux-gnu-g++'},",
))

snap = sdk / 'bin/cache/flutter_tools.snapshot'
if snap.exists():
    snap.unlink()
print('PATCH_OK')
