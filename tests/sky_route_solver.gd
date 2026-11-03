extends SceneTree

const Data = preload("res://levels/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage_script: GDScript = load("res://scripts/stage.gd")
	var failures: Array[int] = []
	var first := clampi(int(OS.get_environment("SKY_TEST_LEVEL")) if OS.has_environment("SKY_TEST_LEVEL") else 1, 1, 12)
	for number in range(first, 13):
		var solved := false
		for offset in [0.0, 0.8, 1.6, 2.4]:
			var stage: Node2D = stage_script.new(Data.level(number))
			stage.record_failures = false
			root.add_child(stage)
			stage.anim = offset
			var outcome := {"won": false, "lost": false}
			stage.won.connect(func(_time: float, _turns: int, _count: int): outcome["won"] = true)
			stage.lost.connect(func(): outcome["lost"] = true)
			for step in 120 * 40:
				var target: Vector2 = stage.details["goal"]
				if stage.collected < stage.crystals.size():
					target = stage.crystals[stage.collected]["position"]
				var player: CharacterBody2D = stage.player
				if stage.details["axis"] == "x":
					var dy: float = target.y - player.position.y
					if absf(dy) > 18.0 or absf(player.velocity.y) > 85.0:
						player.gravity_direction = Vector2.DOWN if dy - player.velocity.y * 0.17 > 0.0 else Vector2.UP
					else:
						player.gravity_direction = Vector2.RIGHT
				else:
					var dx: float = target.x - player.position.x
					if absf(dx) > 18.0 or absf(player.velocity.x) > 85.0:
						player.gravity_direction = Vector2.RIGHT if dx - player.velocity.x * 0.17 > 0.0 else Vector2.LEFT
					else:
						player.gravity_direction = Vector2.UP
				await physics_frame
				if outcome["won"] or outcome["lost"]:
					break
			print("SKY ROUTE ", number, " win=", outcome["won"], " crystal=", stage.collected, " reason=", stage.last_failure, " time=", stage.seconds, " pos=", stage.player.position, " offset=", offset)
			solved = outcome["won"]
			stage.queue_free()
			await process_frame
			if solved:
				break
		if not solved:
			failures.append(number)
	print("SKY ROUTES: ", "OK " + str(13 - first) if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
