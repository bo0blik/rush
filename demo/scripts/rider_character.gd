class_name RiderCharacter
extends Node3D
## One articulated rider: procedural riding/attacks, then the same rig becomes physical.
const PARTS = preload("res://demo/resources/rider_parts.tres")
const RAGDOLL_PARTS = preload("res://demo/resources/rider_ragdoll_parts.tres")
const RAGDOLL_KEYS = ["torso", "helmet", "sleeve_left", "forearm_left", "thigh_left", "shin_left", "boot_left", "sleeve_right", "forearm_right", "thigh_right", "shin_right", "boot_right"]
signal outfit_changed
var helmet: int = 0
var jacket: int = 0
var pants: int = 0
var boots: int = 0
var bike: DemoMotorcycle
var ragdoll_active: bool = false
var attack: String = ""
var attack_side: float = -1.0
var attack_time: float = 0.0
var attack_duration: float = 0.65
var attack_hits: Array[int] = []
var parts: Array[Dictionary] = []
var bone_ids: Dictionary = {}
var physical_bones: Dictionary = {}
var gloves: Dictionary = {}
var neck: MeshInstance3D
var flight_time: float = 0.0
var mounted_visual: Sprite3D
@onready var skeleton: Skeleton3D = $Skeleton3D
@onready var simulator: PhysicalBoneSimulator3D = $Skeleton3D/PhysicalBoneSimulator3D

func _ready() -> void:
	for i in range(skeleton.get_bone_count()):
		bone_ids[skeleton.get_bone_name(i)] = i
	for bone: PhysicalBone3D in simulator.get_children():
		physical_bones[skeleton.find_bone(bone.bone_name)] = bone
	_load_outfit()
	neck = MeshInstance3D.new()
	var neck_mesh := CapsuleMesh.new()
	neck_mesh.radius = 0.055
	neck_mesh.height = 0.13
	neck.mesh = neck_mesh
	var neck_material := StandardMaterial3D.new()
	neck_material.albedo_color = Color("bd936e")
	neck_material.roughness = 1.0
	neck.material_override = neck_material
	add_child(neck)
	_add_part("torso", "hips", "spine2", 0.44, 0.0)
	_add_part("helmet", "head", "", 0.31, 0.25)
	for side: String in ["left", "right"]:
		_add_part("sleeve", side + "_upper_arm", side + "_forearm", 0.16, 0.0)
		_add_part("forearm", side + "_forearm", side + "_hand", 0.135, 0.0)
		_add_part("thigh", side + "_upper_leg", side + "_lower_leg", 0.19, 0.0)
		_add_part("shin", side + "_lower_leg", side + "_foot", 0.15, 0.0)
		_add_part("boot", side + "_foot", "", 0.16, 0.20)
		var glove := MeshInstance3D.new()
		var glove_mesh := SphereMesh.new()
		glove_mesh.radius = 0.045
		glove_mesh.height = 0.09
		glove.mesh = glove_mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("282b2a")
		material.roughness = 1.0
		glove.material_override = material
		add_child(glove)
		gloves[bone_ids[side + "_hand"]] = glove
	_refresh_textures(false)
	mounted_visual = Sprite3D.new()
	mounted_visual.name = "MountedSilhouette"
	mounted_visual.set_script(preload("res://demo/scripts/mounted_rider_visual.gd"))
	mounted_visual.set("rider", self)
	add_child(mounted_visual)

func _add_part(kind: String, start: String, end: String, width: float, length: float) -> void:
	var sprite := Sprite3D.new()
	sprite.name = kind.capitalize() + start.capitalize()
	sprite.shaded = true
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	add_child(sprite)
	parts.append({"sprite": sprite, "kind": kind, "key": kind if kind in ["helmet", "torso"] else kind + "_" + start.get_slice("_", 0), "horizontal": false, "start": bone_ids[start], "end": bone_ids.get(end, -1), "width": width, "length": length})

