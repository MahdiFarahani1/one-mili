extends Node2D
class_name Stage

signal won(seconds: float, turns: int, collected: int)
signal lost
signal crystal_collected(combo: int)
signal secret_found
signal powerup_obtained(kind: String)

const JellyScript = preload("res://entities/jelly.gd")
const Data = preload("res://levels/level_data.gd")
const PlatformScene = preload("res://entities/platform_visual.tscn")
const SAW = preload("res://assets/sprites/saw.png")
const PORTAL = preload("res://assets/sprites/portal.png")
const CRYSTAL = preload("res://assets/sprites/crystal.png")
const EMITTER = preload("res://assets/sprites/laser_emitter.png")
const BACKGROUNDS = [
	preload("res://assets/backgrounds/candy.png"),
	preload("res://assets/backgrounds/jungle.png"),
	preload("res://assets/backgrounds/crystal.png"),
	preload("res://assets/backgrounds/moon.png"),
	preload("res://assets/backgrounds/factory.png")
]
const FIELD := Rect2(60, 250, 600, 880)

var details: Dictionary
var player: Jelly
var camera: Camera2D
var walls: Array[StaticBody2D] = []
var obstacle_bodies: Array[StaticBody2D] = []
var moving_platform: StaticBody2D
var gate_body: StaticBody2D
var crystals: Array[Dictionary] = []
var powerups: Array[Dictionary] = []
var seconds := 0.0
var turns := 0
var combo := 0
var collected := 0
var bonus_collected := false
var ended := false
var world := 0
var anim := 0.0
var near_cooldown := 0.0
var portal_cooldown := 0.0
var previous_player_position := Vector2.ZERO
var last_failure := ""
var turn_flash := 0.0
var shake_intensity := 0.0
var effects: Array[Dictionary] = []

# Special gameplay power-up states
var has_shield := false
var slowmo_timer := 0.0
var invulnerable_timer := 0.0

func _init(level_details: Dictionary = {}) -> void:
	details = level_details

func _ready() -> void:
	process_physics_priority = 10
	world = int(details.get("world", 0))
	for r in [Rect2(36, 226, 648, 24), Rect2(36, 1130, 648, 24), Rect2(36, 250, 24, 880), Rect2(660, 250, 24, 880)]:
		add_wall(r, "boundary")
	for i in details.get("obstacles", []).size():
		var o: Dictionary = details["obstacles"][i]
		var body := add_wall(o["rect"], o["kind"])
		body.set_meta("kind", o["kind"])
		body.set_meta("obstacle_index", i)
		obstacle_bodies.append(body)
	for hazard in details.get("hazards", []):
		if hazard["kind"] == "platform":
			moving_platform = add_wall(Rect2(300, 920, 120, 20), "platform")
		if hazard["kind"] == "gate":
			gate_body = add_wall(Rect2(305, 979, 110, 22), "gate")
	for p in details.get("crystals", []):
		crystals.append({"position": p, "taken": false})
	for pu in details.get("powerups", []):
		powerups.append({"kind": pu["kind"], "position": pu["position"], "taken": false})
	
	player = JellyScript.new()
	add_child(player)
	player.skin = str(Save.data.get("skin", "classic"))
	player.trail = str(Save.data.get("trail", "sparkle"))
	player.reset(details.get("start", Vector2(115, 1030)))
	previous_player_position = player.position
	player.surface_hit.connect(on_surface_hit)
	
	camera = Camera2D.new()
	camera.zoom = Vector2(1.18, 1.18)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 720
	camera.limit_bottom = 1280
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 3.8
	add_child(camera)
	camera.position = player.position
	camera.make_current()
	camera.reset_smoothing()
	Sound.music(world)

func add_wall(rect: Rect2, kind: String = "normal") -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 2
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	var visual: PlatformVisual = PlatformScene.instantiate()
	body.add_child(visual)
	visual.configure(world, rect.size, kind)
	add_child(body)
	walls.append(body)
	return body

