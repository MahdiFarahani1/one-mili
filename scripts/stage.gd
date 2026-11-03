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
const MushroomScript = preload("res://entities/reactive_mushroom.gd")
const SAW = preload("res://assets/sprites/saw.png")
const PORTAL = preload("res://assets/sprites/portal.png")
const CRYSTAL = preload("res://assets/sprites/crystal.png")
const EMITTER = preload("res://assets/sprites/laser_emitter.png")
const LEVEL_ONE_SKY = preload("res://assets/backgrounds/level_01_sky.png")
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
var record_failures := true

# Special gameplay power-up states
var has_shield := false
var slowmo_timer := 0.0
var invulnerable_timer := 0.0

func _init(level_details: Dictionary = {}) -> void:
	details = level_details

func _ready() -> void:
	process_physics_priority = 10
	world = int(details.get("world", 0))
	var first_level := int(details.get("number", 0)) == 1
	var side_width := 44.0 if world == 0 else 24.0
	for r in [Rect2(36, 226, 648, 24), Rect2(36, 1130, 648, 24), Rect2(36, 250, side_width, 880), Rect2(684.0 - side_width, 250, side_width, 880)]:
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
	if int(details.get("number", 0)) == 1:
		for spot in [Vector2(220, 890), Vector2(565, 670), Vector2(265, 450)]:
			var mushroom: StaticBody2D = MushroomScript.new()
			mushroom.position = spot
			add_child(mushroom)
	
	player = JellyScript.new()
	add_child(player)
	player.skin = str(Save.data.get("skin", "classic"))
	player.trail = str(Save.data.get("trail", "sparkle"))
	player.reset(details.get("start", Vector2(115, 1030)))
	previous_player_position = player.position
	player.surface_hit.connect(on_surface_hit)
	
	camera = Camera2D.new()
	camera.zoom = Vector2(1.28, 1.28)
	camera.limit_left = 10
	camera.limit_top = 180
	camera.limit_right = 710
	camera.limit_bottom = 1200
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.2
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
	visual.configure(world, rect.size, kind, world == 0)
	add_child(body)
	walls.append(body)
	return body

