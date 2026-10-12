extends CanvasLayer
## Live settings; original atlases remain intact and derived textures are reusable.

const SAVE_PATH := "user://graphics.cfg"
const DEFAULTS := {"far_enabled": true, "far_start": 100.0, "far_end": 650.0, "far_bias": 0.0, "far_contrast": 0.0, "far_saturation": 0.0, "far_emission": 0.0, "far_haze": 0.0, "far_alpha": 0.5, "render_height": 480.0, "bake": 1.0, "mipmaps": true, "msaa": 1, "distance": 1.0, "density": 1.0, "shadows": true, "shadow_distance": 150.0, "shadow_softness": 2.0, "sun": 0.9, "ambient": 0.55, "fog": 0.00065, "wind": 1.0, "particles": true, "wildlife": true, "flybys": true, "corner_hud": true, "hud_scale": 0.8, "hud_visible": true}
var values: Dictionary = DEFAULTS.duplicate()
var controls: Dictionary = {}
var sources: Dictionary = {}
var atlases: Array[AtlasTexture] = []
var bindings: Array[Dictionary] = []
var scenery: Array[Dictionary] = []
var sprites: Array[SpriteBase3D] = []
var baked: Dictionary = {}
var bake_factor: int = -1
var bake_mipmaps: bool = false
var panel: PanelContainer
var preset: OptionButton
var status: Label
var was_paused: bool = false
var syncing: bool = false
var save_timer: Timer
var texture_timer: Timer
@onready var demo: Node3D = get_parent()
@onready var effects = demo.get_node("ScreenEffects")
@onready var hud: DemoHUD = demo.get_node("HUD/Interface")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_menu()
	_collect_resources()
	_load()
	_apply_world()
	_apply_textures()
	_sync()
	get_viewport().size_changed.connect(_resize)
	_resize()
	effects.graphics_changed.connect(func(_name: String, _index: int, _motion: bool):
		if not syncing:
			_sync()
			_save_later())


