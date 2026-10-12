"""Read generated alpha to fit Godot atlas regions; never modifies source PNGs."""
from collections import deque
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def components(path):
    image = Image.open(path)
    width, height = image.size
    mask = bytearray(image.getchannel('A').point(lambda value: 255 if value >= 128 else 0).tobytes())
    found = []
    for seed in range(len(mask)):
        if not mask[seed]:
            continue
        mask[seed] = 0
        queue = deque([seed])
        left, right = width, 0
        top, bottom = height, 0
        area = 0
        while queue:
            point = queue.popleft()
            x, y = point % width, point // width
            left, right = min(left, x), max(right, x)
            top, bottom = min(top, y), max(bottom, y)
            area += 1
            neighbors = []
            if x: neighbors.append(point - 1)
            if x + 1 < width: neighbors.append(point + 1)
            if y: neighbors.append(point - width)
            if y + 1 < height: neighbors.append(point + width)
            for neighbor in neighbors:
                if mask[neighbor]:
                    mask[neighbor] = 0
                    queue.append(neighbor)
        if area > 3000:
            found.append({'box': [left, top, right + 1, bottom + 1], 'area': area})
    return image.size, found


if __name__ == '__main__':
    result = {}
    for name in ['rider', 'sedan', 'truck']:
        path = ROOT / f'demo/assets/{name}_animation_v{3 if name == "sedan" else 2}.png'
        size, boxes = components(path)
        rows = 6 if name == 'rider' else 4
        ordered = []
        for row in range(rows):
            group = [item for item in boxes if int((item['box'][1] + item['box'][3]) * 0.5 / size[1] * rows) == row]
            group.sort(key=lambda item: item['box'][0])
            assert len(group) == 6, (name, row, len(group))
            ordered.extend(group)
        result[name] = {'size': size, 'frames': [item['box'] for item in ordered]}
        print(name, size, len(boxes))
        for item in ordered:
            print(item)
        animations = ['ride', 'brake', 'lean_left', 'lean_right', 'crash', 'recover'] if name == 'rider' else ['rear_angles', 'front_angles', 'rear_drive', 'front_drive']
        parts = [f'[gd_resource type="SpriteFrames" load_steps={len(ordered) + 2} format=3]',
                 f'[ext_resource type="Texture2D" path="res://{path.relative_to(ROOT).as_posix()}" id="1"]']
        for index, item in enumerate(ordered):
            x, y, right, bottom = item['box']
            x, y = max(0, x - 1), max(0, y - 1)
            right, bottom = min(size[0], right + 1), min(size[1], bottom + 1)
            alpha = Image.open(path).getchannel('A')
            foot_pixels = [(px, py) for py in range(max(y, bottom - 5), bottom) for px in range(x, right) if alpha.getpixel((px, py)) >= 128]
            foot_x = sum(px for px, _ in foot_pixels) / len(foot_pixels)
            parts.append(f'[sub_resource type="AtlasTexture" id="Frame{index}"]\natlas = ExtResource("1")\nregion = Rect2({x}, {y}, {right-x}, {bottom-y})\nfilter_clip = true\nmetadata/foot = Vector2({foot_x-x:.4f}, {bottom-y-1})')
        if name == 'sedan':
            for i in range(6, 12):
                parts[i + 2] += '\nmetadata/source_flip_h = true'
        entries = []
        for row, animation in enumerate(animations):
            frames = ', '.join('{"duration": 1.0, "texture": SubResource("Frame%d")}' % (row * 6 + col) for col in range(6))
            loop = animation in ['ride', 'rear_drive', 'front_drive']
            rate = 10.0 if loop else 8.0
            entries.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %s}' % (frames, str(loop).lower(), animation, rate))
        parts.append('[resource]\nanimations = [' + ',\n'.join(entries) + ']')
        (ROOT / f'demo/resources/{name}_animation_frames.tres').write_text('\n\n'.join(parts) + '\n')
    (ROOT / 'demo/resources/animation_bounds.json').write_text(json.dumps(result, indent=2))
    # Keep the additional pass profiles when regenerating the base resources.
    import runpy
    runpy.run_path(str(ROOT / 'tools/build_side_resources.py'), run_name='__main__')