func on_surface_hit(kind: String, body: StaticBody2D) -> void:
	if kind == "spring":
		Sound.tone("spring")
		trigger_shake(3.2)
		burst(player.position, Color("ffd84d"), 14, 90.0)
		if world == 1: # Magic forest giant mushroom spore burst
			burst(player.position, Color("3fe08c"), 18, 110.0)
	elif kind == "fragile" and not body.get_meta("broken", false):
		body.set_meta("broken", true)
		body.set_deferred("collision_layer", 0)
		body.get_node("PlatformVisual").visible = false
		trigger_shake(4.5)
		burst(body.position, Color("b5e7ff"), 16, 95.0)
		var index := int(body.get_meta("obstacle_index", -1))
		if index >= 0:
			details["obstacles"][index]["broken"] = true
		queue_redraw()

func trigger_shake(intensity: float) -> void:
	shake_intensity = maxf(shake_intensity, intensity)

func rotate_gravity() -> void:
	if ended:
		return
	player.rotate_gravity()
	turns += 1
	turn_flash = 0.32
	burst(player.position, Color("a6e9ff"), 9, 64.0)
	Sound.tone("turn")
	if OS.has_feature("mobile") and Save.data.get("vibration", true):
		Input.vibrate_handheld(18)

func restart() -> void:
	seconds = 0.0
	anim = 0.0
	turns = 0
	combo = 0
	collected = 0
	bonus_collected = false
	ended = false
	last_failure = ""
	turn_flash = 0.0
	shake_intensity = 0.0
	near_cooldown = 0.0
	portal_cooldown = 0.0
	has_shield = false
	slowmo_timer = 0.0
	invulnerable_timer = 0.0
	effects.clear()
	for c in crystals:
		c["taken"] = false
	for pu in powerups:
		pu["taken"] = false
	for i in obstacle_bodies.size():
		obstacle_bodies[i].set_meta("broken", false)
		obstacle_bodies[i].set_deferred("collision_layer", 2)
		obstacle_bodies[i].get_node("PlatformVisual").visible = true
		details["obstacles"][i]["broken"] = false
	player.reset(details.get("start", Vector2(115, 1030)))
	previous_player_position = player.position
	camera.position = player.position