func mount(target: DemoMotorcycle) -> void:
	bike = target
	simulator.physical_bones_stop_simulation()
	simulator.active = false
	var total_mass: float = 0.0
	for bone: PhysicalBone3D in simulator.get_children(): total_mass += bone.mass
	for bone: PhysicalBone3D in simulator.get_children(): bone.mass *= bike.profile.rider_mass_kg / maxf(total_mass, 0.01)
	ragdoll_active = false
	attack = ""
	attack_time = 0.0
	flight_time = 0.0
	top_level = false
	transform = Transform3D.IDENTITY
	_pose_mounted(0.0)
	reset_physics_interpolation()

func cycle_outfit(slot: String) -> void:
	if slot not in ["helmet", "jacket", "pants", "boots"]:
		return
	set(slot, (int(get(slot)) + 1) % 2)
	var config := ConfigFile.new()
	for key: String in ["helmet", "jacket", "pants", "boots"]:
		config.set_value("outfit", key, get(key))
	config.save("user://rider_outfit.cfg")
	_refresh_textures(last_side_view)
	outfit_changed.emit()

func _load_outfit() -> void:
	var config := ConfigFile.new()
	if config.load("user://rider_outfit.cfg") == OK:
		for key: String in ["helmet", "jacket", "pants", "boots"]:
			set(key, clampi(int(config.get_value("outfit", key, 0)), 0, 1))

func start_attack(kind: String, side: float) -> void:
	if ragdoll_active or not attack.is_empty() or kind not in ["punch", "kick"]:
		return
	attack = kind
	attack_side = signf(side)
	attack_time = 0.0
	attack_duration = 0.65 if kind == "punch" else 0.85
	attack_hits.clear()

func _physics_process(delta: float) -> void:
	if bike == null:
		return
	if ragdoll_active:
		flight_time += delta
		return
	if not attack.is_empty():
		attack_time += delta
		if attack_time >= attack_duration:
			attack = ""
	_pose_mounted(delta)
	if not attack.is_empty() and attack_time / attack_duration > 0.3 and attack_time / attack_duration < 0.65:
		_check_attack_contact()

func _joint(a: Vector3, b: Vector3, first: float, second: float, bend: Vector3) -> Vector3:
	var direction: Vector3 = (b - a).normalized()
	var distance: float = clampf(a.distance_to(b), 0.01, first + second - 0.001)
	var along: float = (first * first - second * second + distance * distance) / (2.0 * distance)
	var perpendicular: Vector3 = (bend - direction * bend.dot(direction)).normalized()
	return a + direction * along + perpendicular * sqrt(maxf(0.0, first * first - along * along))

