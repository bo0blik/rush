@tool
class_name DemoTrack
extends Path3D
## Editable centerline. Road geometry and decoration are derived once, not per frame.

@export_range(6.0, 16.0, 0.5) var road_width: float = 9.0:
	set(value):
		road_width = value
		if is_inside_tree():
			_request_rebuild()
@export var scenery_atlas: Texture2D:
	set(value):
		scenery_atlas = value
		if is_inside_tree():
			_request_rebuild()
@export var scenery_seed: int = 77:
	set(value):
		scenery_seed = value
		if is_inside_tree():
			_request_rebuild()

const ROAD_SHADER = preload("res://demo/shaders/road.gdshader")
const STEP: float = 2.0
var length: float = 0.0
var _rebuild_queued: bool = false


func _ready() -> void:
	if curve != null and not curve.changed.is_connected(_request_rebuild):
		curve.changed.connect(_request_rebuild)
	_rebuild()


func _request_rebuild() -> void:
	if not _rebuild_queued:
		_rebuild_queued = true
		_rebuild.call_deferred()


func frame_at(distance: float) -> Transform3D:
	var along: float = fposmod(distance, length)
	var point: Vector3 = curve.sample_baked(along, true)
	var ahead: Vector3 = curve.sample_baked(fposmod(along + 0.5, length), true)
	var forward: Vector3 = (ahead - point).normalized()
	return global_transform * Transform3D(Basis.looking_at(forward, Vector3.UP), point)


func _rebuild() -> void:
	_rebuild_queued = false
	if curve == null or curve.point_count < 2 or not has_node("GeneratedWorld"):
		return
	length = curve.get_baked_length()
	if length < STEP:
		return
	var world: Node3D = $GeneratedWorld
	for child in world.get_children():
		world.remove_child(child)
		child.queue_free()
	_build_road(world)
	_build_landscape(world)
	_build_posts(world)
	_build_roadside(world)
	if scenery_atlas != null:
		_build_forest(world)
		_build_far_forest(world)


func _local_frame(distance: float) -> Transform3D:
	return global_transform.affine_inverse() * frame_at(distance)


