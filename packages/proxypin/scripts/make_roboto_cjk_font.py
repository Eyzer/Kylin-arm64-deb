#!/usr/bin/env python3
"""把文泉驿微米黑的字体族名改写为 Roboto，供 Flutter Linux 应用使用。

背景：Flutter Linux 引擎按 fontconfig 族名查字体，且不加载 /etc/fonts 配置，
上游 Material Typography 在 Linux 下写死请求 "Roboto"。麒麟系统没有该族，
缺字形回退失败，中文全部渲染成方块（tofu）。把中文字体的族名注册成 Roboto
即可让引擎直接命中字形。

用法：
    python3 make_roboto_cjk_font.py 输入.ttc 输出.ttf
依赖：
    pip install fonttools
"""

import sys
from fontTools.ttLib import TTCollection, TTFont


def rewrite(src_ttc: str, dst_ttf: str) -> None:
    coll = TTCollection(src_ttc)
    font = coll.fonts[0]
    name = font["name"]
    for rec in list(name.names):
        if rec.nameID in (1, 16):
            rec.string = "Roboto"
        elif rec.nameID == 4:
            rec.string = "Roboto Regular"
        elif rec.nameID == 6:
            rec.string = "Roboto-Regular"
        elif rec.nameID == 3:
            rec.string = "Roboto-Regular-1.0"
    font.save(dst_ttf)
    check = TTFont(dst_ttf)
    families = sorted({r.toUnicode() for r in check["name"].names if r.nameID == 1})
    print("输出:", dst_ttf, "族名:", families)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    rewrite(sys.argv[1], sys.argv[2])