func on_surface_hit(kind: String, body: StaticBody2D) -> void:
	if kind == "mushroom":
		if body.has_method("react_to_hit") and body.react_to_hit(player.position, player.velocity.length()):
			Sound.tone("mushroom")
			burst(body.position + Vector2(0, -72), Color("71e6f5"), 12, 100.0)
			trigger_shake(3.0)
		return
	var visual := body.get_node_or_null("PlatformVisual")
	if visual != null and visual.has_method("on_spring_bounce"):
		visual.on_spring_bounce()

	if player.velocity.length() > 190.0:
		match world:
			0: burst(player.position, Color("ffd55e"), 7, 65.0) # Sky golden dust
			1: burst(player.position, Color("3fe08c"), 9, 70.0) # Forest spores
			2: burst(player.position, Color("c47aff"), 8, 75.0) # Crystal shards
			3: burst(player.position, Color("74ddff"), 7, 70.0) # Cosmic stardust
			4: burst(player.position, Color("ff9944"), 9, 85.0) # Factory sparks

	if kind == "spring":
		Sound.tone("spring")
		trigger_shake(3.2)
		burst(player.position, Color("ffd84d"), 16, 95.0)
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
		var lead := player.velocity * 0.08 + player.gravity_direction * 28.0
		var target_cam := player.position + lead
		target_cam.x = clampf(target_cam.x, 260.0, 460.0)
		target_cam.y = clampf(target_cam.y, 440.0, 840.0)
		camera.position = camera.position.lerp(target_cam, clampf(delta * 4.8, 0.0, 1.0))
		
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
		if kind == "wind":
			var wind_rect := Rect2(p - Vector2(hazard["size"]) * 0.5, hazard["size"])
			if wind_rect.has_point(player.position):
				player.velocity += Vector2(hazard["force"]) * effective_delta
			continue
		if kind == "mover":
			p.x += sin(anim * 1.55 + float(hazard["phase"])) * float(hazard.get("amplitude", 100.0))
		if kind == "storm":
			if fmod(anim + float(hazard["phase"]), 3.4) < 0.95 and horizontal_beam_hit(movement_start, player.position, hazard["start"], hazard["end"]):
				fail(kind)
			continue
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
	if record_failures:
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
	
	# 1. Deep Parallax Scenery
	var cam_pos := camera.position if camera != null else Vector2(360, 690)
	var deep_offset := (cam_pos - Vector2(360, 690)) * -0.015
	var first_level := world == 0
	draw_texture_rect(LEVEL_ONE_SKY if first_level else BACKGROUNDS[world], Rect2(Vector2(-24, -24) + deep_offset, Vector2(768, 1328)), false)
	if not first_level:
		draw_rect(Rect2(0, 0, 720, 1280), Color("020614", 0.12))

	# 2. Midground Living Parallax Elements
	var mid_offset := (cam_pos - Vector2(360, 690)) * -0.045
	match world:
		0:
			# Fine, tapered cloud wisps keep the flight corridor readable.
			for c in 4:
				var cx := fmod(anim * (8.0 + float(c)) + float(c) * 241.0, 900.0) - 90.0 + mid_offset.x
				var cy := 365.0 + float(c) * 185.0 + mid_offset.y
				var points := PackedVector2Array([
					Vector2(cx - 80, cy + 8), Vector2(cx - 35, cy - 4),
					Vector2(cx + 18, cy - 9), Vector2(cx + 75, cy + 3),
					Vector2(cx + 27, cy + 8), Vector2(cx - 26, cy + 11)
				])
				draw_colored_polygon(points, Color("bad8f4", 0.08))
				draw_line(Vector2(cx - 35, cy - 4), Vector2(cx + 18, cy - 9), Color("d7edff", 0.10), 1.5, true)
		1:
			# Magic Forest: Distant giant mushroom canopies & drifting mist layers
			var mist_x := sin(anim * 0.4) * 35.0 + mid_offset.x
			draw_rect(Rect2(Vector2(40 + mist_x, 460 + mid_offset.y), Vector2(640, 190)), Color("3fe08c", 0.05), true)
			draw_rect(Rect2(Vector2(40 - mist_x, 740 + mid_offset.y), Vector2(640, 170)), Color("40e8d0", 0.04), true)
			for m in 2:
				var mx := 170.0 + float(m) * 380.0 + mid_offset.x
				var my := 590.0 + float(m) * 200.0 + mid_offset.y
				draw_circle(Vector2(mx, my), 85.0, Color("0b2b1a", 0.28))
		2:
			# Crystal World: Distant giant glowing crystal pillars
			for cr in 3:
				var cx := 140.0 + float(cr) * 220.0 + mid_offset.x
				var cy := 640.0 + mid_offset.y
				var c_poly := PackedVector2Array([
					Vector2(cx - 25, cy + 190), Vector2(cx, cy - 170), Vector2(cx + 25, cy + 190)
				])
				var c_alpha := 0.07 + 0.03 * sin(anim * 2.0 + float(cr))
				draw_colored_polygon(c_poly, Color("c47aff", c_alpha))
		3:
			# Cosmic Space: Distant planetary ring arc & celestial dust band
			var ring_center := Vector2(360, 640) + mid_offset
			draw_arc(ring_center, 250.0, anim * 0.04, anim * 0.04 + 1.8, 36, Color("74ddff", 0.07), 20.0)
			draw_arc(ring_center, 280.0, anim * -0.03, anim * -0.03 + 1.4, 36, Color("b566ff", 0.06), 16.0)
		4:
			# Mechanical Factory: Giant slowly rotating silhouette cogs in the background
			for g in 2:
				var gx := 190.0 + float(g) * 340.0 + mid_offset.x
				var gy := 510.0 + float(g) * 270.0 + mid_offset.y
				var gr := 115.0
				draw_arc(Vector2(gx, gy), gr, 0, TAU, 32, Color("331a08", 0.35), 14.0)
				for tooth in 10:
					var ga := anim * 0.35 * (1.0 if g == 0 else -1.0) + float(tooth) * (TAU / 10.0)
					var gp := Vector2(gx, gy) + Vector2(cos(ga), sin(ga)) * (gr + 12.0)
					draw_line(Vector2(gx, gy), gp, Color("331a08", 0.35), 16.0)

	# Slow-motion visual field border
	if slowmo_timer > 0.0:
		var pulse := 0.08 + 0.05 * sin(anim * 8.0)
		draw_rect(Rect2(0, 0, 720, 1280), Color("38b6ff", pulse), false, 10.0)
	
	# 3. Dynamic Atmospheric Living Motes (Drifting and swaying with Gravity!)
	var grav := player.gravity_direction if player != null else Vector2.DOWN
	for i in 18:
		var grav_drift := grav * (18.0 + float(i % 5) * 4.0)
		var x := float((i * 173 + world * 53) % 750) - 15.0 + grav_drift.x * sin(anim * 1.5 + float(i))
		var y := float((i * 251 + world * 119) % 1050) + 150.0 + grav_drift.y * cos(anim * 1.5 + float(i))
		match world:
			0:
				# Floating airy gold petal / feather
				var feather_alpha := 0.45 + 0.3 * sin(anim * 2.5 + float(i))
				draw_circle(Vector2(x, y), 2.5, Color("ffd55e", feather_alpha))
				draw_circle(Vector2(x, y), 5.5, Color("74ddff", feather_alpha * 0.35))
			1:
				# Bioluminescent spores & fireflies
				var p_pulse := 0.5 + 0.5 * sin(anim * 3.0 + float(i) * 1.2)
				draw_circle(Vector2(x, y), 8.0, Color("3fe08c", 0.16 * p_pulse))
				draw_circle(Vector2(x, y), 2.8, Color("b8ffe2", 0.85 * p_pulse))
				draw_circle(Vector2(x, y), 1.2, Color("ffffff", 0.95 * p_pulse))
			2:
				# Refractive crystal prism
				var prism_pulse := 0.4 + 0.4 * sin(anim * 3.5 + float(i))
				draw_colored_polygon(PackedVector2Array([
					Vector2(x, y - 18), Vector2(x + 10, y), Vector2(x, y + 16), Vector2(x - 10, y)
				]), Color("c47aff", 0.35 * prism_pulse))
			3:
				# Twinkling cosmic stars
				var star_size := 2.5 + float(i % 3)
				var star_pulse := 0.5 + 0.5 * sin(anim * 4.0 + float(i))
				draw_circle(Vector2(x, y), star_size * star_pulse, Color("fff6d0", 0.85))
				draw_circle(Vector2(x, y), star_size * 2.5 * star_pulse, Color("74ddff", 0.25))
			4:
				# Clockwork glowing molten embers
				var ember_pulse := 0.6 + 0.4 * sin(anim * 5.0 + float(i))
				draw_circle(Vector2(x, y), 3.2, Color("ff9944", 0.8 * ember_pulse))
				draw_circle(Vector2(x, y), 7.0, Color("ff3b30", 0.25 * ember_pulse))
	if world == 0:
		for prop in details.get("sky_props", []):
			draw_sky_prop(prop)
				
	if not first_level:
		draw_rect(FIELD, Color("030b1f", 0.10), true)
	if int(details.get("number", 0)) == 1:
		draw_first_level_walls()
	
	# Hazards rendering
	for hazard in details.get("hazards", []):
		var p: Vector2 = hazard["center"]
		var kind: String = hazard["kind"]
		if kind == "mover":
			p.x += sin(anim * 1.55 + float(hazard["phase"])) * float(hazard.get("amplitude", 100.0))
			
		match kind:
			"wind":
				draw_wind_field(p, Vector2(hazard["size"]), Vector2(hazard["force"]))
			"storm":
				var phase := fmod(anim + float(hazard["phase"]), 3.4)
				draw_storm_beam(hazard["start"], hazard["end"], phase < 0.95, phase > 2.65)
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

