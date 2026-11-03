extends Sprite2D
class_name PlatformVisual

const TEXTURES = [
	preload("res://assets/sprites/platform_candy.png"),
	preload("res://assets/sprites/platform_jungle.png"),
	preload("res://assets/sprites/platform_crystal.png"),
	preload("res://assets/sprites/platform_moon.png"),
	preload("res://assets/sprites/platform_factory.png")
]
const LEVEL_ONE_TEXTURE = preload("res://assets/sprites/platform_level_01.png")

var deco_node: Node2D
var kind_name := "normal"
var level_one_style := false

func configure(world: int, body_size: Vector2, kind: String = "normal", is_level_one: bool = false) -> void:
	var w := clampi(world, 0, TEXTURES.size() - 1)
	kind_name = kind
	level_one_style = is_level_one
	texture = LEVEL_ONE_TEXTURE if is_level_one else TEXTURES[w]
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	
	var is_boundary := (kind == "boundary")
	var vertical := body_size.y > body_size.x * 1.3
	var span := body_size.y if vertical else body_size.x
	var depth := body_size.x if vertical else body_size.y
	
	if is_boundary:
		visible = false
	else:
		visible = true
		var image_size := texture.get_size()
		if level_one_style:
			# The generated sprite has transparent breathing room around its painted slab.
			# Keep that room in the render so the cyan glow does not get clipped.
			region_enabled = false
			var sprite_width := image_size.x * 0.90
			var fitted_scale := span / sprite_width
			scale = Vector2(fitted_scale, fitted_scale)
			rotation = -PI * 0.5 if vertical else 0.0
			var surface_y := image_size.y * 0.29
			var offset_y := -depth * 0.5 + (image_size.y * 0.5 - surface_y) * fitted_scale
			position = Vector2(offset_y, 0) if vertical else Vector2(0, offset_y)
		else:
			var desired_scale := clampf(span / 480.0, 0.22, 0.38)
			var source_width := minf(image_size.x, span / desired_scale)
			var source_start := (image_size.x - source_width) * 0.5
			region_enabled = true
			region_rect = Rect2(source_start, 0, source_width, image_size.y)
		
		# Proportional uniform scale preserves all carved arches, stalactites, lanterns, and vines
			var actual_scale_x := span / source_width
			var actual_scale_y := actual_scale_x * 0.92
			scale = Vector2(actual_scale_x, actual_scale_y)
			rotation = -PI * 0.5 if vertical else 0.0
		
		# Align top flat surface of stone slab (at Y ≈ 32 in texture) exactly with top collision edge
			var pos_y := -depth * 0.5 + (image_size.y * 0.5 - 32.0) * actual_scale_y
			if vertical:
				position = Vector2(pos_y, 0)
			else:
				position = Vector2(0, pos_y)
	
	match kind:
		"ice": modulate = Color("bceeff")
		"sticky": modulate = Color("f7c9ff")
		"spring": modulate = Color("fff3b5")
		"fragile": modulate = Color("ffdcf8")
		"gate": modulate = Color("ffb2a0")
		_: modulate = Color.WHITE

	var parent_body := get_parent() as StaticBody2D
	if parent_body != null:
		if deco_node == null:
			deco_node = PlatformDeco.new()
			parent_body.add_child(deco_node)
		if deco_node is PlatformDeco:
			(deco_node as PlatformDeco).setup(w, body_size, kind, level_one_style)

func on_spring_bounce() -> void:
	if deco_node is PlatformDeco:
		(deco_node as PlatformDeco).trigger_spring_bounce()