func _pose_mounted(_delta: float) -> void:
	if bike == null:
		return
	rotation.z = -bike.visual_lean
	if bike.impact_time > 0.0 and not bike.severe_impact:
		rotation.z += bike.impact_direction * sin((bike.impact_duration - bike.impact_time) / bike.impact_duration * PI) * 0.12
	position.y = bike.dynamics.suspension
	var hips: Vector3 = bike.profile.seat_anchor
	var pitch: float = clampf(-bike.dynamics.acceleration * 0.004, -0.035, 0.04)
	var chest: Vector3 = hips + Vector3(0, 0.38, -0.16 + pitch)
	var points: Dictionary = {"hips": hips, "spine": hips.lerp(chest, 0.3), "spine1": hips.lerp(chest, 0.6), "spine2": chest, "head": chest + Vector3(0, 0.18, -0.025)}
	var extension: float = 0.0
	if not attack.is_empty():
		var t: float = attack_time / attack_duration
		extension = smoothstep(0.08, 0.4, t) * (1.0 - smoothstep(0.5, 1.0, t))
		chest.x += attack_side * extension * 0.035
		points.spine = hips.lerp(chest, 0.3)
		points.spine1 = hips.lerp(chest, 0.6)
		points.spine2 = chest
		points.head = chest + Vector3(0, 0.18, -0.025)
	for side: String in ["left", "right"]:
		var sign_side: float = -1.0 if side == "left" else 1.0
		var shoulder: Vector3 = chest + Vector3(sign_side * 0.16, 0.06, 0)
		var upper_arm: Vector3 = shoulder + Vector3(sign_side * 0.08, 0, 0)
		var hand: Vector3 = bike.profile.handlebar_anchor * Vector3(sign_side, 1, 1)
		var hip: Vector3 = hips + Vector3(sign_side * 0.13, -0.02, 0)
		var foot: Vector3 = bike.profile.footpeg_anchor * Vector3(sign_side, 1, 1)
		if sign_side == attack_side:
			if attack == "punch":
				hand = hand.lerp(upper_arm + Vector3(sign_side * 0.52, -0.03, -0.04), extension)
			elif attack == "kick":
				foot = foot.lerp(hip + Vector3(sign_side * 0.77, -0.04, -0.03), extension)
		points[side + "_shoulder"] = shoulder
		points[side + "_upper_arm"] = upper_arm
		points[side + "_forearm"] = _joint(upper_arm, hand, 0.28, 0.27, Vector3(sign_side, -0.4, 0.2))
		points[side + "_hand"] = hand
		points[side + "_upper_leg"] = hip
		points[side + "_lower_leg"] = _joint(hip, foot, 0.4, 0.4, Vector3(sign_side * 0.4, 0.1, -1.0))
		points[side + "_foot"] = foot
	var globals: Array[Transform3D] = []
	for i in range(skeleton.get_bone_count()):
		var name_bone: String = skeleton.get_bone_name(i)
		var origin: Vector3 = points[name_bone]
		var children: PackedInt32Array = skeleton.get_bone_children(i)
		var direction := Vector3.UP
		if not children.is_empty():
			direction = (Vector3(points[skeleton.get_bone_name(children[0])]) - origin).normalized()
		var desired := Transform3D(Basis(Quaternion(Vector3.UP, direction)), origin)
		globals.append(desired)
		var parent: int = skeleton.get_bone_parent(i)
		var local: Transform3D = globals[parent].affine_inverse() * desired if parent >= 0 else desired
		skeleton.set_bone_pose(i, local)

func launch(velocity: Vector3, contact_normal: Vector3, relative_speed: float) -> void:
	if ragdoll_active:
		return
	attack = ""
	var world: Transform3D = global_transform
	top_level = true
	global_transform = world
	ragdoll_active = true
	last_side_view = false
	_refresh_textures(false)
	simulator.active = true
	simulator.physical_bones_start_simulation()
	var rebound: Vector3 = contact_normal * minf(relative_speed * 0.08, 2.5)
	var launch_velocity: Vector3 = velocity * 0.8 + rebound + Vector3.UP * minf(relative_speed * 0.22, 7.0)
	for bone: PhysicalBone3D in simulator.get_children():
		bone.linear_velocity = launch_velocity
		bone.angular_velocity = global_basis.x * clampf(relative_speed * 0.06, 0.0, 2.0)

func focus_position() -> Vector3:
	return _bone_world(0).origin

func _bone_world(index: int) -> Transform3D:
	if ragdoll_active and physical_bones.has(index):
		var bone: PhysicalBone3D = physical_bones[index]
		return bone.global_transform * bone.body_offset.affine_inverse()
	return skeleton.global_transform * skeleton.get_bone_global_pose(index)

func _refresh_textures(side_view: bool) -> void:
	for part: Dictionary in parts:
		if ragdoll_active:
			var texture: AtlasTexture = RAGDOLL_PARTS.get_frame_texture(&"front" if side_view else &"back", RAGDOLL_KEYS.find(part.key))
			part.sprite.texture = texture
			part.horizontal = bool(texture.get_meta("horizontal", false))
			part.direction = float(texture.get_meta("direction", 1))
			part.sprite.pixel_size = float(part.width) / (texture.get_height() if part.horizontal else texture.get_width())
			var material: ShaderMaterial = part.sprite.material_override
			if material == null:
				material = ShaderMaterial.new()
				material.shader = preload("res://demo/shaders/rider_outfit.gdshader")
				part.sprite.material_override = material
			material.set_shader_parameter("source", texture.atlas)
			material.set_shader_parameter("boots_start_y", 0.0 if part.kind == "boot" else 1.0)
			for slot: String in ["helmet", "jacket", "pants", "boots"]:
				material.set_shader_parameter(slot, get(slot))
			continue
		part.sprite.material_override = null
		part.horizontal = false
		var index: int = 0
		match part.kind:
			"helmet": index = helmet + (2 if side_view else 0)
			"torso": index = 4 + jacket + (2 if side_view else 0)
			"sleeve": index = 8 + jacket
			"forearm": index = 10 + jacket
			"thigh", "shin": index = 12 + pants + (2 if side_view else 0)
			"boot": index = 16 + boots + (2 if side_view else 0)
		var texture: AtlasTexture = PARTS.get_frame_texture(&"parts", index)
		if part.kind in ["thigh", "shin"]:
			texture = texture.duplicate()
			var region: Rect2 = texture.region
			if part.kind == "shin": region.position.y += region.size.y * 0.48
			region.size.y *= 0.52
			texture.region = region
		part.sprite.texture = texture
		part.sprite.pixel_size = float(part.width) / texture.get_width()

