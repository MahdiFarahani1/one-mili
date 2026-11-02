extends Control

const Data = preload("res://levels/level_data.gd")
const StageScript = preload("res://scripts/stage.gd")
const JellyScript = preload("res://entities/jelly.gd")
const JELLY_MENU = preload("res://assets/sprites/jelly_classic.png")
const FONT = preload("res://assets/fonts/Vazirmatn.ttf")
const BACKGROUNDS = [
	preload("res://assets/backgrounds/candy.png"),
	preload("res://assets/backgrounds/jungle.png"),
	preload("res://assets/backgrounds/crystal.png"),
	preload("res://assets/backgrounds/moon.png"),
	preload("res://assets/backgrounds/factory.png")
]
const WORLD_TAGLINES := [
	"پرواز بر فراز جزایر معلق با فرودهای میلی‌متری",
	"گذر از ریتم تله‌های گیاهی و قارچ‌های شب‌تاب",
	"مسیرخوانی در میان بلورهای درخشان و شکننده",
	"مهار جاذبه در مدارهای بی‌وزنی و پرتال‌های کیهانی",
	"نبرد نهایی با چرخ‌دنده‌ها، پیستون‌ها و لیزرهای سرخ"
]

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
	
	# Background art with dark fantasy vignette overlay
	draw_texture_rect(BACKGROUNDS[world], Rect2(0, 0, 720, 1280), false)
	draw_rect(Rect2(0, 0, 720, 1280), Color("030719", 0.44))
	draw_rect(Rect2(0, 0, 720, 145), Color("050a1c", 0.75))
	draw_rect(Rect2(0, 1090, 720, 190), Color("050a1c", 0.65))
	
	# Ambient glowing runes / dust
	for i in 18:
		var p := Vector2(float((i * 293 + 57) % 720), float((i * 177 + 41) % 1280))
		draw_circle(p + Vector2(0, sin(anim * 1.5 + i) * 5), 1.5 + float(i % 3), Color("ffdd9b", 0.45))
		
	if screen in ["splash", "menu"]:
		var center := Vector2(360, 431 + sin(anim * 2.2) * 10.0)
		draw_circle(center, 106, Color("7fbbff", 0.08))
		draw_circle(center, 88, Color("a88cff", 0.12))
		draw_texture_rect(JELLY_MENU, Rect2(center - Vector2(74, 74), Vector2(148, 148)), false)
		draw_arc(center, 78, 0, TAU, 96, Color("38b6ff", 0.85), 4, true)
		draw_arc(center, 72, PI * 0.96, PI * 1.75, 48, Color("ffffff", 0.7), 3, true)
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
		draw_rect(Rect2(105, 1138, 510, 76), Color("0d1630", 0.92))
		draw_rect(Rect2(105, 1138, 510, 76), Color("597fff", 0.45), false, 2)

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
			label("یک میلی‌متر", 95, 175, 530, 88, 64, Color("fff8ef"))
			label("O N E   M I L L I M E T E R", 80, 262, 560, 52, 21, Color("74ddff"))
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
	n.add_theme_color_override("font_color", color)
	n.add_theme_color_override("font_shadow_color", Color("02040d", 0.9))
	n.add_theme_constant_override("shadow_offset_y", 2)
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
		style.bg_color = color.darkened(0.68) if state == "hover" else (color.darkened(0.82) if state == "pressed" else Color("0e122b", 0.94))
		style.set_corner_radius_all(int(minf(24.0, h * 0.32)))
		style.border_color = color.darkened(0.15) if state != "disabled" else Color("3c4263")
		style.set_border_width_all(2 if state == "disabled" else 3)
		style.shadow_color = Color(color.r, color.g, color.b, 0.40)
		style.shadow_size = 12 if state != "pressed" else 4
		style.shadow_offset = Vector2(0, 4)
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
	button("‹", 34, 43, 70, 70, func(): show_screen(back), Color("74ddff"), 39)
	label(value, 118, 48, 480, 66, 40, Color.WHITE)
	button("✦ %d" % int(Save.data["crystals"]), 505, 130, 165, 55, func(): show_screen("shop"), Color("ffb84d"), 23)

