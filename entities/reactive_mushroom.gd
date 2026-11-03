extends StaticBody2D
class_name ReactiveMushroom

const ART = preload("res://assets/sprites/level_01_cloud_spring.png")

var artwork: Sprite2D
var sway := 0.0
var sway_velocity := 0.0
var compression := 0.0
var contact_cooldown := 0.0
var elapsed := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	set_meta("kind", "mushroom")
	var shape := CircleShape2D.new()
	shape.radius = 32.0
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0, -67)
	collision.shape = shape
	add_child(collision)
	artwork = Sprite2D.new()
	artwork.texture = ART
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	artwork.position = Vector2(0, -54)
	artwork.scale = Vector2(0.12, 0.12)
	add_child(artwork)

func react_to_hit(hit_from: Vector2, strength: float) -> bool:
	if contact_cooldown > 0.0:
		return false
	contact_cooldown = 0.22
	compression = minf(0.27, 0.13 + strength / 1800.0)
	sway_velocity += clampf((position.x - hit_from.x) * 0.024, -1.6, 1.6)
	return true

func _process(delta: float) -> void:
	elapsed += delta
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	sway_velocity += -sway * 18.0 * delta
	sway_velocity *= exp(-5.0 * delta)
	sway += sway_velocity * delta
	compression = move_toward(compression, 0.0, delta * 1.25)
	artwork.rotation = sway + sin(elapsed * 1.7 + position.x * 0.01) * 0.025
	artwork.scale = Vector2(0.12 * (1.0 + compression * 0.5), 0.12 * (1.0 - compression))
