extends SceneTree

var failures: int = 0
const CLASSIC: MotorcycleSpec = preload("res://demo/resources/bikes/classic_350.tres")
const LIGHT: MotorcycleSpec = preload("res://demo/resources/bikes/light_175.tres")
const TOURING: MotorcycleSpec = preload("res://demo/resources/bikes/touring_650.tres")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _model(profile: MotorcycleSpec) -> MotorcycleDynamics:
	var model := MotorcycleDynamics.new()
	model.configure(profile)
	return model


func _run_for(model: MotorcycleDynamics, seconds: float, throttle: float, brake: float = 0.0, steer: float = 0.0, grass: bool = false, rear: float = 0.0, step: float = 1.0 / 120.0) -> float:
	var distance: float = 0.0
	for i in range(roundi(seconds / step)):
		model.step(throttle, brake, rear, steer, step, 0.0, 0.0, grass)
		distance += model.distance_step
	return distance


func _initialize() -> void:
	var basic: MotorcycleDynamics = _model(CLASSIC)
	var light: MotorcycleDynamics = _model(LIGHT)
	var touring: MotorcycleDynamics = _model(TOURING)
	_check(CLASSIC.valid() and LIGHT.valid() and TOURING.valid(), "All motorcycle templates must have valid SI parameters")
	_run_for(basic, 12.0, 1.0)
	_run_for(light, 12.0, 1.0)
	_run_for(touring, 12.0, 1.0)
	print("12s acceleration km/h: ", light.speed * 3.6, " / ", basic.speed * 3.6, " / ", touring.speed * 3.6)
	_check(light.speed < basic.speed and basic.speed < touring.speed, "Torque and mass profiles must change acceleration")
	_check(basic.gear > 1 and basic.rpm < CLASSIC.redline_rpm * 1.1, "Automatic shifting must control engine speed")
	var heavy_profile: MotorcycleSpec = CLASSIC.duplicate(true)
	heavy_profile.mass_kg *= 2.0
	var heavy: MotorcycleDynamics = _model(heavy_profile)
	basic.reset()
	_run_for(basic, 3.0, 1.0)
	_run_for(heavy, 3.0, 1.0)
	_check(heavy.speed < basic.speed * 0.85, "Additional mass must reduce acceleration with the same engine")
	var drag_profile: MotorcycleSpec = CLASSIC.duplicate(true)
	drag_profile.drag_area_m2 *= 2.0
	var drag: MotorcycleDynamics = _model(drag_profile)
	basic.reset()
	_run_for(basic, 80.0, 1.0)
	_run_for(drag, 80.0, 1.0)
	_check(drag.speed < basic.speed * 0.9, "Aerodynamic drag must set a physical attainable speed")
	var dry: MotorcycleDynamics = _model(TOURING)
	var grass: MotorcycleDynamics = _model(TOURING)
	dry.speed = 20.0
	grass.speed = 20.0
	var dry_stop: float = _run_for(dry, 8.0, 0.0, 1.0, 0.0, false, 1.0)
	var grass_stop: float = _run_for(grass, 8.0, 0.0, 1.0, 0.0, true, 1.0)
	_check(dry.speed < 0.1 and grass.speed < 0.1 and grass_stop > dry_stop * 1.5, "Lower surface grip must lengthen stopping distance")
	var turning: MotorcycleDynamics = _model(CLASSIC)
	turning.speed = 20.0
	_run_for(turning, 0.15, 1.0, 0.0, 0.5)
	_check(turning.lean > 0.02 and turning.heading > 0.005, "Steering must establish roll and yaw rather than lateral translation")

	_run_for(turning, 6.0, 0.35)
	_check(absf(turning.heading) < 0.002 and absf(turning.lean) < 0.02, "Releasing steering must arrest sideways motion and stabilize the chosen lane")
	var settled_lane: float = turning.lateral_position
	_run_for(turning, 3.0, 0.35)
	_check(absf(turning.lateral_position - settled_lane) < 0.05, "Released steering must not keep drifting across lanes")
	for profile: MotorcycleSpec in [CLASSIC, LIGHT, TOURING]:
		var follow: MotorcycleDynamics = _model(profile)
		follow.speed = 18.0
		for i in range(2400):
			follow.speed = 18.0
			follow.step(0.35, 0.0, 0.0, 0.0, 1.0 / 120.0, sin(i / 360.0) * 0.012)
		_check(absf(follow.lateral_position) < 0.4 and follow.instability_time < 0.1, "All profiles must hold their lane through ordinary road curves without input")
	turning.reset()
	turning.speed = 20.0
	_run_for(turning, 0.8, 0.35, 0.0, 0.7)
	var dry_usage: float = turning.grip_usage
	for i in range(24):
		turning.step(0.0, 1.0, 1.0, 0.7, 1.0 / 120.0, 0.018, 0.0, true)
	_check(turning.grip_usage > dry_usage * 1.5 and turning.instability_time > 0.0, "Braking while leaned on grass must consume cornering grip and destabilize the bike")
	basic.reset()
	basic.speed = 15.0
	basic.step(0.0, 1.0, 0.0, 0.0, 1.0 / 120.0)
	_check(basic.front_locked, "An old motorcycle without ABS must allow front wheel lock")
	var front_static: float = CLASSIC.mass() * 9.81 * CLASSIC.front_weight_fraction
	basic.step(0.0, 1.0, 0.0, 0.0, 1.0 / 120.0)
	_check(basic.front_load > front_static, "Braking must transfer normal load to the front wheel")
	var stable60: MotorcycleDynamics = _model(CLASSIC)
	var stable120: MotorcycleDynamics = _model(CLASSIC)
	_run_for(stable60, 5.0, 1.0, 0.0, 0.1, false, 0.0, 1.0 / 60.0)
	_run_for(stable120, 5.0, 1.0, 0.0, 0.1)
	_check(absf(stable60.speed - stable120.speed) < 0.3 and absf(stable60.lean - stable120.lean) < 0.01, "The physical model must remain stable across tick rates")
	for profile: MotorcycleSpec in [CLASSIC, LIGHT, TOURING]:
		var response: MotorcycleDynamics = _model(profile)
		response.speed = 18.0
		_run_for(response, 0.1, 1.0, 0.0, 1.0)
		_check(response.steering_command > 0.99 and response.lateral_position > 0.02, "Steering must respond visibly within 100 ms at full throttle on every bike")
		_run_for(response, 0.8, 1.0, 0.0, 1.0)
		_run_for(response, 0.45, 1.0, 0.0, -1.0)
		_check(response.heading < -0.02, "Opposite steering must reverse lateral motion within 450 ms at full throttle")
		var release_lane: float = response.lateral_position
		_run_for(response, 1.0, 1.0)
		_check(absf(response.lateral_position - release_lane) < 0.8 and absf(response.speed * sin(response.heading)) < 0.15, "Released input must stop lateral motion without target windup")
	for entry_speed: float in [3.0, 5.0, 12.0, 25.0]:
		var weave: MotorcycleDynamics = _model(CLASSIC)
		weave.speed = entry_speed
		var sideways: float = 0.0
		for i in range(240):
			var previous_heading: float = weave.heading
			var previous_lean: float = weave.lean
			weave.step(0.35, 0.0, 0.0, 1.0 if (i + 24) % 96 < 48 else -1.0, 1.0 / 120.0)
			sideways += weave.lateral_step
			_check(absf(weave.lean - previous_lean) <= deg_to_rad(85.0) / 120.0 + 0.0001, "Rapid key reversal must respect the roll rate")
			var yaw_acceleration: float = absf(weave.heading - previous_heading) * 120.0 * weave.speed
			_check(yaw_acceleration < 9.2, "Low-speed steering must not bypass the cornering acceleration limit")
		print("weave ",entry_speed," drift ",sideways)
		_check(absf(sideways) < 0.65, "Repeated quick A/D taps must not jump across a lane")
		weave.reset()
		_check(is_zero_approx(weave.steering_command), "Reset must clear smoothed steering input")
	basic.reset()
	basic.automatic = false
	basic.shift_remaining = 0.0
	basic.shift(1)
	_check(basic.gear == 2 and basic.shift_remaining > 0.0, "Manual shifts must select a real ratio and interrupt drive")
	basic.reset()
	_check(basic.gear == 1 and is_zero_approx(basic.speed) and is_zero_approx(basic.heading) and not basic.front_locked, "Reset must clear all dynamic state")
	print("MOTORCYCLE PHYSICS: %s | torque, mass, gears, drag, braking, load transfer, roll/yaw, grip, timestep, reset" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
