extends Sprite3D
const FRAMES = preload("res://demo/resources/motorcycles_separate.tres")
var bike: DemoMotorcycle
var free_body: RigidBody3D
var wheel_material: ShaderMaterial
var rear_overlay: Sprite3D
var overlay_material: ShaderMaterial

func _ready() -> void:
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	shaded = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	wheel_material = ShaderMaterial.new()
	wheel_material.shader = preload("res://demo/shaders/bike_wheels.gdshader")
	rear_overlay = Sprite3D.new()
	rear_overlay.name = "RearFenderOcclusion"
	rear_overlay.texture_filter = texture_filter
	rear_overlay.alpha_cut = alpha_cut
	rear_overlay.shaded = true
	rear_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overlay_material = wheel_material.duplicate()
	overlay_material.set_shader_parameter("rear_occlusion_only", true)
	rear_overlay.material_override = overlay_material
	add_child(rear_overlay)

func _process(_delta: float) -> void:
	if bike == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var frame: Transform3D = free_body.global_transform if free_body != null else bike.global_transform
	if free_body != null:
		frame.origin -= frame.basis.y * 0.4
	var relative: Vector3 = frame.basis.inverse() * (camera.global_position - frame.origin)
	var angle: float = absf(atan2(relative.x, relative.z))
	var view: int = 1 if angle > PI * 0.25 and angle < PI * 0.75 else (2 if angle >= PI * 0.75 else 0)
	texture = FRAMES.get_frame_texture(&"bikes", bike.bike_index * 3 + view)
	if bike.profile.visual_frames != null:
		var animation: StringName = [&"rear", &"side", &"front"][view]
		var frames: SpriteFrames = bike.profile.visual_frames
		texture = frames.get_frame_texture(animation, floori(bike.wheel_phase * frames.get_frame_count(animation)))
	flip_h = view == 1 and relative.x > 0.0
	var height: float = bike.profile.visual_height_m
	pixel_size = height / texture.get_height()
	if texture is AtlasTexture:
		wheel_material.set_shader_parameter("source", texture.atlas)
		wheel_material.set_shader_parameter("atlas_size", Vector2(texture.atlas.get_size()))
		wheel_material.set_shader_parameter("region", Vector4(texture.region.position.x, texture.region.position.y, texture.region.size.x, texture.region.size.y))
		wheel_material.set_shader_parameter("wheel_phase", bike.wheel_phase)
		wheel_material.set_shader_parameter("view", view)
		material_override = wheel_material
	else:
		material_override = null
	var up: Vector3 = frame.basis.y if free_body != null else bike.character.global_basis.y
	if free_body == null:
		frame.origin = bike.character.global_position
	var center: Vector3 = frame.origin + up * height * 0.5
	var facing: Vector3 = camera.global_position - center
	facing = (facing - up * facing.dot(up)).normalized()
	var right: Vector3 = up.cross(facing).normalized()
	global_transform = Transform3D(Basis(right, up, right.cross(up)), center)
	rear_overlay.visible = free_body == null and view == 0 and texture is AtlasTexture
	if rear_overlay.visible:
		rear_overlay.texture = texture
		rear_overlay.pixel_size = pixel_size
		rear_overlay.global_transform = global_transform
		rear_overlay.global_position += facing * 0.05
		for parameter: String in ["source", "atlas_size", "region", "wheel_phase", "view"]:
			overlay_material.set_shader_parameter(parameter, wheel_material.get_shader_parameter(parameter))
		overlay_material.set_shader_parameter("seat_cut_y", 1.0 - bike.profile.seat_anchor.y / height)

func crash(velocity: Vector3, normal: Vector3) -> void:
	if free_body != null:
		return
	free_body = RigidBody3D.new()
	free_body.name = "FallenMotorcycle"
	free_body.mass = bike.profile.mass_kg
	free_body.collision_layer = 8
	free_body.collision_mask = 3
	free_body.continuous_cd = true
	free_body.linear_damp = 0.2
	free_body.angular_damp = 0.6
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.48, 0.65, bike.profile.wheelbase_m + 0.3)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	free_body.add_child(collider)
	bike.get_parent().add_child(free_body)
	free_body.global_transform = bike.global_transform
	free_body.position.y += 0.40
	free_body.linear_velocity = velocity * 0.35 + normal
	free_body.angular_velocity = bike.global_basis.z * 2.0

func reset_body() -> void:
	if is_instance_valid(free_body):
		free_body.queue_free()
	free_body = null
