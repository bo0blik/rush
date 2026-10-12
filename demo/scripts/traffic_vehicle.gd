extends Node3D
## Continuous camera-relative azimuth; source artwork keeps its natural aspect ratio.

const AtlasVisual = preload("res://demo/scripts/atlas_visual.gd")
@export var body_width: float = 1.75
@export var body_length: float = 4.2
@export var body_height: float = 1.5
var distance: float = 0.0
var lateral: float = 0.0
var speed: float = 14.0
var cruise_speed: float = 14.0
var direction: float = 1.0
var collision_cooldown: float = 0.0
var current_view: int = -1
var display_angle: float = 0.0
var wheel_phase: float = 0.0
var attack_reaction: float = 0.0
@onready var sprite: AtlasVisual = $Body


func _ready() -> void:
	var body := AnimatableBody3D.new()
	body.name = "PhysicsBody"
	body.collision_layer = 2
	body.collision_mask = 12
	body.sync_to_physics = false
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	var chassis_height: float = body_height * 0.55 if body_height < 2.0 else body_height
	shape.size = Vector3(body_width, chassis_height, body_length)
	collider.shape = shape
	collider.position.y = chassis_height * 0.5
	body.add_child(collider)
	if body_height < 2.0:
		var cabin := CollisionShape3D.new()
		var cabin_shape := BoxShape3D.new()
		cabin_shape.size = Vector3(body_width * 0.86, body_height - chassis_height, body_length * 0.46)
		cabin.shape = cabin_shape
		cabin.position.y = (chassis_height + body_height) * 0.5
		body.add_child(cabin)
	add_child(body)
	sprite.normalize_pose_height = true
	var reference: AtlasTexture = sprite.sprite_frames.get_frame_texture(sprite.reference_animation, 0)
	sprite.reference_width = body_width
	sprite.reference_height = maxf(body_height, body_width * (reference.region.size.y - 2.0) / (reference.region.size.x - 2.0))
	var shadow_mesh := BoxMesh.new()
	shadow_mesh.size = Vector3(body_width * 0.9, body_height * 0.85, body_length * 0.85)
	$ShadowVolume.mesh = shadow_mesh
	$ShadowVolume.position.y = body_height * 0.45
	var contact_mesh := PlaneMesh.new()
	contact_mesh.size = Vector2(body_width * 1.3, body_length * 1.1)
	$ContactShadow.mesh = contact_mesh


func place(track: DemoTrack, camera: Camera3D, delta: float = 0.0) -> void:
	var road_frame: Transform3D = track.frame_at(distance)
	road_frame.origin += road_frame.basis.x * lateral + Vector3.UP * 0.04
	if direction < 0.0:
		road_frame.basis = road_frame.basis.rotated(Vector3.UP, PI)
	global_transform = road_frame
	var toward_camera: Vector3 = road_frame.basis.inverse() * (camera.global_position - global_position)
	var target_angle: float = atan2(toward_camera.x, toward_camera.z)
	display_angle = lerp_angle(display_angle, target_angle, 1.0 - exp(-10.0 * delta)) if delta > 0.0 and current_view >= 0 else target_angle
	var degrees: float = absf(rad_to_deg(wrapf(display_angle, -PI, PI)))
	current_view = 3 if degrees > 90.0 else 0
	wheel_phase = fposmod(distance / 8.0, 1.0) * 6.0
	var rolling: StringName = &"front_drive" if degrees > 90.0 else &"rear_drive"
	var straight_angle: float = minf(degrees, 180.0 - degrees)
	if straight_angle <= 8.0:
		sprite.set_pose(rolling, wheel_phase)
	else:
		# Every interval shares its endpoint with the next, including the pass at 90°.
		var poses: Array[AtlasTexture] = [
			sprite.sprite_frames.get_frame_texture(&"rear_drive", floori(wheel_phase)),
			sprite.sprite_frames.get_frame_texture(&"rear_angles", 0),
			sprite.sprite_frames.get_frame_texture(&"side_angles", 0),
			sprite.sprite_frames.get_frame_texture(&"side_angles", 1),
			sprite.sprite_frames.get_frame_texture(&"side_angles", 2),
			sprite.sprite_frames.get_frame_texture(&"front_angles", 0),
			sprite.sprite_frames.get_frame_texture(&"front_drive", floori(wheel_phase))]
		var angles: Array[float] = [8.0, 45.0, 60.0, 90.0, 120.0, 135.0, 172.0]
		for i in range(angles.size() - 1):
			if degrees <= angles[i + 1]:
				var blend: float = smoothstep(angles[i], angles[i + 1], degrees)
				sprite.set_pair(poses[i], poses[i + 1], blend, wrapf(display_angle, -PI, PI) > 0.0)
				break
		sprite.animation = &"side_angles" if degrees >= 60.0 and degrees <= 120.0 else (&"front_angles" if degrees > 90.0 else &"rear_angles")
	sprite.material.set_shader_parameter("suspension", sin(distance * 1.4) * 0.012)
	attack_reaction = move_toward(attack_reaction, 0.0, delta * 3.0)
	sprite.material.set_shader_parameter("tint", Color(1.0, 1.0 - attack_reaction * 0.3, 1.0 - attack_reaction * 0.3))

func receive_attack(kind: String, _side: float) -> void:
	attack_reaction = 1.0
	speed = maxf(0.0, speed - (0.7 if kind == "kick" else 0.3))