func _build_menu() -> void:
	save_timer = Timer.new()
	save_timer.one_shot = true
	save_timer.wait_time = 0.4
	save_timer.timeout.connect(_save)
	add_child(save_timer)
	texture_timer = Timer.new()
	texture_timer.one_shot = true
	texture_timer.wait_time = 0.35
	texture_timer.timeout.connect(_apply_textures)
	add_child(texture_timer)
	panel = PanelContainer.new()
	panel.position = Vector2(8, 8)
	panel.visible = false
	panel.add_theme_font_size_override("font_size", 12)
	var theme := Theme.new()
	theme.default_font_size = 12
	panel.theme = theme
	var skin := StyleBoxFlat.new()
	skin.bg_color = Color(0.045, 0.065, 0.09, 0.97)
	skin.border_color = Color("52616a")
	skin.set_border_width_all(1)
	skin.set_corner_radius_all(5)
	skin.content_margin_left = 10
	skin.content_margin_right = 10
	skin.content_margin_top = 8
	skin.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", skin)
	add_child(panel)
	var body := VBoxContainer.new()
	panel.add_child(body)
	var header := HBoxContainer.new()
	body.add_child(header)
	var title := Label.new()
	title.text = "ГРАФИКА / F2"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "×"
	close.pressed.connect(toggle_menu)
	header.add_child(close)
	preset = OptionButton.new()
	for mode: Dictionary in effects.MODES:
		preset.add_item(mode.name)
	preset.add_item("СВОИ НАСТРОЙКИ")
	preset.item_selected.connect(_select_preset)
	body.add_child(preset)
	var tabs := TabContainer.new()
	tabs.add_theme_font_size_override("font_size", 10)
	tabs.add_theme_constant_override("side_margin", 2)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)
	var pixel := _page(tabs, "Пиксель")
	_slider(pixel, "render_height", "Разрешение исходного кадра", 360, 1440, 120)
	_slider(pixel, "pixel_height", "Высота пиксельного кадра", 120, 960, 8, true)
	_slider(pixel, "stability", "Сглаживание перед пикселизацией", 0, 1, 0.05, true)
	_slider(pixel, "steps", "Уровни цвета (0 = полный цвет)", 0, 64, 1, true)
	_slider(pixel, "dither", "Дизеринг / рябь", 0, 1, 0.05, true)
	_slider(pixel, "outline", "Контуры", 0, 0.6, 0.02, true)
	_slider(pixel, "bake", "Запекание спрайтов: размер блока", 1, 8, 1)
	_check(pixel, "mipmaps", "Стабилизировать дальние текстуры")
	_option(pixel, "msaa", "Сглаживание геометрии", ["Выкл.", "2× MSAA", "4× MSAA", "8× MSAA"])
	_note(pixel, "Блок 1 — оригинал; 2–8 — пиксели в самих текстурах.\nЗапекание выполняется после остановки ползунка.\nДля чёткого кино: дизеринг 0, сглаживание 0.8–1.")
	var color := _page(tabs, "Цвет")
	_slider(color, "exposure", "Яркость", 0.5, 1.8, 0.05, true)
	_slider(color, "gamma", "Гамма", 0.65, 1.6, 0.05, true)
	_slider(color, "contrast", "Контраст", 0.6, 1.6, 0.05, true)
	_slider(color, "saturation", "Насыщенность", 0, 1.8, 0.05, true)
	_slider(color, "warmth", "Температура цвета", -0.15, 0.15, 0.01, true)
	_slider(color, "vignette", "Виньетка", 0, 0.5, 0.02, true)
	_check(color, "motion_enabled", "Эффекты скорости / F3", true)
	_slider(color, "blur_strength", "Размытие краёв при разгоне", 0, 1.5, 0.05, true)
	_slider(color, "motion", "Изменение обзора при скорости", 0, 1.5, 0.05, true)
	var world := _page(tabs, "Мир")
	var quality := OptionButton.new()
	for name: String in ["Качество: свои настройки", "Экономный", "Сбалансированный", "Высокое качество"]:
		quality.add_item(name)
	quality.item_selected.connect(func(index: int):
		if index == 0: return
		var profiles: Array[Dictionary] = [
			{"render_height": 360.0, "msaa": 0, "density": 0.5, "distance": 0.6, "shadows": false, "shadow_distance": 80.0},
			{"render_height": 480.0, "msaa": 1, "density": 0.85, "distance": 1.0, "shadows": true, "shadow_distance": 150.0},
			{"render_height": 720.0, "msaa": 2, "density": 1.0, "distance": 1.5, "shadows": true, "shadow_distance": 250.0}]
		values.merge(profiles[index - 1], true)
		effects.settings.name = "СВОИ НАСТРОЙКИ"
		_apply_world()
		_sync()
		_save_later()
		quality.select(0))
	world.add_child(quality)
	_slider(world, "distance", "Дальность окружения", 0.5, 1.8, 0.1)
	_slider(world, "density", "Плотность растительности", 0.2, 1, 0.05)
	_slider(world, "wind", "Колыхание растительности", 0, 1.5, 0.1)
	_check(world, "shadows", "Тени от солнца")
	_slider(world, "shadow_distance", "Дальность теней, м", 40, 300, 10)
	_slider(world, "shadow_softness", "Мягкость теней", 0, 4, 0.25)
	_slider(world, "sun", "Свет солнца", 0.2, 1.8, 0.05)
	_slider(world, "ambient", "Свет окружения", 0.1, 1, 0.05)
	_slider(world, "fog", "Атмосферная дымка", 0, 0.003, 0.0001)
	_check(world, "particles", "Дым, пыль и искры")
	_check(world, "wildlife", "Животные, птицы и насекомые")
	_check(world, "flybys", "Пролёты перед камерой")
	var far := _page(tabs, "Даль")
	_check(far, "far_enabled", "Компенсация дальних спрайтов")
	_slider(far, "far_start", "Начало компенсации, м", 30, 400, 10)
	_slider(far, "far_end", "Полная компенсация, м", 450, 1800, 50)
	_slider(far, "far_bias", "Сохранение мелких деталей", 0, 1.5, 0.1)
	_slider(far, "far_contrast", "Контраст по расстоянию", 0, 0.5, 0.025)
	_slider(far, "far_saturation", "Насыщенность по расстоянию", 0, 0.5, 0.025)
	_slider(far, "far_emission", "Компенсация потери света", 0, 0.3, 0.025)
	_slider(far, "far_haze", "Читаемость леса на горизонте", 0, 0.65, 0.05)
	_slider(far, "far_alpha", "Плотность силуэтов вдали", 0.25, 0.5, 0.025)
	_slider(far, "far_detail", "Детализация зоны горизонта", 1, 3, 0.25, true)
	_slider(far, "far_sharpen", "Резкость зоны горизонта", 0, 1, 0.05, true)
	_slider(far, "sharpen_limit", "Ограничение ореолов", 0.01, 0.15, 0.01, true)
	_slider(far, "horizon_line", "Нижняя граница дальней зоны", 0.25, 0.7, 0.025, true)
	_note(far, "Спрайты компенсируются по реальному расстоянию.\nЗона горизонта — отдельный экранный эффект.\nБольшое сохранение деталей может усилить рябь.")
	for preset_title: String in ["Спокойный дальний план", "Максимум деталей", "Атмосферный пейзаж"]:
		var button := Button.new()
		button.text = preset_title
		button.pressed.connect(_far_preset.bind(preset_title))
		far.add_child(button)
	var extra := _page(tabs, "Эффекты")
	_slider(extra, "sharpen", "Общая резкость", 0, 1, 0.05, true)
	_slider(extra, "bloom", "Свечение ярких участков", 0, 0.5, 0.025, true)
	_slider(extra, "bloom_threshold", "Порог свечения", 0.4, 1, 0.05, true)
	_slider(extra, "aberration", "Хроматические края", 0, 2, 0.1, true)
	_slider(extra, "scanlines", "Полосы ретро-экрана", 0, 0.3, 0.025, true)
	_slider(extra, "grain", "Статичное зерно", 0, 0.08, 0.005, true)
	_slider(extra, "black_lift", "Приподнять чёрный", 0, 0.15, 0.01, true)
	_slider(extra, "highlight_rolloff", "Смягчить светлые участки", 0, 1, 0.05, true)
	var interface := _page(tabs, "HUD")
	_check(interface, "corner_hud", "Приборы по углам / H")
	_slider(interface, "hud_scale", "Размер угловых приборов", 0.55, 1, 0.05)
	_check(interface, "hud_visible", "Показать приборы")
	_note(interface, "H — переключить угловой / классический HUD.\nМеню ставит поездку на паузу.\nНастройки сохраняются автоматически.")
	status = Label.new()
	status.text = "Настройки сохранены на этом устройстве"
	status.add_theme_font_size_override("font_size", 10)
	body.add_child(status)
	var reset_button := Button.new()
	reset_button.text = "Сбросить всё: чёткое кино"
	reset_button.pressed.connect(func():
		values = DEFAULTS.duplicate()
		_select_preset(4))
	body.add_child(reset_button)


