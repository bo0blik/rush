class_name MotorcycleDynamics
extends RefCounted
## Reduced single-track model: longitudinal forces, roll, tire friction and relative yaw.

const G: float = 9.81
const AIR_DENSITY: float = 1.225
var spec: MotorcycleSpec
var speed: float = 0.0
var heading: float = 0.0
var lean: float = 0.0
var lean_rate: float = 0.0
var steering_angle: float = 0.0
var steering_command: float = 0.0
var gear: int = 1
var rpm: float = 1100.0
var automatic: bool = true
var shift_remaining: float = 0.0
var acceleration: float = 0.0
var lateral_acceleration: float = 0.0
var grip_usage: float = 0.0
var front_locked: bool = false
var rear_locked: bool = false
var rear_spinning: bool = false
var front_load: float = 0.0
var suspension: float = 0.0
var suspension_velocity: float = 0.0
var instability_time: float = 0.0
var distance_step: float = 0.0
var lateral_step: float = 0.0
var ground_distance: float = 0.0
var lateral_position: float = 0.0
var lane_target: float = 0.0
var lane_initialized: bool = false


func configure(profile: MotorcycleSpec) -> void:
	assert(profile != null and profile.valid(), "Motorcycle profile requires valid physical dimensions and drivetrain")
	spec = profile
	reset()


func reset() -> void:
	speed = 0.0
	heading = 0.0
	lean = 0.0
	lean_rate = 0.0
	steering_angle = 0.0
	steering_command = 0.0
	gear = 1
	rpm = spec.idle_rpm if spec != null else 1100.0
	shift_remaining = 0.0
	acceleration = 0.0
	lateral_acceleration = 0.0
	grip_usage = 0.0
	front_locked = false
	rear_locked = false
	rear_spinning = false
	suspension = 0.0
	suspension_velocity = 0.0
	instability_time = 0.0
	distance_step = 0.0
	lateral_step = 0.0
	ground_distance = 0.0
	lateral_position = 0.0
	lane_target = 0.0
	lane_initialized = false


func shift(direction: int) -> void:
	if shift_remaining > 0.0:
		return
	var next: int = clampi(gear + direction, 1, spec.gear_ratios.size())
	if next != gear:
		gear = next
		shift_remaining = spec.shift_time_s


