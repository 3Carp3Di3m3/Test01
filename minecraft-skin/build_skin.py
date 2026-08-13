#!/usr/bin/env python3
"""
Builds "Redstone Trapper" - a 64x64 Minecraft skin (1.8+ format).

Every character in the grids below is one pixel in the skin file, which is
one visible block-face on the player model. Edit the grids, re-run, done.

Palette keys are defined in PAL. A '.' means "leave transparent" (used for
the hood overlay opening, and for every overlay region we don't draw).

Usage:  python3 build_skin.py
Output: redstone_trapper.png   (upload this to minecraft.net)
        preview_front.png      (scaled-up front view, not for upload)
"""

import skin_layout as sk
from skin_layout import HEAD, BODY, ARM_R, ARM_L, LEG_R, LEG_L
from skin_layout import HEAD_O as HOOD

# ---------------------------------------------------------------- palette

PAL = {
    'S': (0x2E, 0x31, 0x38),  # slate base
    'D': (0x1F, 0x21, 0x26),  # slate shadow
    'L': (0x3E, 0x43, 0x4C),  # slate highlight
    'K': (0x14, 0x16, 0x1A),  # visor black
    'R': (0xC1, 0x12, 0x1F),  # redstone dust
    'G': (0xFF, 0x3B, 0x3B),  # powered / glow red
    'B': (0x6B, 0x4A, 0x2F),  # leather
    'b': (0x4E, 0x37, 0x22),  # leather dark
    'F': (0xC6, 0x8B, 0x5E),  # skin
    'f': (0xA0, 0x6B, 0x45),  # skin shadow
    'W': (0x9B, 0xA3, 0xAE),  # tripwire string
    'M': (0x6E, 0x76, 0x81),  # metal / buckle
}

# ------------------------------------------------------------------ head
# Visor band on rows 2-4, bare jaw below. No muzzle, no ears, no bowtie.

HEAD_FRONT = [
    'LLLLLLLL',
    'LSSSSSSL',
    'KKKKKKKK',
    'KGGKKGGK',   # two glowing slits
    'KKKKKKKK',
    'SFFFFFFS',
    'SFFffFFS',
    'SfFFFFfS',
]
HEAD_SIDE = [
    'LLLLLLLL',
    'SSSSSSSS',
    'KKKKKKKK',
    'KKKKKKKK',
    'KKKKKKKK',
    'fFFFFFFf',
    'fFFFFFFf',
    'ffFFFFff',
]
HEAD_BACK = [
    'LLLLLLLL',
    'SSSSSSSS',
    'SSSSSSSS',
    'SSSRRSSS',
    'SSSRRSSS',
    'SSSSSSSS',
    'SDDDDDDS',
    'DDDDDDDD',
]
HEAD_TOP = ['LLLLLLLL'] * 2 + ['LSSSSSSL'] * 4 + ['LLLLLLLL'] * 2
HEAD_BOTTOM = ['DDDDDDDD'] * 8

# ------------------------------------------------------- hood (overlay)
# Solid all round, open at the face so the visor reads through it.

HOOD_FRONT = [
    'DDDDDDDD',
    'D......D',
    'D......D',
    'D......D',
    'D......D',
    'D......D',
    'D......D',
    'DD....DD',
]
HOOD_SIDE = ['DDDDDDDD'] * 2 + ['SDDDDDDD'] * 5 + ['DDDDDDDD']
HOOD_BACK = ['SSSSSSSS'] + ['DDDDDDDD'] * 7
HOOD_TOP = ['DDDDDDDD'] * 8
HOOD_BOTTOM = ['........'] * 8

# ------------------------------------------------------------------ body
# Front: tripwire strap across the chest, tool belt, redstone torch on hip.
# Back: a redstone dust circuit.

