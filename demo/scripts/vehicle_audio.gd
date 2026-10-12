extends AudioStreamPlayer3D
## Tire hiss and combustion harmonics move with the actual car, including Doppler.
@export var heavy: bool = false
var vehicle: Node3D


func _ready() -> void:
	vehicle = get_parent()
	stream = preload("res://demo/audio/truck_road.wav") if heavy else preload("res://demo/audio/car_road.wav")
	var loop: AudioStreamWAV = stream.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	stream = loop
	unit_size = 5.0
	max_distance = 70.0
	max_db = -13.0
	doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	panning_strength = 1.25
	playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE if OS.has_feature("web") else AudioServer.PLAYBACK_TYPE_STREAM


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	if global_position.distance_to(camera.global_position) > max_distance:
		if playing:
			stop()
		return
	var road_speed: float = float(vehicle.get("speed"))
	pitch_scale = clampf(0.85 + road_speed / 75.0, 0.85, 1.45)
	volume_db = clampf(-23.0 + road_speed * 0.3, -28.0, -13.0)
	if not playing:
		play(fposmod(float(vehicle.get("distance")) / 25.0, 2.0))
