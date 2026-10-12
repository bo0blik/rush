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
var map_points := PackedVector2Array()
var graphics_name: String = "ЧИСТЫЙ ПИКСЕЛЬ"
var graphics_index: int = 1
var motion_enabled: bool = true
@onready var font: Font = ThemeDB.fallback_font


func setup(track: DemoTrack, start: float = 95.0) -> void:
	track_length = track.length
	start_offset = start
	var points: PackedVector3Array = track.curve.get_baked_points()
	var bounds := Rect2(Vector2(points[0].x, points[0].z), Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(Vector2(point.x, point.z))
	for i in range(0, points.size(), 6):
		var p: Vector2 = (Vector2(points[i].x, points[i].z) - bounds.position) / bounds.size
		map_points.append(Vector2(30.0, 404.0) + p * Vector2(83.0, 56.0))
	map_points.append(map_points[0])


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


func update_motorcycle(name: String, current_gear: int, engine_rpm: float, auto_shift: bool, grip: float) -> void:
	bike_name = name
	gear = current_gear
	rpm = engine_rpm
	automatic = auto_shift
	grip_usage = grip


func clear_collision() -> void:
	collision_time = 0.0
	queue_redraw()


func set_graphics_mode(mode_name: String, index: int, motion: bool) -> void:
	graphics_name = mode_name
	graphics_index = index
	motion_enabled = motion
	queue_redraw()


func _text(at: Vector2, value: String, size: int = 12, color: Color = PAPER) -> void:
	if at.y >= 386.0:
		if at.x >= 404.0:
			at.x += (get_viewport_rect().size.x - 640.0) * 0.5
		elif at.x < 236.0:
			at.x -= (get_viewport_rect().size.x - 640.0) * 0.5
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)


func _panel(rect: Rect2) -> void:
	if rect.position.y >= 386.0:
		if rect.position.x >= 404.0:
			rect.position.x += (get_viewport_rect().size.x - 640.0) * 0.5
		elif rect.position.x < 236.0:
			rect.position.x -= (get_viewport_rect().size.x - 640.0) * 0.5
	draw_rect(rect, INK)
	draw_rect(rect, BORDER, false, 1.0)


