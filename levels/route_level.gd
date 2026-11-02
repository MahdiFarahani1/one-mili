extends RefCounted

const Chapter = preload("res://levels/chapter_challenge.gd")

# Every chamber tests precision, gravity control, and routing.
# 60 levels divided into 5 distinct chapters of 12 levels each:
# Chapter 1 (1-12): Sky Islands
# Chapter 2 (13-24): Magic Forest
# Chapter 3 (25-36): Crystal Depths
# Chapter 4 (37-48): Cosmic Space
# Chapter 5 (49-60): Mechanical Factory

static func build(number: int) -> Dictionary:
	var n := clampi(number, 1, 60)
	var world := (n - 1) / 12
	var local := (n - 1) % 12
	
	# Sideways / Horizontal chambers for specific levels
	if n >= 12 and local in [3, 7, 11]:
		return build_sideways(n, world, local)
		
	var gate_count := 0 if n == 1 else (1 if n <= 5 else (2 if n <= 20 else (3 if n <= 40 else 4)))
	# Climax / Boss levels have extra challenge
	if local == 11 and n >= 24:
		gate_count = mini(4, gate_count + 1)
		
	var rows: Array = []
	match gate_count:
		1: rows = [690.0]
		2: rows = [825.0, 515.0]
		3: rows = [905.0, 680.0, 455.0]
		4: rows = [955.0, 775.0, 595.0, 415.0]
		
	var tier := mini(5, (n - 1) / 10)
	var obstacles: Array[Dictionary] = []
	var crystals: Array[Vector2] = []
	var hazards: Array[Dictionary] = []
	var gates: Array[Dictionary] = []
	
	if n == 1:
		for stone in [
			Rect2(230, 420, 150, 28),
			Rect2(430, 560, 140, 28),
			Rect2(270, 735, 165, 28),
			Rect2(440, 880, 125, 28)
		]:
			obstacles.append({"rect": stone, "kind": "normal"})
			
	for i in rows.size():
		var y: float = rows[i]
		var leftward := (n + i + world) % 2 == 0
		var drift := float(((n * 29 + i * 43) % 61) - 30)
		var center := clampf((230.0 if leftward else 490.0) + drift, 205.0, 515.0)
		if n <= 3:
			center = 200.0 + 45.0 * (n - 1) + 35.0 * i
			
		var width := maxf(125.0, 236.0 - tier * 18.0 - float((n + i * 7) % 3) * 6.0 - float(Chapter.profile(world)["gate_penalty"]))
		if n <= 3:
			width = 260.0
			
		var left_end := center - width * 0.5
		var right_start := center + width * 0.5
		
		# Material diversity based on chapter
		var material := "normal"
		if n >= 25 and i == gate_count - 1:
			match world:
				1: material = "fragile" if n % 2 == 0 else "sticky" # Forest vine/moss
				2: material = "ice" if n % 2 == 0 else "fragile"     # Crystal brittle/slick
				3: material = "spring" if n % 2 == 0 else "ice"     # Cosmic bounce
				4: material = "fragile" if n % 2 == 0 else "spring" # Factory mechanical
				_: material = "normal"
				
		obstacles.append({"rect": Rect2(60.0, y, left_end - 60.0, 28.0), "kind": material})
		obstacles.append({"rect": Rect2(right_start, y, 660.0 - right_start, 28.0), "kind": material})
		crystals.append(Vector2(center, y - 76.0))
		gates.append({"center": center, "y": y, "width": width})
		
		# Saws placed flanking gates
		if n >= 12 and (i + n) % 2 == 0:
			var side := -1.0 if (i + world) % 2 == 0 else 1.0
			if i == gate_count - 1:
				side = 1.0 if center > 360.0 else -1.0
			var saw_x := center + side * (width * 0.5 + 26.0)
			saw_x = clampf(saw_x, 105.0, 615.0)
			hazards.append({
				"kind": "saw",
				"center": Vector2(saw_x, y - 35.0),
				"radius": 18.0,
				"phase": float(i) * 0.7
			})
			
		# Lasers: timed hazards with clear opening corridors
		if n >= 27 and i == 1 and n % 3 == 0:
			var laser_y := y - 150.0
			if n == 39:
				# Level 39 fix: flank laser leaving central traversal corridor clear
				hazards.append({
					"kind": "laser",
					"center": Vector2(195.0, laser_y),
					"radius": 0.0,
					"phase": 1.4,
					"start": Vector2(95.0, laser_y),
					"end": Vector2(295.0, laser_y)
				})
			else:
				var start_x := 95.0 if center > 360.0 else center + 55.0
				var end_x := center - 55.0 if center > 360.0 else 625.0
				hazards.append({
					"kind": "laser",
					"center": Vector2((start_x + end_x) * 0.5, laser_y),
					"radius": 0.0,
					"phase": float(n % 5) * 0.5,
					"start": Vector2(start_x, laser_y),
					"end": Vector2(end_x, laser_y)
				})
				
	# Moving hazards on later levels
	if n >= 21 and n % 4 == 0 and gates.size() > 1:
		var moving_gate: Dictionary = gates[1]
		var side := -1.0 if n % 8 == 0 else 1.0
		var edge_x := float(moving_gate["center"]) + side * (float(moving_gate["width"]) * 0.5 + 65.0)
		edge_x = clampf(edge_x, 115.0, 605.0)
		hazards.append({
			"kind": "mover",
			"center": Vector2(edge_x, float(moving_gate["y"]) - 38.0),
			"radius": 18.0,
			"phase": local * 0.43,
			"amplitude": 24.0
		})
		
	# Goal location at the top
	var goal := Vector2(115.0, 300.0)
	if gate_count > 0:
		goal.x = 605.0 if float(gates[-1]["center"]) < 360.0 else 115.0
		
	# Bonus optional crystal in risky nook
	var bonus := Vector2.ZERO
	if gate_count > 0 and n >= 8:
		var first: Dictionary = gates[0]
		bonus = Vector2(550.0 if float(first["center"]) < 360.0 else 170.0, float(first["y"]) + 95.0)
		
	# Chapter-specific hazards
	hazards.append_array(Chapter.challenge_hazards(world, n, gates, "y"))
	
	# Chapter 5 boss (Level 60) special moving platform
	if n == 60:
		hazards.append({"kind": "platform", "center": Vector2(360, 920)})
		
	var par_time := (10.0 + gate_count * 10.0 + tier * 3.0) * float(Chapter.profile(world)["par_time_multiplier"])
	var par_turns := 2 if n == 1 else maxi(2, roundi((8 + gate_count * 12) * float(Chapter.profile(world)["par_turn_multiplier"])))
	
	return {
		"number": n,
		"world": world,
		"local": local,
		"axis": "y",
		"goal": goal,
		"start": Vector2(115, 1030),
		"crystals": crystals,
		"bonus": bonus,
		"obstacles": obstacles,
		"hazards": hazards,
		"gates": gates,
		"par_time": par_time,
		"par_turns": par_turns
	}