func build_menu() -> void:
	Save.ensure_daily()
	button("✦  %d   +" % int(Save.data["crystals"]), 32, 42, 200, 62, func(): show_screen("shop"), Color("ffb84d"), 24)
	label("یک میلی‌متر", 75, 171, 570, 96, 68, Color("fff8ee"))
	label("O N E   M I L L I M E T E R", 80, 264, 560, 50, 20, Color("74ddff"))
	label("یک لمس، دنیایی دیگر", 80, 543, 560, 50, 25, Color("cbd8ff"))
	
	button("▶  شروع ماجراجویی", 116, 621, 488, 88, func(): show_screen("worlds"), Color("38b6ff"), 35)
	button("∞  حالت بی‌پایان", 144, 733, 432, 71, func(): start_endless(), Color("b566ff"), 29)
	button("مراحل", 74, 834, 270, 67, func(): show_screen("worlds"), Color("3fe08c"), 27)
	button("فروشگاه", 376, 834, 270, 67, func(): show_screen("shop"), Color("ffb84d"), 27)
	button("شخصی‌سازی", 74, 922, 270, 67, func(): show_screen("custom"), Color("6a7eff"), 27)
	button("تنظیمات", 376, 922, 270, 67, func(): show_screen("settings"), Color("b566ff"), 27)
	button("دستاوردها", 74, 1010, 270, 67, func(): show_screen("achievements"), Color("ff7a29"), 27)
	button("چالش %d/%d" % [int(Save.data["daily"]["progress"]), int(Save.data["daily"]["target"])], 376, 1010, 270, 67, func(): claim_daily(), Color("ffd84d"), 27)

func build_worlds() -> void:
	title("انتخاب جهان")
	label("پنج جهان، پنج آزمون متفاوت", 72, 177, 576, 47, 24, Color("cbd6ff"))
	for i in 5:
		var index := i
		var unlocked := Save.unlocked_level() >= i * 12 + 1
		var y := 246.0 + i * 168.0
		var card := button("", 56, y, 608, 144, func(): select_world(index, unlocked), Data.WORLD_COLORS[i], 27)
		
		var holder := Control.new()
		holder.position = Vector2(446, 12)
		holder.size = Vector2(150, 120)
		holder.clip_contents = true
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(holder)
		
		var art := TextureRect.new()
		art.texture = BACKGROUNDS[i]
		art.position = Vector2.ZERO
		art.size = Vector2(150, 120)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(art)
		
		var title_text := Label.new()
		title_text.text = (Data.WORLD_FA[i] + "  ·  %d/12" % completed_in_world(i)) if unlocked else (Data.WORLD_FA[i] + "  🔒")
		title_text.position = Vector2(20, 16)
		title_text.size = Vector2(410, 48)
		title_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		title_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_text.add_theme_font_override("font", FONT)
		title_text.add_theme_font_size_override("font_size", 30)
		title_text.add_theme_color_override("font_color", Color.WHITE if unlocked else Color("9fa4be"))
		title_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(title_text)
		
		var detail := Label.new()
		detail.text = WORLD_TAGLINES[i]
		detail.position = Vector2(20, 74)
		detail.size = Vector2(410, 48)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		detail.add_theme_font_override("font", FONT)
		detail.add_theme_font_size_override("font_size", 19)
		detail.add_theme_color_override("font_color", Color("d0d6f5") if unlocked else Color("7c83a4"))
		detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(detail)

func completed_in_world(world: int) -> int:
	var count := 0
	for i in 12:
		if Save.data["levels"].has(str(world * 12 + i + 1)):
			count += 1
	return count

