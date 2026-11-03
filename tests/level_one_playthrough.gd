extends SceneTree

const Data = preload("res://levels/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage_script: GDScript = load("res://scripts/stage.gd")
	var solved := false
	for offset in [0.0, 0.8, 1.6, 2.4]:
		var stage = stage_script.new(Data.level(1))
		root.add_child(stage)
		stage.anim = offset
		var outcome := {"won": false, "lost": false}
		stage.won.connect(func(_time: float, _turns: int, _count: int): outcome["won"] = true)
		stage.lost.connect(func(): outcome["lost"] = true)
		for step in 120 * 65:
			var target: Vector2 = stage.details["goal"]
			if stage.collected < stage.crystals.size():
				target = stage.crystals[stage.collected]["position"]
			var player: Variant = stage.player
			var dx: float = target.x - player.position.x
			if absf(dx) > 17.0 or absf(player.velocity.x) > 80.0:
				player.gravity_direction = Vector2.RIGHT if dx - player.velocity.x * 0.17 > 0.0 else Vector2.LEFT
			else:
				player.gravity_direction = Vector2.UP
			await physics_frame
			if outcome["won"] or outcome["lost"]:
				break
		print("LEVEL 1 PHYSICS: won=", outcome["won"], " collected=", stage.collected, " reason=", stage.last_failure, " position=", stage.player.position)
		solved = outcome["won"]
		stage.queue_free()
		await process_frame
		if solved:
			break
	quit(0 if solved else 1)