static func build_sideways(n: int, world: int, local: int) -> Dictionary:
	var tier := mini(5, (n - 1) / 10)
	var count := 2 if n <= 20 else (3 if n <= 40 else 4)
	var columns: Array = [255.0, 455.0] if count == 2 else ([215.0, 360.0, 505.0] if count == 3 else [180.0, 310.0, 440.0, 570.0])
	var obstacles: Array[Dictionary] = []
	var crystals: Array[Vector2] = []
	var hazards: Array[Dictionary] = []
	var gates: Array[Dictionary] = []
	
	for i in columns.size():
		var x: float = columns[i]
		var high := (n + i + world) % 2 == 0
		var drift := float(((n * 17 + i * 37) % 69) - 34)
		var center := (475.0 if high else 905.0) + drift
		var width := maxf(175.0, 275.0 - tier * 16.0 - float((n + i) % 3) * 5.0)
		var top_end := center - width * 0.5
		var bottom_start := center + width * 0.5
		
		var material := "normal"
		if n >= 25 and i == 0:
			material = ["ice", "sticky", "spring", "fragile"][(n + world) % 4]
			
		obstacles.append({"rect": Rect2(x, 250.0, 28.0, top_end - 250.0), "kind": material})
		obstacles.append({"rect": Rect2(x, bottom_start, 28.0, 1130.0 - bottom_start), "kind": material})
		crystals.append(Vector2(x + 65.0, center))
		gates.append({"axis": "x", "x": x, "center": center, "width": width})
		
		if n >= 21 and (n + i) % 2 == 0:
			var side := -1.0 if (i + world) % 2 == 0 else 1.0
			if i == columns.size() - 1:
				side = 1.0 if center > 690.0 else -1.0
			var saw_y := center + side * (width * 0.5 + 23.0)
			saw_y = clampf(saw_y, 310.0, 1070.0)
			hazards.append({
				"kind": "saw",
				"center": Vector2(x + 37.0, saw_y),
				"radius": 18.0,
				"phase": i * 0.7
			})
			
	var goal := Vector2(630.0, 315.0 if float(gates[-1]["center"]) > 690.0 else 1050.0)
	var bonus := Vector2(150.0, 490.0 if float(gates[0]["center"]) > 690.0 else 900.0)
	
	hazards.append_array(Chapter.challenge_hazards(world, n, gates, "x"))
	
	var par_time := (12.0 + count * 11.0 + tier * 3.0) * float(Chapter.profile(world)["par_time_multiplier"])
	var par_turns := maxi(2, roundi((10 + count * 12) * float(Chapter.profile(world)["par_turn_multiplier"])))
	
	return {
		"number": n,
		"world": world,
		"local": local,
		"axis": "x",
		"goal": goal,
		"start": Vector2(115, 1030),
		"crystals": crystals,
		"bonus": bonus,
		"obstacles": obstacles,
		"hazards": hazards,
		"gates": gates,
		"par_time": par_time,
		"par_turns": par_turns
	}
