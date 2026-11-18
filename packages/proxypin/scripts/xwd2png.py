import sys, struct
import numpy as np
from PIL import Image

def convert(src, dst):
    d = open(src, 'rb').read()
    hsz = struct.unpack_from('>I', d, 0)[0]
    w, h = struct.unpack_from('>II', d, 16)
    bpl = struct.unpack_from('>I', d, 48)[0]
    ncolors = struct.unpack_from('>I', d, 76)[0]
    stride = bpl // w
    off = hsz + ncolors * 12
    buf = np.frombuffer(d[off:off + bpl * h], dtype=np.uint8).reshape(h, bpl)
    px = buf[:, :w * stride].reshape(h, w, stride)
    rgb = px[:, :, [2, 1, 0]]
    Image.fromarray(np.ascontiguousarray(rgb)).save(dst)
    print('OK', w, h, stride)

convert(sys.argv[1], sys.argv[2])
