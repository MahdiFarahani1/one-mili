extends Control

const Data = preload("res://levels/level_data.gd")
const StageScript = preload("res://scripts/stage.gd")
const JellyScript = preload("res://entities/jelly.gd")
const FONT = preload("res://assets/fonts/Vazirmatn.ttf")
const NEON_BACKDROP = preload("res://assets/backgrounds/ui_neon_cave.png")
const PRIMARY_BUTTON_ART = preload("res://assets/sprites/ui_primary_button.png")
const WORLD_CARD_ART = [
	preload("res://assets/backgrounds/ui_world_sky.png"),
	preload("res://assets/backgrounds/ui_world_jungle.png"),
	preload("res://assets/backgrounds/ui_world_crystal.png"),
	preload("res://assets/backgrounds/ui_world_cosmic.png"),
	preload("res://assets/backgrounds/ui_world_factory.png")
]
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
const UI_IVORY := Color("fff5df")
const UI_MUTED := Color("bac9d5")
const UI_GOLD := Color("eac78e")
const UI_TEAL := Color("8ce7df")
const UI_SURFACE := Color("0b1729")

class TrailPreview extends Control:
	var trail_name := "sparkle"
	var elapsed := 0.0

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()

	func _draw() -> void:
		var palette := {
			"sparkle": Color("ffe7a1"), "bubble": Color("9bdfff"), "fire": Color("ffad78"),
			"snow": Color("e6f7ff"), "rainbow": Color("f69bcf"), "star": Color("f8dc87"),
			"leaf": Color("a0eab2"), "moon": Color("c5b3f4"), "crystal": Color("81ebe1"), "heart": Color("f3a2c7")
		}
		var tint: Color = palette.get(trail_name, Color("ffe7a1"))
		var center := size * 0.5
		for i in 13:
			var phase := float(i) / 13.0
			var x := center.x - 95.0 + phase * 190.0
			var y := center.y + sin(phase * 8.0 + elapsed * 2.2) * 21.0
			var p := Vector2(x, y)
			var radius := 2.5 + float(i % 3) * 1.2
			var color := tint if trail_name != "rainbow" else Color.from_hsv(fmod(phase + elapsed * 0.12, 1.0), 0.60, 1.0)
			draw_circle(p, radius * 2.8, Color(color.r, color.g, color.b, 0.12))
			if trail_name in ["sparkle", "star", "crystal", "snow"]:
				draw_line(p + Vector2(-radius, 0), p + Vector2(radius, 0), color, 2.0, true)
				draw_line(p + Vector2(0, -radius), p + Vector2(0, radius), color, 2.0, true)
			else:
				draw_circle(p, radius, color)

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
var hud_stars_label: Label
var hud_turns_label: Label
var hud_rotate_btn: Button
var current_shop_tab := "skins"
var record_attempts := true

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
		if is_instance_valid(hud_stars_label) and not endless_run:
			var target: Dictionary = Data.level(selected_level)
			var possible := 1 + int(stage.seconds <= float(target["par_time"])) + int(stage.turns <= int(target["par_turns"]))
			hud_stars_label.text = "★".repeat(possible) + "☆".repeat(3 - possible)
		if is_instance_valid(hud_turns_label):
			hud_turns_label.text = "⟳ %d" % stage.turns
	queue_redraw()

