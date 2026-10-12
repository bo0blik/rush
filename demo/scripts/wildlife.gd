extends Node3D
## One reusable animal atlas: registered loops and movement in road coordinates.
const FRAMES: SpriteFrames = preload("res://demo/resources/wildlife_frames.tres")
const NAMES: Array[StringName] = [&"bee", &"bumblebee", &"swallow", &"sparrow", &"rook", &"stork", &"holstein", &"jersey", &"red_cow", &"white_sheep", &"black_sheep", &"ram"]
const HEIGHTS: Array[float] = [0.08, 0.10, 0.30, 0.24, 0.42, 1.05, 1.45, 1.35, 1.45, 0.85, 0.85, 0.95]
var animals: Array[Dictionary] = []
var time: float = 0.0
@onready var track: DemoTrack = get_parent().get_node("Track")


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = track.scenery_seed + 812
	# Bees hover around sunflower patches; birds travel in small flocks overhead.
	for swarm in range(10):
		for i in range(5):
			_spawn(i % 2, 115.0 + swarm * 46.0 + rng.randf_range(-3, 3), rng.randf_range(7.0, 13.0), rng.randf_range(1.4, 2.1), rng.randf() * TAU)
	for flock in range(7):
		for i in range(4):
			_spawn(2 + flock % 4, 60.0 + flock * track.length / 7.0 + i * 3.0, -15.0 + i * 2.5, rng.randf_range(7, 14), rng.randf() * TAU)
	for herd in range(4):
		var along: float = [740.0, 860.0, 1040.0, 1220.0][herd]
		var side: float = -1.0 if herd % 2 == 0 else 1.0
		for i in range(7):
			var kind: int = 6 + i % 3 if herd < 2 else 9 + i % 3
			_spawn(kind, along + rng.randf_range(-6, 6), side * rng.randf_range(14, 24), 0.0, rng.randf() * TAU)
	_update_positions()


func _spawn(kind: int, along: float, offset: float, altitude: float, phase: float) -> void:
	var sprite := AnimatedSprite3D.new()
	sprite.name = "%s_%d" % [NAMES[kind], animals.size()]
	sprite.sprite_frames = FRAMES
	sprite.animation = NAMES[kind]
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = true
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.pixel_size = HEIGHTS[kind] / FRAMES.get_frame_texture(NAMES[kind], 0).get_height()
	sprite.visibility_range_end = 450.0 if kind >= 6 else 250.0
	add_child(sprite)
	sprite.play()
	sprite.frame = int(phase / TAU * FRAMES.get_frame_count(NAMES[kind]))
	animals.append({"sprite": sprite, "kind": kind, "along": along, "offset": offset, "altitude": altitude, "phase": phase})


func _process(delta: float) -> void:
	time += delta
	_update_positions()


func _update_positions() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	for animal: Dictionary in animals:
		var kind: int = animal.kind
		var phase: float = animal.phase
		var along: float = animal.along
		var offset: float = animal.offset
		var altitude: float = animal.altitude
		var direction: float = 1.0
		if kind < 2:
			along += sin(time * 1.9 + phase) * 0.6
			offset += cos(time * 2.3 + phase) * 0.45
			altitude += sin(time * 3.0 + phase) * 0.18
		elif kind < 6:
			along += time * (5.0 if kind != 5 else 3.8)
			offset += sin(time * 0.22 + phase) * 8.0
			altitude += sin(time * 0.8 + phase) * 0.4
		elif kind != 8 and kind != 11:
			along += sin(time * 0.09 + phase) * 5.0
			direction = cos(time * 0.09 + phase)
		var frame: Transform3D = track.frame_at(along)
		var point: Vector3 = frame.origin + frame.basis.x * offset
		if kind >= 6:
			var closest: Vector3 = track.curve.get_closest_point(track.to_local(point))
			animal.sprite.visible = Vector2(point.x - closest.x, point.z - closest.z).length() > track.road_width * 0.5 + 2.0
		point.y += altitude + HEIGHTS[kind] * 0.5
		animal.sprite.global_position = point
		if camera != null and kind >= 2:
			animal.sprite.flip_h = (-frame.basis.z * direction).dot(camera.global_basis.x) > 0.0
