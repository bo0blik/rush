@tool
extends RefCounted
## Seeded ecological clusters, batched by road section for visibility culling.

const FRAMES: SpriteFrames = preload("res://demo/resources/scenery_frames.tres")
const SHADER = preload("res://demo/shaders/scenery_billboard.gdshader")
var track: Path3D
var world: Node3D
var rng := RandomNumberGenerator.new()
var batches: Dictionary = {}
var textures: Array[AtlasTexture] = []
var clearings: Array[Vector3] = []
var tree_count: int = 0
var prop_count: int = 0


func build(road: Path3D, parent: Node3D) -> void:
	track = road
	world = parent
	rng.seed = track.get("scenery_seed")
	for animation: StringName in [&"forest", &"props", &"rural"]:
		for i in range(FRAMES.get_frame_count(animation)):
			textures.append(FRAMES.get_frame_texture(animation, i))
	var length: float = track.get("length")
	for i in range(5):
		var frame: Transform3D = _frame(62.0 + i * length / 5.0)
		clearings.append(frame.origin + frame.basis.x * (18.0 + i % 2 * 5.0))
	for i in range(6):
		var frame: Transform3D = _frame(35.0 + i * length / 6.0)
		clearings.append(frame.origin - frame.basis.x * 10.5)
	_build_rural()
	for i in range(floori(length / 4.5)):
		var along: float = i * 4.5 + rng.randf_range(-1.5, 1.5)
		var zone: int = floori(fposmod(along, length) / length * 6.0)
		for side: float in [-1.0, 1.0]:
			for layer in range(6):
				if along > 60.0 and along < 650.0 and side > 0.0:
					continue
				# Meadows and lake viewpoints leave deliberate gaps in the canopy.
				if layer < 2 and (zone == 2 or (side < 0.0 and zone == 4)):
					continue
				if zone == 3 and side > 0.0 and layer == 0:
					continue
				var kind: int = rng.randi_range(0, 5)
				if zone == 1 or zone == 5:
					kind = 3 if rng.randf() < 0.65 else 4
				elif zone == 0 or zone == 3:
					kind = [0, 1, 2, 5][rng.randi_range(0, 3)]
				if along > 70.0 and along < 650.0 and side < 0.0 and layer < 3:
					kind = 3 if rng.randf() < 0.65 else 4
				var height: float = rng.randf_range(6.5, 11.0) if layer == 0 else rng.randf_range(11.0, 22.0)
				var offset: float = 9.0 + layer * 13.5 + rng.randf_range(0.0, 10.0)
				_add(kind, along, side * offset, height, 0.065, true)
			# Different ground-cover populations distinguish each part of the loop.
			for cluster in range(3):
				var clump_distance: float = along + rng.randf_range(-2.0, 2.0)
				var offset: float = side * rng.randf_range(6.1, 24.0)
				for member in range(rng.randi_range(2, 4)):
					var kind: int = [8, 9, 10, 15][rng.randi_range(0, 3)]
					if zone == 0 or zone == 3:
						kind = 8 if member % 2 == 0 else 10
					elif zone == 2:
						kind = 9
					elif zone == 4 and side < 0.0:
						kind = 11
					var height: float = rng.randf_range(0.35, 0.85) if kind == 8 or kind == 9 else rng.randf_range(0.85, 1.6)
					_add(kind, clump_distance + rng.randf_range(-1.4, 1.4), offset + rng.randf_range(-1.1, 1.1), height, 0.045)
			if i % 4 == 0:
				var kind: int = [12, 13, 14, 7][rng.randi_range(0, 3)]
				_add(kind, along, side * rng.randf_range(7.0, 17.0), rng.randf_range(0.65, 1.55), 0.0)
			if zone == 3 and side > 0.0 and i % 3 == 0:
				_add(14, along, rng.randf_range(12.0, 20.0), rng.randf_range(3.0, 5.5), 0.0)
	# Useful landmarks introduce a visual rhythm without covering the road.
	for i in range(12):
		_add(17, 72.0 + i * length / 12.0, 7.2, 2.3, 0.0)
	_build_landmarks(length)
	_build_batches()
	world.set_meta("tree_count", tree_count)
	world.set_meta("ground_prop_count", prop_count)
	world.set_meta("scenery_batch_count", batches.size())


func _frame(along: float) -> Transform3D:
	return track.call("_local_frame", along)


