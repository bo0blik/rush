extends Sprite3D
## Authored connected silhouettes share the motorcycle's roll plane and seat anchor.
const FRAMES = preload("res://demo/resources/rider_mounted.tres")
var rider: RiderCharacter
var outfit_material: ShaderMaterial
var riding_pose: int = 0
var pending_pose: int = 0
var pending_pose_time: float = 0.0

func _ready() -> void:
	shaded = true
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	outfit_material = ShaderMaterial.new()
	outfit_material.shader = preload("res://demo/shaders/rider_outfit.gdshader")
	material_override = outfit_material

func _process(delta: float) -> void:
	if rider == null or rider.bike == null:
		return
	visible = not rider.ragdoll_active
	if not visible:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var index: int = 0
	if rider.attack.is_empty():
		var requested: int = 1 if rider.bike.dynamics.acceleration > 1.5 else (2 if rider.bike.dynamics.acceleration < -2.0 else 0)
		if requested != pending_pose:
			pending_pose = requested
			pending_pose_time = 0.0
		pending_pose_time += delta
		# Short gear shifts must not flicker between three different silhouettes.
		if pending_pose_time >= 0.18:
			riding_pose = pending_pose
		index = riding_pose
	else:
		var phase: float = rider.attack_time / rider.attack_duration
		index = (3 if rider.attack == "punch" else 6) + (0 if phase < 0.25 else (1 if phase < 0.65 else 2))
	texture = FRAMES.get_frame_texture(&"poses", index)
	flip_h = not rider.attack.is_empty() and rider.attack_side > 0.0
	var anchor: Vector2 = texture.get_meta("seat")
	pixel_size = float(texture.get_meta("pixel_size"))
	var up: Vector3 = rider.global_basis.y.normalized()
	var bike: DemoMotorcycle = rider.bike
	var center: Vector3 = rider.global_position + up * (bike.profile.seat_anchor.y + (anchor.y - texture.get_height() * 0.5) * pixel_size)
	var facing: Vector3 = camera.global_position - (rider.global_position + up * bike.profile.visual_height_m * 0.5)
	facing = (facing - up * facing.dot(up)).normalized()
	var right: Vector3 = up.cross(facing).normalized()
	var offset_x: float = (texture.get_width() * 0.5 - anchor.x) * pixel_size
	center += right * (offset_x * (-1.0 if flip_h else 1.0))
	center += facing * 0.025
	global_transform = Transform3D(Basis(right, up, right.cross(up)), center)
	outfit_material.set_shader_parameter("source", texture.atlas)
	outfit_material.set_shader_parameter("boots_start_y", (texture.region.position.y + texture.region.size.y * 0.5) / texture.atlas.get_height())
	for slot: String in ["helmet", "jacket", "pants", "boots"]:
		outfit_material.set_shader_parameter(slot, rider.get(slot))
