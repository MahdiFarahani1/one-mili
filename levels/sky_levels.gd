extends RefCounted

# Hand-authored routes for the first chapter. Checkpoints keep the same order and
# geometry contract as every other chapter, so saves and scoring remain compatible.
const ROUTES = {
	2: {"gates": [[435.0, 860.0, 245.0], [245.0, 585.0, 225.0]], "materials": ["normal", "normal"]},
	3: {"gates": [[265.0, 885.0, 225.0], [480.0, 605.0, 205.0]], "materials": ["spring", "normal"]},
	4: {"axis": "x", "gates": [[255.0, 855.0, 310.0], [455.0, 470.0, 275.0]], "materials": ["normal", "ice"]},
	5: {"gates": [[445.0, 920.0, 215.0], [250.0, 690.0, 195.0], [455.0, 460.0, 185.0]], "materials": ["normal", "spring", "normal"]},
	6: {"gates": [[260.0, 930.0, 205.0], [470.0, 710.0, 190.0], [260.0, 490.0, 175.0]], "materials": ["ice", "normal", "spring"]},
	7: {"gates": [[470.0, 940.0, 195.0], [240.0, 725.0, 180.0], [475.0, 510.0, 165.0]], "materials": ["normal", "fragile", "normal"]},
	8: {"axis": "x", "gates": [[205.0, 865.0, 300.0], [365.0, 465.0, 275.0], [525.0, 860.0, 250.0]], "materials": ["normal", "spring", "ice"]},
	9: {"gates": [[260.0, 950.0, 195.0], [460.0, 770.0, 180.0], [250.0, 590.0, 170.0], [455.0, 410.0, 160.0]], "materials": ["normal", "ice", "spring", "normal"]},
	10: {"gates": [[465.0, 955.0, 185.0], [245.0, 775.0, 175.0], [465.0, 595.0, 165.0], [245.0, 415.0, 155.0]], "materials": ["spring", "normal", "fragile", "ice"]},
	11: {"gates": [[250.0, 955.0, 180.0], [470.0, 775.0, 170.0], [250.0, 595.0, 160.0], [470.0, 415.0, 150.0]], "materials": ["ice", "fragile", "spring", "normal"]},
	12: {"axis": "x", "gates": [[180.0, 865.0, 290.0], [310.0, 465.0, 270.0], [440.0, 855.0, 250.0], [570.0, 760.0, 230.0]], "materials": ["normal", "spring", "ice", "fragile"]}
}

