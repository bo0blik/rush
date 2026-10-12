extends Node3D
## Composition root: connects self-contained track, rider, camera and HUD scenes.

@onready var track: DemoTrack = $Track
@onready var rider: DemoMotorcycle = $Motorcycle
@onready var camera: DemoChaseCamera = $ChaseCamera
@onready var hud: DemoHUD = $HUD/Interface
@onready var traffic = $Traffic
var elapsed: float = 0.0


func _ready() -> void:
	rider.telemetry_changed.connect(hud.update_telemetry)
	hud.setup(track, rider.start_distance)
	rider.setup(track)
	hud.character = rider.character
	camera.setup(rider, track)
	traffic.setup(track, rider, camera)
	traffic.collision.connect(hud.show_collision)
	traffic.collision.connect(camera.jolt)
	rider.fall_started.connect(hud.show_fall)
	rider.fall_started.connect(camera.jolt)
	$ScreenEffects.graphics_changed.connect(_graphics_changed)
	$ScreenEffects.setup(rider)


func _graphics_changed(mode_name: String, index: int, motion_enabled: bool) -> void:
	hud.set_graphics_mode(mode_name, index, motion_enabled)
	camera.speed_visual_strength = $ScreenEffects.motion_strength()
	if get_tree().paused:
		camera.fov = 55.0 + smoothstep(10.0, 38.0, rider.speed) * 4.0 * camera.speed_visual_strength


func _process(delta: float) -> void:
	if not get_tree().paused:
		elapsed += delta
	hud.update_clock(elapsed, get_tree().paused)
	hud.update_motorcycle(rider.profile.display_name, rider.dynamics.gear, rider.dynamics.rpm, rider.dynamics.automatic, rider.dynamics.grip_usage)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test_crash"):
		get_tree().paused = false
		rider.reset()
		rider.speed = 22.0
		camera.snap_to_rider()
		traffic.setup_crash_test()
		hud.clear_collision()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cycle_helmet") or event.is_action_pressed("cycle_jacket") or event.is_action_pressed("cycle_pants") or event.is_action_pressed("cycle_boots"):
		for slot: String in ["helmet", "jacket", "pants", "boots"]:
			if event.is_action_pressed("cycle_" + slot): rider.character.cycle_outfit(slot)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("punch_left") or event.is_action_pressed("punch_right") or event.is_action_pressed("kick_left") or event.is_action_pressed("kick_right"):
		for action: String in ["punch_left", "punch_right", "kick_left", "kick_right"]:
			if event.is_action_pressed(action):
				rider.character.start_attack("punch" if action.begins_with("punch") else "kick", -1.0 if action.ends_with("left") else 1.0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cycle_bike"):
		get_tree().paused = false
		elapsed = 0.0
		rider.cycle_bike()
		camera.snap_to_rider()
		traffic.reset()
		hud.clear_collision()
		$ScreenEffects.reset()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("gear_up") or event.is_action_pressed("gear_down"):
		rider.dynamics.automatic = false
		rider.dynamics.shift(1 if event.is_action_pressed("gear_up") else -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_transmission"):
		rider.dynamics.automatic = not rider.dynamics.automatic
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cycle_graphics"):
		$ScreenEffects.cycle_mode()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_speed_effects"):
		$ScreenEffects.toggle_motion()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause_demo"):
		get_tree().paused = not get_tree().paused
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reset_demo"):
		get_tree().paused = false
		elapsed = 0.0
		rider.reset()
		camera.snap_to_rider()
		traffic.reset()
		hud.clear_collision()
		$ScreenEffects.reset()
		get_viewport().set_input_as_handled()