class PlatformDeco extends Node2D:
	var world := 0
	var size := Vector2.ZERO
	var kind := "normal"
	var anim := 0.0
	var spring_bounce := 0.0
	var stage_node: Node2D = null
	var level_one_style := false

	func setup(p_world: int, p_size: Vector2, p_kind: String, p_level_one_style: bool = false) -> void:
		world = p_world
		size = p_size
		kind = p_kind
		level_one_style = p_level_one_style
		set_process(true)
		queue_redraw()

	func trigger_spring_bounce() -> void:
		spring_bounce = 1.0

	func _process(delta: float) -> void:
		anim += delta
		if spring_bounce > 0.0:
			spring_bounce = maxf(0.0, spring_bounce - delta * 3.5)
			queue_redraw()
		elif kind in ["spring", "fragile", "gate", "ice", "sticky"] or world in [1, 2, 4]:
			queue_redraw()

	func _draw() -> void:
		# Boundary colliders are invisible to let background art shine through cleanly
		if kind == "boundary":
			return

		var half := size * 0.5
		var rect := Rect2(-half, size)
		
		# 1. THEMED PLATFORM LEDGES & LIVING DETAILS
		match world:
			0:
				draw_sky_decor(half)
			1:
				draw_jungle_decor(half)
			2:
				draw_crystal_decor(half)
			3:
				draw_cosmic_decor(half)
			4:
				draw_factory_decor(half)

		# 2. SPECIAL MECHANICS VISUALS
		match kind:
			"spring":
				draw_spring_mushroom(half)
			"fragile":
				draw_fragile_cracks(half)
			"sticky":
				draw_sticky_goo(half)
			"ice":
				draw_ice_frost(half)
			"gate":
				draw_laser_gate(half, rect)

	# --- WORLD 0: SKY & CLOUDS ---
	func draw_sky_decor(half: Vector2) -> void:
		if level_one_style:
			var top_y := -half.y
			draw_line(Vector2(-half.x, top_y), Vector2(half.x, top_y), Color("3deaff", 0.22), 12.0, true)
			draw_line(Vector2(-half.x, top_y), Vector2(half.x, top_y), Color("c9ffff", 0.94), 2.5, true)
			return
		# Golden gilded filigree top rim
		draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("ffd55e", 0.95), 3.0, true)
		draw_line(Vector2(-half.x, -half.y + 2.0), Vector2(half.x, -half.y + 2.0), Color("74ddff", 0.5), 1.5, true)
		# Corner golden brackets
		draw_line(Vector2(-half.x, -half.y), Vector2(-half.x, -half.y + 12), Color("ffd55e", 0.9), 2.5, true)
		draw_line(Vector2(half.x, -half.y), Vector2(half.x, -half.y + 12), Color("ffd55e", 0.9), 2.5, true)
		# Celestial diamond accents
		var count := mini(5, int(size.x / 55.0))
		for i in count:
			var sx := (i + 1) * (size.x / float(count + 1)) - half.x
			var glint := 0.5 + 0.5 * sin(anim * 5.0 + float(i) * 1.5)
			draw_circle(Vector2(sx, -half.y), 2.0 * glint, Color("ffffff", glint * 0.9))

	# --- WORLD 1: MAGIC FOREST (Lush foliage, reactive flowers, glowing mushrooms) ---
	func draw_jungle_decor(half: Vector2) -> void:
		# Vibrant mossy carpet edge
		draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("2cb869", 0.95), 3.5, true)
		draw_line(Vector2(-half.x, -half.y - 1.0), Vector2(half.x, -half.y - 1.0), Color("68ff9e", 0.6), 1.8, true)
		
		# Reactive Grass Tufts & Small Flowers along the platform top
		var count := mini(8, maxi(2, int(size.x / 32.0)))
		var player_pos := get_player_local_pos()
		
		for i in count:
			var step := (i + 1) * (size.x / float(count + 1)) - half.x
			var wind := sin(anim * 2.6 + float(i) * 1.8) * 3.5
			# Player proximity reaction: bend away smoothly when player jelly is near
			var dist := player_pos.distance_to(Vector2(step, -half.y))
			var bend := 0.0
			if dist < 48.0:
				var push := (Vector2(step, -half.y) - player_pos).normalized().x
				bend = push * (48.0 - dist) * 0.35
			
			var stem_top := Vector2(step + wind + bend, -half.y - 6.5)
			# Grass blade
			draw_line(Vector2(step, -half.y), stem_top, Color("34d673", 0.9), 2.0, true)
			
			# Colorful flower blossoms
			if i % 2 == 0:
				var petal_col := Color("ff91c7", 0.92) if (i % 4 == 0) else Color("ffe875", 0.92)
				draw_circle(stem_top, 2.8, petal_col)
				draw_circle(stem_top, 1.2, Color("ffffff"))
			else:
				draw_circle(stem_top, 1.8, Color("9affc4", 0.85))

		# Glowing corner mushroom clusters
		if size.x > 65.0:
			draw_corner_mushroom(Vector2(-half.x + 8.0, -half.y), Color("ff63ab"), Color("ffe2f0"), -1.0)
			draw_corner_mushroom(Vector2(half.x - 8.0, -half.y), Color("40e8d0"), Color("c7fff7"), 1.0)

		# Hanging swaying vine strands below the platform
		var vine_count := mini(4, maxi(1, int(size.x / 65.0)))
		for v in vine_count:
			var vx := (v + 1) * (size.x / float(vine_count + 1)) - half.x
			var v_len := 15.0 + float((v * 11) % 14)
			var sway := sin(anim * 1.8 + float(v) * 2.2) * 4.5
			var start := Vector2(vx, half.y)
			var mid := Vector2(vx + sway * 0.5, half.y + v_len * 0.5)
			var tip := Vector2(vx + sway, half.y + v_len)
			draw_line(start, mid, Color("207d46", 0.85), 2.2, true)
			draw_line(mid, tip, Color("2cb869", 0.8), 1.8, true)
			draw_circle(tip, 2.0, Color("68ff9e", 0.75))

	func draw_corner_mushroom(base: Vector2, cap_col: Color, spot_col: Color, dir: float) -> void:
		# Stem
		draw_line(base, base + Vector2(dir * 2.0, -8.0), Color("e9f5ed"), 2.8, true)
		# Cap
		var cap_pos := base + Vector2(dir * 2.0, -9.0)
		draw_circle(cap_pos, 5.0, cap_col)
		draw_circle(cap_pos + Vector2(dir * 1.8, -1.8), 1.4, spot_col)
		draw_circle(cap_pos + Vector2(-dir * 1.8, -1.0), 1.2, spot_col)
		draw_circle(cap_pos, 8.0, Color(cap_col.r, cap_col.g, cap_col.b, 0.20))

	# --- WORLD 2: CRYSTAL WORLD ---
	func draw_crystal_decor(half: Vector2) -> void:
		# Prismatic glowing ledge
		draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("c47aff", 0.95), 3.0, true)
		draw_line(Vector2(-half.x, -half.y + 2.0), Vector2(half.x, -half.y + 2.0), Color("82f7ff", 0.55), 1.5, true)
		
		# Faceted crystal spires sticking out of platform
		var count := mini(7, int(size.x / 40.0))
		for i in count:
			var cx := (i + 1) * (size.x / float(count + 1)) - half.x
			var h := 7.5 + float((i * 9) % 7)
			var pulse := 0.7 + 0.3 * sin(anim * 4.0 + float(i))
			var p1 := Vector2(cx - 4.0, -half.y)
			var p2 := Vector2(cx, -half.y - h)
			var p3 := Vector2(cx + 4.0, -half.y)
			draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color("99ebff", 0.9 * pulse))
			draw_line(p1, p2, Color("ffffff", pulse), 1.2, true)
			draw_line(p2, p3, Color("c47aff", 0.8), 1.2, true)

	# --- WORLD 3: COSMIC SPACE ---
	func draw_cosmic_decor(half: Vector2) -> void:
		# Neon indigo-cyan containment grid
		draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("74ddff", 0.95), 2.5, true)
		draw_rect(Rect2(-half, size), Color("6a7eff", 0.12), false, 1.5)
		
		# Star nodes and constellation pulses
		var star_count := mini(6, int(size.x / 48.0))
		for i in star_count:
			var sx := (i + 1) * (size.x / float(star_count + 1)) - half.x
			var p_star := Vector2(sx, -half.y)
			var pulse := 0.5 + 0.5 * sin(anim * 4.5 + float(i) * 1.8)
			draw_circle(p_star, 2.5 * pulse, Color("ffffff", 0.95))
			draw_circle(p_star, 5.5 * pulse, Color("74ddff", 0.25))

	# --- WORLD 4: MECHANICAL FACTORY ---
	func draw_factory_decor(half: Vector2) -> void:
		# Industrial yellow & black hazard caution stripes
		var stripe_w := 14.0
		var x := -half.x
		var toggle := false
		while x < half.x:
			var next_x := minf(x + stripe_w, half.x)
			var col := Color("ffd84d", 0.95) if toggle else Color("1f2328", 0.95)
			draw_line(Vector2(x, -half.y + 2), Vector2(next_x, -half.y + 2), col, 4.0, true)
			x = next_x
			toggle = not toggle
		
		# Rivet bolts
		draw_circle(Vector2(-half.x + 6, -half.y + 5), 2.5, Color("ff7a29", 0.9))
		draw_circle(Vector2(half.x - 6, -half.y + 5), 2.5, Color("ff7a29", 0.9))
		
		# Rotating embedded brass gear wheel inside platform face
		if size.x > 80.0:
			var gear_center := Vector2(0, 0)
			var gear_r := mini(int(size.y * 0.45), 14)
			draw_circle(gear_center, gear_r, Color("573e1c", 0.8))
			draw_arc(gear_center, gear_r, 0, TAU, 16, Color("ffd84d", 0.85), 2.0, true)
			for tooth in 6:
				var ta := anim * 3.0 + float(tooth) * (TAU / 6.0)
				var tp := gear_center + Vector2(cos(ta), sin(ta)) * (gear_r + 3.0)
				draw_line(gear_center, tp, Color("ffd84d", 0.9), 2.5, true)
			draw_circle(gear_center, 3.0, Color("1f2328"))

	# --- SPECIAL MECHANICS DRAWING ---
	func draw_spring_mushroom(half: Vector2) -> void:
		var bounce_wobble := sin(spring_bounce * PI * 4.0) * spring_bounce * 6.0
		var num_caps := mini(3, maxi(1, int(size.x / 65.0)))
		
		for c in num_caps:
			var mx := (c + 1) * (size.x / float(num_caps + 1)) - half.x
			var my := -half.y - 6.0 + bounce_wobble
			var stem_base := Vector2(mx, -half.y)
			var cap_center := Vector2(mx, my)
			
			# Spring stem
			draw_line(stem_base, cap_center, Color("fff6db"), 4.0, true)
			
			# Elastic mushroom cap with squash/stretch
			var cap_w := 18.0 + (spring_bounce * 8.0)
			draw_circle(cap_center, cap_w * 0.6, Color("ffb03a", 0.95))
			draw_circle(cap_center + Vector2(0, -2), cap_w * 0.45, Color("ffd84d", 0.95))
			draw_circle(cap_center + Vector2(0, -3), 2.5, Color("ffffff", 0.9))
			
			# Launch chevron aura
			var aura_phase := fmod(anim * 3.5, 1.0)
			var tip := cap_center + Vector2(0, -10.0 - aura_phase * 9.0)
			draw_line(tip + Vector2(-6, 5), tip, Color("ffd84d", 1.0 - aura_phase), 2.5, true)
			draw_line(tip, tip + Vector2(6, 5), Color("ffd84d", 1.0 - aura_phase), 2.5, true)

	func draw_fragile_cracks(half: Vector2) -> void:
		var pulse := 0.6 + 0.4 * sin(anim * 6.0)
		var c := Color("ffd9fa", pulse)
		draw_line(Vector2(-half.x * 0.5, -half.y), Vector2(-half.x * 0.15, 0), c, 2.5)
		draw_line(Vector2(-half.x * 0.15, 0), Vector2(half.x * 0.35, half.y), c, 2.5)
		draw_line(Vector2(half.x * 0.1, -half.y), Vector2(half.x * 0.45, -half.y * 0.2), c, 1.8)

	func draw_sticky_goo(half: Vector2) -> void:
		draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("f284ff", 0.85), 3.5, true)
		var drip_count := mini(4, int(size.x / 40.0))
		for d in drip_count:
			var dx := (d + 1) * (size.x / float(drip_count + 1)) - half.x
			var drop_len := 4.0 + sin(anim * 2.0 + float(d)) * 3.0
			draw_circle(Vector2(dx, half.y + drop_len), 3.0, Color("f284ff", 0.75))

	func draw_ice_frost(half: Vector2) -> void:
		draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("e0f7ff", 0.95), 3.0, true)
		var glint_x := -half.x + fmod(anim * 120.0, size.x + 30.0) - 15.0
		if glint_x > -half.x and glint_x < half.x:
			draw_line(Vector2(glint_x - 6, -half.y), Vector2(glint_x + 6, -half.y), Color("ffffff"), 2.5, true)

	func draw_laser_gate(half: Vector2, rect: Rect2) -> void:
		var beam_alpha := 0.4 + 0.4 * sin(anim * 6.0)
		draw_rect(rect, Color("ff4971", beam_alpha), false, 2.5)
		for i in 3:
			var gy := -half.y + (i + 1) * (size.y / 4.0)
			draw_line(Vector2(-half.x, gy), Vector2(half.x, gy), Color("ff6b8b", beam_alpha * 0.8), 1.8)

	func get_player_local_pos() -> Vector2:
		var body := get_parent() as Node2D
		if body == null:
			return Vector2(9999, 9999)
		if stage_node == null:
			stage_node = body.get_parent() as Node2D
		if stage_node != null and "player" in stage_node and stage_node.player != null:
			return body.to_local(stage_node.player.position)
		return Vector2(9999, 9999)