func _build_road(world: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var water_surface := SurfaceTool.new()
	water_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: float = road_width * 0.5
	var segment_count: int = ceili(length / STEP)
	for i in range(segment_count):
		var start: float = i * length / segment_count
		var finish: float = (i + 1) * length / segment_count
		var a: Transform3D = _local_frame(start)
		var b: Transform3D = _local_frame(finish)
		_strip(surface, a, b, -70.0, -half - 0.8, -0.06, Color("7c9746"))
		var midpoint: float = (start + finish) * 0.5
		if midpoint > 70.0 and midpoint < 650.0:
			var edges: Vector2 = river_edges(midpoint)
			var soil: Color = Color("9d9252") if midpoint > 300.0 and midpoint < 470.0 else Color("718843")
			_strip(surface, a, b, half + 0.8, edges.x - 2.0, -0.06, soil)
			_strip(surface, a, b, edges.x - 2.0, edges.x, -0.09, Color("c6b380"))
			_strip(surface, a, b, edges.y, edges.y + 2.0, -0.09, Color("c6b380"))
			_strip(surface, a, b, edges.y + 2.0, 120.0, -0.06, Color("98a75a"))
			_strip(water_surface, a, b, edges.x, edges.y, -0.20, Color.WHITE)
		else:
			_strip(surface, a, b, half + 0.8, 70.0, -0.06, Color("93a34e"))
		_strip(surface, a, b, -half - 0.8, half + 0.8, -0.02, Color("a29671"))
		_strip(surface, a, b, -half, half, 0.0, Color("454956"))
		_strip(surface, a, b, -half + 0.15, -half + 0.27, 0.025, Color("eee7cd"))
		_strip(surface, a, b, half - 0.27, half - 0.15, 0.025, Color("eee7cd"))
		if i % 4 < 2:
			_strip(surface, a, b, -0.065, 0.065, 0.03, Color("e8bb4f"))
	var material := ShaderMaterial.new()
	material.shader = ROAD_SHADER
	var road := MeshInstance3D.new()
	road.name = "RoadAndVerge"
	surface.generate_normals()
	road.mesh = surface.commit()
	road.material_override = material
	world.add_child(road)
	if not Engine.is_editor_hint():
		var ground_body := StaticBody3D.new()
		ground_body.name = "GroundCollision"
		ground_body.collision_layer = 1
		ground_body.collision_mask = 12
		var ground_shape := CollisionShape3D.new()
		ground_shape.shape = road.mesh.create_trimesh_shape()
		ground_shape.shape.backface_collision = true
		ground_body.add_child(ground_shape)
		world.add_child(ground_body)
	water_surface.generate_normals()
	var river := MeshInstance3D.new()
	river.name = "VillageRiver"
	river.mesh = water_surface.commit()
	var water_material := ShaderMaterial.new()
	water_material.shader = preload("res://demo/shaders/river.gdshader")
	river.material_override = water_material
	river.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(river)


func river_edges(distance: float) -> Vector2:
	var center: float = 43.0 + sin(distance * 0.024) * 4.0
	var taper: float = smoothstep(70.0, 110.0, distance) * (1.0 - smoothstep(610.0, 650.0, distance))
	var half_width: float = (9.0 + sin(distance * 0.015) * 2.0) * taper
	return Vector2(center - half_width, center + half_width)


func _strip(surface: SurfaceTool, a: Transform3D, b: Transform3D,
		left: float, right: float, height: float, color: Color) -> void:
	var al: Vector3 = a.origin + a.basis.x * left + Vector3.UP * height
	var ar: Vector3 = a.origin + a.basis.x * right + Vector3.UP * height
	var bl: Vector3 = b.origin + b.basis.x * left + Vector3.UP * height
	var br: Vector3 = b.origin + b.basis.x * right + Vector3.UP * height
	for vertex: Vector3 in [al, ar, bl, ar, br, bl]:
		surface.set_color(color)
		surface.set_uv(Vector2(vertex.x, vertex.z))
		surface.add_vertex(vertex)


func _flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.90
	material.metallic_specular = 0.15
	return material


func _build_landscape(world: Node3D) -> void:
	var ground := MeshInstance3D.new()
	ground.name = "ForestFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(3200.0, 3200.0)
	ground.mesh = plane
	ground.position.y = -7.0
	ground.material_override = _flat_material(Color("6b873f"))
	world.add_child(ground)
	var lake := MeshInstance3D.new()
	lake.name = "Lake"
	var water := CylinderMesh.new()
	water.top_radius = 82.0
	water.bottom_radius = 82.0
	water.height = 0.1
	water.radial_segments = 24
	lake.mesh = water
	lake.position = Vector3(0.0, -6.8, -20.0)
	lake.scale.z = 1.5
	lake.material_override = _flat_material(Color("287bc8"))
	world.add_child(lake)
	# Separate physical rings give real parallax as the camera travels around the loop.
	for layer in range(3):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var radius: float = 570.0 + layer * 270.0
		var base_color: Color = [Color("245765"), Color("32678e"), Color("547dc2")][layer]
		for i in range(320):
			var a: float = i * TAU / 320.0
			var b: float = (i + 1) * TAU / 320.0
			var ha: float = _ridge_height(a, layer)
			var hb: float = _ridge_height(b, layer)
			var left := Vector3(cos(a) * radius, ha, sin(a) * radius)
			var right := Vector3(cos(b) * radius, hb, sin(b) * radius)
			var shade: float = 0.82 + 0.18 * sin(a * 18.0 + layer)
			for vertex: Vector3 in [left, right, Vector3(right.x, -40, right.z), left, Vector3(right.x, -40, right.z), Vector3(left.x, -40, left.z)]:
				surface.set_color(base_color * shade)
				surface.add_vertex(vertex)
			if layer == 2 and ha > 160.0:
				for vertex: Vector3 in [left, right, left.lerp(Vector3(right.x, ha - 26.0, right.z), 0.4)]:
					surface.set_color(Color("b9cde8"))
					surface.add_vertex(vertex)
		var ridge := MeshInstance3D.new()
		ridge.name = "ParallaxRidge%d" % layer
		ridge.mesh = surface.commit()
		var material := ShaderMaterial.new()
		material.shader = preload("res://demo/shaders/ridge.gdshader")
		ridge.material_override = material
		world.add_child(ridge)


func _ridge_height(angle: float, layer: int) -> float:
	var broad: float = absf(sin(angle * (5.0 + layer) + layer * 1.4))
	var detail: float = sin(angle * 23.0 + layer) * 11.0 + sin(angle * 57.0) * 5.0
	return 20.0 + layer * 42.0 + pow(broad, 2.5) * (35.0 + layer * 43.0) + detail


func _build_far_forest(world: Node3D) -> void:
	var frames: SpriteFrames = preload("res://demo/resources/scenery_frames.tres")
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var total: int = 0
	for layer in range(8):
		var radius: float = 270.0 + layer * 58.0 if layer < 6 else (837.0 if layer == 6 else 1107.0)
		var count: int = ceili(TAU * radius / 8.0)
		for kind: int in [0, 3]:
			var texture: AtlasTexture = frames.get_frame_texture(&"forest", kind)
			var material := ShaderMaterial.new()
			material.shader = preload("res://demo/shaders/scenery_billboard.gdshader")
			material.set_shader_parameter("atlas", texture.atlas)
			material.set_shader_parameter("atlas_size", Vector2(texture.atlas.get_size()))
			material.set_shader_parameter("region", Vector4(texture.region.position.x, texture.region.position.y, texture.region.size.x, texture.region.size.y))
			material.set_shader_parameter("fade_start", 2300.0)
			material.set_shader_parameter("fade_end", 2500.0)
			material.set_shader_parameter("horizon", 0.8)
			var items: Array[Dictionary] = []
			for i in range(count):
				if (i % 3 == 0) != (kind == 0):
					continue
				var angle: float = i * TAU / count + layer * 0.027
				var radial: float = radius + sin(i * 17.3 + layer) * 9.0
				var point := Vector3(cos(angle) * radial, -5.0, sin(angle) * radial)
				if layer < 5:
					var closest: Vector3 = curve.get_closest_point(point)
					if Vector2(point.x - closest.x, point.z - closest.z).length() < 28.0:
						continue
				else:
					point.y = _ridge_height(angle, 0 if layer == 5 else layer - 5) - 8.0
				var height: float = 18.0 + (sin(i * 7.1) + 1.0) * 7.0
				var width: float = height * texture.region.size.x / texture.region.size.y
				point.y += height * 0.5
				items.append({"origin": point, "size": Vector2(width, height)})
			var batch := MultiMesh.new()
			batch.transform_format = MultiMesh.TRANSFORM_3D
			batch.use_colors = true
			batch.use_custom_data = true
			batch.mesh = quad
			batch.instance_count = items.size()
			var bounds := AABB(items[0].origin, Vector3.ZERO)
			var tint: Color = Color("426c51") if layer < 4 else Color("52765f") if layer == 4 else Color("466d74") if layer == 5 else Color("537a93") if layer == 6 else Color("6a88b2")
			for i in range(items.size()):
				var item: Dictionary = items[i]
				batch.set_instance_transform(i, Transform3D(Basis.IDENTITY, item.origin))
				batch.set_instance_custom_data(i, Color(item.size.x, item.size.y, 0, 0))
				batch.set_instance_color(i, tint)
				var extent := Vector3(item.size.x, item.size.y, item.size.x) * 0.5
				bounds = bounds.merge(AABB(item.origin - extent, extent * 2.0))
			batch.custom_aabb = bounds
			var forest := MultiMeshInstance3D.new()
			forest.name = "HorizonForest_%d_%d" % [layer, kind]
			forest.multimesh = batch
			forest.material_override = material
			forest.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			world.add_child(forest)
			total += items.size()
	world.set_meta("horizon_tree_count", total)


func _build_posts(world: Node3D) -> void:
	var count: int = floori(length / 22.0)
	for top: bool in [false, true]:
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.17, 0.18 if top else 0.68, 0.17)
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = mesh
		batch.instance_count = count * 2
		for i in range(count):
			var frame: Transform3D = _local_frame(i * length / count)
			for side in range(2):
				var sign_side: float = -1.0 if side == 0 else 1.0
				var origin: Vector3 = frame.origin + frame.basis.x * sign_side * (road_width * 0.5 + 0.9)
				origin.y += 0.77 if top else 0.34
				batch.set_instance_transform(i * 2 + side, Transform3D(Basis.IDENTITY, origin))
		var posts := MultiMeshInstance3D.new()
		posts.name = "PostCaps" if top else "RoadsidePosts"
		posts.multimesh = batch
		posts.material_override = _flat_material(Color("222b32") if top else Color("e3e5d5"))
		world.add_child(posts)


