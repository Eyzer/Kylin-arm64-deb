"""Resume the 16-way Flutter SDK download in small chunks, verify, unpack.

The first pass retried whole 96 MB ranges from scratch whenever a connection
stalled. This one appends 4 MB chunks and only retries the missing bytes.
"""
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

URL = ('https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/'
       'flutter_linux_3.44.9-stable.tar.xz')
SZ = 1546711080
N = 16
CH = (SZ + N - 1) // N
CHUNK = 4 * 1024 * 1024
D = '/opt/dlparts'
OUT = '/opt/flutter-sdk.tar.xz'
SHA = 'a9120fa4a01048bdef438ddc3a2d4b7389662ea98a95db86eeaf10382bc4efcb'


def part(i):
    p = os.path.join(D, 'p.%d' % i)
    tmp = os.path.join(D, 't.%d' % i)
    base = i * CH
    end = min(base + CH, SZ)
    want = end - base
    cur = os.path.getsize(p) if os.path.exists(p) else 0
    stalls = 0
    while cur < want:
        s = base + cur
        e = min(s + CHUNK, end) - 1
        n = e - s + 1
        r = subprocess.run(
            ['curl', '-sL', '--fail', '--max-time', '150', '-r', '%d-%d' % (s, e),
             '-o', tmp, URL],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        size = os.path.getsize(tmp) if os.path.exists(tmp) else 0
        if r.returncode or size != n:
            stalls += 1
            if stalls > 40:
                return i, False, cur
            continue
        stalls = 0
        with open(p, 'ab') as f, open(tmp, 'rb') as g:
            f.write(g.read())
        cur += n
        print('PART %02d %d/%d' % (i, cur, want), flush=True)
    return i, True, cur


with ThreadPoolExecutor(max_workers=N) as ex:
    results = list(ex.map(part, range(N)))
bad = [r for r in results if not r[1]]
if bad:
    print('FAILED_PARTS', bad, file=sys.stderr)
    sys.exit(1)

with open(OUT, 'wb') as out:
    for i in range(N):
        with open(os.path.join(D, 'p.%d' % i), 'rb') as f:
            while True:
                b = f.read(1 << 20)
                if not b:
                    break
                out.write(b)
print('SIZE', os.path.getsize(OUT), flush=True)

import hashlib
h = hashlib.sha256()
with open(OUT, 'rb') as f:
    for b in iter(lambda: f.read(1 << 20), b''):
        h.update(b)
got = h.hexdigest()
print('SHA256', got, flush=True)
if got != SHA:
    print('SHA_MISMATCH', file=sys.stderr)
    sys.exit(2)
os.makedirs('/opt/flutter-sdk', exist_ok=True)
subprocess.run(['tar', '-xf', OUT, '-C', '/opt/flutter-sdk', '--strip-components=1'], check=True)
print('EXTRACT_OK', flush=True)
