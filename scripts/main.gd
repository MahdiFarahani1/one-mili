extends Control

const Data = preload("res://levels/level_data.gd")
const StageScript = preload("res://scripts/stage.gd")
const JellyScript = preload("res://entities/jelly.gd")
const JELLY_MENU = preload("res://assets/sprites/jelly_classic.png")
const FONT = preload("res://assets/fonts/Vazirmatn.ttf")
const BACKGROUNDS = [preload("res://assets/backgrounds/candy.png"), preload("res://assets/backgrounds/jungle.png"), preload("res://assets/backgrounds/crystal.png"), preload("res://assets/backgrounds/moon.png"), preload("res://assets/backgrounds/factory.png")]
const LEVEL_POINTS := [Vector2(120, 1030), Vector2(286, 946), Vector2(493, 967), Vector2(590, 839), Vector2(430, 744), Vector2(220, 781), Vector2(112, 647), Vector2(288, 563), Vector2(502, 584), Vector2(593, 460), Vector2(421, 369), Vector2(224, 403)]

var screen := "splash"
var ui: Control
var ui_layer: CanvasLayer
var stage: Stage
var selected_world := 0
var selected_level := 1
var endless_score := 0
var endless_run := false
var anim := 0.0
var toast := ""
var toast_time := 0.0
var hud_timer_label: Label
var hud_crystal_label: Label
var hud_direction_label: Label
var hud_hint_label: Label

func _ready() -> void:
	set_process(true)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui)
	Sound.music(0)
	show_screen("splash")
	get_tree().create_timer(1.6).timeout.connect(func(): if screen == "splash": show_screen("menu"))

func _process(delta: float) -> void:
	anim += delta
	toast_time = maxf(0.0, toast_time - delta)
	if screen == "game" and stage != null:
		if is_instance_valid(hud_timer_label):
			hud_timer_label.text = "◷  %02d:%02d" % [int(stage.seconds) / 60, int(stage.seconds) % 60]
		if is_instance_valid(hud_crystal_label):
			hud_crystal_label.text = "✦  %d/%d" % [stage.collected, stage.crystals.size()]
		if is_instance_valid(hud_direction_label):
			var direction: Vector2 = stage.player.gravity_direction
			hud_direction_label.text = "↓" if direction == Vector2.DOWN else ("←" if direction == Vector2.LEFT else ("↑" if direction == Vector2.UP else "→"))
		if is_instance_valid(hud_hint_label) and (selected_level > 3 or endless_run):
			hud_hint_label.text = "چرخش  %d" % stage.turns
	queue_redraw()

func _draw() -> void:
	if screen in ["game", "pause"]:
		return
	var theme_index := ["candy", "jungle", "crystal", "moon", "factory"].find(str(Save.data.get("theme", "candy")))
	var world := selected_world if screen in ["worlds", "levels"] else (int(Data.level(selected_level)["world"]) if screen in ["victory", "over"] and not endless_run else maxi(0, theme_index))
	draw_texture_rect(BACKGROUNDS[world], Rect2(0, 0, 720, 1280), false)
	draw_rect(Rect2(0, 0, 720, 1280), Color("030719", 0.24))
	draw_rect(Rect2(0, 0, 720, 145), Color("050a1c", 0.45))
	draw_rect(Rect2(0, 1090, 720, 190), Color("050a1c", 0.38))
	for i in 18:
		var p := Vector2(float((i * 293 + 57) % 720), float((i * 177 + 41) % 1280))
		draw_circle(p + Vector2(0, sin(anim * 1.5 + i) * 4), 1.4 + i % 3, Color("ffdd9b", 0.48))
	if screen == "levels":
		for i in LEVEL_POINTS.size() - 1:
			draw_line(LEVEL_POINTS[i], LEVEL_POINTS[i + 1], Color("e08cff", 0.18), 15, true)
			draw_line(LEVEL_POINTS[i], LEVEL_POINTS[i + 1], Color("e9a7ff", 0.81), 4, true)
		for p in LEVEL_POINTS:
			draw_circle(p, 52, Color("a572ff", 0.14))
			draw_circle(p, 47, Color("e5b5ff", 0.28))
	if screen in ["splash", "menu"]:
		var center := Vector2(360, 431 + sin(anim * 2.2) * 10.0)
		draw_circle(center, 101, Color("ffae70", 0.08))
		draw_circle(center, 89, Color("7fbbff", 0.10))
		draw_texture_rect(JELLY_MENU, Rect2(center - Vector2(74, 74), Vector2(148, 148)), false)
		draw_arc(center, 78, 0, TAU, 96, Color("a8dfff", 0.9), 5, true)
		draw_arc(center, 72, PI * 0.96, PI * 1.75, 48, Color("fff6fb", 0.66), 4, true)
		var blink := fmod(anim, 3.8) < 0.14
		if blink:
			draw_line(center + Vector2(-19, 1), center + Vector2(-7, 1), Color("233253"), 3, true)
			draw_line(center + Vector2(9, 1), center + Vector2(21, 1), Color("233253"), 3, true)
		else:
			draw_circle(center + Vector2(-14, -3), 6, Color("203253"))
			draw_circle(center + Vector2(15, -3), 6, Color("203253"))
			draw_circle(center + Vector2(-16, -5), 2, Color.WHITE)
			draw_circle(center + Vector2(13, -5), 2, Color.WHITE)
		draw_arc(center + Vector2(0, 12), 9, 0.15, PI - 0.15, 16, Color("28416b"), 3, true)
	if toast_time > 0.0:
		draw_rect(Rect2(105, 1138, 510, 76), Color("0d1630", 0.90))