func _physics_process(delta: float) -> void:
	invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
	var effective_delta := delta
	if slowmo_timer > 0.0:
		slowmo_timer = maxf(0.0, slowmo_timer - delta)
		effective_delta = delta * 0.45

	anim += effective_delta
	turn_flash = maxf(0.0, turn_flash - delta)
	
	if camera != null:
		if shake_intensity > 0.0:
			camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity
			shake_intensity = move_toward(shake_intensity, 0.0, delta * 25.0)
		else:
			camera.offset = Vector2.ZERO
		camera.position = player.position
		
	for index in range(effects.size() - 1, -1, -1):
		effects[index]["p"] += effects[index]["v"] * effective_delta
		effects[index]["life"] -= delta
		if effects[index]["life"] <= 0.0:
			effects.remove_at(index)
			
	var movement_start := previous_player_position
	previous_player_position = player.position
	
	near_cooldown = maxf(0.0, near_cooldown - delta)
	if player.expression == "fear" and near_cooldown <= 0.0:
		player.expression = "normal"
	portal_cooldown = maxf(0.0, portal_cooldown - delta)
	
	if ended:
		queue_redraw()
		return
		
	seconds += delta
	
	# Bonus secret crystal
	var bonus_position: Vector2 = details.get("bonus", Vector2.ZERO)
	if bonus_position != Vector2.ZERO and not bonus_collected and segment_distance(movement_start, player.position, bonus_position) < 38:
		bonus_collected = true
		Sound.tone("crystal")
		trigger_shake(3.5)
		burst(bonus_position, Color("ffbbf9"), 16, 95.0)
		secret_found.emit()

	# Power-up items (Shield & Slow-Mo)
	for pu in powerups:
		if not pu.get("taken", false) and segment_distance(movement_start, player.position, pu["position"]) < 38.0:
			pu["taken"] = true
			var p_kind: String = pu["kind"]
			if p_kind == "shield":
				has_shield = true
				Sound.tone("crystal")
				trigger_shake(3.2)
				burst(pu["position"], Color("38b6ff"), 22, 110.0)
				powerup_obtained.emit("shield")
			elif p_kind == "slowmo":
				slowmo_timer = 4.0
				Sound.tone("spring")
				trigger_shake(2.8)
				burst(pu["position"], Color("ffd84d"), 22, 110.0)
				powerup_obtained.emit("slowmo")
		
	player.gravity_scale = 1.0
	if moving_platform != null:
		moving_platform.position.x = 360.0 + sin(anim * 1.2) * 90.0
		
	while collected < crystals.size():
		var next: Dictionary = crystals[collected]
		if segment_distance(movement_start, player.position, next["position"]) < 40.0:
			next["taken"] = true
			collected += 1
			combo += 1
			Sound.tone("crystal")
			trigger_shake(2.0)
			burst(next["position"], Color("ffe7a2"), 14, 95.0)
			crystal_collected.emit(combo)
		else:
			break
			
	for hazard in details.get("hazards", []):
		var p: Vector2 = hazard["center"]
		var kind: String = hazard["kind"]
		if kind == "mover":
			p.x += sin(anim * 1.55 + float(hazard["phase"])) * float(hazard.get("amplitude", 100.0))
		if kind == "laser":
			var beam_start: Vector2 = hazard.get("start", Vector2(170, p.y))
			var beam_end: Vector2 = hazard.get("end", Vector2(550, p.y))
			if fmod(anim + float(hazard["phase"]), 3.0) < 1.0 and horizontal_beam_hit(movement_start, player.position, beam_start, beam_end):
				fail(kind)
			continue
		if kind == "bridge_laser":
			if fmod(anim + float(hazard["phase"]), 3.6) < 1.4 and vertical_beam_hit(movement_start, player.position, Vector2(p.x, 251), Vector2(p.x, 412)):
				fail(kind)
			continue
		if kind == "platform":
			continue
		if kind == "gate":
			if gate_body != null:
				var gate_active := fmod(anim + float(hazard["phase"]), 3.2) < 1.7
				gate_body.set_deferred("collision_layer", 2 if gate_active else 0)
				gate_body.get_node("PlatformVisual").modulate.a = 1.0 if gate_active else 0.25
			continue
		if kind == "zero":
			if player.position.distance_to(p) < float(hazard["radius"]):
				player.gravity_scale = 0.0
			continue
		if kind == "portal":
			if portal_cooldown <= 0.0 and player.position.distance_to(p) < 31.0:
				player.position = hazard["exit"]
				portal_cooldown = 1.0
				trigger_shake(4.0)
				burst(hazard["exit"], Color("83e5ff"), 12, 70.0)
				Sound.tone("spring")
			continue
		if kind == "magnet":
			if player.position.distance_to(p) < 100.0:
				player.velocity += (p - player.position).normalized() * 180.0 * effective_delta
			continue
			
		var distance := segment_distance(movement_start, player.position, p)
		if distance < float(hazard["radius"]) + player.radius - 3.0:
			fail(kind)
		elif distance < float(hazard["radius"]) + player.radius + 18.0 and near_cooldown <= 0.0:
			near_cooldown = 1.0
			player.expression = "fear"
			trigger_shake(4.5)
			burst(player.position.lerp(p, 0.5), Color("ffe680"), 8, 75.0)
			Sound.tone("near")
			
	if ended:
		queue_redraw()
		return
		
	if collected >= crystals.size() and segment_distance(movement_start, player.position, details.get("goal", Vector2.ZERO)) < 44.0:
		ended = true
		player.alive = false
		player.expression = "happy"
		trigger_shake(6.0)
		burst(player.position, Color("a4f4ff"), 24, 160.0)
		Sound.tone("win")
		won.emit(seconds, turns, collected + (8 if bonus_collected else 0))
		
	queue_redraw()

func segment_distance(start: Vector2, finish: Vector2, point: Vector2) -> float:
	var distance_squared := start.distance_squared_to(finish)
	if distance_squared < 0.001:
		return point.distance_to(finish)
	var t := clampf((point - start).dot(finish - start) / distance_squared, 0.0, 1.0)
	return point.distance_to(start.lerp(finish, t))

