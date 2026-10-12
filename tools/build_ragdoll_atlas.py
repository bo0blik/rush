"""Register front/back T-pose body parts without editing generated source pixels."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
names = ["torso", "helmet", "sleeve_left", "forearm_left", "thigh_left", "shin_left", "boot_left", "sleeve_right", "forearm_right", "thigh_right", "shin_right", "boot_right"]
views = {
    "front": [(338, 171, 212, 310), (363, 12, 158, 166), (536, 188, 132, 76), (658, 192, 213, 68), (444, 459, 106, 166), (455, 610, 107, 175), (495, 774, 97, 98), (210, 188, 138, 76), (15, 192, 212, 68), (337, 459, 107, 166), (325, 610, 91, 175), (296, 774, 100, 98)],
    "back": [(1228, 165, 209, 320), (1253, 12, 159, 158), (1093, 187, 147, 78), (902, 192, 208, 70), (1226, 459, 105, 166), (1210, 610, 104, 174), (1188, 774, 98, 98), (1421, 187, 137, 78), (1538, 192, 219, 70), (1332, 459, 103, 166), (1340, 610, 103, 175), (1380, 774, 96, 98)],
}
parts = ['[gd_resource type="SpriteFrames" load_steps=26 format=3]', '[ext_resource type="Texture2D" path="res://demo/assets/rider_tpose_front_back.png" id="1"]']
animations = []
for view, rectangles in views.items():
    frames = []
    for index, (name, rect) in enumerate(zip(names, rectangles)):
        identifier = f"{view}_{index}"
        horizontal = name.startswith(("sleeve", "forearm"))
        direction = 1 if name.endswith("left") == (view == "front") else -1
        parts.append(f'[sub_resource type="AtlasTexture" id="{identifier}"]\natlas = ExtResource("1")\nregion = Rect2({", ".join(map(str, rect))})\nfilter_clip = true\nmetadata/horizontal = {str(horizontal).lower()}\nmetadata/direction = {direction}')
        frames.append('{"duration": 1.0, "texture": SubResource("%s")}' % identifier)
    animations.append('{"frames": [%s], "loop": false, "name": &"%s", "speed": 1.0}' % (", ".join(frames), view))
parts.append('[resource]\nanimations = [' + ",\n".join(animations) + ']')
(root / "demo/resources/rider_ragdoll_parts.tres").write_text("\n\n".join(parts) + "\n", encoding="utf-8")
