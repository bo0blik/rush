"""Create sprite regions for new plant/building atlases; preserve source PNGs."""
from pathlib import Path
from build_animation_resources import components

root = Path(__file__).resolve().parents[1]
parts = ['[gd_resource type="SpriteFrames" load_steps=31 format=3]', '[ext_resource type="Texture2D" path="res://demo/assets/plants_expansion_atlas.png" id="1"]', '[ext_resource type="Texture2D" path="res://demo/assets/buildings_expansion_atlas.png" id="2"]']
animations = []
for resource_id, filename, rows, name in [("1", "plants_expansion_atlas.png", 4, "plants"), ("2", "buildings_expansion_atlas.png", 3, "buildings")]:
    _, found = components(root / "demo/assets" / filename)
    if len(found) != rows * 4:
        raise ValueError(f"Expected {rows * 4} complete sprites in {filename}, found {len(found)}")
    found.sort(key=lambda item: (item["box"][1] + item["box"][3]) * 0.5)
    frames = []
    for row in range(rows):
        group = sorted(found[row * 4:(row + 1) * 4], key=lambda item: item["box"][0])
        for col, item in enumerate(group):
            x, y, r, b = item["box"]
            ident = f"{name}_{row * 4 + col}"
            parts.append(f'[sub_resource type="AtlasTexture" id="{ident}"]\natlas = ExtResource("{resource_id}")\nregion = Rect2({x}, {y}, {r-x}, {b-y})\nfilter_clip = true')
            frames.append('{"duration": 1.0, "texture": SubResource("%s")}' % ident)
    animations.append('{"frames": [%s], "loop": false, "name": &"%s", "speed": 1.0}' % (", ".join(frames), name))
parts.append('[resource]\nanimations = [' + ",\n".join(animations) + ']')
(root / "demo/resources/scenery_expansion.tres").write_text("\n\n".join(parts) + "\n", encoding="utf-8")