func clear_ui() -> void:
	for child in ui.get_children():
		child.queue_free()
	if stage != null:
		stage.queue_free()
		stage = null

func show_screen(next: String) -> void:
	screen = next
	clear_ui()
	if next != "game" and next != "pause":
		Sound.music(0)
	match next:
		"splash":
			label("یک میلی‌متر", 95, 175, 530, 88, 62, Color("fff8ef"))
			label("O N E   M I L L I M E T E R", 80, 262, 560, 52, 20, Color("d7e7ff"))
			label("لمس کن، جهان را بچرخان", 90, 606, 540, 60, 28, Color("fff2d4"))
		"menu": build_menu()
		"worlds": build_worlds()
		"levels": build_levels()
		"game": start_stage()
		"pause": build_pause()
		"victory": build_victory()
		"over": build_over()
		"shop": build_shop()
		"custom": build_custom()
		"achievements": build_achievements()
		"settings": build_settings()
	queue_redraw()

func label(value: String, x: float, y: float, w: float, h: float, size: int = 30, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var n := Label.new()
	n.text = value
	n.position = Vector2(x, y + (safe_top() if y < 160 else 0.0))
	n.size = Vector2(w, h)
	n.horizontal_alignment = align
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n.add_theme_font_override("font", FONT)
	n.add_theme_font_size_override("font_size", size)
	var text_color := Color("e9e6ff") if color.get_luminance() < 0.55 else color
	n.add_theme_color_override("font_color", text_color)
	n.add_theme_color_override("font_shadow_color", Color("030716", 0.75))
	n.add_theme_constant_override("shadow_offset_y", 3)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(n)
	return n

func button(value: String, x: float, y: float, w: float, h: float, action: Callable, color: Color = Color("fff4d2"), size: int = 29) -> Button:
	var b := Button.new()
	b.text = value
	b.position = Vector2(x, y + (safe_top() if y < 160 else 0.0))
	b.size = Vector2(w, h)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", Color("fff9ec"))
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", Color("fff5da"))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("25304b", 0.95) if state == "hover" else (Color("3a2a36", 0.97) if state == "pressed" else Color("0a142b", 0.88))
		style.set_corner_radius_all(int(h * 0.43))
		style.border_color = color.darkened(0.18)
		style.set_border_width_all(2 if state == "disabled" else 3)
		style.shadow_color = Color(color.r, color.g, color.b, 0.36)
		style.shadow_size = 12 if state != "pressed" else 4
		style.shadow_offset = Vector2(0, 5)
		b.add_theme_stylebox_override(state, style)
	b.pressed.connect(func(): Sound.tone("tap"); action.call())
	ui.add_child(b)
	return b

func safe_top() -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	var viewport_height := maxf(1.0, float(DisplayServer.window_get_size().y))
	return clampf(float(DisplayServer.get_display_safe_area().position.y) * 1280.0 / viewport_height, 0.0, 90.0)

func title(value: String, back: String = "menu") -> void:
	button("‹", 34, 43, 70, 70, func(): show_screen(back), Color("a8c4f8"), 39)
	label(value, 118, 48, 480, 66, 42, Color.WHITE)
	button("✦ %d" % int(Save.data["crystals"]), 505, 130, 165, 55, func(): show_screen("shop"), Color("b888ff"), 23)

func build_menu() -> void:
	Save.ensure_daily()
	button("✦  %d   +" % int(Save.data["crystals"]), 32, 42, 200, 62, func(): show_screen("shop"), Color("b58fff"), 24)
	label("یک میلی‌متر", 75, 171, 570, 96, 66, Color("fff8ee"))
	label("O N E   M I L L I M E T E R", 80, 264, 560, 50, 19, Color("d9e7ff"))
	label("یک لمس، دنیایی دیگر", 80, 543, 560, 50, 25, Color("e8d8ff"))
	button("▶  بازی کن", 116, 621, 488, 88, func(): show_screen("worlds"), Color("ffba63"), 37)
	button("∞  حالت بی‌پایان", 144, 733, 432, 71, func(): start_endless(), Color("9cb9ff"))
	button("مراحل", 74, 834, 270, 67, func(): show_screen("worlds"), Color("a8bbf0"))
	button("فروشگاه", 376, 834, 270, 67, func(): show_screen("shop"), Color("dab0ff"))
	button("شخصی‌سازی", 74, 922, 270, 67, func(): show_screen("custom"), Color("b8ecff"))
	button("تنظیمات", 376, 922, 270, 67, func(): show_screen("settings"), Color("f2c398"))
	button("دستاوردها", 74, 1010, 270, 67, func(): show_screen("achievements"), Color("eaaad9"))
	button("چالش %d/%d" % [int(Save.data["daily"]["progress"]), int(Save.data["daily"]["target"])], 376, 1010, 270, 67, func(): claim_daily(), Color("ffda89"))

func build_worlds() -> void:
	title("دنیاهای جادویی")
	for i in 5:
		var index := i
		var unlocked := Save.unlocked_level() >= i * 12 + 1
		var sub := "  ·  %s از ۱۲" % persian_number(completed_in_world(i))
		var text_value: String = (Data.WORLD_FA[i] + sub) if unlocked else (Data.WORLD_FA[i] + "  🔒")
		var card := button(text_value, 78, 235 + i * 170, 564, 126, func(): select_world(index, unlocked), Data.WORLD_COLORS[i].lightened(0.25), 29)
		var holder := Control.new()
		holder.position = Vector2(12, 11)
		holder.size = Vector2(104, 104)
		holder.clip_contents = true
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(holder)
		var art := TextureRect.new()
		art.texture = BACKGROUNDS[i]
		art.position = Vector2.ZERO
		art.size = Vector2(104, 104)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(art)
		label(Data.WORLD_NAMES[i], 200, 308 + i * 170, 390, 37, 20, Color("bed4ff"))

func completed_in_world(world: int) -> int:
	var count := 0
	for i in 12:
		if Save.data["levels"].has(str(world * 12 + i + 1)):
			count += 1
	return count

func persian_number(value: int) -> String:
	var result := str(value)
	for i in 10:
		result = result.replace(str(i), "۰۱۲۳۴۵۶۷۸۹"[i])
	return result

func build_levels() -> void:
	title(Data.WORLD_FA[selected_world], "worlds")
	label("مسیر جزیره‌های جادویی", 66, 190, 588, 57, 25, Color("ddd7ff"))
	for i in 12:
		var number := selected_world * 12 + i + 1
		var unlocked := number <= Save.unlocked_level()
		var stars := int(Save.data["levels"].get(str(number), {}).get("stars", 0))
		var point: Vector2 = LEVEL_POINTS[i]
		button(str(number) if unlocked else "🔒", point.x - 43, point.y - 43, 86, 86, func(): select_level(number, unlocked), Color("ffca75") if unlocked else Color("8a83b1"), 32)
		if stars > 0: label("★".repeat(stars), point.x - 57, point.y + 40, 114, 36, 22, Color("ffe18a"))
	label("★  %d ستاره از ۳۶" % stars_in_world(selected_world), 175, 1130, 370, 52, 24, Color("ffe7ad"))

func stars_in_world(world: int) -> int:
	var count := 0
	for i in 12:
		count += int(Save.data["levels"].get(str(world * 12 + i + 1), {}).get("stars", 0))
	return count

func select_world(index: int, unlocked: bool) -> void:
	if unlocked:
		selected_world = index
		show_screen("levels")

func select_level(number: int, unlocked: bool) -> void:
	if unlocked:
		selected_level = number
		endless_run = false
		show_screen("game")

func start_stage() -> void:
	var details := Data.level(selected_level)
	stage = StageScript.new(details)
	add_child(stage)
	move_child(stage, 0)
	stage.won.connect(on_stage_won)
	stage.lost.connect(on_stage_lost)
	stage.crystal_collected.connect(func(c: int): if c >= 2: pop_toast("کمبو ×%d" % c))
	stage.secret_found.connect(func(): pop_toast("کریستال مخفی +۸"))
	Save.data["attempts"] += 1
	Save.save_game()
	button("Ⅱ", 595, 72, 74, 72, func(): screen = "pause"; build_pause(), Color("fff4d2"), 34)
	label("مرحله %d" % selected_level if not endless_run else "بی‌پایان · %d" % endless_score, 72, 72, 430, 65, 37, Color.WHITE)
	create_hud_metrics()
	button("↻", 40, 1168, 95, 74, func(): stage.restart(), Color("aabaff"), 36)
	hud_hint_label = label("لمس کن تا جاذبه بچرخد" if selected_level <= 3 and not endless_run else "چرخش  ۰", 147, 1178, 500, 56, 24, Color.WHITE)

func create_hud_metrics() -> void:
	hud_direction_label = label("↓", 36, 152, 80, 58, 35, Color("a8e6ff"))
	hud_timer_label = label("◷  00:00", 125, 152, 275, 58, 28, Color("fff2dc"))
	hud_crystal_label = label("✦  0/0", 420, 152, 220, 58, 26, Color("ffde98"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if screen == "game":
			screen = "pause"
			build_pause()
		elif screen == "pause":
			screen = "game"
			show_game_hud()
		elif screen in ["worlds", "shop", "custom", "achievements", "settings"]:
			show_screen("menu")
		elif screen == "levels":
			show_screen("worlds")
		get_viewport().set_input_as_handled()
		return
	if screen == "game" and stage != null:
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			stage.rotate_gravity()
			get_viewport().set_input_as_handled()
	elif screen == "menu" and event is InputEventScreenTouch and event.pressed:
		Sound.tone("tap")

func on_stage_won(seconds: float, turns: int, count: int) -> void:
	if endless_run:
		endless_score += 1
		Save.data["crystals"] += count + 3
		if endless_score > int(Save.data["endless_best"]):
			Save.data["endless_best"] = endless_score
		Save.save_game()
		selected_level = (endless_score * 7 + 11) % 60 + 1
		show_screen("game")
		return
	var details := Data.level(selected_level)
	var stars := 1
	if seconds <= float(details["par_time"]): stars += 1
	if turns <= int(details["par_turns"]): stars += 1
	var reward := Save.complete_level(selected_level, seconds, turns, stars, count)
	set_meta("last_result", {"stars": stars, "seconds": seconds, "turns": turns, "reward": reward})
	show_screen("victory")

func on_stage_lost() -> void:
	show_screen("over")

func build_pause() -> void:
	if stage != null:
		stage.process_mode = Node.PROCESS_MODE_DISABLED
		for child in ui.get_children(): child.queue_free()
	var shade := ColorRect.new()
	shade.color = Color("24133e", 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	label("مکث کوچولو", 100, 348, 520, 90, 52, Color.WHITE)
	button("ادامه", 138, 530, 444, 80, func(): screen = "game"; stage.player.alive = true; show_game_hud(), Color("fff1b1"))
	button("شروع دوباره", 138, 634, 444, 80, func(): show_screen("game"), Color("d8f8ef"))
	button("فهرست مراحل", 138, 738, 444, 80, func(): show_screen("levels"), Color("ffe4ef"))

func show_game_hud() -> void:
	if stage != null:
		stage.process_mode = Node.PROCESS_MODE_INHERIT
	for child in ui.get_children(): child.queue_free()
	button("Ⅱ", 595, 72, 74, 72, func(): screen = "pause"; build_pause(), Color("fff4d2"), 34)
	label("مرحله %d" % selected_level if not endless_run else "بی‌پایان · %d" % endless_score, 72, 72, 430, 65, 37, Color.WHITE)
	create_hud_metrics()
	button("↻", 40, 1168, 95, 74, func(): stage.restart(), Color("aabaff"), 36)
	hud_hint_label = label("لمس کن تا جاذبه بچرخد" if selected_level <= 3 and not endless_run else "چرخش  ۰", 147, 1178, 500, 56, 24, Color.WHITE)

func build_victory() -> void:
	var result: Dictionary = get_meta("last_result", {})
	label("درخشان بود!", 80, 310, 560, 90, 54, Color.WHITE)
	var star_label := label("★".repeat(int(result.get("stars", 1))), 120, 405, 480, 100, 67, Color("fff5ac"))
	star_label.pivot_offset = star_label.size / 2.0
	star_label.scale = Vector2(0.65, 0.65)
	create_tween().tween_property(star_label, "scale", Vector2.ONE, 0.44).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if int(result.get("stars", 1)) == 3:
		label("اجرای بی‌نقص!", 140, 487, 440, 50, 26, Color("fff6b5"))
	label("زمان  %.1f ثانیه    ·    %d چرخش" % [float(result.get("seconds", 0)), int(result.get("turns", 0))], 80, 525, 560, 70, 29, Color("5b3d69"))
	label("+%d کریستال" % int(result.get("reward", 0)), 110, 610, 500, 70, 34, Color("fffde4"))
	button("مرحلهٔ بعد", 136, 746, 448, 83, func(): selected_level = mini(60, selected_level + 1); show_screen("game"), Color("fff0a8"))
	button("دوباره", 136, 850, 448, 77, func(): show_screen("game"), Color("e1f7ef"))
	button("فهرست مراحل", 136, 948, 448, 77, func(): show_screen("levels"), Color("ffe6f0"))

func build_over() -> void:
	label("اوه، نزدیک بود!", 75, 355, 570, 90, 51, Color.WHITE)
	label("فقط یک چرخش تا پیروزی فاصله داری", 80, 465, 560, 60, 26, Color("68486f"))
	if endless_run:
		label("امتیاز %d   ·   رکورد %d" % [endless_score, int(Save.data["endless_best"])], 80, 566, 560, 70, 34, Color.WHITE)
		if endless_score > 0 and endless_score == int(Save.data["endless_best"]):
			label("رکورد تازه! ✦", 120, 633, 480, 60, 32, Color("fff4a7"))
	button("تلاش دوباره  ↻", 137, 721, 446, 85, func(): retry_after_loss(), Color("fff1b4"))
	button("بازگشت", 137, 827, 446, 78, func(): show_screen("menu" if endless_run else "levels"), Color("e5f8ee"))

func start_endless() -> void:
	endless_run = true
	endless_score = 0
	selected_level = 1
	show_screen("game")

func retry_after_loss() -> void:
	if endless_run:
		start_endless()
	else:
		show_screen("game")

func pop_toast(message: String) -> void:
	toast = message
	toast_time = 1.7
	label(message, 105, 1139, 510, 70, 30, Color.WHITE)

func claim_daily() -> void:
	var reward := Save.daily_claim()
	pop_toast("+%d کریستال روزانه" % reward if reward > 0 else "اول چالش امروز را کامل کن")
	Sound.tone("crystal" if reward > 0 else "tap")
	if reward > 0: show_screen("menu")

func build_shop() -> void:
	title("فروشگاه کریستالی")
	label("آیتم‌های تازه، با کریستال‌های خودت", 70, 175, 580, 65, 25, Color("63476c"))
	button("اسکین‌ها", 80, 257, 270, 70, func(): build_shop_list("skins"), Color("ffe9f0"))
	button("رد حرکت", 370, 257, 270, 70, func(): build_shop_list("trails"), Color("e1f7fc"))
	button("تم‌ها", 80, 346, 560, 70, func(): build_shop_list("themes"), Color("f6e8ff"))
	label("پرداخت واقعی در این نسخه فعال نیست.", 95, 470, 530, 70, 24, Color("614c71"))
	label("همهٔ آیتم‌های این صفحه با بازی‌کردن باز می‌شوند.", 65, 530, 590, 70, 23, Color("614c71"))
	label("★  اسکین کلاسیک و رد درخشش از ابتدا در دسترس‌اند", 68, 650, 584, 75, 25, Color("fff9e7"))

func build_shop_list(category: String) -> void:
	for child in ui.get_children(): child.queue_free()
	var heading := "اسکین‌ها" if category == "skins" else ("رد حرکت" if category == "trails" else "تم‌های محیط")
	button("‹", 34, 43, 70, 70, func(): show_screen("shop"), Color.WHITE, 39)
	label(heading, 130, 52, 460, 60, 42)
	label("✦ %d کریستال" % int(Save.data["crystals"]), 120, 141, 480, 65, 27, Color("69436c"))
	var names: Array = Data.SKIN_NAMES if category == "skins" else (Data.TRAIL_NAMES if category == "trails" else Data.WORLD_FA)
	var ids: Array = Data.SKINS if category == "skins" else (Data.TRAILS if category == "trails" else ["candy", "jungle", "crystal", "moon", "factory"])
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(45, 235)
	scroll.size = Vector2(630, 910)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(scroll)
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(607, 0)
	list.add_theme_constant_override("separation", 18)
	scroll.add_child(list)
	for i in ids.size():
		var item: String = ids[i]
		var owned := Save.own(category, item)
		var cost := Data.shop_cost(category, i)
		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("fff5e9") if owned else Color("f8e9fa")
		style.set_corner_radius_all(28)
		style.set_content_margin_all(14)
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size.y = 95
		list.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)
		var name_label := Label.new()
		name_label.text = "✦  " + str(names[i])
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_override("font", FONT)
		name_label.add_theme_font_size_override("font_size", 26)
		name_label.add_theme_color_override("font_color", Color("5a3b65"))
		h.add_child(name_label)
		var buy := Button.new()
		buy.text = "دارم" if owned else "✦ %d" % cost
		buy.disabled = owned
		buy.custom_minimum_size = Vector2(145, 65)
		buy.add_theme_font_override("font", FONT)
		buy.add_theme_font_size_override("font_size", 23)
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color("d8f5e3") if owned else Color("fff0ac")
		bs.set_corner_radius_all(25)
		buy.add_theme_stylebox_override("normal", bs)
		buy.add_theme_stylebox_override("disabled", bs)
		buy.pressed.connect(func():
			if Save.purchase(category, item, cost):
				Sound.tone("buy")
				build_shop_list(category)
			else:
				pop_toast("کریستال کافی نیست")
		)
		h.add_child(buy)

func build_custom() -> void:
	title("ژلهٔ من")
	label("اسکین انتخابی", 95, 143, 530, 64, 32, Color("68456b"))
	var preview: Jelly = JellyScript.new()
	preview.position = Vector2(360, 285)
	preview.scale = Vector2(2.8, 2.8)
	preview.skin = str(Save.data["skin"])
	preview.alive = false
	ui.add_child(preview)
	label(Data.SKIN_NAMES[maxi(0, Data.SKINS.find(Save.data["skin"]))], 110, 358, 500, 60, 32, Color.WHITE)
	button("اسکین قبلی", 75, 436, 270, 70, func(): cycle_owned("skins", -1), Color("fff1d4"))
	button("اسکین بعدی", 375, 436, 270, 70, func(): cycle_owned("skins", 1), Color("fff1d4"))
	label("رد حرکت", 95, 548, 530, 55, 32, Color("68456b"))
	label(Data.TRAIL_NAMES[maxi(0, Data.TRAILS.find(Save.data["trail"]))], 110, 600, 500, 55, 30, Color.WHITE)
	button("رد قبلی", 75, 672, 270, 70, func(): cycle_owned("trails", -1), Color("dcf8f3"))
	button("رد بعدی", 375, 672, 270, 70, func(): cycle_owned("trails", 1), Color("dcf8f3"))
	label("تم محیط: " + Data.WORLD_FA[maxi(0, ["candy", "jungle", "crystal", "moon", "factory"].find(str(Save.data["theme"])))], 95, 806, 530, 70, 30, Color("68456b"))
	button("تغییر تم", 140, 894, 440, 74, func(): cycle_owned("themes", 1), Color("e6e7ff"))
	button("رفتن به فروشگاه", 140, 1008, 440, 74, func(): show_screen("shop"), Color("fff2a8"))

func cycle_owned(category: String, direction: int) -> void:
	var owned: Array = Save.data[category]
	if owned.is_empty(): return
	var key := "skin" if category == "skins" else ("trail" if category == "trails" else "theme")
	var index := owned.find(Save.data[key])
	Save.data[key] = owned[posmod(index + direction, owned.size())]
	Save.save_game()
	Sound.tone("tap")
	show_screen("custom")

func build_achievements() -> void:
	title("دستاوردها")
	var stats := [
		["اولین گام", "یک مرحله را کامل کن", Save.data["levels"].size() >= 1],
		["ستاره‌چین", "۱۰ ستاره جمع کن", total_stars() >= 10],
		["جهانگرد", "۱۲ مرحله را کامل کن", Save.data["levels"].size() >= 12],
		["پشتکار ژله‌ای", "۲۰ بار تلاش کن", int(Save.data["attempts"]) >= 20],
		["بی‌پایان", "۵ قطعهٔ بی‌پایان را رد کن", int(Save.data["endless_best"]) >= 5],
		["استاد میلی‌متر", "همهٔ ۶۰ مرحله را کامل کن", Save.data["levels"].size() >= 60]
	]
	for i in stats.size():
		var info: Array = stats[i]
		var achieved: bool = info[2]
		label(("★  " if achieved else "☆  ") + str(info[0]), 72, 241 + i * 145, 380, 60, 32, Color("fff8d9") if achieved else Color("765477"))
		label(str(info[1]), 75, 295 + i * 145, 400, 46, 23, Color("664d72"))
		if achieved and not i in Save.data["achievements"]:
			var id := i
			button("+%d ✦" % (30 + id * 10), 478, 261 + i * 145, 160, 64, func(): claim_achievement(id), Color("fff0a8"), 25)
		elif achieved:
			label("دریافت شد", 480, 266 + i * 145, 155, 52, 23, Color("5a986f"))
	label("تکمیل هر مرحله، کریستال و ستاره می‌دهد", 80, 1128, 560, 56, 22, Color("664d72"))

func claim_achievement(id: int) -> void:
	var reward := Save.claim_achievement(id)
	if reward > 0:
		Sound.tone("buy")
		show_screen("achievements")

func total_stars() -> int:
	var count := 0
	for entry in Save.data["levels"].values(): count += int(entry.get("stars", 0))
	return count

func build_settings() -> void:
	title("تنظیمات")
	button("موسیقی  %s" % ("روشن" if Save.data["music"] else "خاموش"), 105, 290, 510, 88, func(): toggle_setting("music"), Color("e2f7ff"))
	button("صداها  %s" % ("روشن" if Save.data["sfx"] else "خاموش"), 105, 420, 510, 88, func(): toggle_setting("sfx"), Color("ffe8ee"))
	button("لرزش  %s" % ("روشن" if Save.data["vibration"] else "خاموش"), 105, 550, 510, 88, func(): toggle_setting("vibration"), Color("fff3ce"))
	label("بازی کاملاً آفلاین است و پیشرفت روی همین دستگاه ذخیره می‌شود.", 75, 742, 570, 106, 23, Color("654b70"))
	label("ONE MILLIMETER  ·  v0.1", 100, 1006, 520, 60, 24, Color("735277"))

func toggle_setting(key: String) -> void:
	Save.data[key] = not Save.data[key]
	Save.save_game()
	Sound.music(0)
	show_screen("settings")