func burst(center: Vector2, tint: Color, count: int, speed: float) -> void:
	for i in count:
		var angle := TAU * float(i) / float(count) + anim * 0.7
		effects.append({
			"p": center,
			"v": Vector2.RIGHT.rotated(angle) * speed * (0.7 + float(i % 3) * 0.14),
			"life": 0.48,
			"color": tint
		})
	if effects.size() > 90:
		effects = effects.slice(effects.size() - 90)

func horizontal_beam_hit(start: Vector2, finish: Vector2, beam_start: Vector2, beam_end: Vector2) -> bool:
	var min_x := minf(beam_start.x, beam_end.x) - player.radius
	var max_x := maxf(beam_start.x, beam_end.x) + player.radius
	var min_y := minf(start.y, finish.y)
	var max_y := maxf(start.y, finish.y)
	return maxf(start.x, finish.x) >= min_x and minf(start.x, finish.x) <= max_x and min_y <= beam_start.y + player.radius + 5.0 and max_y >= beam_start.y - player.radius - 5.0

func vertical_beam_hit(start: Vector2, finish: Vector2, beam_start: Vector2, beam_end: Vector2) -> bool:
	var min_y := minf(beam_start.y, beam_end.y) - player.radius
	var max_y := maxf(beam_start.y, beam_end.y) + player.radius
	return maxf(start.y, finish.y) >= min_y and minf(start.y, finish.y) <= max_y and minf(start.x, finish.x) <= beam_start.x + player.radius + 5.0 and maxf(start.x, finish.x) >= beam_start.x - player.radius - 5.0

func fail(reason: String = "") -> void:
	if ended:
		return
	if invulnerable_timer > 0.0:
		return
	if has_shield:
		has_shield = false
		invulnerable_timer = 1.3
		trigger_shake(8.5)
		burst(player.position, Color("38b6ff"), 28, 140.0)
		Sound.tone("spring")
		player.velocity = -player.velocity.normalized() * 260.0
		return

	last_failure = reason
	ended = true
	player.alive = false
	player.expression = "sad"
	trigger_shake(12.0)
	burst(player.position, Color("ff4267"), 22, 140.0)
	Save.data["deaths"] += 1
	Save.save_game()
	Sound.tone("hurt")
	if OS.has_feature("mobile") and Save.data.get("vibration", true):
		Input.vibrate_handheld(40)
	lost.emit()