func _page(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 7)
	scroll.add_child(column)
	return column


func _slider(parent: VBoxContainer, key: String, title: String, minimum: float, maximum: float, step: float, post: bool = false) -> void:
	var label := Label.new()
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(slider)
	controls[key] = {"node": slider, "label": label, "title": title, "post": post}
	slider.value_changed.connect(func(value: float):
		label.text = "%s: %s" % [title, _number(value)]
		if not syncing:
			_change(key, value, post))


func _check(parent: VBoxContainer, key: String, title: String, post: bool = false) -> void:
	var check := CheckButton.new()
	check.text = title
	parent.add_child(check)
	controls[key] = {"node": check, "post": post}
	check.toggled.connect(func(value: bool):
		if not syncing: _change(key, value, post))


func _option(parent: VBoxContainer, key: String, title: String, items: Array) -> void:
	_note(parent, title)
	var option := OptionButton.new()
	for item: String in items: option.add_item(item)
	parent.add_child(option)
	controls[key] = {"node": option, "post": false}
	option.item_selected.connect(func(value: int):
		if not syncing: _change(key, value, false))


func _note(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 10)
	parent.add_child(label)


func _number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else ("%.4f" % value).rstrip("0").rstrip(".")


func _sync() -> void:
	syncing = true
	preset.select(effects.mode_index if effects.settings.name != "СВОИ НАСТРОЙКИ" else effects.MODES.size())
	for key: String in controls:
		var entry: Dictionary = controls[key]
		var value: Variant = effects.motion_enabled if key == "motion_enabled" else effects.settings.get(key, 0) if entry.post else values[key]
		if entry.node is Range:
			entry.node.set_value_no_signal(float(value))
			entry.label.text = "%s: %s" % [entry.title, _number(float(value))]
		elif entry.node is OptionButton:
			entry.node.select(int(value))
		else:
			entry.node.set_pressed_no_signal(bool(value))
	syncing = false


