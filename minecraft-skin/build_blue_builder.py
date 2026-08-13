#!/usr/bin/env python3
"""
Builds "Blue Builder" - a 64x64 Minecraft skin blending two references:

  * the blue creature character (ears, snout, pale chest patch, fur paws)
  * the hi-vis builder outfit (checkered vest, reflective stripes, black
    jacket with bright blue trim, grey work pants, blue boots)

Plus a redstone torch on the tool belt and a dust circuit on the jacket
back, since the character is a redstone/trap builder.

Deliberately NOT carried over from the reference: the grey muzzle plate,
the red bowtie, and the magenta eyes. Snout is pale periwinkle and set
lower, eyes are violet, and the bowtie's job is done by the vest collar.

Usage:  python3 build_blue_builder.py
Output: blue_builder.png   (upload this one to minecraft.net)
        blue_builder_preview.png
"""

import skin_layout as sk

PAL = {
    'U': (0x4A, 0x4F, 0xA8),  # fur base
    'u': (0x32, 0x36, 0x6F),  # fur shadow
    'V': (0x6E, 0x74, 0xCE),  # fur highlight
    'P': (0xA9, 0xAE, 0xEA),  # pale snout / chest patch / paw pads
    'p': (0x8A, 0x5F, 0xA8),  # inner ear
    'N': (0x14, 0x14, 0x1C),  # outline / nose
    'E': (0xF5, 0xF5, 0xF5),  # eye white
    'I': (0x4A, 0x3A, 0x9E),  # iris

    'K': (0x16, 0x16, 0x1C),  # jacket black
    'A': (0x1E, 0x5F, 0xE0),  # bright blue trim
    'a': (0x12, 0x3F, 0x99),  # blue shadow
    'Y': (0xF2, 0xC2, 0x1C),  # hi-vis yellow
    'O': (0xE8, 0x90, 0x1E),  # hi-vis orange
    'W': (0xF2, 0xF2, 0xF2),  # reflective stripe

    'G': (0x9A, 0x9A, 0xA0),  # work trousers
    'g': (0x6E, 0x6E, 0x76),  # trouser shadow

    'B': (0x6B, 0x4A, 0x2F),  # tool belt leather
    'b': (0x4E, 0x37, 0x22),  # leather shadow / torch stick
    'R': (0xC1, 0x12, 0x1F),  # redstone dust
    'X': (0xFF, 0x3B, 0x3B),  # lit torch head
}

# ------------------------------------------------------------------ head

HEAD_FRONT = [
    'VUUUUUUV',
    'UUUUUUUU',
    'UNNUUNNU',   # dark eye patches
    'UEIUUIEU',   # violet eyes
    'UUUUUUUU',
    'UUUUUUUU',
    'UUPNNPUU',   # small snout, nose set into it
    'UuPPPPuU',
]
HEAD_SIDE = [
    'VUUUUUUV',
    'UUUUUUUU',
    'UUUUUUUU',
    'UUUUUUUU',
    'UUUUUUUU',
    'UUUUUUUU',
    'UuuuuuuU',
    'uuuuuuuu',
]
HEAD_BACK = [
    'VVUUUUVV',
    'UUUUUUUU',
    'UUUUUUUU',
    'UUUUUUUU',
    'UUUUUUUU',
    'UUUUUUUU',
    'UuuuuuuU',
    'uuuuuuuu',
]
HEAD_TOP = ['VVVVVVVV'] * 2 + ['VUUUUUUV'] * 4 + ['VVVVVVVV'] * 2
HEAD_BOTTOM = ['uuuuuuuu'] * 8

# ------------------------------------------------------- ears (overlay)
# Two blocks at the top corners of the head, 2px tall and 4px deep. The
# ear touches the outer wall, so the side faces carry its outer surface;
# the top face carries its footprint.

EAR_FRONT = ['UU....UU', 'Up....pU'] + ['........'] * 6
EAR_BACK = ['UU....UU', 'UU....UU'] + ['........'] * 6
EAR_SIDE = ['..UUUU..', '..UUUU..'] + ['........'] * 6
EAR_TOP = ['........'] * 2 + ['UU....UU'] * 4 + ['........'] * 2
EAR_BOTTOM = ['........'] * 8

