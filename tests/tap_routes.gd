extends SceneTree

const Data = preload("res://levels/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage_script = load("res://scripts/stage.gd")
	var failures: Array[int] = []
	var levels_to_test := [2, 6, 12, 13, 24, 25, 37, 44, 60]
	if OS.has_environment("TAP_TEST_LEVEL"):
		levels_to_test = [int(OS.get_environment("TAP_TEST_LEVEL"))]
	for number in levels_to_test:
		var stage: Node2D = stage_script.new(Data.level(number))
		stage.record_failures = false
		root.add_child(stage)
		var state := {"won": false, "lost": false}
		stage.won.connect(func(_seconds: float, _turns: int, _count: int): state["won"] = true)
		stage.lost.connect(func(): state["lost"] = true)
		var last_tap := -100
		var frame := 0
		for step in 120 * 90:
			var target: Vector2 = stage.details["goal"]
			if stage.collected < stage.crystals.size():
				var gate: Dictionary = stage.details["gates"][stage.collected]
				target = Vector2(float(gate["x"]) + 65.0, float(gate["center"])) if stage.details["axis"] == "x" else Vector2(float(gate["center"]), float(gate["y"]) - 76.0)
			var player: CharacterBody2D = stage.player
			var desired := Vector2.RIGHT if stage.details["axis"] == "x" else Vector2.UP
			if stage.details["axis"] == "x":
				var dy: float = target.y - player.position.y
				if absf(dy) > 18.0 or absf(player.velocity.y) > 85.0:
					desired = Vector2.DOWN if dy - player.velocity.y * 0.17 > 0 else Vector2.UP
			else:
				var dx: float = target.x - player.position.x
				if absf(dx) > 18.0 or absf(player.velocity.x) > 85.0:
					desired = Vector2.RIGHT if dx - player.velocity.x * 0.17 > 0 else Vector2.LEFT
			if player.gravity_direction != desired and step - last_tap >= 2:
				stage.rotate_gravity()
				last_tap = step
			await physics_frame
			frame = step
			if state["won"] or state["lost"]: break
		print("TAP ROUTE ", number, " won=", state["won"], " collected=", stage.collected, " turns=", stage.turns, " seconds=", snapped(float(frame) / 120.0, 0.1), " p=", stage.player.position, " failure=", stage.last_failure)
		if not state["won"]: failures.append(number)
		stage.queue_free()
		await process_frame
	print("TAP ROUTES: ", "OK" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
