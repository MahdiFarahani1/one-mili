extends Control

const Data = preload("res://levels/level_data.gd")
const StageScript = preload("res://scripts/stage.gd")
const JellyScript = preload("res://entities/jelly.gd")
const FONT = preload("res://assets/fonts/Vazirmatn.ttf")
const BACKGROUNDS = [
	preload("res://assets/backgrounds/candy.png"),
	preload("res://assets/backgrounds/jungle.png"),
	preload("res://assets/backgrounds/crystal.png"),
	preload("res://assets/backgrounds/moon.png"),
	preload("res://assets/backgrounds/factory.png")
]
const WORLD_TAGLINES := [
	"پرش‌های دقیق · لبه‌های جهت‌دار · سکوهای متحرک",
	"سکوهای ناپایدار · گیاهان تله‌دار · مسیرهای مخفی",
	"مسیرهای چندمسیره · سوئیچ مسیر · چالش سرعت",
	"گرانش متغیر · پرتل‌های جابه‌جایی · فیزیک مدار",
	"لیزرهای هوشمند · زمان‌بندی دقیق · پیستون‌های متحرک"
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
var hud_turns_label: Label
var hud_rotate_btn: Button
var current_shop_tab := "skins"

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
	get_tree().create_timer(1.4).timeout.connect(func(): if screen == "splash": show_screen("menu"))

func _process(delta: float) -> void:
	anim += delta
	toast_time = maxf(0.0, toast_time - delta)
	if screen == "game" and stage != null:
		if is_instance_valid(hud_timer_label):
			if stage.slowmo_timer > 0.0:
				hud_timer_label.text = "⏱ %04.1fs" % stage.slowmo_timer
				hud_timer_label.add_theme_color_override("font_color", Color("74ddff"))
			else:
				hud_timer_label.text = "◷ %02d:%02d" % [int(stage.seconds) / 60, int(stage.seconds) % 60]
				hud_timer_label.add_theme_color_override("font_color", Color("fff2dc"))
		if is_instance_valid(hud_crystal_label):
			hud_crystal_label.text = "✦ %d/%d" % [stage.collected, stage.crystals.size()]
		if is_instance_valid(hud_turns_label):
			hud_turns_label.text = "⟳ %d" % stage.turns
	queue_redraw()

func _draw() -> void:
	if screen in ["game", "pause"]:
		return
	var theme_index := ["candy", "jungle", "crystal", "moon", "factory"].find(str(Save.data.get("theme", "candy")))
	var world := selected_world if screen in ["worlds", "levels"] else (int(Data.level(selected_level)["world"]) if screen in ["victory", "over"] and not endless_run else maxi(0, theme_index))
	
	# Background art with cinematic dark fantasy vignette
	draw_texture_rect(BACKGROUNDS[world], Rect2(0, 0, 720, 1280), false)
	draw_rect(Rect2(0, 0, 720, 1280), Color("030719", 0.42))
	draw_rect(Rect2(0, 0, 720, 130), Color("050a1c", 0.70))
	draw_rect(Rect2(0, 1140, 720, 140), Color("050a1c", 0.65))
	
	# Ambient floating motes
	for i in 18:
		var p := Vector2(float((i * 293 + 57) % 720), float((i * 177 + 41) % 1280))
		draw_circle(p + Vector2(0, sin(anim * 1.5 + i) * 6.0), 1.6 + float(i % 3), Color("ffdd9b", 0.40))
		
	# Living Diorama on Main Menu: Glowing crystal pediment with interactive breathing Jelly
	if screen in ["splash", "menu"]:
		var dais_center := Vector2(360, 485)
		# Glowing pedestal base
		draw_circle(dais_center + Vector2(0, 40), 95.0, Color("142244", 0.75))
		draw_arc(dais_center + Vector2(0, 40), 95.0, 0, TAU, 48, Color("38b6ff", 0.60), 3.0, true)
		draw_circle(dais_center + Vector2(0, 40), 75.0, Color("0b1326", 0.90))
		
		# Glowing crystals on pedestal flanks
		for c in 4:
			var ca := float(c) * (PI / 3.0) + PI * 0.25
			var cp := dais_center + Vector2(0, 40) + Vector2(cos(ca), sin(ca) * 0.5) * 85.0
			draw_colored_polygon(PackedVector2Array([
				cp + Vector2(-6, 12), cp + Vector2(0, -16), cp + Vector2(6, 12)
			]), Color("c47aff", 0.85))
			draw_line(cp + Vector2(0, -16), cp + Vector2(0, 12), Color("ffffff", 0.7), 1.5)
		
		# Breathing Jelly Character
		var breathe := sin(anim * 2.8) * 0.05
		var jelly_pos := dais_center + Vector2(0, -15.0 + sin(anim * 2.0) * 5.0)
		var current_skin := str(Save.data.get("skin", "classic"))
		var tex: Texture2D = Jelly.BODY_TEXTURES.get(current_skin, Jelly.BODY_TEXTURES["classic"])
		var j_w := 140.0 * (1.0 + breathe)
		var j_h := 140.0 * (1.0 - breathe)
		
		# Soft glow halo
		draw_circle(jelly_pos, 85.0, Color("38b6ff", 0.18 + sin(anim * 3.0) * 0.06))
		draw_texture_rect(tex, Rect2(jelly_pos - Vector2(j_w * 0.5, j_h * 0.5), Vector2(j_w, j_h)), false)
		
		# Facial expression with animated blinking eyes
		var blink := fmod(anim, 4.0) < 0.15
		if blink:
			draw_line(jelly_pos + Vector2(-18, 2), jelly_pos + Vector2(-6, 2), Color("172338"), 3.5, true)
			draw_line(jelly_pos + Vector2(6, 2), jelly_pos + Vector2(18, 2), Color("172338"), 3.5, true)
		else:
			draw_circle(jelly_pos + Vector2(-12, -2), 6.5, Color("172338"))
			draw_circle(jelly_pos + Vector2(12, -2), 6.5, Color("172338"))
			draw_circle(jelly_pos + Vector2(-14, -4), 2.2, Color.WHITE)
			draw_circle(jelly_pos + Vector2(10, -4), 2.2, Color.WHITE)
		# Smile
		draw_arc(jelly_pos + Vector2(0, 12), 10.0, 0.2, PI - 0.2, 16, Color("1f2f4d"), 3.5, true)

	if toast_time > 0.0:
		draw_rect(Rect2(105, 1140, 510, 68), Color("0d1630", 0.94))
		draw_rect(Rect2(105, 1140, 510, 68), Color("597fff", 0.5), false, 2)

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
			label("یک میلی‌متر", 80, 175, 560, 90, 66, Color("fff8ef"))
			label("O N E   M I L L I M E T E R", 80, 265, 560, 50, 21, Color("74ddff"))
			label("لمس کن، جهان را بچرخان", 90, 650, 540, 60, 28, Color("fff2d4"))
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
		style.bg_color = color.darkened(0.65) if state == "hover" else (color.darkened(0.80) if state == "pressed" else Color("0e122b", 0.95))
		style.set_corner_radius_all(int(minf(24.0, h * 0.35)))
		style.border_color = color.darkened(0.12) if state != "disabled" else Color("3c4263")
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
	label(value, 118, 48, 480, 66, 38, Color.WHITE)
	button("✦ %d" % int(Save.data["crystals"]), 505, 48, 175, 60, func(): show_screen("shop"), Color("ffb84d"), 24)

# --- 1. MAIN MENU: Cinematic Title Screen matching Poster ---
func build_menu() -> void:
	Save.ensure_daily()
	# Top Header: Crystals on right, Endless high-score on left
	button("✦  %d  +" % int(Save.data["crystals"]), 490, 42, 195, 62, func(): show_screen("shop"), Color("ffb84d"), 24)
	button("∞  %d" % int(Save.data["endless_best"]), 35, 42, 160, 62, func(): start_endless(), Color("b566ff"), 24)
	
	# Logo
	label("یک میلی‌متر", 75, 145, 570, 95, 68, Color("fff8ee"))
	label("O N E   M I L L I M E T E R", 80, 238, 560, 45, 20, Color("74ddff"))
	
	# Clean primary action buttons matching Poster layout
	var next_unlocked := Save.unlocked_level()
	button("▶  بازی", 160, 650, 400, 84, func(): selected_level = next_unlocked; endless_run = false; show_screen("game"), Color("38b6ff"), 36)
	button("مراحل", 160, 755, 400, 72, func(): show_screen("worlds"), Color("3fe08c"), 28)
	button("فروشگاه", 160, 845, 400, 72, func(): show_screen("shop"), Color("ffb84d"), 28)
	button("شخصی‌سازی", 160, 935, 400, 72, func(): show_screen("custom"), Color("6a7eff"), 28)
	
	# Small utility buttons in footer
	button("تنظیمات", 160, 1025, 190, 64, func(): show_screen("settings"), Color("b566ff"), 24)
	button("دستاوردها", 370, 1025, 190, 64, func(): show_screen("achievements"), Color("ff7a29"), 24)

# --- 2. WORLD SELECTION ---
func build_worlds() -> void:
	title("انتخاب جهان")
	label("۵ تم حرفه‌ای با ایده‌های مرحله، چالش و حس متفاوت", 72, 155, 576, 47, 23, Color("cbd6ff"))
	for i in 5:
		var index := i
		var unlocked := Save.unlocked_level() >= i * 12 + 1
		var y := 220.0 + i * 176.0
		var card := button("", 56, y, 608, 152, func(): select_world(index, unlocked), Data.WORLD_COLORS[i], 27)
		
		var holder := Control.new()
		holder.position = Vector2(446, 14)
		holder.size = Vector2(148, 124)
		holder.clip_contents = true
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(holder)
		
		var art := TextureRect.new()
		art.texture = BACKGROUNDS[i]
		art.position = Vector2.ZERO
		art.size = Vector2(148, 124)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(art)
		
		var title_text := Label.new()
		var stars_str := "★ %d/۳۶" % stars_in_world(i) if unlocked else "🔒"
		title_text.text = Data.WORLD_FA[i] + "  ·  " + stars_str
		title_text.position = Vector2(20, 18)
		title_text.size = Vector2(410, 48)
		title_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		title_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_text.add_theme_font_override("font", FONT)
		title_text.add_theme_font_size_override("font_size", 28)
		title_text.add_theme_color_override("font_color", Color.WHITE if unlocked else Color("9fa4be"))
		title_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(title_text)
		
		var detail := Label.new()
		detail.text = WORLD_TAGLINES[i]
		detail.position = Vector2(20, 78)
		detail.size = Vector2(410, 48)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		detail.add_theme_font_override("font", FONT)
		detail.add_theme_font_size_override("font_size", 18)
		detail.add_theme_color_override("font_color", Color("d0d6f5") if unlocked else Color("7c83a4"))
		detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(detail)

# --- 3. LEVEL SELECTION: 4-Column Arched Grid matching Poster ---
func build_levels() -> void:
	title("مراحل - " + Data.WORLD_FA[selected_world], "worlds")
	label(WORLD_TAGLINES[selected_world], 76, 145, 568, 50, 22, Color("d6d9ff"))
	
	# 4 columns x 3 rows grid
	var col_w := 132.0
	var row_h := 132.0
	var start_x := 74.0
	var start_y := 225.0
	var gap_x := 18.0
	var gap_y := 24.0
	
	for i in 12:
		var number := selected_world * 12 + i + 1
		var unlocked := number <= Save.unlocked_level()
		var stars := int(Save.data["levels"].get(str(number), {}).get("stars", 0))
		var col := i % 4
		var row := i / 4
		var x := start_x + float(col) * (col_w + gap_x)
		var y := start_y + float(row) * (row_h + gap_y)
		
		var tile_color: Color = Data.WORLD_COLORS[selected_world] if unlocked else Color("3c4260")
		var card := button(str(i + 1) if unlocked else "🔒", x, y, col_w, row_h, func(): select_level(number, unlocked), tile_color, 36)
		
		if unlocked:
			# 3-star display neatly centered at bottom of tile
			var stars_holder := HBoxContainer.new()
			stars_holder.position = Vector2(6, row_h - 38.0)
			stars_holder.size = Vector2(col_w - 12.0, 32)
			stars_holder.alignment = BoxContainer.ALIGNMENT_CENTER
			stars_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(stars_holder)
			
			for s in 3:
				var s_lbl := Label.new()
				s_lbl.text = "★"
				s_lbl.add_theme_font_override("font", FONT)
				s_lbl.add_theme_font_size_override("font_size", 20)
				var has_star := s < stars
				s_lbl.add_theme_color_override("font_color", Color("ffd45e") if has_star else Color("4c5478", 0.6))
				s_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
				stars_holder.add_child(s_lbl)
				
	label("★  %d / ۳۶ ستاره جهان" % stars_in_world(selected_world), 160, 780, 400, 56, 28, Color("ffe7ad"))
	button("▶  ادامهٔ بازی", 160, 870, 400, 78, func(): select_level(mini(60, Save.unlocked_level()), true), Color("38b6ff"), 30)

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
	stage.powerup_obtained.connect(func(kind: String):
		if kind == "shield":
			pop_toast("🛡 سپر انرژی فعال شد!")
		elif kind == "slowmo":
			pop_toast("⏱ زمان آهسته شد!")
	)
	Save.data["attempts"] += 1
	Save.save_game()
	show_game_hud()

# --- 4. GAMEPLAY HUD: Minimalist & Clean ---
func show_game_hud() -> void:
	if stage != null:
		stage.process_mode = Node.PROCESS_MODE_INHERIT
	for child in ui.get_children():
		child.queue_free()
	
	# Top bar: Pause button, Level title, Metrics pill
	button("Ⅱ", 36, 42, 64, 64, func(): screen = "pause"; build_pause(), Color("fff4d2"), 30)
	label("مرحله %d" % selected_level if not endless_run else "بی‌پایان · %d" % endless_score, 120, 42, 280, 64, 30, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	
	hud_timer_label = label("◷ 00:00", 410, 42, 140, 64, 24, Color("fff2dc"))
	hud_crystal_label = label("✦ 0/0", 555, 42, 130, 64, 24, Color("ffde98"))
	
	# Bottom bar: Sleek circular restart and responsive gravity tap
	var is_pc := not OS.has_feature("mobile")
	button("↻", 36, 1170, 74, 74, func(): stage.restart(), Color("74ddff"), 34)
	
	var rotate_title := "↷ چرخش جاذبه  [Space / کلیک]" if is_pc else "↷ چرخش جاذبه"
	hud_rotate_btn = button(rotate_title, 126, 1170, 558, 74, func():
		if stage != null:
			stage.rotate_gravity()
	, Color("38b6ff"), 24 if is_pc else 26)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if screen == "game":
				screen = "pause"
				build_pause()
			elif screen in ["worlds", "levels", "shop", "custom", "achievements", "settings"]:
				show_screen("menu")
		elif event.keycode in [KEY_SPACE, KEY_UP, KEY_DOWN, KEY_W, KEY_S, KEY_ENTER]:
			if screen == "game" and stage != null:
				stage.rotate_gravity()
		elif event.keycode == KEY_R:
			if screen == "game" and stage != null:
				stage.restart()
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if screen == "game" and stage != null:
			var mb := event as InputEventMouseButton
			if mb.position.y > 120.0 and mb.position.y < 1160.0:
				stage.rotate_gravity()

func on_stage_won(seconds: float, turns: int, count: int) -> void:
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
	shade.color = Color("040714", 0.75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	
	var card := make_modal_panel(110, 320, 500, 470, Color("38b6ff"))
	ui.add_child(card)
	
	label("مکث", 110, 340, 500, 65, 48, Color.WHITE)
	label("مرحله %d" % selected_level if not endless_run else "حالت بی‌پایان", 110, 410, 500, 45, 24, Color("cbd8ff"))
	
	button("ادامه", 150, 485, 420, 76, func(): screen = "game"; stage.player.alive = true; show_game_hud(), Color("3fe08c"), 30)
	button("شروع دوباره", 150, 580, 420, 76, func(): show_screen("game"), Color("74ddff"), 30)
	button("فهرست مراحل", 150, 675, 420, 76, func(): show_screen("levels"), Color("b566ff"), 30)

# --- 5. VICTORY SCREEN ---
func build_victory() -> void:
	var result: Dictionary = get_meta("last_result", {})
	var stars: int = int(result.get("stars", 1))
	
	var shade := ColorRect.new()
	shade.color = Color("040714", 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	
	var card := make_modal_panel(80, 240, 560, 760, Color("ffd45e"))
	ui.add_child(card)
	
	label("پیروزی درخشان!", 80, 265, 560, 75, 50, Color("fff8d4"))
	
	# Animated Stars Pedestal
	var star_label := label("★".repeat(stars), 120, 350, 480, 80, 64, Color("ffe18a"))
	star_label.pivot_offset = star_label.size / 2.0
	star_label.scale = Vector2(0.5, 0.5)
	create_tween().tween_property(star_label, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if stars == 3:
		label("اجرای بی‌نقص و مهارتی!", 120, 435, 480, 45, 25, Color("9fffe8"))
		
	label("زمان: %.1f ثانیه   ·   چرخش: %d" % [float(result.get("seconds", 0)), int(result.get("turns", 0))], 90, 495, 540, 55, 26, Color("cbd8ff"))
	label("+%d کریستال پاداش ✦" % int(result.get("reward", 0)), 90, 560, 540, 55, 32, Color("ffe794"))
	
	button("مرحلهٔ بعدی  ▶", 130, 665, 460, 84, func(): selected_level = mini(60, selected_level + 1); show_screen("game"), Color("38b6ff"), 34)
	button("تلاش مجدد  ↻", 130, 765, 460, 74, func(): show_screen("game"), Color("3fe08c"), 28)
	button("فهرست مراحل", 130, 855, 460, 74, func(): show_screen("levels"), Color("b566ff"), 28)

# --- 6. GAME OVER SCREEN ---
func build_over() -> void:
	var shade := ColorRect.new()
	shade.color = Color("040714", 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	
	var card := make_modal_panel(80, 290, 560, 620, Color("ff4971"))
	ui.add_child(card)
	
	label("فرود ناموفق!", 80, 315, 560, 75, 48, Color("fff0f3"))
	label("فقط یک چرخش با پیروزی فاصله داشتی", 90, 400, 540, 50, 24, Color("ffbdc9"))
	
	if endless_run:
		label("امتیاز %d   ·   رکورد %d" % [endless_score, int(Save.data["endless_best"])], 90, 465, 540, 55, 30, Color.WHITE)
	else:
		label("مرحله %d" % selected_level, 90, 465, 540, 55, 30, Color("cbd8ff"))
		
	# Immediate fast restart button
	button("تلاش دوباره  ↻", 130, 575, 460, 84, func(): retry_after_loss(), Color("3fe08c"), 34)
	button("فهرست مراحل", 130, 680, 460, 74, func(): show_screen("levels"), Color("b566ff"), 28)

# --- 7. SHOP: 3-Column Card Grid matching Poster ---
func build_shop(category: String = "") -> void:
	if category != "":
		current_shop_tab = category
	title("فروشگاه", "menu")
	
	# Top 3 Tabs matching Poster: [اسکین] [افکت] [تم]
	var tabs := [
		["skins", "اسکین", Color("38b6ff")],
		["trails", "افکت", Color("b566ff")],
		["themes", "تم", Color("3fe08c")]
	]
	for idx in tabs.size():
		var t: Array = tabs[idx]
		var tab_id: String = t[0]
		var tab_name: String = t[1]
		var tab_color: Color = t[2]
		var is_active := current_shop_tab == tab_id
		var btn := button(tab_name, 56 + idx * 206, 128, 196, 62, func(): show_shop_tab(tab_id), tab_color if is_active else Color("323a54"), 26)
		if is_active:
			btn.add_theme_color_override("font_color", Color.WHITE)
			
	build_shop_grid(current_shop_tab)

func show_shop_tab(tab_id: String) -> void:
	current_shop_tab = tab_id
	show_screen("shop")

func build_shop_grid(category: String) -> void:
	var names: Array = Data.SKIN_NAMES if category == "skins" else (Data.TRAIL_NAMES if category == "trails" else Data.WORLD_FA)
	var ids: Array = Data.SKINS if category == "skins" else (Data.TRAILS if category == "trails" else ["candy", "jungle", "crystal", "moon", "factory"])
	
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(40, 208)
	scroll.size = Vector2(640, 990)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(scroll)
	
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)
	
	var card_w := 198.0
	var card_h := 220.0
	var equipped_item := str(Save.data.get("skin" if category == "skins" else ("trail" if category == "trails" else "theme"), ""))
	
	for i in ids.size():
		var item: String = ids[i]
		var owned := Save.own(category, item)
		var is_equipped := (item == equipped_item)
		var cost := Data.shop_cost(category, i)
		
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(card_w, card_h)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("0d1330", 0.95)
		style.set_corner_radius_all(22)
		style.set_content_margin_all(10)
		style.border_color = Color("38b6ff") if is_equipped else (Color("3fe08c", 0.7) if owned else Color("495478", 0.55))
		style.set_border_width_all(3 if is_equipped else 2)
		style.shadow_color = Color(0.1, 0.2, 0.5, 0.25)
		style.shadow_size = 10
		card.add_theme_stylebox_override("panel", style)
		grid.add_child(card)
		
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)
		
		# Thumbnail
		var img := TextureRect.new()
		if category == "skins":
			img.texture = Jelly.BODY_TEXTURES.get(item, Jelly.BODY_TEXTURES["classic"])
		elif category == "themes":
			var t_idx := ["candy", "jungle", "crystal", "moon", "factory"].find(item)
			img.texture = BACKGROUNDS[maxi(0, t_idx)]
		img.custom_minimum_size = Vector2(76, 76)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(img)
			
		# Item Name
		var name_lbl := Label.new()
		name_lbl.text = str(names[i])
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_override("font", FONT)
		name_lbl.add_theme_font_size_override("font_size", 19)
		name_lbl.add_theme_color_override("font_color", Color.WHITE if owned else Color("b8c0e6"))
		vbox.add_child(name_lbl)
		
		# Action Button: Equip / Equipped / Buy
		var act_btn := Button.new()
		act_btn.custom_minimum_size = Vector2(card_w - 24.0, 46.0)
		act_btn.add_theme_font_override("font", FONT)
		act_btn.add_theme_font_size_override("font_size", 19)
		
		var b_style := StyleBoxFlat.new()
		b_style.set_corner_radius_all(14)
		
		if is_equipped:
			act_btn.text = "فعال ✓"
			act_btn.disabled = true
			b_style.bg_color = Color("1f4a70", 0.95)
			b_style.border_color = Color("74ddff")
			b_style.set_border_width_all(2)
		elif owned:
			act_btn.text = "انتخاب"
			b_style.bg_color = Color("23694f", 0.95)
			b_style.border_color = Color("3fe08c")
			b_style.set_border_width_all(2)
			act_btn.pressed.connect(func():
				var key := "skin" if category == "skins" else ("trail" if category == "trails" else "theme")
				Save.data[key] = item
				Save.save_game()
				Sound.tone("tap")
				show_screen("shop")
			)
		else:
			act_btn.text = "✦ %d" % cost
			b_style.bg_color = Color("734e12", 0.95)
			b_style.border_color = Color("ffd45e")
			b_style.set_border_width_all(2)
			act_btn.pressed.connect(func():
				if Save.purchase(category, item, cost):
					Sound.tone("buy")
					show_screen("shop")
				else:
					pop_toast("کریستال کافی نیست")
			)
			
		act_btn.add_theme_stylebox_override("normal", b_style)
		act_btn.add_theme_stylebox_override("disabled", b_style)
		vbox.add_child(act_btn)

# --- 8. CUSTOMIZATION / CLOSET ---
func build_custom() -> void:
	title("شخصی‌سازی")
	label("اسکین انتخابی", 95, 140, 530, 55, 30, Color("cbd8ff"))
	
	var preview_panel := make_modal_panel(180, 205, 360, 220, Color("38b6ff"))
	ui.add_child(preview_panel)
	
	var preview: Jelly = JellyScript.new()
	preview.position = Vector2(180, 110)
	preview.skin = str(Save.data.get("skin", "classic"))
	preview.trail = str(Save.data.get("trail", "sparkle"))
	preview_panel.add_child(preview)
	
	label(Data.SKIN_NAMES[maxi(0, Data.SKINS.find(Save.data["skin"]))], 110, 440, 500, 50, 28, Color("ffe18a"))
	button("اسکین قبلی", 75, 500, 265, 72, func(): cycle_owned("skins", -1), Color("38b6ff"), 26)
	button("اسکین بعدی", 380, 500, 265, 72, func(): cycle_owned("skins", 1), Color("38b6ff"), 26)
	
	label("رد حرکت", 95, 600, 530, 55, 30, Color("cbd8ff"))
	label(Data.TRAIL_NAMES[maxi(0, Data.TRAILS.find(Save.data["trail"]))], 110, 655, 500, 50, 28, Color("ffe18a"))
	button("رد قبلی", 75, 715, 265, 72, func(): cycle_owned("trails", -1), Color("b566ff"), 26)
	button("رد بعدی", 380, 715, 265, 72, func(): cycle_owned("trails", 1), Color("b566ff"), 26)
	
	var theme_name: String = Data.WORLD_FA[maxi(0, ["candy", "jungle", "crystal", "moon", "factory"].find(str(Save.data["theme"])))]
	label("تم منو و پس‌زمینه: " + theme_name, 95, 815, 530, 60, 26, Color("3fe08c"))
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

# --- 9. ACHIEVEMENTS & SETTINGS ---
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
	button("روشن" if active else "خاموش", 410, y + 4, 200, 64, func(): toggle_setting(key), Color("3fe08c") if active else Color("ff4971"), 25)

func toggle_setting(key: String) -> void:
	Save.data[key] = not Save.data[key]
	Save.save_game()
	Sound.music(0)
	show_screen("settings")

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
	label(message, 105, 1140, 510, 68, 26, Color.WHITE)
