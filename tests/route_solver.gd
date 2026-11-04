extends SceneTree

const Data = preload("res://levels/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage_script = load("res://scripts/stage.gd")
	var failures: Array[int] = []
	var first := clampi(int(OS.get_environment("ROUTE_TEST_FIRST")) if OS.has_environment("ROUTE_TEST_FIRST") else 1, 1, 60)
	var last := clampi(int(OS.get_environment("ROUTE_TEST_LAST")) if OS.has_environment("ROUTE_TEST_LAST") else 60, first, 60)
	var numbers: Array[int] = []
	if OS.has_environment("ROUTE_TEST_LEVELS"):
		for value in OS.get_environment("ROUTE_TEST_LEVELS").split(","):
			numbers.append(clampi(int(value), 1, 60))
	else:
		for number in range(first, last + 1):
			numbers.append(number)
	for number in numbers:
		var solved := false
		for offset in [0.0, 0.6, 1.4, 2.2, 2.6]:
			var stage: Node2D = stage_script.new(Data.level(number))
			stage.record_failures = false
			root.add_child(stage)
			stage.anim = offset
			var result := {"won": false, "lost": false}
			stage.won.connect(func(_seconds: float, _turns: int, _crystals: int): result["won"] = true)
			stage.lost.connect(func(): result["lost"] = true)
			var frame := 0
			for step in 120 * 90:
				var target: Vector2 = stage.details["goal"]
				if stage.collected < stage.crystals.size():
					var gate: Dictionary = stage.details["gates"][stage.collected]
					target = Vector2(float(gate["x"]) + 65.0, float(gate["center"])) if stage.details["axis"] == "x" else Vector2(float(gate["center"]), float(gate["y"]) - 76.0)
				var player: CharacterBody2D = stage.player
				if stage.details["axis"] == "x":
					var dy: float = target.y - player.position.y
					if absf(dy) > 18.0 or absf(player.velocity.y) > 85.0:
						player.gravity_direction = Vector2.DOWN if dy - player.velocity.y * 0.17 > 0 else Vector2.UP
					else:
						player.gravity_direction = Vector2.RIGHT
				else:
					var dx: float = target.x - player.position.x
					if absf(dx) > 18.0 or absf(player.velocity.x) > 85.0:
						player.gravity_direction = Vector2.RIGHT if dx - player.velocity.x * 0.17 > 0 else Vector2.LEFT
					else:
						player.gravity_direction = Vector2.UP
				await physics_frame
				frame = step
				if result["won"] or result["lost"]: break
			print("SOLVER ", number, " won=", result["won"], " crystals=", stage.collected, " frame=", frame, " offset=", offset, " p=", stage.player.position, " hazard=", stage.last_failure)
			solved = result["won"]
			stage.queue_free()
			await process_frame
			if solved: break
		if not solved: failures.append(number)
	print("SOLVER ALL: ", "OK %d levels" % numbers.size() if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
