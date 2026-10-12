class_name DemoMotorcycle
extends Node3D
## Track coordinates locate the bike; a physical single-track model controls its motion.

const EngineSound = preload("res://demo/scripts/engine_sound.gd")
const TireEffects = preload("res://demo/scripts/tire_effects.gd")

signal telemetry_changed(speed_kmh: float, traveled: float, off_road: bool)
signal fall_started(speed_mps: float)

const BIKE_PROFILES: Array[MotorcycleSpec] = [preload("res://demo/resources/bikes/classic_350.tres"), preload("res://demo/resources/bikes/light_175.tres"), preload("res://demo/resources/bikes/touring_650.tres")]
@export var profile: MotorcycleSpec = preload("res://demo/resources/bikes/classic_350.tres")
var dynamics := MotorcycleDynamics.new()
var bike_index: int = 0

var track: DemoTrack
var speed: float = 0.0
var traveled: float = 0.0
var lateral: float = 0.0
var lateral_velocity: float = 0.0
var visual_lean: float = 0.0
var off_road: bool = false
var start_distance: float = 95.0
var wheel_phase: float = 0.0
var impact_time: float = 0.0
var impact_duration: float = 0.0
var impact_direction: float = -1.0
var severe_impact: bool = false
@onready var engine: EngineSound = $Engine
@onready var tire_effects: TireEffects = $TireEffects
@onready var character: RiderCharacter = $Character
@onready var bike_visual = $BikeVisual


func setup(road: DemoTrack) -> void:
	track = road
	dynamics.configure(profile)
	bike_visual.bike = self
	reset()


func reset() -> void:
	dynamics.reset()
	speed = 0.0
	traveled = 0.0
	lateral = 1.6
	lateral_velocity = 0.0
	visual_lean = 0.0
	off_road = false
	$ShadowGeometry.rotation.z = 0.0
	wheel_phase = 0.0
	impact_time = 0.0
	impact_duration = 0.0
	severe_impact = false
	$ShadowGeometry.scale = Vector3(0.8, 0.85, 0.8)
	tire_effects.clear()
	engine.road_speed = 0.0
	engine.throttle = 0.0
	engine.engine_rpm = profile.idle_rpm
	if track != null:
		_place_on_track()
	if character != null and track != null:
		character.mount(self)
		bike_visual.reset_body()
	$Shadow.visible = true
	$ShadowGeometry.visible = true
	reset_physics_interpolation()
	telemetry_changed.emit(0.0, traveled, off_road)


func _physics_process(delta: float) -> void:
	if track == null:
		return
	step_controls(Input.get_action_strength("accelerate"),
		Input.get_action_strength("brake"), Input.get_axis("steer_left", "steer_right"), delta, Input.get_action_strength("rear_brake"))


