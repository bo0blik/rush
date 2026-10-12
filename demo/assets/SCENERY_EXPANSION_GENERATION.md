# Additional plant and building atlases

Both PNGs generated with the built-in image generation tool, using `rural_atlas.png` as the shared pixel-art style reference. Transparent backgrounds; no source pixel edits.

## Plants: `plants_expansion_atlas.png`

Prompt: strict 4 by 4 atlas, 16 complete isolated botanical sprites with transparent gutters; crisp detailed rural game pixel art, consistent daylight from the upper left. Rows: birch/pine/spruce/oak; willow/maple/rowan/apple; fern/daisies/fireweed/poppies; reeds/cattails/meadow grasses/currant bush. No background, text, grid or cast floor shadows. Runtime applies real-world sizes.

## Buildings: `buildings_expansion_atlas.png`

Prompt: strict 4 by 3 atlas, 12 complete buildings in three-quarter front/right view with transparent gutters; Russian/Eastern European countryside, timber, brick, plaster, metal/tile roofs, consistent upper-left daylight and pixel-art style. Rows: carved teal cottage/plaster cottage/brick house/two-story apartments; clinic/school/grocery/hay barn; forge/gazebo/watermill/small chapel. No labels, readable signs, logos, background or cast floor shadows.

`tools/build_scenery_expansion.py` registers cropped AtlasTextures. Trees mix into forest populations, flowers and shrubs into ground cover, reeds/cattails along river banks, and new buildings/fruit trees form roadside landmarks. Extra vegetation shares batches per road section to keep draw calls bounded.
