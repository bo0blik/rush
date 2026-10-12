extends Node3D
## World-space particles and a bounded skid pool follow the rear contact patch.

const MAX_MARKS: int = 160
var smoke: CPUParticles3D
var dust: CPUParticles3D
var sparks: CPUParticles3D
var marks: Array[MeshInstance3D] = []
var mark_index: int = 0
var mark_timer: float = 0.0
var slipping: bool = false


func _ready() -> void:
	smoke = _particles("TireSmoke", Color(0.83, 0.85, 0.88, 0.55), 0.80, 1.25)
	dust = _particles("VergeDust", Color(0.70, 0.59, 0.36, 0.55), 0.42, 0.85)
	sparks = _particles("ImpactSparks", Color(1.0, 0.74, 0.25, 0.95), 0.065, 0.4)
	sparks.amount = 18
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.spread = 80.0
	sparks.direction = Vector3.UP
	sparks.initial_velocity_min = 1.5
	sparks.initial_velocity_max = 4.0
	sparks.gravity = Vector3(0, -7.0, 0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.12, 0.13, 0.15)
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(0.13, 0.52)
	for i in range(MAX_MARKS):
		var mark := MeshInstance3D.new()
		mark.mesh = mesh
		mark.material_override = material
		mark.visible = false
		mark.top_level = true
		add_child(mark)
		marks.append(mark)


func _particles(label: String, color: Color, size: float, life: float) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = label
	particles.amount = 64
	particles.lifetime = life
	particles.local_coords = false
	particles.emitting = false
	particles.position = Vector3(0, 0.15, 0.35)
	particles.direction = Vector3(0, 0.35, 1)
	particles.spread = 28.0
	particles.gravity = Vector3(0, 0.45, 0)
	particles.initial_velocity_min = 0.8
	particles.initial_velocity_max = 2.0
	particles.scale_amount_min = size * 0.5
	particles.scale_amount_max = size
	var fade := Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	particles.color_ramp = fade
	var growth := Curve.new()
	growth.add_point(Vector2(0, 0.35))
	growth.add_point(Vector2(1, 1.0))
	particles.scale_amount_curve = growth
	var quad := QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = preload("res://demo/shaders/smoke.gdshader")
	quad.material = material
	particles.mesh = quad
	add_child(particles)
	return particles


func update_contact(speed: float, brake: float, off_road: bool, contact: Transform3D, delta: float) -> void:
	slipping = brake > 0.65 and speed > 3.0 and not off_road
	smoke.emitting = slipping
	dust.emitting = off_road and speed > 2.5
	mark_timer += delta
	if slipping and mark_timer >= 0.025:
		var mark_length: float = clampf(speed * mark_timer + 0.15, 0.52, 2.5)
		mark_timer = 0.0
		var mark: MeshInstance3D = marks[mark_index]
		mark_index = (mark_index + 1) % MAX_MARKS
		contact.origin += Vector3.UP * 0.035
		mark.global_transform = contact
		mark.scale.z = mark_length / 0.52
		mark.visible = true


func clear() -> void:
	mark_index = 0
	mark_timer = 0.0
	slipping = false
	if smoke != null:
		smoke.restart()
		dust.restart()
		smoke.emitting = false
		dust.emitting = false
		sparks.restart()
		sparks.emitting = false
	for mark in marks:
		mark.visible = false


func impact() -> void:
	sparks.restart()
