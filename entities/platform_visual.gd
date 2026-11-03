extends Sprite2D
class_name PlatformVisual

# The base sprite provides texture background while PlatformDecoration renders
# sharp, theme-specific neon borders, hazard stripes, crystals, vines, and launch arrows.
const TEXTURES = [
	preload("res://assets/sprites/platform_candy.png"),
	preload("res://assets/sprites/platform_jungle.png"),
	preload("res://assets/sprites/platform_crystal.png"),
	preload("res://assets/sprites/platform_moon.png"),
	preload("res://assets/sprites/platform_factory.png")
]

var deco_node: Node2D

func configure(world: int, body_size: Vector2, kind: String = "normal") -> void:
	var w := clampi(world, 0, TEXTURES.size() - 1)
	texture = TEXTURES[w]
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var vertical := body_size.y > body_size.x * 1.3
	var span := body_size.y if vertical else body_size.x
	var depth := body_size.x if vertical else body_size.y
	var image_size := texture.get_size()
	var source_width := minf(image_size.x, 480.0 if span < 275.0 else image_size.x)
	var source_start := (image_size.x - source_width) * 0.5
	region_enabled = true
	region_rect = Rect2(source_start, 0, source_width, image_size.y)
	var visible_depth := maxf(depth + 28.0, minf(72.0, span * 0.32))
	scale = Vector2(span / source_width, visible_depth / image_size.y)
	rotation = -PI * 0.5 if vertical else 0.0
	position = Vector2(0, visible_depth * 0.5 - depth * 0.5 - 2.0)
	if vertical:
		position = Vector2(visible_depth * 0.5 - depth * 0.5 - 2.0, 0)
	
	match kind:
		"ice": modulate = Color("b6ecff")
		"sticky": modulate = Color("f2c6ff")
		"spring": modulate = Color("fff0b8")
		"fragile": modulate = Color("ffd9fa")
		"gate": modulate = Color("ffb09c")
		_ : modulate = Color.WHITE

	# Attach or update sharp unscaled vector decoration overlay on parent body
	var parent_body := get_parent() as StaticBody2D
	if parent_body != null:
		if deco_node == null:
			deco_node = PlatformDeco.new()
			parent_body.add_child(deco_node)
		if deco_node is PlatformDeco:
			(deco_node as PlatformDeco).setup(w, body_size, kind)

