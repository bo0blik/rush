class_name DemoHUD
extends Control

const INK := Color("151e29")
const BORDER := Color("52616a")
const PAPER := Color("f2efdb")
const MUTED := Color("a0b3b0")
const AMBER := Color("f0c766")
var speed: float = 0.0
var traveled: float = 0.0
var elapsed: float = 0.0
var off_road: bool = false
var paused: bool = false
var collision_time: float = 0.0
var collision_label: String = "СТОЛКНОВЕНИЕ!"
var bike_name: String = "КЛАССИК 350"
var gear: int = 1
var rpm: float = 1100.0
var automatic: bool = true
var grip_usage: float = 0.0
var character: RiderCharacter
var track_length: float = 1.0
var start_offset: float = 95.0
var needle_speed: float = 0.0
var steering: float = 0.0
var graphics_name: String = "ЧИСТЫЙ ПИКСЕЛЬ"
var graphics_index: int = 1
var motion_enabled: bool = true
var corner_layout: bool = true
var hud_scale: float = 0.8
var settings_open: bool = false
@onready var font: Font = ThemeDB.fallback_font


func setup(track: DemoTrack, start: float = 95.0) -> void:
	track_length = track.length
	start_offset = start



func update_telemetry(kmh: float, distance: float, outside: bool) -> void:
	speed = kmh
	traveled = distance
	off_road = outside
	queue_redraw()


func update_clock(seconds: float, is_paused: bool) -> void:
	if not is_paused:
		collision_time = maxf(0.0, collision_time - maxf(0.0, seconds - elapsed))
	elapsed = seconds
	paused = is_paused
	queue_redraw()


func show_collision(relative_speed: float) -> void:
	collision_label = "СТОЛКНОВЕНИЕ!"
	collision_time = 2.6 if relative_speed > 28.0 else 1.2
	queue_redraw()


func show_fall(_speed: float) -> void:
	collision_label = "ПОТЕРЯ СЦЕПЛЕНИЯ"
	collision_time = 2.6
	queue_redraw()


func update_motorcycle(name: String, current_gear: int, engine_rpm: float, auto_shift: bool, grip: float, turn: float = 0.0) -> void:
	bike_name = name
	gear = current_gear
	rpm = engine_rpm
	automatic = auto_shift
	grip_usage = grip
	steering = turn


func clear_collision() -> void:
	collision_time = 0.0
	queue_redraw()


func set_graphics_mode(mode_name: String, index: int, motion: bool) -> void:
	graphics_name = mode_name
	graphics_index = index
	motion_enabled = motion
	queue_redraw()


func _process(delta: float) -> void:
	needle_speed = lerpf(needle_speed, speed, 1.0 - exp(-delta * 9.0))
	queue_redraw()


func _text(at: Vector2, value: String, size: int = 12, color: Color = PAPER) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func _lamp(rect: Rect2, color: Color, active: bool) -> void:
	draw_rect(rect.grow(2), Color("090c12"))
	draw_rect(rect, Color("232631"))
	if active:
		draw_rect(rect.grow(-2), color * Color(0.24, 0.24, 0.24))
		draw_line(rect.position + Vector2(3, 2), rect.position + Vector2(rect.size.x - 3, 2), color * 0.4, 1.0)
	draw_rect(rect, Color("414554"), false, 1.0)


func _arrow(at: Vector2, right: bool, color: Color) -> void:
	var points := PackedVector2Array([Vector2(-7, 0), Vector2(-1, -5), Vector2(-1, -2), Vector2(6, -2), Vector2(6, 2), Vector2(-1, 2), Vector2(-1, 5)])
	for i in range(points.size()):
		points[i] = at + points[i] * Vector2(-1.0 if right else 1.0, 1.0)
	draw_colored_polygon(points, color)


