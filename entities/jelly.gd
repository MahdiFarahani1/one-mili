extends CharacterBody2D
class_name Jelly

const VisualScript = preload("res://entities/jelly_visual.gd")

signal collided
signal surface_hit(kind: String, body: StaticBody2D)

var gravity_direction := Vector2.DOWN
var alive := true
var squash := 0.0
var expression := "normal"
var skin := "classic"
var trail := "sparkle"
var particles: Array[Dictionary] = []
var radius := 24.0
var gravity_scale := 1.0
var hit_feedback_cooldown := 0.0
var trail_timer := 0.0
var spring_cooldown := 0.0

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var art: Node2D = VisualScript.new()
	art.name = "Visual"
	add_child(art)
	collision_layer = 1
	collision_mask = 2
	add_to_group("jelly")

func reset(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	gravity_scale = 1.0
	gravity_direction = Vector2.DOWN
	alive = true
	squash = 0.0
	expression = "normal"
	particles.clear()
	hit_feedback_cooldown = 0.0
	trail_timer = 0.0
	spring_cooldown = 0.0
	queue_redraw()

func _draw() -> void:
	var trail_colors := {"sparkle": Color("fff0ab"), "bubble": Color("bfefff"), "fire": Color("ffac68"), "snow": Color("e7faff"), "rainbow": Color("ff91cc"), "star": Color("ffe287"), "leaf": Color("a8f4ad"), "moon": Color("c9b6ff"), "crystal": Color("8affef"), "heart": Color("ff9ab9")}
	for particle in particles:
		var c: Color = trail_colors.get(trail, Color("fff0ab"))
		c.a = float(particle["life"]) * 1.7
		var particle_pos: Vector2 = particle["p"] - velocity.normalized() * (0.45 - float(particle["life"])) * 65.0
		var particle_size := 3.0 * float(particle["life"]) / 0.45
		if trail in ["star", "sparkle", "crystal"]:
			draw_line(particle_pos + Vector2(-particle_size, 0), particle_pos + Vector2(particle_size, 0), c, 1.5, true)
			draw_line(particle_pos + Vector2(0, -particle_size), particle_pos + Vector2(0, particle_size), c, 1.5, true)
		else:
			draw_circle(particle_pos, particle_size, c)

func rotate_gravity() -> void:
	gravity_direction = Vector2(-gravity_direction.y, gravity_direction.x)
	# Down -> Left -> Up -> Right.
	squash = 0.25
	velocity += gravity_direction * 75.0
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	hit_feedback_cooldown = maxf(0.0, hit_feedback_cooldown - delta)
	trail_timer = maxf(0.0, trail_timer - delta)
	spring_cooldown = maxf(0.0, spring_cooldown - delta)
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
		var spring_hit := kind in ["spring", "mushroom"]
		var bounced := spring_hit and spring_cooldown <= 0.0
		if bounced:
			velocity += hit.get_normal() * (580.0 if kind == "mushroom" else 520.0)
			spring_cooldown = 0.18
		var fresh_hit := hit_feedback_cooldown <= 0.0
		if old_velocity.length() > 180.0 and fresh_hit:
			squash = minf(0.38, old_velocity.length() / 1700.0)
			collided.emit()
		if fresh_hit and (old_velocity.length() > 100.0 or bounced) and (not spring_hit or bounced):
			surface_hit.emit(kind, body)
			hit_feedback_cooldown = 0.13
	squash = move_toward(squash, 0.0, delta * 1.6)
	if velocity.length() > 130.0 and trail_timer <= 0.0:
		particles.append({"p": -velocity.normalized() * 21.0 + Vector2(randf_range(-7, 7), randf_range(-7, 7)), "life": 0.45})
		trail_timer = 0.04
		if particles.size() > 14:
			particles.pop_front()
	for i in range(particles.size() - 1, -1, -1):
		particles[i]["life"] -= delta
		if particles[i]["life"] <= 0:
			particles.remove_at(i)
	queue_redraw()
