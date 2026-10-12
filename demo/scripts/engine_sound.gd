class_name DemoEngineSound
extends AudioStreamPlayer
## Small synthesized engine loop; no external audio dependency.

var playback: AudioStreamGeneratorPlayback
var phase: float = 0.0
var road_speed: float = 0.0
var throttle: float = 0.0
var engine_rpm: float = 1100.0
var frequency: float = 25.0


func _ready() -> void:
	playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	play()
	playback = get_stream_playback()


func _exit_tree() -> void:
	stop()
	playback = null


func _process(delta: float) -> void:
	if playback == null:
		return
	var desired: float = engine_rpm / 60.0 + throttle * 4.0
	frequency = lerpf(frequency, desired, 1.0 - exp(-delta * 10.0))
	for i in range(playback.get_frames_available()):
		phase = fposmod(phase + frequency / 22050.0, 1.0)
		var sample: float = sin(phase * TAU) * 0.55 + sin(phase * TAU * 2.0) * 0.3 + sin(phase * TAU * 4.0) * 0.15
		playback.push_frame(Vector2.ONE * sample * (0.22 + throttle * 0.14))
