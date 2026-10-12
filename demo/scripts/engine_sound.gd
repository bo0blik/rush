class_name DemoEngineSound
extends AudioStreamPlayer
## A baked loop avoids frame-driven generator underruns in Web builds.

var road_speed: float = 0.0
var throttle: float = 0.0
var engine_rpm: float = 1100.0


func _ready() -> void:
	var loop: AudioStreamWAV = preload("res://demo/audio/motorcycle_engine.wav").duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = roundi(loop.get_length() * loop.mix_rate)
	stream = loop
	playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE if OS.has_feature("web") else AudioServer.PLAYBACK_TYPE_STREAM
	pitch_scale = 0.55
	play()


func _exit_tree() -> void:
	stop()


func _process(delta: float) -> void:
	var desired: float = clampf(engine_rpm / 2400.0, 0.55, 3.3)
	pitch_scale = lerpf(pitch_scale, desired, 1.0 - exp(-delta * 7.0))
	volume_db = lerpf(volume_db, -20.0 + throttle * 7.0, 1.0 - exp(-delta * 7.0))