func build_levels() -> void:
	title(Data.WORLD_FA[selected_world], "worlds")
	label(WORLD_TAGLINES[selected_world], 76, 181, 568, 52, 24, Color("d6d9ff"))
	for i in 12:
		var number := selected_world * 12 + i + 1
		var unlocked := number <= Save.unlocked_level()
		var stars := int(Save.data["levels"].get(str(number), {}).get("stars", 0))
		var col := i % 3
		var row := i / 3
		var x := 85.0 + float(col) * 192.0
		var y := 280.0 + float(row) * 180.0
		var card := button(str(i + 1) if unlocked else "🔒", x, y, 164, 140, func(): select_level(number, unlocked), Data.WORLD_COLORS[selected_world] if unlocked else Color("595c73"), 44)
		if stars > 0:
			var star_text := Label.new()
			star_text.text = "★".repeat(stars)
			star_text.position = Vector2(8, 98)
			star_text.size = Vector2(148, 35)
			star_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			star_text.add_theme_font_override("font", FONT)
			star_text.add_theme_font_size_override("font_size", 23)
			star_text.add_theme_color_override("font_color", Color("ffe18a"))
			star_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(star_text)
	label("★  %d / ۳۶ ستاره جهان" % stars_in_world(selected_world), 160, 1081, 400, 56, 28, Color("ffe7ad"))

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
	button("↻", 40, 1168, 95, 74, func(): stage.restart(), Color("74ddff"), 36)
	hud_hint_label = label("لمس کن تا جاذبه بچرخد" if selected_level <= 3 and not endless_run else "چرخش  ۰", 147, 1178, 500, 56, 24, Color.WHITE)