func _change(key: String, value: Variant, post: bool) -> void:
	if post:
		if key == "motion_enabled": effects.motion_enabled = value
		else: effects.settings[key] = value
	else:
		values[key] = value
	effects.settings.name = "СВОИ НАСТРОЙКИ"
	effects.apply_settings()
	if key in ["bake", "mipmaps"]:
		status.text = "Подготовка текстур…"
		texture_timer.start()
	elif not post:
		_apply_world()
	_save_later()


func _select_preset(index: int) -> void:
	if index >= effects.MODES.size(): return
	effects.apply_mode(index)
	effects.motion_enabled = true
	values.bake = 1.0
	values.mipmaps = true
	values.msaa = 1
	effects.apply_settings()
	_apply_world()
	texture_timer.start()
	_sync()
	_save_later()


func _far_preset(title: String) -> void:
	var strong: bool = title == "Максимум деталей"
	var atmosphere: bool = title == "Атмосферный пейзаж"
	values.merge({"far_enabled": true, "far_start": 100.0, "far_end": 650.0,
		"far_bias": 0.7 if strong else 0.15, "far_contrast": 0.22 if strong else 0.1,
		"far_saturation": 0.15 if strong else 0.05, "far_emission": 0.08 if strong else 0.03,
		"far_haze": 0.4 if strong else 0.0 if atmosphere else 0.2, "far_alpha": 0.4,
		"render_height": 1080.0 if strong else 720.0, "mipmaps": true, "bake": 1.0}, true)
	effects.settings.merge({"name": "СВОИ НАСТРОЙКИ", "far_detail": 2.5 if strong else 1.5,
		"far_sharpen": 0.45 if strong else 0.2, "sharpen_limit": 0.05,
		"horizon_line": 0.52, "stability": 0.8, "dither": 0.0}, true)
	effects.apply_settings()
	_apply_world()
	texture_timer.start()
	_sync()
	_save_later()


func toggle_hud() -> void:
	_change("corner_hud", not values.corner_hud, false)
	_sync()


func toggle_menu() -> void:
	if panel.visible:
		panel.hide()
		hud.settings_open = false
		get_tree().paused = was_paused
		if not texture_timer.is_stopped():
			texture_timer.stop()
			_apply_textures()
		_save()
	else:
		was_paused = get_tree().paused
		get_tree().paused = true
		hud.settings_open = true
		panel.show()
		_sync()
		preset.grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F2 or (panel.visible and event.physical_keycode == KEY_ESCAPE):
			toggle_menu()
			get_viewport().set_input_as_handled()
		elif panel.visible and event.physical_keycode == KEY_H:
			toggle_hud()
			get_viewport().set_input_as_handled()
		elif panel.visible and event.physical_keycode == KEY_F3:
			effects.toggle_motion()
			get_viewport().set_input_as_handled()
		elif panel.visible and event.physical_keycode not in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_TAB, KEY_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()


