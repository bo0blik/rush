# Rider T-pose front and back

Built-in image generation using `rider_mounted_v6.png` as an appearance reference. Final source: `rider_tpose_front_back.png`.

Prompt: two complete, identically sized front/rear views of the same rider in anatomical T-pose; red/white helmet with front visor, olive jacket, blue jeans, brown boots, black gloves; arms horizontal, straight legs at natural hip spacing. Cohesive crisp pixel art, transparent background, generous padding, no motorcycle, labels or floor shadows.

`tools/build_ragdoll_atlas.py` registers 12 body parts in each view as AtlasTextures. Source pixels are unchanged. Forearms include the authored gloves. Runtime part orientation follows the physical bones, front/back selection follows the tumbling torso, and outfit palette customization is retained.
