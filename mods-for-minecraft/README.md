# Mods for Minecraft

A starter [Fabric](https://fabricmc.net/) mod for **Minecraft 1.21.1** (Java 21).

Included as a working example:

- A custom item — **Ruby** (`modsforminecraft:ruby`) with texture, model, English name, and a crafting recipe (redstone around a diamond).
- Registration wired through `ModItems`, added to the *Ingredients* creative tab.

## Project layout

```
src/main/java/com/tkalec/modsforminecraft/
  ModsForMinecraft.java   ← mod entrypoint
  ModItems.java           ← item registration
src/main/resources/
  fabric.mod.json         ← mod metadata
  assets/modsforminecraft/
    lang/en_us.json       ← item names
    models/item/ruby.json ← item model
    textures/item/ruby.png
  data/modsforminecraft/
    recipe/ruby.json      ← crafting recipe
```

## Building

```bash
./gradlew build
```

The mod jar ends up in `build/libs/`.

## Running in a dev environment

```bash
./gradlew runClient
```

This launches Minecraft with the mod loaded — no manual install needed.

## Adding more content

1. Register new items in `ModItems.java` following the `RUBY` example.
2. Add a model JSON in `assets/modsforminecraft/models/item/`.
3. Add a 16×16 texture PNG in `assets/modsforminecraft/textures/item/`.
4. Add the display name to `lang/en_us.json`.