func _resize() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var ui_scale: float = maxf(0.75, float(get_window().content_scale_size.y) / 480.0)
	panel.scale = Vector2.ONE * ui_scale
	panel.position = Vector2(8, 8) * ui_scale
	panel.size = Vector2(minf(340, view.x / ui_scale - 16), maxf(160, view.y / ui_scale - 16))


func _apply_world() -> void:
	get_window().content_scale_size = Vector2i(roundi(float(values.render_height) * 4.0 / 3.0), int(values.render_height))
	_resize()
	var sun: DirectionalLight3D = demo.get_node("Sun")
	sun.shadow_enabled = values.shadows
	sun.directional_shadow_max_distance = values.shadow_distance
	sun.shadow_blur = values.shadow_softness
	sun.light_energy = values.sun
	var environment: Environment = demo.get_node("WorldEnvironment").environment
	environment.ambient_light_energy = values.ambient
	environment.fog_density = values.fog
	environment.fog_enabled = float(values.fog) > 0.0
	get_viewport().msaa_3d = int(values.msaa)
	demo.get_node("ChaseCamera").far = 2600.0 * maxf(1.0, values.distance)
	hud.corner_layout = values.corner_hud
	hud.hud_scale = values.hud_scale
	hud.visible = values.hud_visible
	demo.get_node("Wildlife").visible = values.wildlife
	demo.get_node("CloseFlybys").visible = values.flybys
	for particle: Node in demo.find_children("*", "CPUParticles3D", true, false):
		particle.visible = values.particles
	for entry: Dictionary in scenery:
		var node: MultiMeshInstance3D = entry.node
		if entry.foliage:
			node.multimesh.visible_instance_count = floori(node.multimesh.instance_count * float(values.density))
		if entry.range > 0.0:
			node.visibility_range_end = entry.range * float(values.distance)
		var material: ShaderMaterial = node.material_override as ShaderMaterial
		if material != null:
			for parameter: String in ["far_start", "far_end", "far_bias", "far_contrast", "far_saturation", "far_emission", "far_haze", "far_alpha"]:
				material.set_shader_parameter(parameter, values[parameter])
			material.set_shader_parameter("far_enabled", values.far_enabled)
		if material != null and entry.fade > 0.0:
			material.set_shader_parameter("fade_start", entry.fade_start * float(values.distance))
			material.set_shader_parameter("fade_end", entry.fade * float(values.distance))
			material.set_shader_parameter("wind_strength", values.wind)
	for sprite: SpriteBase3D in sprites:
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS if values.mipmaps else BaseMaterial3D.TEXTURE_FILTER_NEAREST
		var original_range: float = sprite.get_meta("graphics_range", 0.0)
		if original_range > 0.0: sprite.visibility_range_end = original_range * float(values.distance)


func _register_texture(texture: Texture2D) -> void:
	if texture is AtlasTexture:
		if not atlases.has(texture): atlases.append(texture)
		_register_texture(texture.atlas)
	elif texture != null:
		sources[texture.get_instance_id()] = texture


