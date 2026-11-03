extends CharacterBody2D
class_name Jelly

const BODY_TEXTURES = {
	"classic": preload("res://assets/sprites/jelly_classic.png"),
	"fire": preload("res://assets/sprites/jelly_fire.png"),
	"ice": preload("res://assets/sprites/jelly_ice.png"),
	"galaxy": preload("res://assets/sprites/jelly_galaxy.png"),
	"gold": preload("res://assets/sprites/jelly_gold.png"),
	"rainbow": preload("res://assets/sprites/jelly_rainbow.png"),
	"ninja": preload("res://assets/sprites/jelly_ninja.png"),
	"robot": preload("res://assets/sprites/jelly_robot.png"),
	"ghost": preload("res://assets/sprites/jelly_ghost.png"),
	"crystal": preload("res://assets/sprites/jelly_crystal.png"),
	"candy": preload("res://assets/sprites/jelly_candy.png"),
	"star": preload("res://assets/sprites/jelly_star.png"),
	"electric": preload("res://assets/sprites/jelly_electric.png"),
	"moon": preload("res://assets/sprites/jelly_moon.png"),
	"legendary": preload("res://assets/sprites/jelly_legendary.png")
}

signal collided
signal surface_hit(kind: String, body: StaticBody2D)

var gravity_direction := Vector2.DOWN
var alive := true
var elapsed := 0.0
var squash := 0.0
var blink := 0.0
var expression := "normal"
var skin := "classic"
var trail := "sparkle"
var particles: Array[Dictionary] = []
var radius := 24.0
var gravity_scale := 1.0

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	collision_layer = 1
	collision_mask = 2
	add_to_group("jelly")