func _add(kind: int, along: float, offset: float, height: float, wind: float, tree: bool = false) -> void:
	var frame: Transform3D = _frame(along)
	var origin: Vector3 = frame.origin + frame.basis.x * offset
	if kind < 16 or kind == 24 or kind == 25:
		for clearing: Vector3 in clearings:
			if Vector2(origin.x - clearing.x, origin.z - clearing.z).length() < (8.0 if tree else 4.0):
				return
	# Reject decorations where a different bend of the loop comes close.
	var closest: Vector3 = track.curve.get_closest_point(origin)
	if Vector2(origin.x - closest.x, origin.z - closest.z).length() < float(track.get("road_width")) * 0.5 + 1.3:
		return
	if along > 70.0 and along < 650.0 and offset > 0.0 and kind < 20:
		var river: Vector2 = track.call("river_edges", along)
		if offset > river.x - 2.0 and offset < river.y + 2.0:
			return
	var texture: AtlasTexture = textures[kind]
	var width: float = height * texture.region.size.x / texture.region.size.y
	origin.y += height * 0.5
	var section: int = floori(fposmod(along, float(track.get("length"))) / 95.0)
	var key: String = "%02d_%02d" % [section, kind]
	if not batches.has(key):
		batches[key] = {"kind": kind, "tree": tree, "items": []}
	var shade: float = rng.randf_range(0.88, 1.08)
	batches[key].items.append({"origin": origin, "size": Vector2(width, height), "phase": rng.randf() * TAU, "wind": wind, "color": Color(shade, shade * rng.randf_range(0.97, 1.02), shade * 0.96)})
	if tree:
		tree_count += 1
	else:
		prop_count += 1


func _build_batches() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var materials: Dictionary = {}
	for key: String in batches:
		var group: Dictionary = batches[key]
		var kind: int = group.kind
		if not materials.has(kind):
			var texture: AtlasTexture = textures[kind]
			var material := ShaderMaterial.new()
			material.shader = SHADER
			material.set_shader_parameter("atlas", texture.atlas)
			material.set_shader_parameter("atlas_size", Vector2(texture.atlas.get_size()))
			material.set_shader_parameter("region", Vector4(texture.region.position.x, texture.region.position.y, texture.region.size.x, texture.region.size.y))
			materials[kind] = material
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.use_custom_data = true
		multimesh.mesh = quad
		multimesh.instance_count = group.items.size()
		var bounds := AABB(group.items[0].origin, Vector3.ZERO)
		for i in range(group.items.size()):
			var item: Dictionary = group.items[i]
			multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, item.origin))
			multimesh.set_instance_color(i, item.color)
			multimesh.set_instance_custom_data(i, Color(item.size.x, item.size.y, item.phase, item.wind))
			var extent := Vector3(item.size.x, item.size.y, item.size.x) * 0.5 + Vector3.ONE * 0.15
			bounds = bounds.merge(AABB(item.origin - extent, extent * 2.0))
		# Shader-expanded quads require explicit bounds to avoid early culling.
		multimesh.custom_aabb = bounds
		var instance := MultiMeshInstance3D.new()
		instance.name = "SceneryBatch_" + key
		instance.multimesh = multimesh
		instance.material_override = materials[kind]
		instance.visibility_range_end = 330.0 if group.tree else 165.0 if group.kind >= 24 else 115.0
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED if group.tree else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(instance)


func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	return track.call("_box", parent, position, size, color)


func _landmark(name: String, along: float, offset: float) -> Node3D:
	var node := Node3D.new()
	node.name = name
	node.transform = _frame(along)
	node.position += node.basis.x * offset
	world.add_child(node)
	return node


func _build_landmarks(length: float) -> void:
	for i in range(5):
		var along: float = 62.0 + i * length / 5.0
		var cabin: Node3D = _landmark("ForestCabin%d" % i, along, 18.0 + i % 2 * 5.0)
		_box(cabin, Vector3(0, 1.3, 0), Vector3(4.8, 2.6, 4.0), Color("82613f"))
		for plank in range(12):
			_box(cabin, Vector3(0, 0.16 + plank * 0.21, 2.05), Vector3(4.9, 0.07, 0.11), Color("5e482f"))
		for x: float in [-1.5, 1.5]:
			_box(cabin, Vector3(x, 1.5, 2.12), Vector3(0.94, 1.05, 0.12), Color("ddcaa0"))
			_box(cabin, Vector3(x, 1.5, 2.20), Vector3(0.70, 0.81, 0.05), Color("42778e"))
			_box(cabin, Vector3(x, 1.5, 2.24), Vector3(0.05, 0.81, 0.04), Color("e6d5ad"))
		_box(cabin, Vector3(0, 0.95, 2.14), Vector3(0.86, 1.9, 0.13), Color("493d2c"))
		for x: float in [-1.35, 1.35]:
			var roof := _box(cabin, Vector3(x, 3.0, 0), Vector3(3.2, 0.18, 4.8), Color("554938") if i % 2 == 0 else Color("704733"))
			roof.rotation.z = -0.38 if x > 0 else 0.38
		_box(cabin, Vector3(1.5, 3.25, -0.8), Vector3(0.47, 1.25, 0.55), Color("75655c"))
		_box(cabin, Vector3(0, 0.12, 2.85), Vector3(1.4, 0.24, 1.2), Color("94856a"))
		_build_fence(along - 12.0, 13.0, 23.0)
		_add(16, along + 4.0, 15.0, 1.1, 0.0)
		_add(18, along - 6.0, 16.0, 1.7, 0.0)
		_add(19, along - 10.0, 22.0, 2.3, 0.0)
	for i in range(6):
		var picnic := _landmark("PicnicSpot%d" % i, 35.0 + i * length / 6.0, -10.5)
		_box(picnic, Vector3(0, 0.78, 0), Vector3(2.1, 0.13, 0.95), Color("aa8756"))
		for x: float in [-0.7, 0.7]:
			_box(picnic, Vector3(x, 0.36, 0), Vector3(0.16, 0.72, 0.85), Color("715738"))
		for z: float in [-0.8, 0.8]:
			_box(picnic, Vector3(0, 0.43, z), Vector3(2.2, 0.13, 0.32), Color("8e714b"))
			for x: float in [-0.7, 0.7]:
				_box(picnic, Vector3(x, 0.2, z), Vector3(0.12, 0.4, 0.22), Color("604b33"))
		_box(picnic, Vector3(2.0, 0.35, 0), Vector3(0.55, 0.7, 0.55), Color("40554e"))


