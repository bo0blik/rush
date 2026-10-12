"""Register 12 eight-frame animal loops without modifying the generated PNG."""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = root / "demo/assets/wildlife_atlas.png"
image = Image.open(source).convert("RGBA")
alpha = image.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
names = ["bee", "bumblebee", "swallow", "sparrow", "rook", "stork", "holstein", "jersey", "red_cow", "white_sheep", "black_sheep", "ram"]
parts = ['[gd_resource type="SpriteFrames" load_steps=98 format=3]', '[ext_resource type="Texture2D" path="res://demo/assets/wildlife_atlas.png" id="1"]']
animations = []
for row, name in enumerate(names):
    top, bottom = round(row * image.height / 12), round((row + 1) * image.height / 12)
    cells = []
    for col in range(8):
        left, right = round(col * image.width / 8), round((col + 1) * image.width / 8)
        box = alpha.crop((left, top, right, bottom)).getbbox()
        if box is None:
            raise ValueError(f"Missing sprite: {name}, frame {col}")
        cells.append((left, right, box))
    # One crop/pivot for the entire row prevents bobbing from changing frame bounds.
    x = max(0, min(c[2][0] for c in cells) - 1)
    y = max(0, min(c[2][1] for c in cells) - 1)
    w = min(c[1] - c[0] for c in cells) - x
    h = min(bottom - top, max(c[2][3] for c in cells) + 1) - y
    refs = []
    for col, (left, _, _) in enumerate(cells):
        ident = f"W{row}_{col}"
        parts.append(f'[sub_resource type="AtlasTexture" id="{ident}"]\natlas = ExtResource("1")\nregion = Rect2({left+x}, {top+y}, {w}, {h})\nfilter_clip = true')
        refs.append('{"duration": 1.0, "texture": SubResource("%s")}' % ident)
    fps = 20 if row < 2 else 12 if row < 6 else 8
    animations.append('{"frames": [%s], "loop": true, "name": &"%s", "speed": %s}' % (", ".join(refs), name, fps))
parts.append('[resource]\nanimations = [' + ',\n'.join(animations) + ']')
(root / "demo/resources/wildlife_frames.tres").write_text("\n\n".join(parts) + "\n", encoding="utf-8")