func draw_first_level_walls() -> void:
	# Keep the physics boundary readable without covering the floating-island art.
	for x in [80.0, 640.0]:
		draw_line(Vector2(x, 250), Vector2(x, 1130), Color("39dfff", 0.14), 10.0, true)
		draw_line(Vector2(x, 250), Vector2(x, 1130), Color("d4ffff", 0.54), 1.5, true)
		for row in 8:
			var y := 304.0 + float(row) * 108.0
			draw_circle(Vector2(x, y), 3.0, Color("fff2c0", 0.72))
	for y in [250.0, 1130.0]:
		draw_line(Vector2(80, y), Vector2(640, y), Color("39dfff", 0.12), 9.0, true)
		draw_line(Vector2(80, y), Vector2(640, y), Color("d4ffff", 0.45), 1.5, true)

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
			draw_circle(p, r + 14, Color("3fe08c", 0.20))
			draw_circle(p, r + 8, Color("144d2d", 0.45))
			for thorn in 8:
				var a := anim * 2.5 + float(thorn) * (TAU / 8.0)
				var tip := p + Vector2(cos(a), sin(a)) * (r + 10.0)
				var base_l := p + Vector2(cos(a - 0.2), sin(a - 0.2)) * (r * 0.7)
				var base_r := p + Vector2(cos(a + 0.2), sin(a + 0.2)) * (r * 0.7)
				draw_colored_polygon(PackedVector2Array([base_l, tip, base_r]), Color("3fe08c", 0.9))
			texture_at(SAW, p, Vector2(radius * 2.7, radius * 2.7), Color("b8ffe2"), anim * 2.5)
			var snap := 0.5 + 0.5 * sin(anim * 6.0)
			draw_circle(p, 10.0, Color("6b1834"))
			draw_circle(p, 5.0 * snap, Color("ff4971"))
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
			# Mechanical Factory: Industrial Steel Gear with Molten Core & Friction Sparks
			var r := radius * 1.35
			draw_circle(p, r + 14, Color("ff7a29", 0.22))
			for tooth in 8:
				var a := anim * 4.0 + float(tooth) * (TAU / 8.0)
				var tip := p + Vector2(cos(a), sin(a)) * (r + 9.0)
				draw_line(p, tip, Color("ffd84d", 0.9), 4.0, true)
			texture_at(SAW, p, Vector2(radius * 2.7, radius * 2.7), Color("ffaa77"), anim * 3.5)
			draw_circle(p, 9.0, Color("ff3b30"))
			for sp in 3:
				var sa := anim * 7.0 + float(sp) * 2.1
				var spark_pt := p + Vector2(cos(sa), sin(sa)) * (r + 4.0) + Vector2(-sin(sa), cos(sa)) * (float((sp * 7) % 11) + 4.0)
				draw_circle(spark_pt, 2.0, Color("ffe380"))

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