func create_hud_metrics() -> void:
	hud_direction_label = label("↓", 36, 152, 80, 58, 35, Color("74ddff"))
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
	
	# Frosted dark overlay
	var shade := ColorRect.new()
	shade.color = Color("040714", 0.75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	
	var card := make_modal_panel(110, 300, 500, 480, Color("38b6ff"))
	ui.add_child(card)
	
	label("مکث", 110, 320, 500, 70, 50, Color.WHITE)
	label("مرحله %d" % selected_level if not endless_run else "حالت بی‌پایان", 110, 395, 500, 45, 24, Color("cbd8ff"))
	
	button("ادامه", 150, 470, 420, 76, func(): screen = "game"; stage.player.alive = true; show_game_hud(), Color("3fe08c"), 30)
	button("شروع دوباره", 150, 565, 420, 76, func(): show_screen("game"), Color("74ddff"), 30)
	button("فهرست مراحل", 150, 660, 420, 76, func(): show_screen("levels"), Color("b566ff"), 30)

func show_game_hud() -> void:
	if stage != null:
		stage.process_mode = Node.PROCESS_MODE_INHERIT
	for child in ui.get_children(): child.queue_free()
	button("Ⅱ", 595, 72, 74, 72, func(): screen = "pause"; build_pause(), Color("fff4d2"), 34)
	label("مرحله %d" % selected_level if not endless_run else "بی‌پایان · %d" % endless_score, 72, 72, 430, 65, 37, Color.WHITE)
	create_hud_metrics()
	button("↻", 40, 1168, 95, 74, func(): stage.restart(), Color("74ddff"), 36)
	hud_hint_label = label("لمس کن تا جاذبه بچرخد" if selected_level <= 3 and not endless_run else "چرخش  ۰", 147, 1178, 500, 56, 24, Color.WHITE)

func build_victory() -> void:
	var result: Dictionary = get_meta("last_result", {})
	var stars: int = int(result.get("stars", 1))
	
	var shade := ColorRect.new()
	shade.color = Color("040714", 0.75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	
	var card := make_modal_panel(80, 240, 560, 760, Color("ffd45e"))
	ui.add_child(card)
	
	label("پیروزی درخشان!", 80, 265, 560, 80, 52, Color("fff8d4"))
	
	var star_label := label("★".repeat(stars), 120, 360, 480, 80, 64, Color("ffe18a"))
	star_label.pivot_offset = star_label.size / 2.0
	star_label.scale = Vector2(0.5, 0.5)
	create_tween().tween_property(star_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if stars == 3:
		label("اجرای بی‌نقص و مهارتی!", 120, 445, 480, 45, 25, Color("9fffe8"))
		
	label("زمان: %.1f ثانیه   ·   چرخش: %d" % [float(result.get("seconds", 0)), int(result.get("turns", 0))], 90, 505, 540, 60, 26, Color("cbd8ff"))
	label("+%d کریستال پاداش ✦" % int(result.get("reward", 0)), 90, 575, 540, 60, 32, Color("ffe794"))
	
	button("مرحلهٔ بعدی  ▶", 130, 675, 460, 84, func(): selected_level = mini(60, selected_level + 1); show_screen("game"), Color("38b6ff"), 33)
	button("تلاش مجدد  ↻", 130, 775, 460, 76, func(): show_screen("game"), Color("3fe08c"), 28)
	button("فهرست مراحل", 130, 865, 460, 76, func(): show_screen("levels"), Color("b566ff"), 28)

func build_over() -> void:
	var shade := ColorRect.new()
	shade.color = Color("040714", 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	
	var card := make_modal_panel(80, 270, 560, 690, Color("ff4971"))
	ui.add_child(card)
	
	label("فرود ناموفق!", 80, 295, 560, 80, 52, Color("fff0f3"))
	label("فقط یک چرخش با پیروزی فاصله داشتی", 90, 385, 540, 50, 25, Color("ffbdc9"))
	
	if endless_run:
		label("امتیاز %d   ·   رکورد %d" % [endless_score, int(Save.data["endless_best"])], 90, 455, 540, 60, 32, Color.WHITE)
		if endless_score > 0 and endless_score == int(Save.data["endless_best"]):
			label("رکورد تازه! ✦", 120, 515, 480, 50, 28, Color("ffe18a"))
	else:
		label("مرحله %d" % selected_level, 90, 455, 540, 55, 30, Color("cbd8ff"))
		
	button("تلاش دوباره  ↻", 130, 620, 460, 86, func(): retry_after_loss(), Color("ffb84d"), 34)
	button("فهرست مراحل", 130, 725, 460, 76, func(): show_screen("levels" if not endless_run else "menu"), Color("74ddff"), 28)

func make_modal_panel(x: float, y: float, w: float, h: float, border_glow: Color) -> Panel:
	var panel := Panel.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(w, h)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0c102b", 0.96)
	style.set_corner_radius_all(32)
	style.border_color = border_glow
	style.set_border_width_all(3)
	style.shadow_color = Color(border_glow.r, border_glow.g, border_glow.b, 0.42)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", style)
	return panel

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
	label(message, 105, 1139, 510, 70, 28, Color.WHITE)

func claim_daily() -> void:
	var reward := Save.daily_claim()
	pop_toast("+%d کریستال روزانه" % reward if reward > 0 else "اول چالش امروز را کامل کن")
	Sound.tone("crystal" if reward > 0 else "tap")
	if reward > 0: show_screen("menu")

func build_shop() -> void:
	title("فروشگاه کریستالی")
	label("آیتم‌های اختصاصی با کریستال‌های به‌دست‌آمده", 70, 180, 580, 50, 24, Color("cbd8ff"))
	
	button("اسکین‌های ژله", 80, 255, 265, 75, func(): build_shop_list("skins"), Color("38b6ff"), 27)
	button("رد حرکت نئونی", 375, 255, 265, 75, func(): build_shop_list("trails"), Color("b566ff"), 27)
	button("تم‌های محیطی", 80, 350, 560, 75, func(): build_shop_list("themes"), Color("3fe08c"), 27)
	
	var info_box := make_modal_panel(75, 480, 570, 320, Color("4f78ff"))
	ui.add_child(info_box)
	label("سیستم کاملاً آفلاین و عادلانه", 90, 510, 540, 55, 29, Color("ffe18a"))
	label("تمام اسکین‌ها، رد‌های حرکتی و تم‌ها", 90, 575, 540, 45, 23, Color.WHITE)
	label("فقط با بازی‌کردن و مهارت خودت باز می‌شوند.", 90, 620, 540, 45, 23, Color("cbd8ff"))
	label("★ اسکین کلاسیک و رد درخشش از آغاز فعال‌اند", 90, 695, 540, 50, 23, Color("9fffe8"))

func build_shop_list(category: String) -> void:
	for child in ui.get_children(): child.queue_free()
	var heading := "اسکین‌های ژله" if category == "skins" else ("رد حرکت نئونی" if category == "trails" else "تم‌های محیطی")
	button("‹", 34, 43, 70, 70, func(): show_screen("shop"), Color("74ddff"), 39)
	label(heading, 130, 52, 460, 60, 40)
	button("✦ %d" % int(Save.data["crystals"]), 505, 130, 165, 55, func(): {}, Color("ffb84d"), 23)
	
	var names: Array = Data.SKIN_NAMES if category == "skins" else (Data.TRAIL_NAMES if category == "trails" else Data.WORLD_FA)
	var ids: Array = Data.SKINS if category == "skins" else (Data.TRAILS if category == "trails" else ["candy", "jungle", "crystal", "moon", "factory"])
	
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(45, 210)
	scroll.size = Vector2(630, 930)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(scroll)
	
	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(610, 0)
	list.add_theme_constant_override("separation", 16)
	scroll.add_child(list)
	
	for i in ids.size():
		var item: String = ids[i]
		var owned := Save.own(category, item)
		var cost := Data.shop_cost(category, i)
		
		var row := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color("0d1330", 0.94)
		style.set_corner_radius_all(22)
		style.set_content_margin_all(12)
		style.border_color = Color("38b6ff", 0.6) if owned else Color("59668d", 0.5)
		style.set_border_width_all(2)
		style.shadow_color = Color(0.1, 0.2, 0.5, 0.25)
		style.shadow_size = 8
		row.add_theme_stylebox_override("panel", style)
		row.custom_minimum_size.y = 100
		list.add_child(row)
		
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 14)
		row.add_child(h)
		
		# Thumbnail
		var icon_holder := Control.new()
		icon_holder.custom_minimum_size = Vector2(76, 76)
		if category == "skins":
			var tex: Texture2D = Jelly.BODY_TEXTURES.get(item, Jelly.BODY_TEXTURES["classic"])
			var icon_rect := TextureRect.new()
			icon_rect.texture = tex
			icon_rect.size = Vector2(68, 68)
			icon_rect.position = Vector2(4, 4)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_holder.add_child(icon_rect)
		elif category == "themes":
			var theme_idx := ["candy", "jungle", "crystal", "moon", "factory"].find(item)
			var icon_rect := TextureRect.new()
			icon_rect.texture = BACKGROUNDS[maxi(0, theme_idx)]
			icon_rect.size = Vector2(68, 68)
			icon_rect.position = Vector2(4, 4)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			icon_holder.add_child(icon_rect)
		h.add_child(icon_holder)
		
		var name_label := Label.new()
		name_label.text = str(names[i])
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", FONT)
		name_label.add_theme_font_size_override("font_size", 27)
		name_label.add_theme_color_override("font_color", Color.WHITE if owned else Color("d6dbf5"))
		h.add_child(name_label)
		
		var buy := Button.new()
		buy.text = "دارم ✓" if owned else "✦ %d" % cost
		buy.disabled = owned
		buy.custom_minimum_size = Vector2(150, 68)
		buy.add_theme_font_override("font", FONT)
		buy.add_theme_font_size_override("font_size", 24)
		
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color("23694f", 0.9) if owned else Color("996b1b", 0.95)
		bs.set_corner_radius_all(20)
		bs.border_color = Color("3fe08c") if owned else Color("ffd45e")
		bs.set_border_width_all(2)
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
	title("شخصی‌سازی")
	label("اسکین انتخابی", 95, 140, 530, 55, 30, Color("cbd8ff"))
	
	var preview_panel := make_modal_panel(180, 205, 360, 220, Color("38b6ff"))
	ui.add_child(preview_panel)
	
	var preview: Jelly = JellyScript.new()
	preview.position = Vector2(360, 315)
	preview.scale = Vector2(2.6, 2.6)
	preview.skin = str(Save.data["skin"])
	preview.alive = false
	ui.add_child(preview)
	
	label(Data.SKIN_NAMES[maxi(0, Data.SKINS.find(Save.data["skin"]))], 110, 435, 500, 55, 30, Color.WHITE)
	button("اسکین قبلی", 75, 500, 265, 72, func(): cycle_owned("skins", -1), Color("38b6ff"), 27)
	button("اسکین بعدی", 380, 500, 265, 72, func(): cycle_owned("skins", 1), Color("38b6ff"), 27)
	
	label("رد حرکت", 95, 600, 530, 55, 30, Color("cbd8ff"))
	label(Data.TRAIL_NAMES[maxi(0, Data.TRAILS.find(Save.data["trail"]))], 110, 655, 500, 50, 28, Color("ffe18a"))
	button("رد قبلی", 75, 715, 265, 72, func(): cycle_owned("trails", -1), Color("b566ff"), 27)
	button("رد بعدی", 380, 715, 265, 72, func(): cycle_owned("trails", 1), Color("b566ff"), 27)
	
	var theme_name: String = Data.WORLD_FA[maxi(0, ["candy", "jungle", "crystal", "moon", "factory"].find(str(Save.data["theme"])))]
	label("تم منو و پس‌زمینه: " + theme_name, 95, 815, 530, 60, 28, Color("3fe08c"))
	button("تغییر تم", 140, 885, 440, 74, func(): cycle_owned("themes", 1), Color("3fe08c"), 28)
	button("فروشگاه آیتم‌ها", 140, 985, 440, 74, func(): show_screen("shop"), Color("ffb84d"), 28)

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
		var y := 230.0 + i * 140.0
		
		var card := make_modal_panel(60, y, 600, 122, Color("ffd45e") if achieved else Color("464d6e"))
		ui.add_child(card)
		
		label(("★  " if achieved else "☆  ") + str(info[0]), 80, y + 15, 340, 48, 29, Color("fff8d9") if achieved else Color("8f95b5"), HORIZONTAL_ALIGNMENT_RIGHT)
		label(str(info[1]), 80, y + 63, 340, 42, 21, Color("cbd6ff") if achieved else Color("6e7494"), HORIZONTAL_ALIGNMENT_RIGHT)
		
		if achieved and not i in Save.data["achievements"]:
			var id := i
			button("+%d ✦" % (30 + id * 10), 450, y + 26, 180, 68, func(): claim_achievement(id), Color("ffd45e"), 26)
		elif achieved:
			label("دریافت شد ✓", 450, y + 36, 180, 50, 24, Color("3fe08c"))
		else:
			label("🔒 قفل", 450, y + 36, 180, 50, 24, Color("6e7494"))
			
	label("تکمیل هر مرحله، کریستال و ستاره به همراه دارد", 80, 1115, 560, 56, 23, Color("cbd8ff"))

func claim_achievement(id: int) -> void:
	var reward := Save.claim_achievement(id)
	if reward > 0:
		Sound.tone("buy")
		show_screen("achievements")

func total_stars() -> int:
	var count := 0
	for entry in Save.data["levels"].values():
		count += int(entry.get("stars", 0))
	return count

func build_settings() -> void:
	title("تنظیمات")
	
	var box := make_modal_panel(70, 230, 580, 480, Color("38b6ff"))
	ui.add_child(box)
	
	build_toggle_row("موسیقی متن", "music", 270)
	build_toggle_row("جلوه‌های صوتی", "sfx", 390)
	build_toggle_row("لرزش دستگاه", "vibration", 510)
	
	label("بازی کاملاً آفلاین است و تمام پیشرفت روی همین دستگاه ذخیره می‌شود.", 75, 750, 570, 80, 24, Color("cbd8ff"))
	label("ONE MILLIMETER  ·  v1.0 Dark Fantasy Edition", 100, 1010, 520, 60, 23, Color("74ddff"))

func build_toggle_row(title_text: String, key: String, y: float) -> void:
	label(title_text, 100, y, 280, 70, 28, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	var active: bool = bool(Save.data.get(key, true))
	var btn := button("روشن" if active else "خاموش", 410, y + 4, 200, 64, func(): toggle_setting(key), Color("3fe08c") if active else Color("ff4971"), 25)

func toggle_setting(key: String) -> void:
	Save.data[key] = not Save.data[key]
	Save.save_game()
	Sound.music(0)
	show_screen("settings")