# ------------------------------------------------------------------ body
# Front: hi-vis vest panels either side of the pale fur chest patch, with
# reflective stripes between. Tool belt with a lit redstone torch.
# Back: reflective band plus a redstone dust loop on the jacket.

BODY_FRONT = [
    'KAAAAAAK',   # blue collar
    'KYOPPOYK',
    'KOYPPYOK',   # checkered vest panels either side of the chest patch
    'KYOPPOYK',
    'KWWPPWWK',   # reflective band
    'KWWPPWWK',
    'KOYPPYOK',
    'KYOPPOYK',
    'KOYPPYXK',   # torch head
    'BBBBBBbB',   # belt + torch stick
    'BBgGGgBB',   # buckle
    'AAAAAAAA',
]
BODY_BACK = [
    'KAAAAAAK',
    'KKKKKKKK',
    'KKWWWWKK',   # reflective band
    'KKKKKKKK',
    'KKKRRKKK',
    'KKRKKRKK',   # redstone loop
    'KKRKKRKK',
    'KKKRRKKK',
    'KKKKKKKK',
    'BBBBBBBB',
    'BBBBBBBB',
    'AAAAAAAA',
]
BODY_SIDE = ['AAAA'] + ['KKKK'] * 8 + ['BBBB'] * 2 + ['AAAA']
BODY_TOP = ['KKKKKKKK'] * 4
BODY_BOTTOM = ['AAAAAAAA'] * 4

# ------------------------------------------------------------------ arms
# Jacket sleeve with a hi-vis band, blue cuff, blue fur paw.

ARM_SIDE = [
    'AAAA',
    'KKKK',
    'KKKK',
    'YYYY',
    'WWWW',   # reflective band
    'YYYY',
    'KKKK',
    'KKKK',
    'KKKK',
    'AAAA',   # cuff
    'UUUU',   # paw
    'UPPU',
]
ARM_TOP = ['AAAA'] * 4
ARM_BOTTOM = ['PPPP'] * 4   # paw pads

# ------------------------------------------------------------------ legs

LEG_SIDE = [
    'uuuu',   # fur at the hip
    'GGGG',
    'GGGG',
    'GgGG',
    'AAAA',   # kneepad
    'AaaA',
    'GGGG',
    'GgGG',
    'GGGG',
    'KKKK',
    'AAAA',   # boot
    'AAAA',
]
LEG_TOP = ['uuuu'] * 4
LEG_BOTTOM = ['KKKK'] * 4   # sole


def build():
    img = sk.new_skin()

    sk.draw(img, sk.HEAD, PAL, front=HEAD_FRONT, back=HEAD_BACK,
            right=HEAD_SIDE, left=HEAD_SIDE,
            top=HEAD_TOP, bottom=HEAD_BOTTOM)

    sk.draw(img, sk.HEAD_O, PAL, front=EAR_FRONT, back=EAR_BACK,
            right=EAR_SIDE, left=EAR_SIDE,
            top=EAR_TOP, bottom=EAR_BOTTOM)

    sk.draw(img, sk.BODY, PAL, front=BODY_FRONT, back=BODY_BACK,
            right=BODY_SIDE, left=BODY_SIDE,
            top=BODY_TOP, bottom=BODY_BOTTOM)

    for arm in (sk.ARM_R, sk.ARM_L):
        sk.draw(img, arm, PAL, front=ARM_SIDE, back=ARM_SIDE,
                right=ARM_SIDE, left=ARM_SIDE,
                top=ARM_TOP, bottom=ARM_BOTTOM)

    for leg in (sk.LEG_R, sk.LEG_L):
        sk.draw(img, leg, PAL, front=LEG_SIDE, back=LEG_SIDE,
                right=LEG_SIDE, left=LEG_SIDE,
                top=LEG_TOP, bottom=LEG_BOTTOM)

    return img


if __name__ == '__main__':
    skin = build()
    skin.save('blue_builder.png')
    sk.sheet(skin, 'blue_builder_preview.png')
    print('wrote blue_builder.png (%dx%d) and blue_builder_preview.png'
          % skin.size)
