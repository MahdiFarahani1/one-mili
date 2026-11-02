extends RefCounted
class_name ChapterChallenge

# Five chapters share gravity rotation but demand different mastery.
const NAMES_FA := ["آسمان معلق", "جنگل تله‌ها", "غار کریستال", "مدار بی‌وزنی", "کارخانه مرگبار"]
const SKILLS := ["precision", "rhythm", "route_reading", "gravity_control", "mastery"]

static func profile(world: int) -> Dictionary:
	var w := clampi(world, 0, 4)
	return {
		"name": NAMES_FA[w],
		"skill": SKILLS[w],
		"gate_penalty": [0.0, 8.0, 14.0, 20.0, 26.0][w],
		"par_time_multiplier": [1.0, 0.94, 0.88, 0.82, 0.77][w],
		"par_turn_multiplier": [1.0, 0.95, 0.90, 0.85, 0.80][w],
	}

static func challenge_hazards(world: int, number: int, gates: Array, axis: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if gates.is_empty() or number < 13:
		return result
	# Keep hazards away from the actual gate opening to preserve fair traversal.
	for i in gates.size():
		var gate: Dictionary = gates[i]
		if axis == "y":
			var y: float = float(gate["y"])
			var center: float = float(gate["center"])
			var side := -1.0 if (number + i) % 2 == 0 else 1.0
			var x := clampf(center + side * (float(gate["width"]) * 0.5 + 48.0), 96.0, 624.0)
			match world:
				1:
					if i % 2 == 0:
						result.append({"kind":"mover", "center":Vector2(x,y-65.0), "radius":15.0, "phase":float(i)*0.8, "amplitude":18.0})
				2:
					if i % 2 == 1:
						result.append({"kind":"saw", "center":Vector2(x,y-62.0), "radius":18.0, "phase":0.0})
				3:
					if i == 0:
						result.append({"kind":"zero", "center":Vector2(x,y-115.0), "radius":72.0, "phase":0.0})
				4:
					result.append({"kind":"mover", "center":Vector2(x,y-65.0), "radius":18.0, "phase":float(i)*1.2, "amplitude":22.0})
	return result