static func build(number: int) -> Dictionary:
	var config: Dictionary = ROUTES[number]
	var sideways := str(config.get("axis", "y")) == "x"
	var obstacles: Array[Dictionary] = []
	var crystals: Array[Vector2] = []
	var gates: Array[Dictionary] = []
	var hazards: Array[Dictionary] = []
	var sky_props: Array[Dictionary] = []
	var entries: Array = config["gates"]
	var materials: Array = config["materials"]
	for i in entries.size():
		var entry: Array = entries[i]
		var center: float = entry[0]
		var position: float = entry[1]
		var width: float = entry[2]
		var kind: String = materials[i]
		if sideways:
			var gap_top := position - width * 0.5
			var gap_bottom := position + width * 0.5
			if number == 12 and i == 0:
				# A second opening prevents a fall back through the first gate from trapping a run.
				obstacles.append({"rect": Rect2(center, 250.0, 28.0, 100.0), "kind": kind})
				obstacles.append({"rect": Rect2(center, 580.0, 28.0, gap_top - 580.0), "kind": kind})
			else:
				obstacles.append({"rect": Rect2(center, 250.0, 28.0, gap_top - 250.0), "kind": kind})
			obstacles.append({"rect": Rect2(center, gap_bottom, 28.0, 1130.0 - gap_bottom), "kind": kind})
			crystals.append(Vector2(center + 65.0, position))
			gates.append({"axis": "x", "x": center, "center": position, "width": width})
			sky_props.append({"kind": "kite", "position": Vector2(center + 68.0, 360.0 if position > 690.0 else 1020.0), "phase": i * 1.1})
		else:
			var gap_left := center - width * 0.5
			var gap_right := center + width * 0.5
			obstacles.append({"rect": Rect2(80.0, position, gap_left - 80.0, 28.0), "kind": kind})
			obstacles.append({"rect": Rect2(gap_right, position, 640.0 - gap_right, 28.0), "kind": kind})
			crystals.append(Vector2(center, position - 76.0))
			gates.append({"center": center, "y": position, "width": width})
			sky_props.append({"kind": "kite", "position": Vector2(130.0 if center > 360.0 else 590.0, position - 135.0), "phase": i * 1.1})

	# A gentle wind field alters momentum; its arrows reveal direction before entry.
	if number in [3, 5, 6, 8, 9, 10, 11, 12]:
		var first: Dictionary = gates[0]
		var wind_position := Vector2(355.0, 765.0 if sideways else float(first["y"]) - 125.0)
		var wind_force := Vector2(85.0 if number % 2 == 0 else -85.0, -38.0)
		hazards.append({"kind": "wind", "center": wind_position, "size": Vector2(145.0, 95.0), "force": wind_force})
		sky_props.append({"kind": "wind_vane", "position": wind_position + Vector2(-105, -63), "phase": 0.0})

	if not sideways:
		# Edge hazards ask for precision without covering the mandatory crystal route.
		if number >= 5:
			var gate: Dictionary = gates[-1]
			var side := 1.0 if float(gate["center"]) > 360.0 else -1.0
			hazards.append({"kind": "saw", "center": Vector2(clampf(float(gate["center"]) + side * (float(gate["width"]) * 0.5 + 30.0), 110.0, 610.0), float(gate["y"]) - 46.0), "radius": 16.0, "phase": 0.0})
		if number >= 9:
			var gate: Dictionary = gates[1]
			var side := 1.0 if float(gate["center"]) > 360.0 else -1.0
			hazards.append({"kind": "mover", "center": Vector2(clampf(float(gate["center"]) + side * (float(gate["width"]) * 0.5 + 55.0), 110.0, 610.0), float(gate["y"]) - 48.0), "radius": 15.0, "phase": float(number) * 0.3, "amplitude": 24.0})
		if number in [7, 10, 11]:
			var gate: Dictionary = gates[0]
			var left := float(gate["center"]) < 360.0
			var x1 := 100.0 if left else 535.0
			var x2 := 190.0 if left else 620.0
			var beam_y := float(gate["y"]) - 127.0
			hazards.append({"kind": "storm", "center": Vector2((x1 + x2) * 0.5, beam_y), "start": Vector2(x1, beam_y), "end": Vector2(x2, beam_y), "phase": float(number % 3) * 0.55})
	else:
		if number >= 8:
			var gate: Dictionary = gates[1]
			var mover_offset := 135.0 if number == 12 else 65.0
			hazards.append({"kind": "mover", "center": Vector2(float(gate["x"]) + mover_offset, float(gate["center"]) + 175.0), "radius": 15.0, "phase": 0.8, "amplitude": 23.0})
		if number == 12:
			hazards.append({"kind": "storm", "center": Vector2(355, 330), "start": Vector2(290, 330), "end": Vector2(420, 330), "phase": 1.4})

	var bonus := Vector2(580.0 if number % 2 == 0 else 135.0, 1040.0 if not sideways else 340.0)
	var goal := Vector2(630.0, 315.0 if float(gates[-1]["center"]) > 690.0 else 1050.0) if sideways else Vector2(115.0 if float(gates[-1]["center"]) > 360.0 else 605.0, 305.0)
	var powerups: Array[Dictionary] = []
	if number >= 4:
		powerups.append({"kind": "shield" if number % 2 == 0 else "slowmo", "position": Vector2(575.0 if number % 2 == 0 else 145.0, 1010.0 if not sideways else 690.0)})
	return {
		"number": number, "world": 0, "local": number - 1,
		"axis": "x" if sideways else "y", "start": Vector2(130, 1040), "goal": goal,
		"crystals": crystals, "bonus": bonus, "obstacles": obstacles,
		"hazards": hazards, "gates": gates, "powerups": powerups, "sky_props": sky_props,
		"par_time": 14.0 + entries.size() * 4.0 + float(number) * 0.7,
		"par_turns": 5 + entries.size() * 5 + roundi(float(number) * 0.5)
	}
