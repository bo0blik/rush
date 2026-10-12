# Countryside wildlife atlas

Generated with the built-in image generation tool; source PNG saved as `wildlife_atlas.png`.

Prompt: one transparent pixel art atlas in a strict 12-row, 8-column layout. Rows: honey bee, bumblebee, swallow, sparrow, rook, stork, Holstein cow, Jersey cow, red-white grazing cow, white sheep, black sheep, cream grazing ram. Eight registered looping wingbeat/walking/grazing poses per species. Match the rural motorcycle game's sprite style. Preserve padding, complete silhouettes and fixed hoof/pivot height; no labels or background.

`tools/build_wildlife_atlas.py` creates AtlasTexture regions and animation loops without editing source pixels. Ground animals are 0.85–1.45 m tall; flying animals use species-specific dimensions. Wildlife has decorative movement and no collision bodies. Native/Web runtime validation is intentionally left to the user.