func _build_forest(world: Node3D) -> void:
	preload("res://demo/scripts/dense_scenery.gd").new().build(self, world)

func _box(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _flat_material(color)
	parent.add_child(instance)
	return instance


func _build_roadside(world: Node3D) -> void:
	var metal := Color("9baab7")
	# Curved guardrails use one instanced mesh and follow the road tangent.
	var count: int = floori(length / 4.0)
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(0.12, 0.28, 4.2)
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = rail_mesh
	batch.instance_count = count
	for i in range(count):
		var frame: Transform3D = _local_frame(i * 4.0)
		frame.origin += frame.basis.x * -(road_width * 0.5 + 1.2) + Vector3.UP * 0.68
		batch.set_instance_transform(i, frame)
	var rails := MultiMeshInstance3D.new()
	rails.name = "LakeGuardrail"
	rails.multimesh = batch
	rails.material_override = _flat_material(metal)
	world.add_child(rails)
	for i in range(floori(length / 95.0)):
		var distance: float = 55.0 + i * 95.0
		var frame: Transform3D = _local_frame(distance)
		var ahead: Transform3D = _local_frame(distance + 12.0)
		var turn: float = (-frame.basis.z).cross(-ahead.basis.z).y
		var sign_node := Node3D.new()
		sign_node.name = "TurnSign%02d" % i
		sign_node.transform = frame
		sign_node.position += frame.basis.x * (road_width * 0.5 + 1.3)
		world.add_child(sign_node)
		_box(sign_node, Vector3(0, 0.95, 0), Vector3(0.09, 1.9, 0.09), metal)
		_box(sign_node, Vector3(0, 1.8, 0), Vector3(1.05, 0.62, 0.08), Color("f5eee1"))
		for arrow in range(2):
			for stroke in range(2):
				var chevron := _box(sign_node, Vector3(-0.24 + arrow * 0.47, 1.8 + (-0.1 if stroke == 0 else 0.1), 0.06), Vector3(0.31, 0.10, 0.04), Color("cf382a"))
				chevron.rotation.z = (0.72 if stroke == 0 else -0.72) * (-1.0 if turn < 0.0 else 1.0)
	for i in range(4):
		var frame: Transform3D = _local_frame(115.0 + i * length / 4.0)
		var shelter := Node3D.new()
		shelter.name = "TimberBusStop%d" % i
		shelter.transform = frame
		shelter.position += frame.basis.x * 8.4
		world.add_child(shelter)
		_box(shelter, Vector3(0, 0.04, 0), Vector3(3.6, 0.12, 2.5), Color("9c9586"))
		for x: float in [-1.5, 1.5]:
			for z: float in [-0.9, 0.9]:
				_box(shelter, Vector3(x, 1.15, z), Vector3(0.16, 2.3, 0.16), Color("63462d"))
		for plank in range(9):
			_box(shelter, Vector3(0, 0.35 + plank * 0.22, -1.0), Vector3(3.1, 0.19, 0.12), Color("806039") if plank % 2 == 0 else Color("715231"))
		_box(shelter, Vector3(0, 0.5, -0.60), Vector3(2.6, 0.16, 0.50), Color("aa8150"))
		for x: float in [-0.9, 0.9]:
			var roof := _box(shelter, Vector3(x, 2.40, 0), Vector3(2.0, 0.15, 2.8), Color("513b2c"))
			roof.rotation.z = -0.28 if x > 0 else 0.28
		_box(shelter, Vector3(-2.1, 1.35, 0.3), Vector3(0.08, 2.7, 0.08), metal)
		_box(shelter, Vector3(-2.1, 2.4, 0.3), Vector3(0.57, 0.7, 0.08), Color("2567b9"))
		_box(shelter, Vector3(-2.1, 2.43, 0.36), Vector3(0.36, 0.26, 0.05), Color("eee8d8"))