func _draw() -> void:
	var accents: Array[Color] = [
		Color("38b6ff"), # Sky cyan
		Color("3fe08c"), # Forest emerald
		Color("b566ff"), # Crystal violet
		Color("6a7eff"), # Cosmic indigo
		Color("ff7a29")  # Factory molten orange
	]
	var base: Color = accents[world]
	
	# Parallax Scenery
	var offset := Vector2((player.position.x - 360.0) * -0.014, (player.position.y - 690.0) * -0.008)
	draw_texture_rect(BACKGROUNDS[world], Rect2(Vector2(-12, -12) + offset, Vector2(744, 1304)), false)
	draw_rect(Rect2(0, 0, 720, 1280), Color("020614", 0.16))
	
	# Slow-motion visual field border
	if slowmo_timer > 0.0:
		var pulse := 0.08 + 0.05 * sin(anim * 8.0)
		draw_rect(Rect2(0, 0, 720, 1280), Color("38b6ff", pulse), false, 10.0)
	
	# Ambient atmospheric motes
	for i in 16:
		var x := float((i * 173 + world * 53) % 750) - 15.0
		var y := float((i * 251 + world * 119) % 1050) + 150.0 + sin(anim * 0.5 + i) * 8.0
		match world:
			0:
				# Floating airy petal / feather
				draw_circle(Vector2(x, y), 2.2 + float(i % 3), Color("ffd8eb", 0.55))
			1:
				# Bioluminescent spores
				var p_pulse := 0.4 + 0.6 * sin(anim * 2.0 + i)
				draw_circle(Vector2(x, y), 7.0, Color("3fe08c", 0.12 * p_pulse))
				draw_circle(Vector2(x, y), 2.5, Color("b8ffe2", 0.75 * p_pulse))
			2:
				# Refractive crystal polygon
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, y - 26), Vector2(x + 14, y), Vector2(x, y + 22), Vector2(x - 14, y)
				]), Color("d7f8ff", 0.22))
			3:
				# Twinkling cosmic stars
				var star_size := 2.5 + float(i % 3)
				draw_circle(Vector2(x, y), star_size, Color("fff6d0", 0.70))
			4:
				# Clockwork glowing embers
				draw_circle(Vector2(x, y), 3.0 + float(i % 2) * 2.0, Color("ff9944", 0.60))
				
	draw_rect(FIELD, Color("030b1f", 0.10), true)
	
	# Hazards rendering
	for hazard in details.get("hazards", []):
		var p: Vector2 = hazard["center"]
		var kind: String = hazard["kind"]
		if kind == "mover":
			p.x += sin(anim * 1.55 + float(hazard["phase"])) * float(hazard.get("amplitude", 100.0))
			
		match kind:
			"laser":
				var beam_phase := fmod(anim + float(hazard["phase"]), 3.0)
				var active := beam_phase < 1.0
				var warning := beam_phase > 2.2 # 0.8s telegraph before active
				var beam_start: Vector2 = hazard.get("start", Vector2(170, p.y))
				var beam_end: Vector2 = hazard.get("end", Vector2(550, p.y))
				draw_laser(beam_start, beam_end, active, warning)
				draw_emitter(beam_start + Vector2(-4, 0), 0.0)
				draw_emitter(beam_end + Vector2(4, 0), PI)
			"bridge_laser":
				var beam_phase := fmod(anim + float(hazard["phase"]), 3.6)
				var active := beam_phase < 1.4
				var warning := beam_phase > 2.8
				draw_laser(Vector2(p.x, 251), Vector2(p.x, 412), active, warning)
				draw_emitter(Vector2(p.x, 249), PI * 0.5)
				draw_emitter(Vector2(p.x, 414), -PI * 0.5)
			"zero":
				var radius: float = hazard["radius"]
				draw_circle(p, radius, Color("927bff", 0.12))
				draw_arc(p, radius + sin(anim * 3.0) * 3.0, 0, TAU, 48, Color("ccbdff", 0.55), 3, true)
				texture_at(PORTAL, p, Vector2(65, 65), Color("a9d6ff", 0.38), anim * 0.25)
			"portal":
				for portal_position in [p, hazard["exit"]]:
					var pulse := 68.0 + sin(anim * 3.5) * 3.0
					texture_at(PORTAL, portal_position, Vector2(pulse, pulse), Color.WHITE, anim * 0.32)
			"magnet":
				draw_arc(p, 65 + sin(anim * 3) * 5, 0, TAU, 48, Color("a5e4ff", 0.36), 3, true)
				texture_at(PORTAL, p, Vector2(48, 48), Color("83e5ff", 0.62), -anim * 0.25)
			"saw", "mover":
				var radius: float = hazard["radius"]
				draw_themed_hazard(p, radius)
				
	# Powerups rendering (Shield & Slow-Mo)
	for pu in powerups:
		if not pu.get("taken", false):
			var pu_pos: Vector2 = pu["position"] + Vector2(0, sin(anim * 3.5 + pu["position"].x) * 4.5)
			if pu["kind"] == "shield":
				draw_arc(pu_pos, 22.0 + sin(anim * 4.0) * 3.0, 0, TAU, 32, Color("38b6ff", 0.65), 2.5, true)
				draw_circle(pu_pos, 16.0, Color("143b66", 0.85))
				var crest := PackedVector2Array([
					pu_pos + Vector2(0, -9), pu_pos + Vector2(8, -5),
					pu_pos + Vector2(6, 6), pu_pos + Vector2(0, 10),
					pu_pos + Vector2(-6, 6), pu_pos + Vector2(-8, -5)
				])
				draw_colored_polygon(crest, Color("74ddff"))
			elif pu["kind"] == "slowmo":
				draw_arc(pu_pos, 22.0 + sin(anim * 4.0) * 3.0, 0, TAU, 32, Color("ffd84d", 0.65), 2.5, true)
				draw_circle(pu_pos, 16.0, Color("4a390e", 0.85))
				draw_colored_polygon(PackedVector2Array([
					pu_pos + Vector2(-7, -8), pu_pos + Vector2(7, -8),
					pu_pos + Vector2(1, 0), pu_pos + Vector2(7, 8),
					pu_pos + Vector2(-7, 8), pu_pos + Vector2(-1, 0)
				]), Color("ffe380"))

	# Crystals rendering
	if collected < crystals.size():
		var c: Dictionary = crystals[collected]
		var position: Vector2 = c["position"] + Vector2(0, sin(anim * 3.0 + c["position"].x) * 4.0)
		draw_circle(position, 25, Color("ffcf71", 0.20))
		texture_at(CRYSTAL, position, Vector2(30, 49), Color.WHITE, sin(anim * 2.0) * 0.08)
		
	var bonus_position: Vector2 = details.get("bonus", Vector2.ZERO)
	if bonus_position != Vector2.ZERO and not bonus_collected:
		var secret := bonus_position + Vector2(0, sin(anim * 2.5) * 5)
		draw_circle(secret, 28, Color("df8eff", 0.25))
		texture_at(CRYSTAL, secret, Vector2(33, 53), Color("d4a4ff"), -sin(anim * 2.0) * 0.08)
		
	var goal: Vector2 = details.get("goal", Vector2(112, 340))
	var unlocked := collected >= crystals.size()
	var goal_size := 84.0 + sin(anim * 3.0) * 4.0
	texture_at(PORTAL, goal, Vector2(goal_size, goal_size), Color.WHITE if unlocked else Color("8391b1", 0.68), -anim * 0.22)
	
	# Active player energy shield
	if has_shield:
		var hex_points := PackedVector2Array()
		for h in 6:
			var a := anim * 2.2 + float(h) * (TAU / 6.0)
			hex_points.append(player.position + Vector2(cos(a), sin(a)) * 36.0)
		draw_polyline(hex_points + PackedVector2Array([hex_points[0]]), Color("38b6ff", 0.9), 3.0, true)
		draw_circle(player.position, 34.0, Color("38b6ff", 0.12))
		for s in 3:
			var sa := anim * -3.5 + float(s) * (TAU / 3.0)
			draw_circle(player.position + Vector2(cos(sa), sin(sa)) * 36.0, 3.5, Color("d0f4ff"))
	elif invulnerable_timer > 0.0:
		draw_arc(player.position, 37.0, 0, TAU, 24, Color("ffffff", 0.7 * (sin(anim * 32.0) * 0.5 + 0.5)), 3.0, true)

	if near_cooldown > 0.0:
		draw_arc(player.position, 35 + (1.0 - near_cooldown) * 12.0, 0, TAU, 48, Color("fff3b7", near_cooldown * 0.6), 3, true)
	if turn_flash > 0.0:
		draw_arc(player.position, 31.0 + (0.32 - turn_flash) * 80.0, 0, TAU, 48, Color("abedff", turn_flash * 1.6), 3, true)
		
	for effect in effects:
		var point: Vector2 = effect["p"]
		var tint: Color = effect["color"]
		tint.a = clampf(float(effect["life"]) * 1.8, 0.0, 0.85)
		draw_line(point + Vector2(-3, 0), point + Vector2(3, 0), tint, 2, true)
		draw_line(point + Vector2(0, -3), point + Vector2(0, 3), tint, 2, true)

