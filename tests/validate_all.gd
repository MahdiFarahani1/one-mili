extends SceneTree

const Data = preload("res://levels/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var failures: Array[String] = []
	var layouts := {}
	for n in range(1, 61):
		var level: Dictionary = Data.level(n)
		var gates: Array = level["gates"]
		var crystals: Array = level["crystals"]
		if int(level["number"]) != n or int(level["world"]) != (n - 1) / 12:
			failures.append("metadata %d" % n)
		if crystals.size() != gates.size():
			failures.append("checkpoint count %d" % n)
		if n > 1 and gates.is_empty():
			failures.append("missing traversal %d" % n)
		var signature: String = str(level["axis"]) + "|"
		for gate in gates:
			var center: float = gate["center"]
			var width: float = gate["width"]
			if level["axis"] == "x":
				var x: float = gate["x"]
				signature += "%d:%d:%d|" % [roundi(x), roundi(center), roundi(width)]
				if center - width * 0.5 < 280.0 or center + width * 0.5 > 1100.0 or width < 150.0:
					failures.append("gap clearance %d" % n)
				if not crystals.has(Vector2(x + 65.0, center)):
					failures.append("missing checkpoint %d" % n)
			else:
				var y: float = gate["y"]
				signature += "%d:%d:%d|" % [roundi(center), roundi(y), roundi(width)]
				if center - width * 0.5 < 90.0 or center + width * 0.5 > 630.0 or width < 120.0:
					failures.append("gap clearance %d" % n)
				if not crystals.has(Vector2(center, y - 76.0)):
					failures.append("missing checkpoint %d" % n)
		if layouts.has(signature):
			failures.append("duplicate route %d and %d" % [int(layouts[signature]), n])
		layouts[signature] = n
		for checkpoint in crystals + [level["goal"]]:
			for obstacle in level["obstacles"]:
				if obstacle["rect"].grow(25.0).has_point(checkpoint):
					failures.append("checkpoint blocked %d" % n)
		for hazard in level["hazards"]:
			if hazard["kind"] == "laser":
				for checkpoint in crystals:
					if absf(checkpoint.y - hazard["center"].y) < 55.0:
						failures.append("laser too close to checkpoint %d" % n)
		if float(level["par_time"]) <= 0 or int(level["par_turns"]) < 2:
			failures.append("par target %d" % n)
		if n >= 13:
			var props: Array = level.get("world_props", [])
			if props.size() != gates.size():
				failures.append("chapter props %d" % n)
			for prop in props:
				var position: Vector2 = prop["position"]
				if position.x < 80.0 or position.x > 640.0 or position.y < 250.0 or position.y > 1130.0:
					failures.append("chapter prop outside stage %d" % n)
			if level["obstacles"].size() != gates.size() * 2:
				failures.append("chapter platform count %d" % n)
	print("LEVEL DATA: ", "OK 60 unique routes" if failures.is_empty() else "FAIL %d" % failures.size())
	for failure in failures: print(failure)
	quit(0 if failures.is_empty() else 1)
