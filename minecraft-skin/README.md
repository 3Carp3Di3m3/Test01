# Minecraft skins

Skins are authored as ASCII pixel grids in Python — one character per
pixel, one pixel per visible block face — so they can be edited as text
and regenerated. `skin_layout.py` holds the shared 64x64 texture layout
(1.8+ format) and the drawing/preview helpers.

## Build

```
pip install pillow
python3 build_blue_builder.py     # -> blue_builder.png
python3 build_skin.py             # -> redstone_trapper.png
```

Upload the plain `*.png` to minecraft.net. The `*_preview.png` files are
scaled-up front/back views for eyeballing the design and are **not** valid
skin files.

## The skins

**`blue_builder.png`** — blue creature character in hi-vis builder kit.
Ears on the hat layer, violet eyes, small pale snout, fur paws; black
jacket with bright blue trim, checkered hi-vis vest with a reflective
band, pale chest patch, grey work trousers with blue kneepads and boots.
Tool belt with a lit redstone torch, and a redstone dust loop on the
jacket back.

**`redstone_trapper.png`** — darker alternative. Hooded silhouette, visor
face with glowing slits, tripwire strap across the chest, tool belt,
powered-dust seams down the arms, redstone circuit on the back.

## Editing

Change a letter in a grid and re-run. The chest of `blue_builder` is
literally this:

```python
'KWWPPWWK',   # reflective band
'KOYPPYOK',
'KOYPPYXK',   # torch head
'BBBBBBbB',   # belt + torch stick
```

Colours live in the `PAL` dict at the top of each build script, so
recolouring the whole skin is a few lines. `.` in a grid means leave the
pixel transparent — used for the ear shapes on the overlay layer, and for
every overlay region that isn't drawn.