func draw_themed_hazard(p: Vector2, radius: float) -> void:
	match world:
		0:
			# Sky & Clouds: Sun-Gear Razor Saw
			var r := radius * 1.35
			draw_circle(p, r + 14, Color("ffd55e", 0.18))
			for ray in 8:
				var a := anim * 3.5 + float(ray) * (TAU / 8.0)
				var pt := p + Vector2(cos(a), sin(a)) * (r + 7.0)
				draw_line(p, pt, Color("ffd55e", 0.8), 3.0, true)
			texture_at(SAW, p, Vector2(radius * 2.7, radius * 2.7), Color("fff4ba"), anim * 2.8)
			draw_circle(p, 8.0, Color("ffb84d"))
		1:
			# Magic Forest: Carnivorous Bramble / Spiked Thorn Maw
			var r := radius * 1.35
			draw_circle(p, r + 12, Color("3fe08c", 0.16))
			for thorn in 6:
				var a := anim * 2.2 + float(thorn) * (TAU / 6.0)
				var tip := p + Vector2(cos(a), sin(a)) * (r + 8.0)
				draw_line(p, tip, Color("9affc4", 0.9), 3.5, true)
			texture_at(SAW, p, Vector2(radius * 2.6, radius * 2.6), Color("b8ffe2"), anim * 2.2)
			draw_circle(p, 9.0, Color("802d99"))
		2:
			# Crystal World: Radiant Crystal Star Shard
			var r := radius * 1.4
			draw_circle(p, r + 16, Color("b566ff", 0.20))
			for shard in 6:
				var a := anim * 3.0 + float(shard) * (TAU / 6.0)
				var tip := p + Vector2(cos(a), sin(a)) * (r + 10.0)
				var left := p + Vector2(cos(a - 0.25), sin(a - 0.25)) * (r * 0.6)
				var right := p + Vector2(cos(a + 0.25), sin(a + 0.25)) * (r * 0.6)
				draw_colored_polygon(PackedVector2Array([left, tip, right]), Color("c47aff", 0.85))
			texture_at(SAW, p, Vector2(radius * 2.5, radius * 2.5), Color("e9c4ff"), -anim * 2.5)
			draw_circle(p, 8.0, Color("ffffff"))
		3:
			# Cosmic Space: Dark Matter Vortex / Asteroid Maw
			var r := radius * 1.4
			draw_circle(p, r + 16, Color("6a7eff", 0.22))
			draw_arc(p, r + 6.0 + sin(anim * 5.0) * 4.0, 0, TAU, 36, Color("74ddff", 0.7), 2.5, true)
			texture_at(SAW, p, Vector2(radius * 2.7, radius * 2.7), Color("9bb1ff"), anim * 1.8)
			draw_circle(p, 10.0, Color("0b0922"))
		4:
			# Mechanical Factory: Industrial Steel Gear with Molten Core
			var r := radius * 1.35
			draw_circle(p, r + 14, Color("ff7a29", 0.22))
			for tooth in 8:
				var a := anim * 4.0 + float(tooth) * (TAU / 8.0)
				var tip := p + Vector2(cos(a), sin(a)) * (r + 9.0)
				draw_line(p, tip, Color("ffd84d", 0.9), 4.0, true)
			texture_at(SAW, p, Vector2(radius * 2.7, radius * 2.7), Color("ffaa77"), anim * 3.5)
			draw_circle(p, 9.0, Color("ff3b30"))