func step(throttle: float, front_brake: float, rear_brake: float, steering: float,
		delta: float, road_curvature: float = 0.0, slope: float = 0.0, grass: bool = false, lateral_offset: float = NAN) -> void:
	if delta <= 0.0:
		return
	throttle = clampf(throttle, 0.0, 1.0)
	front_brake = clampf(front_brake, 0.0, 1.0)
	rear_brake = clampf(rear_brake, 0.0, 1.0)
	steering = clampf(steering, -1.0, 1.0)
	if not is_nan(lateral_offset):
		lateral_position = lateral_offset
	if not lane_initialized:
		lane_target = lateral_position
		lane_initialized = true
	shift_remaining = maxf(0.0, shift_remaining - delta)
	var mass: float = spec.mass()
	var weight: float = mass * G * cos(slope)
	var grip: float = spec.grass_grip if grass else spec.asphalt_grip
	var transfer: float = mass * acceleration * spec.center_of_mass_height_m / spec.wheelbase_m
	front_load = clampf(weight * spec.front_weight_fraction - transfer, weight * 0.04, weight * 0.96)
	var rear_load: float = weight - front_load
	var front_capacity: float = grip * front_load
	var rear_capacity: float = grip * rear_load
	# Immediate keyboard intent; turning reserves tire grip before engine thrust.
	steering_command = steering
	var lane_speed: float = minf(2.7, speed * 0.25)
	var desired_heading: float = asin(clampf(steering * lane_speed / maxf(speed, 0.1), -0.25, 0.25))
	var correction: float = clampf((desired_heading - heading) * speed * 14.0, -9.0, 9.0)
	var turn_share: float = clampf(absf(road_curvature * speed * speed + correction) / maxf(grip * G, 0.1), 0.0, 0.95)
	var ratio: float = spec.gear_ratios[gear - 1] * spec.primary_ratio * spec.final_drive_ratio
	var wheel_rpm: float = speed / spec.wheel_radius_m * ratio * 60.0 / TAU
	if automatic:
		if wheel_rpm > spec.shift_up_rpm:
			shift(1)
		elif gear > 1 and wheel_rpm < spec.shift_down_rpm:
			shift(-1)
	ratio = spec.gear_ratios[gear - 1] * spec.primary_ratio * spec.final_drive_ratio
	wheel_rpm = speed / spec.wheel_radius_m * ratio * 60.0 / TAU
	# Automatic clutch permits keyboard launches; there is no engine-stall simulation.
	rpm = maxf(wheel_rpm, lerpf(spec.idle_rpm, spec.launch_rpm, throttle))
	var drive: float = spec.torque_at(rpm) * ratio * spec.transmission_efficiency / spec.wheel_radius_m * throttle
	if rpm >= spec.redline_rpm or shift_remaining > 0.0:
		drive = 0.0
	drive = minf(drive, rear_capacity * sqrt(1.0 - turn_share * turn_share))
	var engine_brake: float = spec.engine_braking_nm * ratio / spec.wheel_radius_m * (1.0 - throttle) * smoothstep(1.0, 5.0, speed)
	var requested_front: float = front_brake * spec.front_brake_force_n
	var requested_rear: float = rear_brake * spec.rear_brake_force_n + engine_brake
	front_locked = not spec.abs_enabled and speed > 2.0 and requested_front > front_capacity
	rear_locked = not spec.abs_enabled and speed > 2.0 and requested_rear > rear_capacity
	rear_spinning = drive > rear_capacity
	var front_force: float = -minf(requested_front, front_capacity) * (0.78 if front_locked else 1.0)
	var rear_force: float = clampf(drive - requested_rear, -rear_capacity, rear_capacity) * (0.78 if rear_locked else 1.0)
	var drag: float = 0.5 * AIR_DENSITY * spec.drag_area_m2 * speed * speed
	var rolling: float = weight * (0.08 if grass else spec.rolling_resistance) * smoothstep(0.0, 0.5, speed)
	var resistance: float = drag + rolling + mass * G * sin(slope)
	acceleration = (front_force + rear_force - resistance) / mass
	var old_speed: float = speed
	speed = maxf(0.0, speed + acceleration * delta)
	var average_speed: float = (old_speed + speed) * 0.5
	var max_lean: float = deg_to_rad(spec.max_lean_degrees)
	# Release requests zero sideways velocity, without a spring pulling to an old lane.
	lane_target = lateral_position
	var along_speed: float = average_speed * cos(heading) / maxf(0.35, 1.0 - road_curvature * lateral_position)
	var target_lateral: float = clampf(road_curvature * along_speed * average_speed + correction, -G * tan(max_lean), G * tan(max_lean))
	var target_lean: float = atan(target_lateral / G) * smoothstep(1.0, 7.0, speed)
	var inertia: float = mass * spec.center_of_mass_height_m * spec.center_of_mass_height_m * spec.roll_inertia_factor
	var frequency: float = sqrt(spec.roll_stiffness_nm / inertia)
	lean_rate += ((target_lean - lean) * frequency * frequency - 2.0 * spec.roll_damping_ratio * frequency * lean_rate) * delta
	lean_rate = clampf(lean_rate, -deg_to_rad(85.0), deg_to_rad(85.0))
	lean = clampf(lean + lean_rate * delta, -max_lean, max_lean)
	var bar_limit: float = deg_to_rad(spec.low_speed_steer_degrees)
	var target_bar: float = clampf(atan(spec.wheelbase_m * target_lateral / maxf(speed * speed, 0.1)), -bar_limit, bar_limit)
	steering_angle = move_toward(steering_angle, target_bar, deg_to_rad(90.0) * delta)
	# During steering transients the turn develops before the roll reaches equilibrium.
	var requested_lateral: float = target_lateral
	# Each tire spends one common grip budget on turning and longitudinal forces.
	var available_lateral: float = (sqrt(maxf(0.0, front_capacity * front_capacity - front_force * front_force)) + sqrt(maxf(0.0, rear_capacity * rear_capacity - rear_force * rear_force))) / mass
	if front_locked:
		available_lateral *= 0.35
	elif rear_locked:
		available_lateral *= 0.65
	if rear_spinning:
		available_lateral *= 0.8
	grip_usage = absf(requested_lateral) / maxf(available_lateral, 0.1)
	lateral_acceleration = clampf(requested_lateral, -available_lateral, available_lateral)
	var slow_lateral: float = average_speed * average_speed * tan(steering_angle) / spec.wheelbase_m
	var slow_yaw: float = clampf(slow_lateral, -available_lateral, available_lateral) / maxf(average_speed, 0.1)
	var fast_yaw: float = lateral_acceleration / maxf(average_speed, 1.0)
	var yaw_rate: float = lerpf(slow_yaw, fast_yaw, smoothstep(3.0, 7.0, average_speed))
	distance_step = along_speed * delta
	var relative_yaw: float = yaw_rate - road_curvature * along_speed
	lateral_step = average_speed * sin(heading + relative_yaw * delta * 0.5) * delta
	heading = wrapf(heading + yaw_rate * delta - road_curvature * distance_step, -PI, PI)
	lateral_position += lateral_step
	var risky: bool = average_speed > 6.0 and (grip_usage > 1.25 or (front_locked and absf(lean) > 0.12))
	instability_time = instability_time + delta if risky else maxf(0.0, instability_time - delta * 2.0)
	ground_distance += average_speed * delta
	var bump: float = (sin(ground_distance * 4.3) + sin(ground_distance * 9.1) * 0.4) * (0.015 if grass else 0.001)
	var target_suspension: float = clampf(-acceleration * 0.004 + bump, -spec.suspension_travel_m * 0.4, spec.suspension_travel_m * 0.4)
	var suspension_frequency: float = TAU * spec.suspension_frequency_hz
	suspension_velocity += ((target_suspension - suspension) * suspension_frequency * suspension_frequency - 2.0 * spec.suspension_damping_ratio * suspension_frequency * suspension_velocity) * delta
	suspension += suspension_velocity * delta
