class_name DemoChaseCamera
extends Camera3D

@export var follow_distance: float = 6.8
@export var follow_height: float = 2.7
@export var smoothing: float = 8.0
var rider: DemoMotorcycle
var track: DemoTrack
var shake_time: float = 0.0
var shake_strength: float = 0.0
var speed_visual_strength: float = 0.65


func setup(target: DemoMotorcycle, road: DemoTrack) -> void:
	rider = target
	track = road
	snap_to_rider()


func snap_to_rider() -> void:
	shake_time = 0.0
	fov = 55.0
	global_transform = _desired_transform()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if rider == null:
		return
	var desired: Transform3D = _desired_transform()
	fov = lerpf(fov, 55.0 + smoothstep(10.0, 38.0, rider.speed) * 4.0 * speed_visual_strength, 1.0 - exp(-3.0 * delta))
	shake_time = maxf(0.0, shake_time - delta)
	if shake_time > 0.0:
		desired.origin += desired.basis.x * sin(shake_time * 67.0) * shake_strength * shake_time / 0.35
		desired.origin += Vector3.UP * cos(shake_time * 53.0) * shake_strength * shake_time / 0.35
	global_transform = global_transform.interpolate_with(desired, 1.0 - exp(-smoothing * delta))


func jolt(relative_speed: float) -> void:
	shake_time = 0.35
	shake_strength = clampf(relative_speed * 0.003, 0.03, 0.14)


func _desired_transform() -> Transform3D:
	var frame: Transform3D = track.frame_at(rider.start_distance + rider.traveled)
	if rider.character.ragdoll_active:
		var focus: Vector3 = rider.character.focus_position()
		var crash_origin: Vector3 = focus + frame.basis.z * 7.5 + Vector3.UP * 3.5
		return Transform3D(Basis.looking_at(focus - crash_origin, Vector3.UP), crash_origin)
	var forward: Vector3 = -frame.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var origin: Vector3 = rider.global_position - forward * follow_distance + Vector3.UP * follow_height
	var aim: Vector3 = track.frame_at(rider.start_distance + rider.traveled + 12.0).origin
	aim += frame.basis.x * rider.lateral * 0.3 + Vector3.UP * 0.8
	return Transform3D(Basis.looking_at(aim - origin, Vector3.UP), origin)
