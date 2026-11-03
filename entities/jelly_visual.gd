extends Node2D
class_name JellyVisual

# The same atlas and animation drive gameplay, menu and shop portraits.
const ATLAS = preload("res://assets/sprites/jelly_neon_atlas.png")
const SKIN_IDS := [
	"classic", "fire", "ice", "galaxy", "gold", "rainbow", "ninja", "robot",
	"ghost", "crystal", "candy", "star", "electric", "moon", "legendary"
]
const GLOW_COLORS := [
	Color("44e4ff"), Color("ff973f"), Color("a8f4ff"), Color("ad73ff"),
	Color("ffe074"), Color("ff9dda"), Color("a97aff"), Color("84d6f2"),
	Color("e3edff"), Color("7af4ef"), Color("ffaacb"), Color("ffe57a"),
	Color("f6f969"), Color("bba8ff"), Color("ffa2e8")
]

var skin := "classic"
var expression := "normal"
var motion := Vector2.ZERO
var squash := 0.0
var clock := 0.0

func _process(delta: float) -> void:
	clock += delta
	var owner_jelly := get_parent() as Jelly
	if owner_jelly != null:
		skin = owner_jelly.skin
		expression = owner_jelly.expression
		motion = owner_jelly.velocity
		squash = owner_jelly.squash
	queue_redraw()

func _draw() -> void:
	var index := maxi(0, SKIN_IDS.find(skin))
	var tint: Color = GLOW_COLORS[index]
	var speed := motion.length()
	var stretch := clampf(speed / 1800.0, 0.0, 0.16)
	var breathe := sin(clock * 3.1) * (0.025 if speed < 100.0 else 0.007)
	var tilt := clampf(motion.x / 1600.0, -0.17, 0.17)
	var bob := sin(clock * 2.5) * (1.0 if speed < 70.0 else 0.0)
	if expression == "sad":
		tilt += sin(clock * 18.0) * 0.035
	var shape := Transform2D(tilt, Vector2(0, bob)).scaled(Vector2(1.0 + stretch - squash * 0.52 + breathe, 1.0 - stretch * 0.50 + squash - breathe))
	draw_set_transform_matrix(shape)
	draw_circle(Vector2(0, 2), 31.0, Color(tint.r, tint.g, tint.b, 0.10 + 0.04 * sin(clock * 3.0)))
	var cell := Vector2(ATLAS.get_width() / 3.0, ATLAS.get_height() / 5.0)
	var source := Rect2(Vector2(float(index % 3) * cell.x, float(index / 3) * cell.y), cell)
	var body_tint := Color.WHITE
	if expression == "sad":
		body_tint = Color("ffc2d0")
	elif expression == "fear":
		body_tint = Color("fff0bf")
	draw_texture_rect_region(ATLAS, Rect2(-28, -34, 56, 68), source, body_tint)
	if expression == "happy":
		var shine := Vector2(31, -28) + Vector2(0, sin(clock * 5.0) * 2.0)
		draw_line(shine + Vector2(-4, 0), shine + Vector2(4, 0), Color.WHITE, 1.8, true)
		draw_line(shine + Vector2(0, -4), shine + Vector2(0, 4), Color.WHITE, 1.8, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