func _draw() -> void:
	if screen in ["game", "pause"]:
		return
	if screen in ["splash", "menu", "worlds", "levels", "shop", "settings"]:
		draw_texture_rect(NEON_BACKDROP, Rect2(0, 0, 720, 1280), false)
		draw_rect(Rect2(0, 0, 720, 1280), Color("080624", 0.16))
		for mote in 20:
			var x := float((mote * 197 + 67) % 720)
			var y := float((mote * 283 + 103) % 1200)
			var pulse := 0.35 + 0.35 * sin(anim * 1.8 + float(mote))
			draw_circle(Vector2(x, y + sin(anim + float(mote)) * 5.0), 1.7, Color("a9afff", pulse))
		if screen == "menu":
			var hover := sin(anim * 2.0) * 8.0
			draw_circle(Vector2(360, 1050 + hover), 112.0, Color("34dfff", 0.10))
		return
	var theme_index := ["candy", "jungle", "crystal", "moon", "factory"].find(str(Save.data.get("theme", "candy")))
	var world := selected_world if screen in ["worlds", "levels"] else (int(Data.level(selected_level)["world"]) if screen in ["victory", "over"] and not endless_run else maxi(0, theme_index))
	
	# Background art with cinematic dark fantasy vignette
	draw_texture_rect(BACKGROUNDS[world], Rect2(0, 0, 720, 1280), false)
	draw_rect(Rect2(0, 0, 720, 1280), Color("030b18", 0.55))
	draw_rect(Rect2(0, 0, 720, 140), Color("06111f", 0.84))
	draw_rect(Rect2(0, 1120, 720, 160), Color("06111f", 0.78))
	# Ambient floating motes
	for i in 18:
		var p := Vector2(float((i * 293 + 57) % 720), float((i * 177 + 41) % 1280))
		draw_circle(p + Vector2(0, sin(anim * 1.5 + i) * 6.0), 1.6 + float(i % 3), Color("ffdd9b", 0.40))
		
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
			var intro: Jelly = JellyScript.new()
			intro.skin = str(Save.data.get("skin", "classic"))
			intro.alive = false
			intro.position = Vector2(360, 485)
			intro.scale = Vector2(3.6, 3.6)
			ui.add_child(intro)
		"menu": build_neon_menu()
		"worlds": build_neon_worlds()
		"levels": build_neon_levels()
		"game": start_stage()
		"pause": build_pause()
		"victory": build_victory()
		"over": build_over()
		"shop": build_neon_shop()
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
	n.add_theme_color_override("font_shadow_color", Color("020711", 0.72))
	n.add_theme_constant_override("shadow_offset_y", 1)
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
	b.add_theme_color_override("font_color", UI_IVORY)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", UI_IVORY)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = UI_SURFACE.lerp(color, 0.15 if state == "hover" else (0.07 if state == "pressed" else 0.025))
		style.bg_color.a = 0.97
		style.set_corner_radius_all(int(minf(18.0, h * 0.27)))
		style.border_color = color.lightened(0.22) if state == "hover" else Color(color.r, color.g, color.b, 0.72 if state != "disabled" else 0.28)
		style.set_border_width_all(1 if state == "disabled" else 2)
		style.shadow_color = Color(color.r, color.g, color.b, 0.20)
		style.shadow_size = 7 if state == "hover" else 3
		style.shadow_offset = Vector2(0, 3)
		b.add_theme_stylebox_override(state, style)
	b.pivot_offset = b.size * 0.5
	b.mouse_entered.connect(func(): create_tween().tween_property(b, "scale", Vector2(1.025, 1.025), 0.16).set_trans(Tween.TRANS_CUBIC))
	b.mouse_exited.connect(func(): create_tween().tween_property(b, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_CUBIC))
	b.pressed.connect(func(): Sound.tone("tap"); action.call())
	ui.add_child(b)
	return b

func safe_top() -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	var viewport_height := maxf(1.0, float(DisplayServer.window_get_size().y))
	return clampf(float(DisplayServer.get_display_safe_area().position.y) * 1280.0 / viewport_height, 0.0, 90.0)

func title(value: String, back: String = "menu") -> void:
	button("‹", 34, 43, 70, 70, func(): show_screen(back), UI_TEAL, 39)
	label(value, 116, 48, 374, 66, 34, UI_IVORY)
	button("✦ %d" % int(Save.data["crystals"]), 505, 48, 175, 60, func(): show_screen("shop"), UI_GOLD, 24)

# --- 1. MAIN MENU: Cinematic Title Screen matching Poster ---
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
	if record_attempts:
		Save.data["attempts"] += 1
		Save.save_game()
	show_game_hud()

