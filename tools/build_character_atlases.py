"""Fit atlas regions to generated alpha; source images are never modified."""
from pathlib import Path
from PIL import Image
from build_animation_resources import components

ROOT = Path(__file__).resolve().parents[1]

def build(filename, columns, rows, output, animation):
    source = Image.open(ROOT / 'demo/assets' / filename)
    alpha = source.getchannel('A')
    regions = []
    _, found = components(ROOT / 'demo/assets' / filename)
    assert len(found) == columns * rows, (filename, len(found))
    found.sort(key=lambda item: (item['box'][1] + item['box'][3]) / 2)
    for row in range(rows):
        group = sorted(found[row*columns:(row+1)*columns], key=lambda item: item['box'][0])
        for item in group:
            x, y, right, bottom = item['box']
            regions.append((x, y, right-x, bottom-y))
    text = [f'[gd_resource type="SpriteFrames" load_steps={len(regions)+2} format=3]',
            f'[ext_resource type="Texture2D" path="res://demo/assets/{filename}" id="1"]']
    for i, (x,y,w,h) in enumerate(regions):
        text.append(f'[sub_resource type="AtlasTexture" id="A{i}"]\natlas = ExtResource("1")\nregion = Rect2({x}, {y}, {w}, {h})\nfilter_clip = true')
    frames = ', '.join('{"duration": 1.0, "texture": SubResource("A%d")}' % i for i in range(len(regions)))
    text.append(f'[resource]\nanimations = [{{"frames": [{frames}], "loop": false, "name": &"{animation}", "speed": 1.0}}]')
    (ROOT / 'demo/resources' / output).write_text('\n\n'.join(text) + '\n')
    print(filename, len(regions), 'regions')

if __name__ == '__main__':
    build('rider_parts_v2.png', 4, 5, 'rider_parts.tres', 'parts')
    build('motorcycles_separate.png', 3, 3, 'motorcycles_separate.tres', 'bikes')