func _collect_resources() -> void:
	for file: String in ResourceLoader.list_directory("res://demo/resources"):
		if file.ends_with(".tres"):
			var frames := load("res://demo/resources/" + file) as SpriteFrames
			if frames != null:
				for animation: StringName in frames.get_animation_names():
					for frame in range(frames.get_frame_count(animation)):
						_register_texture(frames.get_frame_texture(animation, frame))
	for node: Node in demo.find_children("*", "", true, false):
		if node is SpriteBase3D:
			sprites.append(node)
			node.set_meta("graphics_range", node.visibility_range_end)
			if node is Sprite3D: _register_texture(node.texture)
		if node is GeometryInstance3D:
			var material: ShaderMaterial = node.material_override as ShaderMaterial
			if material != null:
				for parameter: Dictionary in material.shader.get_shader_uniform_list():
					var texture: Variant = material.get_shader_parameter(parameter.name)
					if texture is Texture2D:
						_register_texture(texture)
						bindings.append({"material": material, "parameter": parameter.name, "source": texture})
		if node is MultiMeshInstance3D:
			var material: ShaderMaterial = node.material_override as ShaderMaterial
			var fade: float = 0.0
			var start: float = 0.0
			if material != null:
				var raw: Variant = material.get_shader_parameter("fade_end")
				if raw != null: fade = float(raw)
				raw = material.get_shader_parameter("fade_start")
				if raw != null: start = float(raw)
			var kind: int = int(String(node.name).get_slice("_", 2))
			var foliage: bool = String(node.name).begins_with("HorizonForest") or (String(node.name).begins_with("SceneryBatch") and (kind < 16 or kind in [24, 25] or String(node.name).contains("extra")))
			scenery.append({"node": node, "range": node.visibility_range_end, "fade": fade, "fade_start": start, "foliage": foliage})
	for texture: AtlasTexture in atlases:
		texture.set_meta("graphics_source", texture.atlas)


func _apply_textures() -> void:
	var factor := int(values.bake)
	if factor != bake_factor or bool(values.mipmaps) != bake_mipmaps:
		baked.clear()
		bake_factor = factor
		bake_mipmaps = values.mipmaps
	for id: int in sources:
		if factor == 1 and not values.mipmaps: continue
		if not baked.has(id):
			var source: Texture2D = sources[id]
			var image: Image = source.get_image()
			if image == null or image.is_empty(): continue
			if image.is_compressed(): image.decompress()
			image.clear_mipmaps()
			var original_size := Vector2i(image.get_width(), image.get_height())
			if factor > 1:
				image.resize(maxi(1, original_size.x / factor), maxi(1, original_size.y / factor), Image.INTERPOLATE_BILINEAR)
				image.resize(original_size.x, original_size.y, Image.INTERPOLATE_NEAREST)
			if values.mipmaps: image.generate_mipmaps()
			baked[id] = ImageTexture.create_from_image(image)
	for texture: AtlasTexture in atlases:
		var source: Texture2D = texture.get_meta("graphics_source")
		texture.atlas = baked.get(source.get_instance_id(), source) if values.mipmaps or factor > 1 else source
	for entry: Dictionary in bindings:
		var source: Texture2D = entry.source
		var replacement: Texture2D = source if source is AtlasTexture else baked.get(source.get_instance_id(), source) if values.mipmaps or factor > 1 else source
		entry.material.set_shader_parameter(entry.parameter, replacement)
	_apply_world()
	status.text = "Текстуры: блок %d · настройки сохранены" % factor


func _save_later() -> void:
	save_timer.start()


func _save() -> void:
	var config := ConfigFile.new()
	for key: String in values: config.set_value("world", key, values[key])
	for key: String in effects.settings:
		if key != "grid": config.set_value("post", key, effects.settings[key])
	config.set_value("post", "mode_index", effects.mode_index)
	config.set_value("post", "motion_enabled", effects.motion_enabled)
	var error := config.save(SAVE_PATH)
	if error != OK: status.text = "Не удалось сохранить настройки (%d)" % error


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK: return
	for key: String in values:
		if config.has_section_key("world", key): values[key] = config.get_value("world", key)
	effects.apply_mode(clampi(int(config.get_value("post", "mode_index", 1)), 0, effects.MODES.size() - 1))
	for key: String in effects.settings:
		if key != "grid" and config.has_section_key("post", key): effects.settings[key] = config.get_value("post", key)
	effects.motion_enabled = bool(config.get_value("post", "motion_enabled", true))
	# Clamp persisted controls to the supported ranges before applying them.
	for key: String in controls:
		var entry: Dictionary = controls[key]
		if entry.node is Range:
			var source: Dictionary = effects.settings if entry.post else values
			source[key] = clampf(float(source[key]), entry.node.min_value, entry.node.max_value)
	values.msaa = clampi(int(values.msaa), 0, 3)
	effects.apply_settings()