func _draw() -> void:
	if font == null:
		return
	var view: Vector2 = get_viewport_rect().size
	var ui_scale: float = maxf(0.75, float(get_window().content_scale_size.y) / 480.0)
	var instrument_scale: float = hud_scale * ui_scale
	draw_set_transform(Vector2(view.x * 0.5 - 320.0 * ui_scale, view.y - 480.0 * ui_scale), 0.0, Vector2.ONE * ui_scale)
	if corner_layout:
		draw_set_transform(Vector2(10 * ui_scale, view.y - 10 * ui_scale) - Vector2(173, 484) * instrument_scale, 0.0, Vector2.ONE * instrument_scale)
	var housing := PackedVector2Array([Vector2(173, 484), Vector2(183, 417), Vector2(200, 372), Vector2(219, 358), Vector2(281, 358), Vector2(300, 371), Vector2(330, 409), Vector2(334, 484)])
	draw_colored_polygon(housing, Color("090c14"))
	draw_polyline(housing, Color("0a0c11"), 7.0)
	draw_polyline(housing, Color("606576"), 2.0)
	for i in range(15):
		draw_line(Vector2(215 + i * 4, 362), Vector2(218 + i * 4, 362), Color("85899a"), 1.0)
	var green := Color("12efa2")
	var blue := Color("368dff")
	var red := Color("ef4d5a")
	var blink: bool = fmod(elapsed, 0.7) < 0.35
	var left_on: bool = steering < -0.1 and blink
	var right_on: bool = steering > 0.1 and blink
	_lamp(Rect2(211, 386, 44, 32), green, left_on or right_on)
	_arrow(Vector2(224, 402), false, green if left_on else Color("235b4a"))
	_arrow(Vector2(243, 402), true, green if right_on else Color("235b4a"))
	var battery_on: bool = rpm < 1200.0
	_lamp(Rect2(263, 386, 37, 32), red, battery_on)
	var battery: Color = red if battery_on else Color("63343d")
	draw_rect(Rect2(273, 397, 18, 11), battery, false, 2.0)
	draw_rect(Rect2(277, 394, 4, 3), battery)
	draw_rect(Rect2(285, 394, 4, 3), battery)
	_text(Vector2(275, 406), "+ -", 8, battery)
	_lamp(Rect2(207, 426, 27, 30), blue, speed > 0.5)
	var headlight: Color = blue if speed > 0.5 else Color("304465")
	draw_arc(Vector2(221, 441), 6, -PI * 0.5, PI * 0.5, 12, headlight, 2.0)
	draw_line(Vector2(221, 435), Vector2(221, 447), headlight, 2.0)
	for y in range(437, 447, 3):
		draw_line(Vector2(210, y), Vector2(217, y), headlight, 1.0)
	_lamp(Rect2(241, 426, 27, 30), green, true)
	_text(Vector2(249, 447), str(gear), 17, green)
	var warning: bool = collision_time > 0.0 or (character != null and character.ragdoll_active)
	_lamp(Rect2(275, 426, 27, 30), red, warning)
	var oil: Color = red if warning else Color("63343d")
	draw_rect(Rect2(283, 438, 11, 6), oil, false, 1.0)
	draw_line(Vector2(280, 436), Vector2(288, 436), oil, 2.0)
	draw_line(Vector2(289, 438), Vector2(297, 434), oil, 2.0)
	draw_circle(Vector2(298, 445), 1.5, oil)
	for bolt: Vector2 in ([Vector2(191, 468), Vector2(311, 470)] if corner_layout else [Vector2(191, 468), Vector2(311, 470), Vector2(452, 470)]):
		draw_circle(bolt, 4, Color("0a0b10"))
		draw_circle(bolt, 2.5, Color("bea86a"))
		draw_line(bolt + Vector2(-1, -1), bolt + Vector2(1, 1), Color("55492f"), 1.0)
	_text(Vector2(213, 472), "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60], 10, Color("a1a69c"))
	var center := Vector2(383, 411)
	if corner_layout:
		draw_set_transform(Vector2(view.x - 10 * ui_scale, view.y - 10 * ui_scale) - Vector2(461, 489) * instrument_scale, 0.0, Vector2.ONE * instrument_scale)
	for ring: Array in [[78.0, Color("070a10")], [75.0, Color("5a6070")], [73.0, Color("161b28")], [70.0, Color("343b49")], [68.0, Color("0e131f")]]:
		draw_circle(center, ring[0], ring[1])
	draw_arc(center, 74, deg_to_rad(200), deg_to_rad(292), 30, Color("9297a5"), 1.0)
	draw_arc(center, 65, deg_to_rad(190), deg_to_rad(340), 42, Color("252b39"), 2.0)
	for tick in range(41):
		var angle: float = deg_to_rad(135.0 + tick * 270.0 / 40.0)
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * 63.0, center + direction * (55.0 if tick % 5 == 0 else 59.0), PAPER, 1.0)
		if tick % 5 == 0:
			var label: String = str(tick * 4)
			var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			_text(center + direction * 48.0 + Vector2(-width * 0.5, 3), label, 10)
	var digits: String = "%05d%d" % [int(traveled / 1000.0) % 100000, int(traveled / 100.0) % 10]
	draw_rect(Rect2(353, 387, 62, 15), Color("05080e"))
	for digit in range(6):
		var rect := Rect2(355 + digit * 10, 389, 9, 11)
		draw_rect(rect, Color("892f38") if digit == 5 else Color("202530"))
		_text(rect.position + Vector2(1, 9), digits[digit], 10, PAPER)
	_text(Vector2(370, 434), "km/h", 10)
	_text(Vector2(355, 454), "TRIP %05.1f" % (traveled / 1000.0), 8, MUTED)
	var needle: float = deg_to_rad(135.0 + clampf(needle_speed / 160.0, 0.0, 1.0) * 270.0)
	var direction := Vector2(cos(needle), sin(needle))
	draw_line(center + Vector2(1, 2) - direction * 9.0, center + Vector2(1, 2) + direction * 53.0, Color("07090f"), 4.0)
	draw_line(center - direction * 9.0, center + direction * 53.0, Color("ead9b5"), 2.0)
	draw_circle(center, 4, Color("333943"))
	draw_circle(center, 2, Color("c4bea5"))
	if paused and not settings_open:
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(Vector2.ZERO, view), Color(0.04, 0.07, 0.1, 0.65))
		_text(view * 0.5 + Vector2(-42, 0), "ПАУЗА", 22)
