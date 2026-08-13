"""
Shared 64x64 Minecraft skin (1.8+) texture layout and drawing helpers.

Each entry below is the (x, y) top-left corner of one cube face in the
texture. Head/body/leg faces are laid out in the classic 64x32 area; the
left arm and left leg live in the lower half that 1.8 added.

Skins are authored as lists of equal-length strings, one character per
pixel, decoded through a palette dict. '.' means "leave transparent".
"""

from PIL import Image

HEAD = {'top': (8, 0), 'bottom': (16, 0), 'right': (0, 8),
        'front': (8, 8), 'left': (16, 8), 'back': (24, 8)}
# head overlay - hat layer, a slightly larger cube around the head
HEAD_O = {'top': (40, 0), 'bottom': (48, 0), 'right': (32, 8),
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

FACES = ('front', 'back', 'right', 'left', 'top', 'bottom')


def new_skin():
    return Image.new('RGBA', (64, 64), (0, 0, 0, 0))


def blit(img, origin, grid, pal):
    """Draw one ASCII grid at a face origin. '.' pixels are skipped."""
    ox, oy = origin
    for dy, row in enumerate(grid):
        for dx, ch in enumerate(row):
            if ch == '.':
                continue
            img.putpixel((ox + dx, oy + dy), pal[ch] + (255,))


def draw(img, part, pal, **grids):
    """blit(part['front'], grids['front']) for every face given."""
    for face, grid in grids.items():
        blit(img, part[face], grid, pal)


def view(img, face='front', scale=20, bg=(0x22, 0x24, 0x28)):
    """Flat front or back view, overlay composited, scaled up nearest."""
    out = Image.new('RGBA', (16, 32), (0, 0, 0, 0))

    def crop(region, w, h):
        return img.crop((region[0], region[1],
                         region[0] + w, region[1] + h))

    # seen from behind, the model's left and right swap sides on screen
    near, far = (ARM_R, ARM_L) if face == 'front' else (ARM_L, ARM_R)
    lnear, lfar = (LEG_R, LEG_L) if face == 'front' else (LEG_L, LEG_R)

    out.paste(crop(HEAD[face], 8, 8), (4, 0))
    out.alpha_composite(crop(HEAD_O[face], 8, 8), (4, 0))
    out.paste(crop(BODY[face], 8, 12), (4, 8))
    out.paste(crop(near[face], 4, 12), (0, 8))
    out.paste(crop(far[face], 4, 12), (12, 8))
    out.paste(crop(lnear[face], 4, 12), (4, 20))
    out.paste(crop(lfar[face], 4, 12), (8, 20))

    plate = Image.new('RGBA', out.size, bg + (255,))
    plate.alpha_composite(out)
    return plate.resize((16 * scale, 32 * scale), Image.NEAREST)


def sheet(img, path, scale=20, bg=(0x22, 0x24, 0x28), gap=40):
    """Front and back side by side, for eyeballing without the game."""
    f, b = view(img, 'front', scale, bg), view(img, 'back', scale, bg)
    out = Image.new('RGBA', (f.width * 2 + gap, f.height), bg + (255,))
    out.paste(f, (0, 0))
    out.paste(b, (f.width + gap, 0))
    out.save(path)
