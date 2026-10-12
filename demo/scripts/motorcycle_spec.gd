class_name MotorcycleSpec
extends Resource
## SI units; templates are tunable examples, not measured manufacturer specifications.

@export var display_name: String = "КЛАССИК 350"
@export var visual_frames: SpriteFrames
@export var visual_height_m: float = 1.12
@export var seat_anchor: Vector3 = Vector3(0, 0.82, 0.08)
@export var handlebar_anchor: Vector3 = Vector3(0.32, 1.0, -0.58)
@export var footpeg_anchor: Vector3 = Vector3(0.24, 0.32, -0.05)
@export var mass_kg: float = 168.0
@export var rider_mass_kg: float = 80.0
@export var wheelbase_m: float = 1.43
@export var body_width_m: float = 0.82
@export var wheel_radius_m: float = 0.32
@export var center_of_mass_height_m: float = 0.62
@export_range(0.25, 0.75) var front_weight_fraction: float = 0.47
@export var peak_torque_nm: float = 27.0
@export var torque_curve: Curve
@export var idle_rpm: float = 1100.0
@export var launch_rpm: float = 2900.0
@export var redline_rpm: float = 6500.0
@export var shift_up_rpm: float = 5700.0
@export var shift_down_rpm: float = 2400.0
@export var gear_ratios: PackedFloat32Array = PackedFloat32Array([2.8, 1.85, 1.35, 1.0])
@export var primary_ratio: float = 2.25
@export var final_drive_ratio: float = 2.8
@export var transmission_efficiency: float = 0.90
@export var shift_time_s: float = 0.18
@export var drag_area_m2: float = 0.62
@export var rolling_resistance: float = 0.018
@export var engine_braking_nm: float = 4.0
@export var asphalt_grip: float = 1.0
@export var grass_grip: float = 0.42
@export var front_brake_force_n: float = 2200.0
@export var rear_brake_force_n: float = 1000.0
@export var abs_enabled: bool = false
@export var max_lean_degrees: float = 42.0
@export var low_speed_steer_degrees: float = 28.0
@export var roll_stiffness_nm: float = 5000.0
@export var roll_inertia_factor: float = 0.75
@export var roll_damping_ratio: float = 0.95
@export var suspension_travel_m: float = 0.13
@export var suspension_frequency_hz: float = 2.0
@export var suspension_damping_ratio: float = 0.80


func valid() -> bool:
	if mass_kg <= 0.0 or rider_mass_kg <= 0.0 or wheelbase_m <= 0.0 or wheel_radius_m <= 0.0 or center_of_mass_height_m <= 0.0 or body_width_m <= 0.0:
		return false
	if peak_torque_nm <= 0.0 or redline_rpm <= idle_rpm or gear_ratios.is_empty() or primary_ratio <= 0.0 or final_drive_ratio <= 0.0:
		return false
	for ratio: float in gear_ratios:
		if ratio <= 0.0:
			return false
	if front_weight_fraction <= 0.0 or front_weight_fraction >= 1.0 or transmission_efficiency <= 0.0 or transmission_efficiency > 1.0:
		return false
	if asphalt_grip <= 0.0 or grass_grip <= 0.0 or max_lean_degrees <= 0.0 or max_lean_degrees >= 75.0 or visual_height_m <= 0.0:
		return false
	if roll_stiffness_nm <= 0.0 or roll_inertia_factor <= 0.0 or suspension_frequency_hz <= 0.0 or shift_time_s < 0.0:
		return false
	if front_brake_force_n <= 0.0 or rear_brake_force_n <= 0.0 or drag_area_m2 < 0.0 or rolling_resistance < 0.0 or engine_braking_nm < 0.0:
		return false
	if visual_frames != null:
		for animation: StringName in [&"rear", &"side", &"front"]:
			if not visual_frames.has_animation(animation) or visual_frames.get_frame_count(animation) < 1:
				return false
	return true


func mass() -> float:
	return mass_kg + rider_mass_kg


func torque_at(rpm: float) -> float:
	var ratio: float = clampf(rpm / redline_rpm, 0.0, 1.0)
	return peak_torque_nm * (torque_curve.sample_baked(ratio) if torque_curve != null else 1.0)
