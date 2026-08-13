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

from PIL import Image

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

# ------------------------------------------------------- texture regions
# (x, y) of the top-left corner of each face in the 64x64 texture.

HEAD = {'top': (8, 0), 'bottom': (16, 0), 'right': (0, 8),
        'front': (8, 8), 'left': (16, 8), 'back': (24, 8)}
HOOD = {'top': (40, 0), 'bottom': (48, 0), 'right': (32, 8),
        'front': (40, 8), 'left': (48, 8), 'back': (56, 8)}

BODY = {'top': (20, 16), 'bottom': (28, 16), 'right': (16, 20),
        'front': (20, 20), 'left': (28, 20), 'back': (32, 20)}

ARM_R = {'top': (44, 16), 'bottom': (48, 16), 'right': (40, 20),
         'front': (44, 20), 'left': (48, 20), 'back': (52, 20)}
ARM_L = {'top': (36, 48), 'bottom': (40, 48), 'right': (32, 52),
         'front': (36, 52), 'left': (40, 52), 'back': (44, 52)}

LEG_R = {'top': (4, 16), 'bottom': (8, 16), 'right': (0, 20),
         'front': (4, 20), 'left': (8, 20), 'back': (12, 20)}
LEG_L = {'top': (20, 48), 'bottom': (24, 48), 'right': (16, 52),
         'front': (20, 52), 'left': (24, 52), 'back': (28, 52)}

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

def blit(img, origin, grid):
    ox, oy = origin
    for dy, row in enumerate(grid):
        for dx, ch in enumerate(row):
            if ch == '.':
                continue
            img.putpixel((ox + dx, oy + dy), PAL[ch] + (255,))


def build():
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))

    for reg, grid in (
        (HEAD['front'], HEAD_FRONT), (HEAD['right'], HEAD_SIDE),
        (HEAD['left'], HEAD_SIDE), (HEAD['back'], HEAD_BACK),
        (HEAD['top'], HEAD_TOP), (HEAD['bottom'], HEAD_BOTTOM),

        (HOOD['front'], HOOD_FRONT), (HOOD['right'], HOOD_SIDE),
        (HOOD['left'], HOOD_SIDE), (HOOD['back'], HOOD_BACK),
        (HOOD['top'], HOOD_TOP), (HOOD['bottom'], HOOD_BOTTOM),

        (BODY['front'], BODY_FRONT), (BODY['back'], BODY_BACK),
        (BODY['right'], BODY_SIDE), (BODY['left'], BODY_SIDE),
        (BODY['top'], BODY_TOP), (BODY['bottom'], BODY_BOTTOM),
    ):
        blit(img, reg, grid)

    # arms: the seam goes on the outer face of each arm
    for arm, outer in ((ARM_R, 'right'), (ARM_L, 'left')):
        for face in ('front', 'back', 'right', 'left'):
            blit(img, arm[face], ARM_OUTER if face == outer else ARM_PLAIN)
        blit(img, arm['top'], ARM_TOP)
        blit(img, arm['bottom'], ARM_BOTTOM)

    for leg in (LEG_R, LEG_L):
        for face in ('front', 'back', 'right', 'left'):
            blit(img, leg[face], LEG_SIDE)
        blit(img, leg['top'], LEG_TOP)
        blit(img, leg['bottom'], LEG_BOTTOM)

    return img


def preview(img, face='front', scale=20):
    """Flat view so you can eyeball it without loading the game."""
    out = Image.new('RGBA', (16, 32), (0, 0, 0, 0))

    def paste(region, w, h, at):
        out.paste(img.crop((region[0], region[1],
                            region[0] + w, region[1] + h)), at)

    def over(region, w, h, at):
        out.alpha_composite(img.crop((region[0], region[1],
                                      region[0] + w, region[1] + h)), at)

    # from behind, the model's left/right swap places on screen
    near, far = (ARM_R, ARM_L) if face == 'front' else (ARM_L, ARM_R)
    lnear, lfar = (LEG_R, LEG_L) if face == 'front' else (LEG_L, LEG_R)

    paste(HEAD[face], 8, 8, (4, 0))
    over(HOOD[face], 8, 8, (4, 0))
    paste(BODY[face], 8, 12, (4, 8))
    paste(near[face], 4, 12, (0, 8))
    paste(far[face], 4, 12, (12, 8))
    paste(lnear[face], 4, 12, (4, 20))
    paste(lfar[face], 4, 12, (8, 20))

    bg = Image.new('RGBA', out.size, (0x22, 0x24, 0x28, 255))
    bg.alpha_composite(out)
    return bg.resize((16 * scale, 32 * scale), Image.NEAREST)


if __name__ == '__main__':
    skin = build()
    skin.save('redstone_trapper.png')

    front, back = preview(skin, 'front'), preview(skin, 'back')
    sheet = Image.new('RGBA', (front.width * 2 + 40, front.height),
                      (0x22, 0x24, 0x28, 255))
    sheet.paste(front, (0, 0))
    sheet.paste(back, (front.width + 40, 0))
    sheet.save('preview.png')

    print('wrote redstone_trapper.png (%dx%d) and preview.png' % skin.size)