class PlatformDeco extends Node2D:
	var world := 0
	var size := Vector2.ZERO
	var kind := "normal"
	var anim := 0.0

	func setup(p_world: int, p_size: Vector2, p_kind: String) -> void:
		world = p_world
		size = p_size
		kind = p_kind
		set_process(true)
		queue_redraw()

	func _process(delta: float) -> void:
		anim += delta
		if kind in ["spring", "gate", "fragile"] or world in [2, 4]:
			queue_redraw()

	func _draw() -> void:
		var half := size * 0.5
		var rect := Rect2(-half, size)
		
		# 1. World-specific ledge & border dressing
		match world:
			0:
				# Sky & Clouds: Golden gilded top rim with soft cyan neon underglow
				draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("ffd55e", 0.95), 3.0, true)
				draw_line(Vector2(-half.x, -half.y + 3), Vector2(half.x, -half.y + 3), Color("74ddff", 0.5), 1.5, true)
				# Golden corner brackets
				draw_line(Vector2(-half.x, -half.y), Vector2(-half.x, -half.y + 12), Color("ffd55e", 0.8), 2.5, true)
				draw_line(Vector2(half.x, -half.y), Vector2(half.x, -half.y + 12), Color("ffd55e", 0.8), 2.5, true)
			1:
				# Magic Forest: Vibrant mossy emerald edge with sprouting foliage
				draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("3fe08c", 0.95), 3.5, true)
				var count := mini(12, int(size.x / 36.0))
				for i in count:
					var step := (i + 1) * (size.x / float(count + 1)) - half.x
					# Leaf tuft / mushroom cap
					draw_circle(Vector2(step, -half.y - 2), 2.8, Color("9affc4", 0.85))
					draw_circle(Vector2(step + 3, -half.y - 1), 1.8, Color("ffe380", 0.75))
			2:
				# Crystal World: Faceted sharp crystal clusters along the ledge
				draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("c47aff", 0.95), 3.0, true)
				var crystal_count := mini(8, int(size.x / 45.0))
				for i in crystal_count:
					var cx := (i + 1) * (size.x / float(crystal_count + 1)) - half.x
					var h := 6.0 + float((i * 7) % 5)
					var p1 := Vector2(cx - 4, -half.y)
					var p2 := Vector2(cx, -half.y - h)
					var p3 := Vector2(cx + 4, -half.y)
					draw_colored_polygon(PackedVector2Array([p1, p2, p3]), Color("82f7ff", 0.85))
			3:
				# Cosmic Space: Indigo nebula border with pulsing starlight points
				draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color("8b94ff", 0.9), 2.5, true)
				draw_rect(rect, Color("6a7eff", 0.15), false, 1.5)
				var star_count := mini(6, int(size.x / 50.0))
				for i in star_count:
					var sx := (i + 1) * (size.x / float(star_count + 1)) - half.x
					var pulse := 0.5 + 0.5 * sin(anim * 4.0 + i)
					draw_circle(Vector2(sx, -half.y), 2.0 * pulse, Color("ffffff", 0.9))
			4:
				# Mechanical Factory: Diagonal yellow/black hazard caution stripes along ledge
				var stripe_w := 14.0
				var x := -half.x
				var toggle := false
				while x < half.x:
					var next_x := minf(x + stripe_w, half.x)
					var col := Color("ffd84d", 0.92) if toggle else Color("22272e", 0.92)
					draw_line(Vector2(x, -half.y + 2), Vector2(next_x, -half.y + 2), col, 4.0, true)
					x = next_x
					toggle = not toggle
				# Glowing red industrial rivet at corners
				draw_circle(Vector2(-half.x + 5, -half.y + 5), 2.5, Color("ff3b30", 0.9))
				draw_circle(Vector2(half.x - 5, -half.y + 5), 2.5, Color("ff3b30", 0.9))

		# 2. Special mechanics visual decorations
		if kind == "spring":
			# Directional bounce chevrons ▲ ▲ ▲ pointing outward
			var num_arrows := mini(5, maxi(1, int(size.x / 55.0)))
			var wave := fmod(anim * 3.5, 1.0)
			for i in num_arrows:
				var ax := (i + 1) * (size.x / float(num_arrows + 1)) - half.x
				var ay := -half.y - 4.0 - wave * 7.0
				var tip := Vector2(ax, ay - 6.0)
				var left := Vector2(ax - 6, ay)
				var right := Vector2(ax + 6, ay)
				var c := Color("ffd84d", 1.0 - wave * 0.7)
				draw_line(left, tip, c, 2.5, true)
				draw_line(tip, right, c, 2.5, true)
		elif kind == "fragile":
			# Fissure / fracture crack lines
			draw_line(Vector2(-half.x * 0.4, -half.y), Vector2(-half.x * 0.1, 0), Color("ffc7e6", 0.8), 2.0)
			draw_line(Vector2(-half.x * 0.1, 0), Vector2(half.x * 0.3, half.y), Color("ffc7e6", 0.8), 2.0)
			draw_line(Vector2(half.x * 0.1, -half.y), Vector2(half.x * 0.4, -half.y * 0.2), Color("ffc7e6", 0.7), 1.5)
		elif kind == "gate":
			# Laser gate energy weave
			var beam_alpha := 0.4 + 0.4 * sin(anim * 6.0)
			draw_rect(rect, Color("ff4971", beam_alpha), false, 2.0)
			for i in 3:
				var gy := -half.y + (i + 1) * (size.y / 4.0)
				draw_line(Vector2(-half.x, gy), Vector2(half.x, gy), Color("ff6b8b", beam_alpha * 0.7), 1.5)
