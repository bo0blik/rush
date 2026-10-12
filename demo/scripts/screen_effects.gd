extends CanvasLayer
## A shared pixel grid and restrained acceleration streaks for the final frame.

signal graphics_changed(mode_name: String, index: int, motion_enabled: bool)
const MODES: Array[Dictionary] = [
	{"name": "ОРИГИНАЛ", "grid": Vector2(640, 480), "steps": 0.0, "dither": 0.0, "contrast": 1.0, "saturation": 1.0, "warmth": 0.0, "outline": 0.0, "vignette": 0.0, "motion": 0.0},
	{"name": "ЧИСТЫЙ ПИКСЕЛЬ", "grid": Vector2(320, 240), "steps": 32.0, "dither": 0.0, "contrast": 1.0, "saturation": 1.05, "warmth": 0.0, "outline": 0.0, "vignette": 0.0, "motion": 0.65},
	{"name": "РЕТРО 16-БИТ", "grid": Vector2(320, 240), "steps": 16.0, "dither": 0.8, "contrast": 1.06, "saturation": 1.12, "warmth": 0.02, "outline": 0.10, "vignette": 0.025, "motion": 0.9},
	{"name": "КРУПНЫЙ ПИКСЕЛЬ", "grid": Vector2(160, 120), "steps": 8.0, "dither": 0.65, "contrast": 1.08, "saturation": 1.08, "warmth": 0.0, "outline": 0.22, "vignette": 0.0, "motion": 1.0},
	{"name": "КИНО", "grid": Vector2(320, 240), "steps": 40.0, "dither": 0.0, "contrast": 1.10, "saturation": 0.93, "warmth": 0.065, "outline": 0.0, "vignette": 0.16, "motion": 0.85},
]
var mode_index: int = 1
var motion_enabled: bool = true
var rider: DemoMotorcycle
var speed_amount: float = 0.0
var motion_time: float = 0.0
var previous_speed: float = 0.0
var settings: Dictionary = {}
@onready var effect: ShaderMaterial = $Filter.material


func setup(target: DemoMotorcycle) -> void:
	rider = target
	reset()
	apply_mode(mode_index)


func cycle_mode() -> void:
	apply_mode((mode_index + 1) % MODES.size())


func apply_mode(index: int) -> void:
	mode_index = posmod(index, MODES.size())
	settings = MODES[mode_index].duplicate()
	settings["pixel_height"] = settings.grid.y
	settings["stability"] = 0.85 if mode_index == 4 else 0.55
	settings["exposure"] = 1.0
	settings["gamma"] = 1.0
	settings["blur_strength"] = 1.0
	apply_settings()


func apply_settings() -> void:
	for parameter: String in ["steps", "dither", "contrast", "saturation", "warmth", "outline", "vignette", "stability", "exposure", "gamma"]:
		effect.set_shader_parameter(parameter, settings[parameter])
	_update_motion()
	graphics_changed.emit(settings.name, mode_index, motion_enabled)


func toggle_motion() -> void:
	motion_enabled = not motion_enabled
	apply_settings()


func motion_strength() -> float:
	return float(settings.get("motion", 0.65)) if motion_enabled else 0.0


func _update_motion() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var grid := Vector2(640, float(settings.get("pixel_height", 240)))
	grid.x = roundf(grid.y * view.x / maxf(1.0, view.y))
	effect.set_shader_parameter("pixel_grid", grid)
	effect.set_shader_parameter("speed_amount", clampf(speed_amount * float(settings.get("blur_strength", 1.0)), 0.0, 1.0) if motion_enabled else 0.0)


func reset() -> void:
	speed_amount = 0.0
	motion_time = 0.0
	previous_speed = 0.0
	effect.set_shader_parameter("speed_amount", 0.0)
	effect.set_shader_parameter("motion_time", 0.0)


func _process(delta: float) -> void:
	if rider == null or delta <= 0.0:
		return
	var acceleration: float = maxf(0.0, rider.dynamics.acceleration)
	previous_speed = rider.speed
	var pace: float = smoothstep(9.0, 36.0, rider.speed)
	var target: float = clampf(pace * 0.2 + smoothstep(0.4, 3.5, acceleration) * smoothstep(0.5, 4.0, rider.speed) * 0.8, 0.0, 1.0)
	speed_amount = lerpf(speed_amount, target, 1.0 - exp(-4.0 * delta))
	motion_time += delta * (0.35 + pace * 0.65)
	_update_motion()
	effect.set_shader_parameter("motion_time", motion_time)