func draw_wind_field(center: Vector2, size: Vector2, force: Vector2) -> void:
	var area := Rect2(center - size * 0.5, size)
	draw_rect(area, Color("71eaff", 0.045))
	draw_rect(area, Color("b8f5ff", 0.28), false, 1.5, true)
	var direction := 1.0 if force.x >= 0.0 else -1.0
	for row in 3:
		var y := area.position.y + 19.0 + float(row) * 27.0
		var drift := fmod(anim * 32.0 + float(row) * 36.0, size.x - 36.0)
		var x := area.position.x + (18.0 + drift if direction > 0.0 else size.x - 18.0 - drift)
		var glow := Color("86efff", 0.48)
		draw_line(Vector2(x - direction * 13.0, y), Vector2(x + direction * 7.0, y), glow, 2.0, true)
		draw_line(Vector2(x + direction * 7.0, y), Vector2(x, y - 6.0), glow, 2.0, true)
		draw_line(Vector2(x + direction * 7.0, y), Vector2(x, y + 6.0), glow, 2.0, true)

func draw_storm_beam(start: Vector2, finish: Vector2, active: bool, warning: bool) -> void:
	for endpoint in [start, finish]:
		draw_circle(endpoint, 14.0, Color("74dfff", 0.25))
		draw_arc(endpoint, 11.0, 0, TAU, 20, Color("d6faff", 0.75), 2.0, true)
	if active:
		draw_line(start, finish, Color("5e9dff", 0.30), 22.0, true)
		var points := PackedVector2Array([start])
		for i in range(1, 8):
			var t := float(i) / 8.0
			points.append(start.lerp(finish, t) + Vector2(0, sin(anim * 31.0 + float(i) * 4.2) * 6.0))
		points.append(finish)
		draw_polyline(points, Color("8fefff"), 5.0, true)
		draw_polyline(points, Color.WHITE, 1.6, true)
	elif warning:
		var pulse := 0.35 + 0.35 * sin(anim * 17.0)
		draw_line(start, finish, Color("f9e992", pulse), 2.5, true)
	else:
		draw_line(start, finish, Color("98d9f4", 0.16), 1.5, true)

func draw_sky_prop(prop: Dictionary) -> void:
	var p: Vector2 = prop["position"]
	var phase: float = float(prop.get("phase", 0.0))
	if prop["kind"] == "kite":
		p += Vector2(sin(anim * 1.2 + phase) * 6.0, cos(anim * 1.5 + phase) * 4.0)
		draw_line(p + Vector2(0, 15), p + Vector2(7, 53), Color("fff2d2", 0.40), 1.4, true)
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -22), p + Vector2(17, 0), p + Vector2(0, 20), p + Vector2(-17, 0)]), Color("7bdfff", 0.48))
		draw_line(p + Vector2(0, -22), p + Vector2(0, 20), Color("ffffff", 0.7), 1.5, true)
		draw_line(p + Vector2(-17, 0), p + Vector2(17, 0), Color("f8d985", 0.75), 1.5, true)
	elif prop["kind"] == "wind_vane":
		draw_line(p + Vector2(0, 33), p + Vector2(0, -2), Color("7dd8ee", 0.55), 2.5, true)
		draw_circle(p + Vector2(0, -7), 7.0, Color("ffdf83", 0.8))
		for blade in 4:
			var angle := anim * 1.7 + float(blade) * TAU / 4.0
			var tip := p + Vector2(0, -7) + Vector2(cos(angle), sin(angle)) * 22.0
			draw_line(p + Vector2(0, -7), tip, Color("d5f9ff", 0.75), 3.0, true)