func step_controls(throttle: float, brake: float, steering: float, delta: float, rear_brake: float = 0.0) -> void:
	if track == null or delta <= 0.0:
		return
	if character.ragdoll_active:
		speed = 0.0
		engine.throttle = 0.0
		engine.engine_rpm = profile.idle_rpm
		telemetry_changed.emit(0.0, traveled, off_road)
		return
	impact_time = maxf(0.0, impact_time - delta)
	if impact_time > 0.0:
		throttle = 0.0
		if severe_impact:
			steering = 0.0
			speed = move_toward(speed, 0.0, 24.0 * delta)
	var steps: int = maxi(1, ceili(delta * 120.0))
	var step: float = delta / steps
	dynamics.speed = speed
	for i in range(steps):
		var frame: Transform3D = track.frame_at(start_distance + traveled)
		var ahead: Transform3D = track.frame_at(start_distance + traveled + 0.75)
		var forward: Vector3 = -frame.basis.z
		var next_forward: Vector3 = -ahead.basis.z
		var curvature: float = -atan2(forward.cross(next_forward).y, forward.dot(next_forward)) / 0.75
		off_road = absf(lateral) > track.road_width * 0.5 - 0.25
		var slope: float = atan2(ahead.origin.y - frame.origin.y, Vector2(ahead.origin.x - frame.origin.x, ahead.origin.z - frame.origin.z).length())
		dynamics.step(throttle, brake, rear_brake, steering, step, curvature, slope, off_road, lateral)
		traveled += dynamics.distance_step
		lateral += dynamics.lateral_step
		if severe_impact and impact_time > 0.0:
			dynamics.heading = move_toward(dynamics.heading, 0.0, step * 2.0)
			dynamics.lean = move_toward(dynamics.lean, 0.0, step * 2.0)
		# Track coordinates stop being reliable far from the road; recover with R.
		if absf(lateral) > 35.0:
			lateral = clampf(lateral, -35.0, 35.0)
			dynamics.speed = 0.0
			break
	speed = dynamics.speed
	lateral_velocity = speed * sin(dynamics.heading)
	off_road = absf(lateral) > track.road_width * 0.5 - 0.25
	if impact_time <= 0.0 and dynamics.instability_time > 0.45:
		fall_started.emit(speed)
		hit_traffic(maxf(29.0, speed), signf(dynamics.lean), lateral, 0.0, Vector3.ZERO, true)
		dynamics.instability_time = 0.0
	_place_on_track()
	_update_visuals(delta)
	var skid: float = 1.0 if dynamics.front_locked or dynamics.rear_locked or dynamics.rear_spinning or impact_time > 0.0 else 0.0
	tire_effects.update_contact(speed, skid, off_road, global_transform, delta)
	engine.road_speed = speed
	engine.engine_rpm = dynamics.rpm
	engine.throttle = throttle
	telemetry_changed.emit(speed * 3.6, traveled, off_road)


func cycle_bike() -> void:
	bike_index = (bike_index + 1) % BIKE_PROFILES.size()
	profile = BIKE_PROFILES[bike_index]
	dynamics.configure(profile)
	reset()


func hit_traffic(relative_speed: float, away: float, car_lateral: float, clearance: float, contact_normal: Vector3 = Vector3.ZERO, ground_fall: bool = false) -> void:
	if impact_time > 0.0:
		return
	var incoming_velocity: Vector3 = -global_basis.z * speed
	if contact_normal.is_zero_approx():
		contact_normal = global_basis.x * away
	severe_impact = relative_speed > 14.0
	if severe_impact:
		character.launch(incoming_velocity, contact_normal, 0.0 if ground_fall else relative_speed)
		bike_visual.crash(incoming_velocity, contact_normal)
		$Shadow.visible = false
		$ShadowGeometry.visible = false
	speed *= 0.22 if severe_impact else 0.45
	impact_duration = 9999.0 if severe_impact else 0.8
	impact_time = impact_duration
	impact_direction = away
	dynamics.heading *= 0.35
	dynamics.lean_rate = 0.0
	tire_effects.impact()
	if clearance > 0.0:
		lateral = car_lateral + away * (clearance + 0.12)
		dynamics.lane_target = lateral
	lateral_velocity = away * 2.5
	off_road = absf(lateral) > track.road_width * 0.5 - 0.25
	_place_on_track()
	telemetry_changed.emit(speed * 3.6, traveled, off_road)


func _update_visuals(delta) -> void:
	var wheel_speed: float = 0.0 if dynamics.rear_locked else speed
	if dynamics.rear_spinning:
		var ratio: float = profile.gear_ratios[dynamics.gear - 1] * profile.primary_ratio * profile.final_drive_ratio
		wheel_speed = maxf(wheel_speed, dynamics.rpm / ratio / 60.0 * TAU * profile.wheel_radius_m)
	wheel_phase = fposmod(wheel_phase + wheel_speed * delta / (TAU * profile.wheel_radius_m), 1.0)
	var target: float = clampf(dynamics.lean * 0.45, -deg_to_rad(18.0), deg_to_rad(18.0))
	visual_lean = lerpf(visual_lean, target, 1.0 - exp(-delta * 12.0))
	$ShadowGeometry.rotation.z = -visual_lean



func _place_on_track() -> void:
	var frame: Transform3D = track.frame_at(start_distance + traveled)
	frame.origin += frame.basis.x * lateral + Vector3.UP * 0.04
	frame.basis = frame.basis.rotated(Vector3.UP, -dynamics.heading)
	global_transform = frame