func _build_fence(along: float, offset: float, span: float) -> void:
	var fence := _landmark("FarmFence%d" % int(along), along, offset)
	fence.basis = Basis.IDENTITY
	var segments: int = ceili(span / 1.7)
	var previous: Vector3
	for i in range(segments + 1):
		var frame: Transform3D = _frame(along + span * i / segments)
		var point: Vector3 = fence.to_local(frame.origin + frame.basis.x * offset)
		_box(fence, point + Vector3.UP * 0.6, Vector3(0.16, 1.2, 0.16), Color("796345"))
		if i > 0:
			for height: float in [0.4, 0.86]:
				var rail := _box(fence, (point + previous) * 0.5 + Vector3.UP * height, Vector3(0.12, 0.12, point.distance_to(previous)), Color("a28b61"))
				rail.basis = Basis.looking_at(point - previous, Vector3.UP)
		previous = point


func _architecture(name: String, kind: int, along: float, offset: float, height: float) -> void:
	var node: Node3D = _landmark(name, along, offset)
	clearings.append(node.position)
	var texture: AtlasTexture = textures[kind]
	var sprite := Sprite3D.new()
	sprite.name = "Artwork"
	sprite.texture = texture
	sprite.pixel_size = height / texture.region.size.y
	sprite.position.y = height * 0.5
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.visibility_range_end = 700.0
	node.add_child(sprite)
	var width: float = height * texture.region.size.x / texture.region.size.y
	var shadow := _box(node, Vector3(0, height * 0.325, 0), Vector3(width * 0.65, height * 0.65, width * 0.5), Color.WHITE)
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	if kind == 23:
		shadow.mesh.size = Vector3(width * 0.75, height * 0.28, width * 0.45)
		shadow.position.y = height * 0.14
		var tower := _box(node, Vector3(0, height * 0.45, 0), Vector3(1.9, height * 0.85, 1.9), Color.WHITE)
		tower.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func _build_rural() -> void:
	# Both banks remain open so fields, water and architecture read from the road.
	for i in range(12):
		var along: float = 104.0 + i * 40.0
		var edges: Vector2 = track.call("river_edges", along)
		_architecture("VillageHouse%02d" % i, 20 + i % 3, along, edges.y + 9.0 + i % 2 * 5.0, rng.randf_range(4.5, 6.0))
	for i in range(5):
		_architecture("FarmHouse%d" % i, 20 + i % 3, 122.0 + i * 106.0, 20.0 + i % 2 * 4.0, 4.6)
	_architecture("VillageChurch", 23, 240.0, 68.0, 16.5)
	_architecture("VillageBarn", 26, 370.0, 71.0, 6.0)
	_architecture("VillageWindmill", 27, 515.0, 63.0, 9.0)
	var crop_count: int = 0
	for i in range(290):
		var along: float = 90.0 + i * 1.8
		var edges: Vector2 = track.call("river_edges", along)
		var kind: int = 25 if along > 300.0 and along < 470.0 else 24
		for row in range(10):
			var offset: float = 7.5 + row * 2.0
			if offset >= edges.x - 3.0:
				continue
			var before: int = prop_count
			_add(kind, along + rng.randf_range(-0.25, 0.25), offset + rng.randf_range(-0.15, 0.15), rng.randf_range(1.25, 1.65) if kind == 24 else rng.randf_range(0.65, 1.0), 0.04)
			crop_count += prop_count - before
		if i % 4 == 0:
			_add(11, along, edges.x - 0.7, rng.randf_range(0.9, 1.4), 0.035)
			_add(11, along, edges.y + 0.5, rng.randf_range(1.0, 1.4), 0.035)
	for i in range(5):
		_build_fence(100.0 + i * 104.0, 6.7, 80.0)
	var along: float = 310.0
	var edges: Vector2 = track.call("river_edges", along)
	var bridge := _landmark("RiverFootbridge", along, (edges.x + edges.y) * 0.5)
	var span: float = edges.y - edges.x + 5.0
	_box(bridge, Vector3(0, 0.10, 0), Vector3(span, 0.22, 2.4), Color("948266"))
	for side: float in [-1.0, 1.0]:
		_box(bridge, Vector3(0, 1.0, side * 1.1), Vector3(span, 0.12, 0.14), Color("74654e"))
		for i in range(8):
			_box(bridge, Vector3(-span * 0.5 + i * span / 7.0, 0.56, side * 1.1), Vector3(0.13, 1.0, 0.13), Color("66563c"))
	world.set_meta("crop_count", crop_count)
