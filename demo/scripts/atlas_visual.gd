extends MeshInstance3D
## Fixed world canvas, measured tire anchors, and interpolation between authored poses.

@export var sprite_frames: SpriteFrames
@export var reference_animation: StringName = &"ride"
@export var reference_width: float = 0.90
@export var reference_height: float = 1.80
@export var canvas_size: Vector2 = Vector2(2.8, 2.2)
@export var normalize_pose_height: bool = false
var animation: StringName = &"ride"
var frame: int = 0
var frame_progress: float = 0.0
var pixel_scale: Vector2
var flip_h: bool = false
var material: ShaderMaterial


func _ready() -> void:
	var reference: AtlasTexture = sprite_frames.get_frame_texture(reference_animation, 0)
	# One scale for both axes preserves the artist's proportions.
	pixel_scale = Vector2.ONE * reference_height / (reference.region.size.y - 2.0)
	var quad := QuadMesh.new()
	quad.size = canvas_size
	mesh = quad
	position.y = canvas_size.y * 0.5
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	material = ShaderMaterial.new()
	material.shader = preload("res://demo/shaders/atlas_animation.gdshader")
	material.set_shader_parameter("atlas", reference.atlas)
	material.set_shader_parameter("atlas_size", Vector2(reference.atlas.get_size()))
	material.set_shader_parameter("quad_size", canvas_size)
	material_override = material
	set_pose(reference_animation, 0.0)


func set_pose(name: StringName, progress: float, mirror: bool = false) -> void:
	animation = name
	flip_h = mirror
	var count: int = sprite_frames.get_frame_count(name)
	var loop: bool = sprite_frames.get_animation_loop(name)
	var position_in_frames: float = fposmod(progress, count) if loop else clampf(progress, 0.0, count - 1.0)
	frame = floori(position_in_frames)
	frame_progress = position_in_frames - frame
	var next: int = (frame + 1) % count if loop else mini(frame + 1, count - 1)
	set_pair(sprite_frames.get_frame_texture(name, frame), sprite_frames.get_frame_texture(name, next), frame_progress, mirror)


func set_pair(a: AtlasTexture, b: AtlasTexture, blend: float, mirror: bool = false) -> void:
	material.set_shader_parameter("atlas", a.atlas)
	material.set_shader_parameter("atlas_b", b.atlas)
	material.set_shader_parameter("atlas_size", Vector2(a.atlas.get_size()))
	material.set_shader_parameter("atlas_size_b", Vector2(b.atlas.get_size()))
	material.set_shader_parameter("rect_a", Vector4(a.region.position.x, a.region.position.y, a.region.size.x, a.region.size.y))
	material.set_shader_parameter("rect_b", Vector4(b.region.position.x, b.region.position.y, b.region.size.x, b.region.size.y))
	material.set_shader_parameter("foot_a", a.get_meta("foot"))
	material.set_shader_parameter("foot_b", b.get_meta("foot"))
	material.set_shader_parameter("frame_blend", blend)
	material.set_shader_parameter("pixel_scale", pixel_scale)
	material.set_shader_parameter("scale_a", Vector2.ONE * reference_height / (a.region.size.y - 2.0) if normalize_pose_height else pixel_scale)
	material.set_shader_parameter("scale_b", Vector2.ONE * reference_height / (b.region.size.y - 2.0) if normalize_pose_height else pixel_scale)
	if normalize_pose_height:
		material.set_shader_parameter("foot_a", Vector2(a.region.size.x * 0.5, a.region.size.y - 1.0))
		material.set_shader_parameter("foot_b", Vector2(b.region.size.x * 0.5, b.region.size.y - 1.0))
	material.set_shader_parameter("mirrored", mirror)
	material.set_shader_parameter("source_flip_a", a.get_meta("source_flip_h", false))
	material.set_shader_parameter("source_flip_b", b.get_meta("source_flip_h", false))
