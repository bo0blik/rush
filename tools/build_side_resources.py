"""Read sprite alpha and append side-view Godot resources; leaves PNG untouched."""
from build_animation_resources import ROOT, components

path = ROOT / 'demo/assets/traffic_side_views.png'
size, boxes = components(path)
for row, name in enumerate(['sedan', 'truck']):
    group = sorted([b['box'] for b in boxes if (b['box'][1] + b['box'][3]) / 2 / size[1] * 2 // 1 == row])
    assert len(group) == 3, (name, group)
    target = ROOT / f'demo/resources/{name}_animation_frames.tres'
    source = target.read_text()
    if 'side_angles' in source:
        continue
    source = source.replace('load_steps=26', 'load_steps=30')
    start = source.index('[sub_resource')
    source = source[:start] + '[ext_resource type="Texture2D" path="res://demo/assets/traffic_side_views.png" id="2"]\n\n' + source[start:]
    entries = []
    for i, (x, y, right, bottom) in enumerate(group):
        x, y = max(0, x-1), max(0, y-1)
        right, bottom = min(size[0], right+1), min(size[1], bottom+1)
        entries.append(f'[sub_resource type="AtlasTexture" id="Side{i}"]\natlas = ExtResource("2")\nregion = Rect2({x}, {y}, {right-x}, {bottom-y})\nfilter_clip = true\nmetadata/foot = Vector2({(right-x)/2}, {bottom-y-1})')
    source = source.replace('[resource]', '\n\n'.join(entries) + '\n\n[resource]')
    frames = ', '.join('{"duration": 1.0, "texture": SubResource("Side%d")}' % i for i in range(3))
    source = source.rstrip()[:-1] + ',\n{"frames": [' + frames + '], "loop": false, "name": &"side_angles", "speed": 8.0}]\n'
    target.write_text(source)
    print(name, group)