func _draw() -> void:
	if font == null:
		return
	var view: Vector2 = get_viewport_rect().size
	var margin: float = (view.x - 640.0) * 0.5
	draw_set_transform(Vector2(margin, view.y - 480.0))
	if collision_time > 0.0:
		_panel(Rect2(239, 78, 218, 28))
		_text(Vector2(250, 97), collision_label, 12, Color("ee7154"))
	elif off_road:
		_panel(Rect2(248, 78, 144, 28))
		_text(Vector2(262, 97), "ОБОЧИНА • СБРОСЬ ГАЗ", 10, AMBER)
	var dash := Rect2(-margin, 376, view.x, 104)
	draw_rect(dash, Color("222d37"))
	draw_rect(Rect2(-margin, 376, view.x, 3), Color("97a29a"))
	draw_rect(Rect2(-margin, 379, view.x, 2), INK)
	_panel(Rect2(14, 391, 222, 76))
	_text(Vector2(28, 405), "МАРШРУТ", 9, MUTED)
	if map_points.size() > 1:
		draw_set_transform(Vector2(0, view.y - 480.0))
		draw_polyline(map_points, Color("627d7b"), 2.0)
		var progress: float = fposmod(traveled + start_offset, track_length) / track_length
		var index: int = mini(int(progress * (map_points.size() - 1)), map_points.size() - 1)
		draw_circle(map_points[index], 3.0, AMBER)
		draw_set_transform(Vector2(margin, view.y - 480.0))
	_text(Vector2(130, 430), "%04.2f КМ" % (traveled / 1000.0), 18)
	_text(Vector2(131, 448), "КРУГ  %02d" % (floori(traveled / track_length) + 1), 10, MUTED)
	_text(Vector2(131, 460), "В ПУТИ %02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60], 9, MUTED)
	_panel(Rect2(404, 386, 222, 88))
	_text(Vector2(412, 397), "ЛЕСНОЙ ПЕРЕВАЛ / УПРАВЛЕНИЕ", 8, MUTED)
	_text(Vector2(412, 408), "W ГАЗ · A/D РУЛЬ · S/SPACE ТОРМОЗ", 8)
	_text(Vector2(412, 418), "Q/E ПЕРЕДАЧИ · M АВТО · R СБРОС · ESC", 8, MUTED)
	_text(Vector2(412, 428), "F4 %s · %d / %04d · %s" % [bike_name, gear, roundi(rpm), "АВТО" if automatic else "РУЧН."], 8)
	_text(Vector2(412, 438), "F2 %d/5 %s · F3 %s" % [graphics_index + 1, graphics_name, "ВКЛ" if motion_enabled and graphics_index != 0 else "ВЫКЛ"], 8, AMBER)
	if character != null:
		_text(Vector2(412, 448), "F5 ШЛЕМ %d · F6 КУРТКА %d" % [character.helmet + 1, character.jacket + 1], 8, MUTED)
		_text(Vector2(412, 458), "F7 ШТАНЫ %d · F8 БОТИНКИ %d" % [character.pants + 1, character.boots + 1], 8, MUTED)
	_text(Vector2(412, 468), "Z/X РУКА · C/V НОГА · F9 СТОЛКНОВЕНИЕ", 8, MUTED)
	var center := Vector2(320, 477)
	draw_circle(center, 85.0, Color("83948e"))
	draw_circle(center, 82.0, INK)
	draw_arc(center, 72.0, PI, TAU, 48, BORDER, 2.0)
	for tick in range(15):
		var angle: float = PI + tick * PI / 14.0
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(center + direction * 68.0, center + direction * (59.0 if tick % 2 == 0 else 64.0), PAPER, 1.0)
		if tick % 2 == 0:
			_text(center + direction * 56.0 + Vector2(-7, 3), str(tick * 10), 9, MUTED)
	var needle_angle: float = PI + clampf(speed / 140.0, 0.0, 1.0) * PI
	draw_line(center, center + Vector2(cos(needle_angle), sin(needle_angle)) * 61.0, Color("ee7154"), 3.0)
	draw_circle(center, 5.0, PAPER)
	_panel(Rect2(288, 442, 64, 26))
	_text(Vector2(298, 462), "%03d" % roundi(speed), 22)
	_text(Vector2(309, 473), "КМ/Ч", 8, MUTED)
	if character != null:
		if character.ragdoll_active:
			_panel(Rect2(190, 324, 260, 34))
			_text(Vector2(213, 346), "R — ВЕРНУТЬСЯ К МОТОЦИКЛУ", 12, PAPER)
	if grip_usage > 0.90 and collision_time <= 0.0:
		_panel(Rect2(264, 110, 154, 24))
		_text(Vector2(275, 127), "ПРЕДЕЛ СЦЕПЛЕНИЯ", 10, AMBER)
	if speed < 0.5 and not paused and collision_time <= 0.0 and (character == null or not character.ragdoll_active):
		_panel(Rect2(188, 228, 264, 43))
		_text(Vector2(207, 248), "УДЕРЖИВАЙТЕ W", 15)
		_text(Vector2(222, 263), "ДОРОГА ОТКРЫТА. МОЖНО ЕХАТЬ.", 9, MUTED)
	if paused:
		draw_rect(Rect2(-margin, 480.0 - view.y, view.x, view.y), Color(0.04, 0.07, 0.1, 0.65))
		_panel(Rect2(178, 192, 284, 90))
		_text(Vector2(273, 226), "ПАУЗА", 26)
		_text(Vector2(204, 254), "ESC — ПРОДОЛЖИТЬ    R — В НАЧАЛО", 11, MUTED)
