extends CanvasLayer
## Rare foreground animals cross the view independently of distant world flocks.
const FRAMES: SpriteFrames = preload("res://demo/resources/wildlife_frames.tres")
var rng := RandomNumberGenerator.new()
var countdown: float = 5.0
var active: Array[Dictionary] = []
@onready var rider: DemoMotorcycle = get_parent().get_node("Motorcycle")


func _ready() -> void:
	rng.randomize()
	layer = 5


func _process(delta: float) -> void:
	if not rider.character.ragdoll_active and rider.speed > 3.0:
		countdown -= delta
		if countdown <= 0.0:
			_spawn()
			countdown = rng.randf_range(8.0, 18.0)
	for i in range(active.size() - 1, -1, -1):
		var flight: Dictionary = active[i]
		flight.time += delta
		var progress: float = minf(1.0, flight.time / flight.duration)
		flight.sprite.position = flight.start.lerp(flight.finish, progress)
		flight.sprite.scale = Vector2.ONE * flight.scale * (0.65 + sin(progress * PI) * 0.45)
		flight.sprite.modulate.a = minf(0.95, sin(progress * PI) * 2.0)
		if progress >= 1.0:
			flight.sprite.queue_free()
			active.remove_at(i)


func _spawn() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var kind: StringName = [&"bee", &"bumblebee", &"swallow", &"sparrow"][rng.randi_range(0, 3)]
	var from_left: bool = rng.randf() < 0.5
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = FRAMES
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.flip_h = from_left
	add_child(sprite)
	sprite.play(kind)
	var height: float = rng.randf_range(12.0, 18.0) if kind in [&"bee", &"bumblebee"] else rng.randf_range(27.0, 43.0)
	active.append({"sprite": sprite, "time": 0.0, "duration": rng.randf_range(0.28, 0.45), "scale": height / FRAMES.get_frame_texture(kind, 0).get_height(), "start": Vector2(-70 if from_left else view.x + 70, view.y * rng.randf_range(0.2, 0.6)), "finish": Vector2(view.x + 70 if from_left else -70, view.y * rng.randf_range(0.2, 0.6))})