func reset(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	gravity_scale = 1.0
	gravity_direction = Vector2.DOWN
	alive = true
	elapsed = 0.0
	squash = 0.0
	expression = "normal"
	particles.clear()
	queue_redraw()

func rotate_gravity() -> void:
	gravity_direction = Vector2(-gravity_direction.y, gravity_direction.x)
	# Down -> Left -> Up -> Right.
	squash = 0.25
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	elapsed += delta
	blink = 1.0 if fmod(elapsed + 0.37, 3.9) < 0.11 else 0.0
	velocity += gravity_direction * 900.0 * gravity_scale * delta
	velocity = velocity.limit_length(730.0)
	velocity *= pow(0.991, delta * 120.0)
	var old_velocity := velocity
	move_and_slide()
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider() as StaticBody2D
		if body == null: continue
		var kind: String = str(body.get_meta("kind", "normal"))
		if kind == "ice": velocity = velocity.slide(hit.get_normal()) * 1.03
		if kind == "sticky": velocity *= 0.66
		if kind == "spring": velocity += hit.get_normal() * 520.0
		if old_velocity.length() > 180.0:
			squash = minf(0.38, old_velocity.length() / 1700.0)
			collided.emit()
		surface_hit.emit(kind, body)
	squash = move_toward(squash, 0.0, delta * 1.6)
	if velocity.length() > 130.0 and randf() < delta * 24.0:
		particles.append({"p": -velocity.normalized() * 21.0 + Vector2(randf_range(-7, 7), randf_range(-7, 7)), "life": 0.45})
	for i in range(particles.size() - 1, -1, -1):
		particles[i]["life"] -= delta
		if particles[i]["life"] <= 0:
			particles.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for particle in particles:
		var trail_colors := {"sparkle": Color("fff0ab"), "bubble": Color("bfefff"), "fire": Color("ffac68"), "snow": Color("e7faff"), "rainbow": Color("ff91cc"), "star": Color("ffe287"), "leaf": Color("a8f4ad"), "moon": Color("c9b6ff"), "crystal": Color("8affef"), "heart": Color("ff9ab9")}
		var c: Color = trail_colors.get(trail, Color("fff0ab"))
		c.a = float(particle["life"]) * 1.7
		var particle_pos: Vector2 = particle["p"] - velocity.normalized() * (0.45 - float(particle["life"])) * 65.0
		var particle_size := 3.0 * float(particle["life"]) / 0.45
		if trail in ["star", "sparkle", "crystal"]:
			draw_line(particle_pos + Vector2(-particle_size, 0), particle_pos + Vector2(particle_size, 0), c, 1.5, true)
			draw_line(particle_pos + Vector2(0, -particle_size), particle_pos + Vector2(0, particle_size), c, 1.5, true)
		else:
			draw_circle(particle_pos, particle_size, c)
	var palette := {"classic": Color("9edfff"), "fire": Color("ff9a67"), "ice": Color("85dfff"), "galaxy": Color("9772df"), "gold": Color("ffd45e"), "rainbow": Color("f78ed4"), "ninja": Color("6c709c"), "robot": Color("98b5c7"), "ghost": Color("d9e7f7"), "crystal": Color("91d9ef"), "candy": Color("ff9dad"), "star": Color("ffe07a"), "electric": Color("eee66a"), "moon": Color("b8a0ed"), "legendary": Color("fa93d0")}
	var body: Color = palette.get(skin, Color("9edfff"))
	var stretch := clampf(velocity.length() / 1250.0, 0.0, 0.32)
	var angle := velocity.angle() if velocity.length() > 10.0 else 0.0
	var transform_local := Transform2D(angle, Vector2.ZERO).scaled(Vector2(1.0 + stretch - squash * 0.7, 1.0 - stretch * 0.5 + squash))
	draw_set_transform_matrix(transform_local)
	draw_circle(Vector2(0, 4), 30, Color(body.r, body.g, body.b, 0.15))
	draw_texture_rect(BODY_TEXTURES.get(skin, BODY_TEXTURES["classic"]), Rect2(-26, -26, 52, 52), false)
	draw_circle(Vector2(0, 1), 12, Color("e6f8ff", 0.17))
	match skin:
		"fire":
			draw_colored_polygon(PackedVector2Array([Vector2(-11, -20), Vector2(-7, -36), Vector2(-1, -24), Vector2(5, -39), Vector2(13, -20)]), Color("ffdc72"))
		"ice":
			for i in 3:
				var x := -12 + i * 12
				draw_colored_polygon(PackedVector2Array([Vector2(x, -22), Vector2(x + 5, -31), Vector2(x + 9, -21)]), Color("e9ffff"))
		"galaxy":
			for i in 7:
				var p := Vector2(-14 + i * 5, -14 + (i * 11) % 26)
				draw_circle(p, 1.5 + i % 2, Color("ffe9ff"))
		"rainbow":
			for i in 3:
				draw_arc(Vector2(0, 1), 11 + i * 5, PI + 0.2, TAU - 0.2, 18, [Color("ffe37b"), Color("8ce8e2"), Color("e8b0ff")][i], 3, true)
		"ghost":
			draw_arc(Vector2.ZERO, 22, 0.1, PI - 0.1, 18, Color("ffffff", 0.75), 3, true)
		"crystal":
			draw_colored_polygon(PackedVector2Array([Vector2(-3, -22), Vector2(10, -8), Vector2(0, 8), Vector2(-10, -8)]), Color("dcffff", 0.38))
		"candy":
			draw_arc(Vector2(0, -6), 11, 0.3, TAU * 1.7, 28, Color("fff1e8"), 3, true)
		"electric":
			draw_colored_polygon(PackedVector2Array([Vector2(-2, -24), Vector2(8, -24), Vector2(0, -9), Vector2(10, -9), Vector2(-5, 8), Vector2(-1, -5), Vector2(-10, -5)]), Color("fffdf0"))
		"moon":
			draw_circle(Vector2(0, -13), 10, Color("f8f2ff"))
			draw_circle(Vector2(5, -16), 9, body)
		"legendary":
			for i in 4:
				draw_circle(Vector2(-15 + i * 10, -17 + i % 2 * 4), 2, Color("ffffff"))
	if skin in ["gold", "star", "legendary"]:
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -23), Vector2(-2, -37), Vector2(4, -23), Vector2(13, -34), Vector2(15, -21)]), Color("ffe7a1"))
	if skin == "ninja":
		draw_rect(Rect2(-23, -10, 46, 13), Color("34334f"))
	if skin == "robot":
		draw_rect(Rect2(-8, -28, 16, 7), Color("76869d"))
	if blink > 0.0:
		draw_line(Vector2(-8, 0), Vector2(-3, 0), Color("453253"), 2.5, true)
		draw_line(Vector2(4, 0), Vector2(9, 0), Color("453253"), 2.5, true)
	else:
		draw_circle(Vector2(-6, -1), 3.6, Color("342841"))
		draw_circle(Vector2(7, -1), 3.6, Color("342841"))
		draw_circle(Vector2(-7, -2), 1.2, Color.WHITE)
		draw_circle(Vector2(6, -2), 1.2, Color.WHITE)
	if expression == "fear":
		draw_circle(Vector2(1, 10), 4, Color("813a62"))
	elif expression == "sad":
		draw_arc(Vector2(1, 13), 5, PI + 0.25, TAU - 0.25, 12, Color("813a62"), 2.3, true)
	elif expression == "happy":
		draw_arc(Vector2(1, 7), 7, 0.2, PI - 0.2, 12, Color("813a62"), 2.5, true)
	else:
		draw_arc(Vector2(1, 6), 4, 0.15, PI - 0.15, 12, Color("813a62"), 2.0, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