func texture_at(source: Texture2D, center: Vector2, size: Vector2, tint: Color = Color.WHITE, angle: float = 0.0) -> void:
	draw_set_transform(center, angle)
	draw_texture_rect(source, Rect2(-size * 0.5, size), false, tint)
	draw_set_transform(Vector2.ZERO)

func draw_emitter(center: Vector2, angle: float) -> void:
	texture_at(EMITTER, center, Vector2(48, 29), Color.WHITE, angle)

func draw_laser(start: Vector2, finish: Vector2, active: bool, warning: bool = false) -> void:
	var phase := 0.6 + 0.4 * sin(anim * 12.0)
	if active:
		draw_line(start, finish, Color("ff2a55", 0.35), 24, true)
		draw_line(start, finish, Color("ff4971", 0.70), 12, true)
		draw_line(start, finish, Color("fff6db", 0.95 + phase * 0.05), 4, true)
		draw_circle(start, 9.0 + phase * 3.0, Color("ff315d", 0.8))
		draw_circle(finish, 9.0 + phase * 3.0, Color("ff315d", 0.8))
	elif warning:
		var warn_pulse := 0.5 + 0.5 * sin(anim * 18.0)
		draw_line(start, finish, Color("ff8e3d", 0.25 * warn_pulse), 14, true)
		draw_line(start, finish, Color("ffe380", 0.60 * warn_pulse), 3, true)
		draw_circle(start, 6.0, Color("ff9933", 0.6 * warn_pulse))
		draw_circle(finish, 6.0, Color("ff9933", 0.6 * warn_pulse))
	else:
		draw_line(start, finish, Color("ff5577", 0.12), 2, true)
