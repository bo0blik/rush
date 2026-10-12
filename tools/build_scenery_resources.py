"""Measure source alpha and write AtlasTextures; never edits the generated images."""
from build_animation_resources import ROOT, components

sources = [('forest_atlas.png', 4, 2), ('forest_props.png', 4, 3), ('rural_atlas.png', 4, 2)]
parts = ['[gd_resource type="SpriteFrames" load_steps=32 format=3]']
for index, (filename, _, _) in enumerate(sources):
    parts.append(f'[ext_resource type="Texture2D" path="res://demo/assets/{filename}" id="{index}"]')
entries = []
for source, (filename, columns, rows) in enumerate(sources):
    size, found = components(ROOT / 'demo/assets' / filename)
    assert len(found) == columns * rows, (filename, len(found))
    found.sort(key=lambda item: (item['box'][1] + item['box'][3]) / 2)
    ordered = []
    for row in range(rows):
        ordered.extend(sorted(found[row*columns:(row+1)*columns], key=lambda item: item['box'][0]))
    for index, item in enumerate(ordered):
        x, y, right, bottom = item['box']
        x, y = max(0, x-1), max(0, y-1)
        right, bottom = min(size[0], right+1), min(size[1], bottom+1)
        parts.append(f'[sub_resource type="AtlasTexture" id="S{source}_{index}"]\natlas = ExtResource("{source}")\nregion = Rect2({x}, {y}, {right-x}, {bottom-y})\nfilter_clip = true')
    frames = ', '.join('{"duration": 1.0, "texture": SubResource("S%d_%d")}' % (source, i) for i in range(len(ordered)))
    entries.append('{"frames": [%s], "loop": false, "name": &"%s", "speed": 1.0}' % (frames, ['forest', 'props', 'rural'][source]))
    print(filename, len(ordered), 'fitted regions')
parts.append('[resource]\nanimations = [' + ',\n'.join(entries) + ']')
(ROOT / 'demo/resources/scenery_frames.tres').write_text('\n\n'.join(parts) + '\n')
