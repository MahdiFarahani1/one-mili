extends Sprite2D
class_name PlatformVisual

# Art is a child of its physics body. Decoration may hang below the flat
# collision surface, while movement and breakage stay in sync with physics.
const TEXTURES = [
	preload("res://assets/sprites/platform_candy.png"),
	preload("res://assets/sprites/platform_jungle.png"),
	preload("res://assets/sprites/platform_crystal.png"),
	preload("res://assets/sprites/platform_moon.png"),
	preload("res://assets/sprites/platform_factory.png")
]

func configure(world: int, body_size: Vector2, kind: String = "normal") -> void:
	texture = TEXTURES[clampi(world, 0, TEXTURES.size() - 1)]
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