var last_side_view: bool = false
func _process(_delta: float) -> void:
	for part: Dictionary in parts:
		part.sprite.visible = ragdoll_active
	for glove: MeshInstance3D in gloves.values():
		glove.visible = false
	neck.visible = ragdoll_active
	if not ragdoll_active:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or parts.is_empty():
		return
	var relative_camera: Vector3 = global_basis.inverse() * (camera.global_position - focus_position())
	var chest: Transform3D = _bone_world(bone_ids.spine2)
	var side_view: bool = chest.basis.z.dot(camera.global_position - chest.origin) < 0.0
	if side_view != last_side_view:
		last_side_view = side_view
		_refresh_textures(side_view)
	for part: Dictionary in parts:
		var a: Transform3D = _bone_world(part.start)
		var end: Vector3 = _bone_world(part.end).origin if part.end >= 0 else a.origin + a.basis.y * float(part.length)
		if part.kind == "forearm":
			end += (end - a.origin).normalized() * 0.06
		if part.kind in ["helmet", "boot"]:
			end = a.origin + a.basis.y * float(part.length) * 0.5
			a.origin -= a.basis.y * float(part.length) * 0.5
		var up: Vector3 = (end - a.origin).normalized()
		if part.kind in ["thigh", "shin"]:
			up = -up
		var center: Vector3 = (a.origin + end) * 0.5
		var facing: Vector3 = camera.global_position - center
		facing = (facing - up * facing.dot(up)).normalized()
		if facing.length_squared() < 0.01: facing = camera.global_basis.z
		var right: Vector3 = up.cross(facing).normalized()
		if part.horizontal:
			part.sprite.global_transform = Transform3D(Basis(up * part.direction, -right * part.direction, right.cross(up)), center)
			var natural_length: float = part.sprite.texture.get_width() * part.sprite.pixel_size
			part.sprite.scale.x = maxf(0.05, a.origin.distance_to(end)) / maxf(natural_length, 0.001)
		else:
			part.sprite.global_transform = Transform3D(Basis(right, up, right.cross(up)), center)
			var natural_height: float = part.sprite.texture.get_height() * part.sprite.pixel_size
			part.sprite.scale.y = maxf(0.05, a.origin.distance_to(end)) / maxf(natural_height, 0.001)
		part.sprite.flip_h = false
	for index: int in gloves:
		gloves[index].global_position = _bone_world(index).origin
	var chest_frame: Transform3D = _bone_world(bone_ids.spine2)
	neck.global_transform = chest_frame
	neck.global_position += chest_frame.basis.y * 0.08

func _check_attack_contact() -> void:
	var endpoint: String = ("left" if attack_side < 0 else "right") + ("_hand" if attack == "punch" else "_foot")
	var location: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(bone_ids[endpoint]).origin
	var shape := SphereShape3D.new()
	shape.radius = 0.18
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = location
	query.collision_mask = 2
	for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 8):
		var target: Object = hit.collider
		if target.get_instance_id() not in attack_hits:
			attack_hits.append(target.get_instance_id())
			if target.get_parent().has_method("receive_attack"):
				target.get_parent().receive_attack(attack, attack_side)
