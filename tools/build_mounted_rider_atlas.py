"""Measure authored poses and helmet registration points without editing source pixels."""
from pathlib import Path
from PIL import Image
from build_animation_resources import components

ROOT = Path(__file__).resolve().parents[1]
source = ROOT / 'demo/assets/rider_mounted_v6.png'
size, found = components(source)
assert len(found) == 9, len(found)
image = Image.open(source).convert('RGBA')
found.sort(key=lambda item: item['box'][1])
ordered = []
for row in range(3):
    ordered.extend(sorted(found[row*3:row*3+3], key=lambda item: item['box'][0]))
text = ['[gd_resource type="SpriteFrames" load_steps=11 format=3]',
        '[ext_resource type="Texture2D" path="res://demo/assets/rider_mounted_v6.png" id="1"]']
# Authored pelvis landmarks measured on the source sheet, independent of frame cropping.
seats = [(239, 230), (633, 235), (1061, 230), (231, 645), (666, 647), (1060, 647), (233, 1040), (701, 1041), (1067, 1040)]
hands = [((153, 170), (330, 170)), ((547, 172), (724, 172)), ((974, 170), (1151, 170))]
for i, item in enumerate(ordered):
    x, y, right, bottom = item['box']
    x, right = max(0, x - 32), min(size[0], right + 32)
    pixels = [(px, py) for py in range(y, y + int((bottom-y)*0.20)) for px in range(x, right)
              if (lambda c: c[3] > 128 and c[0] > 70 and c[0] > c[1]*1.7 and c[0] > c[2]*1.7)(image.getpixel((px, py)))]
    assert pixels, (i, item)
    left_head = min(p[0] for p in pixels)
    right_head = max(p[0] for p in pixels)
    head_x = (left_head + right_head)*0.5 - x
    head_y = (min(p[1] for p in pixels) + max(p[1] for p in pixels))*0.5 - y
    pixel_size = 0.32 / (right_head - left_head + 1)
    seat_x, seat_y = seats[i][0] - x, seats[i][1] - y
    boot_pixels = [(px, py) for py in range(y + int((bottom-y)*0.72), bottom) for px in range(seats[i][0] + 10, right)
                   if (lambda c: c[3] > 128 and c[0] > 45 and c[0] > c[1]*1.2 and c[1] > c[2]*1.2 and c[0] < c[1]*2.4)(image.getpixel((px, py)))]
    assert boot_pixels, i
    boot_x = sum(p[0] for p in boot_pixels) / len(boot_pixels) - x
    boot_y = sum(p[1] for p in boot_pixels) / len(boot_pixels) - y
    boot_width = max(p[0] for p in boot_pixels) - min(p[0] for p in boot_pixels) + 1
    boot_height = max(p[1] for p in boot_pixels) - min(p[1] for p in boot_pixels) + 1
    text.append(f'[sub_resource type="AtlasTexture" id="P{i}"]\natlas = ExtResource("1")\nregion = Rect2({x}, {y}, {right-x}, {bottom-y})\nfilter_clip = true\nmetadata/head = Vector2({head_x}, {head_y})\nmetadata/seat = Vector2({seat_x}, {seat_y})\nmetadata/boot = Vector2({boot_x:.4f}, {boot_y:.4f})\nmetadata/boot_width = {boot_width}\nmetadata/boot_height = {boot_height}\nmetadata/pixel_size = {pixel_size:.8f}')
    if i < 3:
        left, hand_right = hands[i]
        text[-1] += f'\nmetadata/hand_left = Vector2({left[0]-x}, {left[1]-y})\nmetadata/hand_right = Vector2({hand_right[0]-x}, {hand_right[1]-y})'
    print(i, item['box'], 'head', head_x, head_y, 'height m', (bottom-y)*pixel_size)
frames = ', '.join('{"duration": 1.0, "texture": SubResource("P%d")}' % i for i in range(9))
text.append('[resource]\nanimations = [{"frames": [' + frames + '], "loop": false, "name": &"poses", "speed": 1.0}]')
(ROOT / 'demo/resources/rider_mounted.tres').write_text('\n\n'.join(text)+'\n', encoding='utf-8')