# --- 4. GAMEPLAY HUD: Minimalist & Clean ---
func show_game_hud() -> void:
	if stage != null:
		stage.process_mode = Node.PROCESS_MODE_INHERIT
	for child in ui.get_children():
		child.queue_free()
	
	# A single translucent panel separates small metrics from detailed scenery.
	var hud_back := Panel.new()
	hud_back.position = Vector2(25, 32)
	hud_back.size = Vector2(670, 98)
	hud_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color("071126", 0.78)
	hud_style.border_color = Color("8ad9ff", 0.38)
	hud_style.set_border_width_all(1)
	hud_style.set_corner_radius_all(22)
	hud_back.add_theme_stylebox_override("panel", hud_style)
	ui.add_child(hud_back)
	# Top bar: Pause button, level, live star potential and metrics.
	button("Ⅱ", 36, 42, 64, 64, func(): screen = "pause"; build_pause(), Color("fff4d2"), 30)
	label("مرحله %d" % selected_level if not endless_run else "بی‌پایان · %d" % endless_score, 118, 40, 275, 54, 29, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	hud_stars_label = label("★★★" if not endless_run else "", 120, 88, 265, 30, 22, Color("ffe18a"), HORIZONTAL_ALIGNMENT_RIGHT)
	
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
	var previous: Dictionary = Save.data["levels"].get(str(selected_level), {})
	var record := seconds < float(previous.get("best_time", INF))
	var stars := 1
	if seconds <= float(details["par_time"]): stars += 1
	if turns <= int(details["par_turns"]): stars += 1
	var reward := Save.complete_level(selected_level, seconds, turns, stars, count)
	set_meta("last_result", {"stars": stars, "seconds": seconds, "turns": turns, "reward": reward, "record": record})
	show_screen("victory")

func on_stage_lost() -> void:
	if stage != null:
		var start: Vector2 = stage.details.get("start", Vector2(115, 1030))
		var goal: Vector2 = stage.details.get("goal", Vector2(115, 300))
		var progress := 0.0
		if stage.details.get("axis", "y") == "x":
			progress = (stage.player.position.x - start.x) / maxf(1.0, goal.x - start.x)
		else:
			progress = (start.y - stage.player.position.y) / maxf(1.0, start.y - goal.y)
		set_meta("last_progress", clampi(roundi(progress * 100.0), 0, 99))
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
	
	var card := make_modal_panel(110, 290, 500, 525, UI_TEAL)
	ui.add_child(card)
	
	label("مکث", 110, 318, 500, 65, 48, UI_IVORY)
	label("نفسی تازه کن و مسیر را دوباره ببین", 120, 391, 480, 42, 22, UI_MUTED)
	label("مرحله %d" % selected_level if not endless_run else "حالت بی‌پایان", 110, 435, 500, 45, 24, UI_GOLD)
	
	button("ادامهٔ بازی  ▶", 150, 500, 420, 76, func(): screen = "game"; stage.player.alive = true; show_game_hud(), UI_GOLD, 30)
	button("شروع دوباره  ↻", 150, 596, 420, 76, func(): show_screen("game"), UI_TEAL, 30)
	button("نقشهٔ مراحل", 150, 692, 420, 76, func(): show_screen("levels"), UI_MUTED, 30)

# --- 5. VICTORY SCREEN ---
func build_victory() -> void:
	var result: Dictionary = get_meta("last_result", {})
	var stars: int = int(result.get("stars", 1))
	
	var shade := ColorRect.new()
	shade.color = Color("040714", 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	
	var card := make_modal_panel(80, 230, 560, 785, UI_GOLD)
	ui.add_child(card)
	
	label("مسیر را فتح کردی", 80, 265, 560, 75, 45, UI_IVORY)
	
	for s in 3:
		var star_label := label("★" if s < stars else "☆", 178 + s * 110, 348, 105, 85, 62, UI_GOLD if s < stars else Color("586a7e"))
		star_label.pivot_offset = star_label.size / 2.0
		star_label.scale = Vector2(0.25, 0.25)
		create_tween().tween_property(star_label, "scale", Vector2.ONE, 0.34).set_delay(float(s) * 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	label("رکورد تازه" if bool(result.get("record", false)) else "مرحله کامل شد", 120, 440, 480, 45, 26, UI_TEAL)
		
	label("زمان: %.1f ثانیه   ·   چرخش: %d" % [float(result.get("seconds", 0)), int(result.get("turns", 0))], 90, 500, 540, 55, 25, UI_MUTED)
	label("+%d کریستال پاداش ✦" % int(result.get("reward", 0)), 90, 562, 540, 55, 31, UI_GOLD)
	
	button("مرحلهٔ بعدی  ▶", 130, 670, 460, 84, func(): selected_level = mini(60, selected_level + 1); show_screen("game"), UI_GOLD, 33)
	button("تلاش مجدد  ↻", 130, 770, 460, 74, func(): show_screen("game"), UI_TEAL, 28)
	button("نقشهٔ مراحل", 130, 860, 460, 74, func(): show_screen("levels"), UI_MUTED, 28)

# --- 6. GAME OVER SCREEN ---
func build_over() -> void:
	var shade := ColorRect.new()
	shade.color = Color("040714", 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(shade)
	
	var card := make_modal_panel(80, 290, 560, 620, Color("d6939f"))
	ui.add_child(card)
	
	label("این بار نشد", 80, 315, 560, 75, 48, UI_IVORY)
	label("%d٪ مسیر را پیمودی" % int(get_meta("last_progress", 0)), 90, 400, 540, 50, 26, UI_MUTED)
	var progress_track := ColorRect.new()
	progress_track.position = Vector2(145, 455)
	progress_track.size = Vector2(430, 12)
	progress_track.color = Color("314258")
	progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(progress_track)
	var progress_fill := ColorRect.new()
	progress_fill.position = progress_track.position
	progress_fill.size = Vector2(430.0 * float(get_meta("last_progress", 0)) / 100.0, 12)
	progress_fill.color = UI_TEAL
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(progress_fill)
	
	if endless_run:
		label("امتیاز %d   ·   رکورد %d" % [endless_score, int(Save.data["endless_best"])], 90, 465, 540, 55, 30, Color.WHITE)
	else:
		label("مرحله %d" % selected_level, 90, 480, 540, 55, 28, UI_GOLD)
		
	# Immediate fast restart button
	button("تلاش دوباره  ↻", 130, 585, 460, 84, func(): retry_after_loss(), UI_GOLD, 34)
	button("نقشهٔ مراحل", 130, 690, 460, 74, func(): show_screen("levels"), UI_MUTED, 28)

# --- 7. SHOP: large collectible displays with animated reveal ---
func show_shop_tab(tab_id: String) -> void:
	current_shop_tab = tab_id
	show_screen("shop")

# --- 8. CUSTOMIZATION / CLOSET ---
func build_custom() -> void:
	title("شخصی‌سازی")
	label("ظاهر قهرمانت را انتخاب کن", 95, 140, 530, 55, 26, UI_MUTED)
	
	var preview_panel := make_modal_panel(180, 205, 360, 220, UI_TEAL)
	ui.add_child(preview_panel)
	
	var preview: Jelly = JellyScript.new()
	preview.position = Vector2(180, 110)
	preview.scale = Vector2(2.1, 2.1)
	preview.alive = false
	preview.skin = str(Save.data.get("skin", "classic"))
	preview.trail = str(Save.data.get("trail", "sparkle"))
	preview_panel.add_child(preview)
	
	label(Data.SKIN_NAMES[maxi(0, Data.SKINS.find(Save.data["skin"]))], 110, 440, 500, 50, 28, UI_GOLD)
	button("‹  اسکین قبلی", 75, 500, 265, 72, func(): cycle_owned("skins", -1), UI_TEAL, 25)
	button("اسکین بعدی  ›", 380, 500, 265, 72, func(): cycle_owned("skins", 1), UI_TEAL, 25)
	
	label("رد حرکت", 95, 600, 530, 55, 30, UI_MUTED)
	label(Data.TRAIL_NAMES[maxi(0, Data.TRAILS.find(Save.data["trail"]))], 110, 655, 500, 50, 28, UI_GOLD)
	button("‹  رد قبلی", 75, 715, 265, 72, func(): cycle_owned("trails", -1), UI_TEAL, 25)
	button("رد بعدی  ›", 380, 715, 265, 72, func(): cycle_owned("trails", 1), UI_TEAL, 25)
	
	var theme_name: String = Data.WORLD_FA[maxi(0, ["candy", "jungle", "crystal", "moon", "factory"].find(str(Save.data["theme"])))]
	label("تم منو: " + theme_name, 95, 815, 530, 60, 26, UI_MUTED)
	button("تغییر تم", 140, 885, 440, 74, func(): cycle_owned("themes", 1), UI_TEAL, 28)
	button("دیدن آیتم‌های فروشگاه", 140, 985, 440, 74, func(): show_screen("shop"), UI_GOLD, 28)

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
	label("نشان‌های مسیر و پاداش‌های تو", 80, 150, 560, 45, 23, UI_MUTED)
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
		
		var card := make_modal_panel(60, y, 600, 122, UI_GOLD if achieved else Color("5b7084"))
		ui.add_child(card)
		
		label(("★  " if achieved else "☆  ") + str(info[0]), 80, y + 15, 340, 48, 29, UI_IVORY if achieved else UI_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		label(str(info[1]), 80, y + 63, 340, 42, 21, UI_MUTED if achieved else Color("7c8b9b"), HORIZONTAL_ALIGNMENT_RIGHT)
		
		if achieved and not i in Save.data["achievements"]:
			var id := i
			button("+%d ✦" % (30 + id * 10), 450, y + 26, 180, 68, func(): claim_achievement(id), UI_GOLD, 26)
		elif achieved:
			label("دریافت شد ✓", 450, y + 36, 180, 50, 24, UI_TEAL)
		else:
			label("🔒 قفل", 450, y + 36, 180, 50, 24, Color("6e7494"))
			
	label("هر گام، نشانی از مهارت توست", 80, 1115, 560, 56, 23, UI_MUTED)

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
	neon_header("تنظیمات")
	label("تجربهٔ بازی را به سلیقهٔ خودت تنظیم کن", 67, 129, 586, 54, 23, Color("c9c6ec"))
	build_neon_setting_row("♫", "موسیقی متن", "موسیقی آرام جهان‌ها", "music", 225, Color("a785ff"))
	build_neon_setting_row("✦", "جلوه‌های صوتی", "صدای تعامل، برخورد و پیروزی", "sfx", 380, Color("65dfff"))
	build_neon_setting_row("◈", "لرزش دستگاه", "بازخورد ملایم هنگام رویدادهای مهم", "vibration", 535, Color("ffce80"))
	neon_panel(53, 727, 614, 180, Color("8e80e7"))
	label("پیشرفت بازی", 100, 753, 520, 52, 29, Color.WHITE)
	label("مرحله‌ها و خریدهای تو روی همین دستگاه ذخیره می‌شوند.", 84, 817, 552, 56, 22, Color("c7c3e7"))
	var hero: Jelly = JellyScript.new()
	hero.skin = str(Save.data.get("skin", "classic"))
	hero.alive = false
	hero.position = Vector2(360, 1053)
	hero.scale = Vector2(2.1, 2.1)
	ui.add_child(hero)
	label("یک میلی‌متر", 205, 1153, 310, 50, 22, Color("bcb7f0"))

func build_neon_setting_row(icon: String, title_text: String, subtitle: String, key: String, y: float, accent: Color) -> void:
	neon_panel(53, y, 614, 134, accent)
	label(icon, 79, y + 28, 60, 72, 38, accent)
	label(title_text, 142, y + 21, 285, 47, 28, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	label(subtitle, 132, y + 70, 300, 40, 18, Color("c2c0e0"), HORIZONTAL_ALIGNMENT_RIGHT)
	var active: bool = bool(Save.data.get(key, true))
	var toggle := neon_button("روشن  ●" if active else "خاموش  ○", 457, y + 34, 170, 63, func(): toggle_setting(key), accent if active else Color("777399"), 23)
	toggle.set_meta("setting_key", key)

func toggle_setting(key: String) -> void:
	Save.data[key] = not Save.data[key]
	Save.save_game()
	Sound.music(0)
	Sound.tone("tap")
	show_screen("settings")

func make_modal_panel(x: float, y: float, w: float, h: float, border_glow: Color) -> Panel:
	var panel := Panel.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(w, h)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = UI_SURFACE
	style.bg_color.a = 0.97
	style.set_corner_radius_all(28)
	style.border_color = Color(border_glow.r, border_glow.g, border_glow.b, 0.70)
	style.set_border_width_all(2)
	style.shadow_color = Color("020812", 0.70)
	style.shadow_size = 17
	style.shadow_offset = Vector2(0, 8)
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

# The four presentation screens share one compact neon visual language.
# Game logic and the gameplay HUD keep their existing implementation.
func neon_button(value: String, x: float, y: float, w: float, h: float, action: Callable, accent: Color, font_size: int = 27, prominent: bool = false) -> Button:
	var control := button(value, x, y, w, h, action, accent, font_size)
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_color_override("font_hover_color", Color.WHITE)
	control.add_theme_color_override("font_pressed_color", Color.WHITE)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		var active: bool = state != "disabled"
		style.bg_color = (Color("303983") if prominent else Color("221747")).lerp(accent, 0.36 if prominent else 0.11)
		if state == "hover":
			style.bg_color = style.bg_color.lightened(0.12)
		if state == "pressed":
			style.bg_color = style.bg_color.darkened(0.12)
		if not active:
			style.bg_color = Color("191a39")
		style.set_corner_radius_all(int(minf(25.0, h * 0.29)))
		style.border_color = Color(accent.r, accent.g, accent.b, 0.94 if active else 0.27)
		style.set_border_width_all(3 if prominent and active else 2)
		style.shadow_color = Color(accent.r, accent.g, accent.b, 0.47 if prominent and active else 0.22)
		style.shadow_size = 16 if prominent else 8
		style.shadow_offset = Vector2(0, 3)
		control.add_theme_stylebox_override(state, style)
	if prominent:
		var cropped := AtlasTexture.new()
		cropped.atlas = PRIMARY_BUTTON_ART
		var image_size: Vector2 = PRIMARY_BUTTON_ART.get_size()
		cropped.region = Rect2(Vector2(image_size.x * 0.03, image_size.y * 0.193), Vector2(image_size.x * 0.94, image_size.y * 0.622))
		for state in ["normal", "hover", "focus"]:
			var image_style := StyleBoxTexture.new()
			image_style.texture = cropped
			control.add_theme_stylebox_override(state, image_style)
	return control

func neon_header(heading: String, back: String = "menu") -> void:
	neon_button("❮", 34, 37, 70, 68, func(): show_screen(back), Color("b58aff"), 32)
	label(heading, 120, 40, 410, 65, 34, Color.WHITE)
	neon_button("✦ %d" % int(Save.data["crystals"]), 542, 43, 145, 58, func(): show_screen("shop"), Color("f5c65f"), 22)

func neon_panel(x: float, y: float, w: float, h: float, accent: Color = Color("835cff")) -> Panel:
	var panel := Panel.new()
	panel.position = Vector2(x, y)
	panel.size = Vector2(w, h)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("11122e", 0.88)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.64)
	style.set_border_width_all(2)
	style.set_corner_radius_all(29)
	style.shadow_color = Color(accent.r, accent.g, accent.b, 0.22)
	style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", style)
	ui.add_child(panel)
	return panel

func build_neon_menu() -> void:
	Save.ensure_daily()
	neon_button("∞  %d" % int(Save.data["endless_best"]), 36, 35, 135, 57, func(): start_endless(), Color("8d6dff"), 22)
	neon_button("✦  %d" % int(Save.data["crystals"]), 545, 35, 140, 57, func(): show_screen("shop"), Color("f9c764"), 22)
	label("یک میلی‌متر", 78, 162, 564, 92, 67, Color.WHITE)
	label("One MilliMeter", 128, 252, 464, 41, 21, Color("aba8e3"))
	label("ماجراجویی در پنج جهان شگفت‌انگیز", 85, 345, 550, 52, 23, Color("d0c9ec"))
	var next_unlocked := mini(60, Save.unlocked_level())
	neon_button("▶  بازی", 155, 445, 410, 91, func(): selected_level = next_unlocked; endless_run = false; show_screen("game"), Color("59dfff"), 39, true)
	neon_button("▣  مراحل", 158, 560, 404, 75, func(): selected_world = (next_unlocked - 1) / 12; show_screen("levels"), Color("b26aff"), 30)
	neon_button("♛  فروشگاه", 158, 653, 404, 75, func(): show_screen("shop"), Color("b26aff"), 30)
	neon_button("⚙  تنظیمات", 158, 746, 404, 75, func(): show_screen("settings"), Color("b26aff"), 30)
	neon_button("◈  جهان‌ها", 81, 843, 270, 61, func(): show_screen("worlds"), Color("7dd9ff"), 23)
	neon_button("✧  دستاوردها", 369, 843, 270, 61, func(): show_screen("achievements"), Color("e0a4ff"), 23)
	neon_button("ظاهر", 247, 918, 226, 55, func(): show_screen("custom"), Color("9e9aff"), 21)
	var hero: Jelly = JellyScript.new()
	hero.skin = str(Save.data.get("skin", "classic"))
	hero.alive = false
	hero.position = Vector2(360, 1060)
	hero.scale = Vector2(2.6, 2.6)
	ui.add_child(hero)

func build_neon_worlds() -> void:
	neon_header("انتخاب جهان")
	label("پنج جهان، پنج ماجراجویی متفاوت", 80, 111, 560, 55, 23, Color("c6c1e8"))
	for i in 5:
		var index := i
		var unlocked := Save.unlocked_level() >= i * 12 + 1
		var accent: Color = Data.WORLD_COLORS[i]
		var y := 180.0 + float(i) * 194.0
		var card := neon_button("", 46, y, 628, 177, func(): select_world(index, unlocked), accent, 25)
		card.set_meta("world_index", i)
		card.disabled = not unlocked
		card.clip_contents = true
		var art := TextureRect.new()
		art.texture = WORLD_CARD_ART[i]
		art.position = Vector2(4, 4)
		art.size = Vector2(340, 169)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.modulate = Color.WHITE if unlocked else Color("8b82a4")
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(art)
		art.position = Vector2(4, 4)
		art.size = Vector2(340, 169)
		var veil := ColorRect.new()
		veil.position = Vector2(320, 4)
		veil.size = Vector2(304, 169)
		veil.color = Color("0b0b2d", 0.81 if unlocked else 0.88)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(veil)
		var title_label := Label.new()
		title_label.text = Data.WORLD_FA[i]
		title_label.position = Vector2(335, 32)
		title_label.size = Vector2(265, 58)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.add_theme_font_override("font", FONT)
		title_label.add_theme_font_size_override("font_size", 30)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(title_label)
		var progress_label := Label.new()
		progress_label.text = "★ %d / ۳۶" % stars_in_world(i) if unlocked else "🔒  قفل"
		progress_label.position = Vector2(337, 99)
		progress_label.size = Vector2(261, 46)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		progress_label.add_theme_font_override("font", FONT)
		progress_label.add_theme_font_size_override("font_size", 23)
		progress_label.add_theme_color_override("font_color", Color("ffe282") if unlocked else Color("c7c3db"))
		progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(progress_label)

func build_neon_levels() -> void:
	neon_header("مراحل · " + Data.WORLD_FA[selected_world], "worlds")
	var world_art := TextureRect.new()
	var focus := AtlasTexture.new()
	focus.atlas = WORLD_CARD_ART[selected_world]
	var source_size: Vector2 = WORLD_CARD_ART[selected_world].get_size()
	var focus_height := source_size.x * 172.0 / 636.0
	focus.region = Rect2(0, source_size.y * 0.23, source_size.x, focus_height)
	world_art.texture = focus
	world_art.position = Vector2(42, 133)
	world_art.size = Vector2(636, 172)
	world_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_art.stretch_mode = TextureRect.STRETCH_SCALE
	world_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(world_art)
	world_art.position = Vector2(42, 133)
	world_art.size = Vector2(636, 172)
	neon_panel(40, 323, 640, 680, Data.WORLD_COLORS[selected_world])
	for i in 12:
		var number := selected_world * 12 + i + 1
		var unlocked := number <= Save.unlocked_level()
		var stars := int(Save.data["levels"].get(str(number), {}).get("stars", 0))
		var column := i % 4
		var row := i / 4
		var x := 61.0 + float(column) * 155.0
		var y := 365.0 + float(row) * 196.0
		var accent: Color = Data.WORLD_COLORS[selected_world] if unlocked else Color("494365")
		var tile := neon_button(str(i + 1) if unlocked else "🔒", x, y, 133, 154, func(): select_level(number, unlocked), accent, 42)
		tile.set_meta("level_number", number)
		tile.disabled = not unlocked
		if unlocked:
			var star_text := "★".repeat(stars) + "☆".repeat(3 - stars)
			label(star_text, x + 8, y + 104, 117, 34, 23, Color("ffe171"))
	label("★  %d / ۳۶ ستاره" % stars_in_world(selected_world), 157, 1013, 406, 54, 29, Color("ffe391"))
	var world_start := selected_world * 12 + 1
	var world_end := world_start + 11
	var continue_level := mini(world_end, Save.unlocked_level())
	var can_continue := Save.unlocked_level() >= world_start
	var caption := "▶  بازی دوباره" if Save.unlocked_level() > world_end else "▶  ادامهٔ بازی"
	var continue_button := neon_button(caption, 159, 1085, 402, 84, func(): select_level(continue_level, can_continue), Color("53dfff"), 31, true)
	continue_button.set_meta("continue_level", continue_level)
	continue_button.disabled = not can_continue

func build_neon_shop() -> void:
	neon_header("فروشگاه")
	var tabs := [
		["skins", "اسکین"], ["trails", "افکت"], ["themes", "تم"]
	]
	for i in tabs.size():
		var tab_id: String = tabs[i][0]
		var active := current_shop_tab == tab_id
		var tab := neon_button(tabs[i][1], 48 + i * 210, 139, 202, 72, func(): show_shop_tab(tab_id), Color("cf67ff") if active else Color("7777af"), 27, active)
		tab.set_meta("shop_tab", tab_id)
	build_neon_shop_grid(current_shop_tab)

func build_neon_shop_grid(category: String) -> void:
	var names: Array = Data.SKIN_NAMES if category == "skins" else (Data.TRAIL_NAMES if category == "trails" else Data.WORLD_FA)
	var ids: Array = Data.SKINS if category == "skins" else (Data.TRAILS if category == "trails" else ["candy", "jungle", "crystal", "moon", "factory"])
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(36, 232)
	scroll.size = Vector2(648, 950)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ui.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 17)
	scroll.add_child(grid)
	var equipped_item := str(Save.data.get("skin" if category == "skins" else ("trail" if category == "trails" else "theme"), ""))
	for i in ids.size():
		var item: String = ids[i]
		var owned := Save.own(category, item)
		var equipped := item == equipped_item
		var cost := Data.shop_cost(category, i)
		var accent: Color = [Color("54dfff"), Color("ff9e44"), Color("bd6bff"), Color("69ef9b"), Color("9ee9ff"), Color("ffd16c")][i % 6]
		var card := PanelContainer.new()
		card.set_meta("shop_item", item)
		card.custom_minimum_size = Vector2(204, 266)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("141434", 0.96)
		card_style.border_color = accent if owned else Color(accent.r, accent.g, accent.b, 0.47)
		card_style.set_border_width_all(3 if equipped else 2)
		card_style.set_corner_radius_all(23)
		card_style.set_content_margin_all(8)
		card_style.shadow_color = Color(accent.r, accent.g, accent.b, 0.18)
		card_style.shadow_size = 9
		card.add_theme_stylebox_override("panel", card_style)
		grid.add_child(card)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 5)
		card.add_child(content)
		var preview: Control
		if category == "skins":
			var portrait := Control.new()
			portrait.clip_contents = true
			var character: Jelly = JellyScript.new()
			character.skin = item
			character.alive = false
			character.position = Vector2(92, 80)
			character.scale = Vector2(1.9, 1.9)
			portrait.add_child(character)
			preview = portrait
		elif category == "trails":
			var trail_preview := TrailPreview.new()
			trail_preview.trail_name = item
			preview = trail_preview
		else:
			var image := TextureRect.new()
			image.texture = WORLD_CARD_ART[i]
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			preview = image
		preview.custom_minimum_size = Vector2(184, 151)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(preview)
		var name_label := Label.new()
		name_label.text = str(names[i])
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_override("font", FONT)
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.custom_minimum_size.y = 37
		content.add_child(name_label)
		var action := Button.new()
		action.custom_minimum_size = Vector2(180, 47)
		action.add_theme_font_override("font", FONT)
		action.add_theme_font_size_override("font_size", 20)
		var action_style := StyleBoxFlat.new()
		action_style.set_corner_radius_all(13)
		action_style.border_color = accent
		action_style.set_border_width_all(2)
		action_style.bg_color = Color("303467") if equipped else (Color("176451") if owned else Color("57347c"))
		action.add_theme_stylebox_override("normal", action_style)
		action.add_theme_stylebox_override("disabled", action_style)
		if equipped:
			action.text = "فعال ✓"
			action.disabled = true
		elif owned:
			action.text = "انتخاب"
			action.pressed.connect(func():
				var key := "skin" if category == "skins" else ("trail" if category == "trails" else "theme")
				Save.data[key] = item
				Save.save_game()
				Sound.tone("tap")
				show_screen("shop")
			)
		else:
			action.text = "✦ %d" % cost
			action.pressed.connect(func():
				if Save.purchase(category, item, cost):
					Sound.tone("buy")
					show_screen("shop")
				else:
					pop_toast("کریستال کافی نیست")
			)
		content.add_child(action)