BODY_FRONT = [
    'DDDDDDDD',
    'DSSSSSSD',
    'DSSSSSWD',
    'DSSSSWSD',
    'DSSSWSSD',
    'DSSWSSSD',
    'DSWSSSSD',
    'DWSSSSGD',   # torch head
    'DWSSSSbD',   # torch stick
    'BBBBBBBB',   # belt
    'BBBMMBBB',   # buckle
    'DDDDDDDD',
]
BODY_BACK = [
    'DDDDDDDD',
    'DSSSSSSD',
    'DSSRSSSD',
    'DSSRSSSD',
    'DSRRRRSD',
    'DSRSSRSD',
    'DSRSSRSD',
    'DSSSSRSD',
    'DSSSSRSD',
    'BBBBBBBB',
    'BBBBBBBB',
    'DDDDDDDD',
]
BODY_SIDE = ['DDDD'] + ['SSSS'] * 8 + ['BBBB'] * 2 + ['DDDD']
BODY_TOP = ['LLLLLLLL'] * 4
BODY_BOTTOM = ['DDDDDDDD'] * 4

# ------------------------------------------------------------------ arms
# Outer face carries a powered-dust seam; leather cuff, bare hand.

ARM_OUTER = [
    'LLLL',
    'SSSS',
    'SGSS',
    'SRSS',
    'SRSS',
    'SRSS',
    'SRSS',
    'SGSS',
    'bbbb',
    'BBBB',
    'FFFF',
    'fFFf',
]
ARM_PLAIN = [
    'LLLL',
    'SSSS',
    'SSSS',
    'SSSS',
    'SSSS',
    'SSSS',
    'SSSS',
    'SSSS',
    'bbbb',
    'BBBB',
    'FFFF',
    'fFFf',
]
ARM_TOP = ['LLLL'] * 4
ARM_BOTTOM = ['ffff'] * 4

# ------------------------------------------------------------------ legs

LEG_SIDE = [
    'SSSS',
    'SSSS',
    'SSSS',
    'SSSS',
    'SLLS',
    'SLLS',
    'SSSS',
    'SSSS',
    'bbbb',
    'BBBB',
    'BBBB',
    'bbbb',
]
LEG_TOP = ['LLLL'] * 4
LEG_BOTTOM = ['bbbb'] * 4


# ----------------------------------------------------------------- build

def build():
    img = sk.new_skin()

    sk.draw(img, HEAD, PAL, front=HEAD_FRONT, back=HEAD_BACK,
            right=HEAD_SIDE, left=HEAD_SIDE,
            top=HEAD_TOP, bottom=HEAD_BOTTOM)

    sk.draw(img, HOOD, PAL, front=HOOD_FRONT, back=HOOD_BACK,
            right=HOOD_SIDE, left=HOOD_SIDE,
            top=HOOD_TOP, bottom=HOOD_BOTTOM)

    sk.draw(img, BODY, PAL, front=BODY_FRONT, back=BODY_BACK,
            right=BODY_SIDE, left=BODY_SIDE,
            top=BODY_TOP, bottom=BODY_BOTTOM)

    # arms: the powered-dust seam goes on the outer face of each arm
    for arm, outer in ((ARM_R, 'right'), (ARM_L, 'left')):
        faces = {f: (ARM_OUTER if f == outer else ARM_PLAIN)
                 for f in ('front', 'back', 'right', 'left')}
        sk.draw(img, arm, PAL, top=ARM_TOP, bottom=ARM_BOTTOM, **faces)

    for leg in (LEG_R, LEG_L):
        sk.draw(img, leg, PAL, front=LEG_SIDE, back=LEG_SIDE,
                right=LEG_SIDE, left=LEG_SIDE,
                top=LEG_TOP, bottom=LEG_BOTTOM)

    return img


if __name__ == '__main__':
    skin = build()
    skin.save('redstone_trapper.png')
    sk.sheet(skin, 'redstone_trapper_preview.png')
    print('wrote redstone_trapper.png (%dx%d) and '
          'redstone_trapper_preview.png' % skin.size)
