extends SceneTree

const Data = preload("res://levels/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var StageScript: GDScript = load("res://scripts/stage.gd")
	var stage = StageScript.new(Data.level(1))
	stage.record_failures = false
	root.add_child(stage)
	stage.process_mode = Node.PROCESS_MODE_DISABLED
	for index in 2:
		var point: Vector2 = stage.crystals[index]["position"]
		stage.player.position = point
		stage.previous_player_position = point
		stage._physics_process(1.0 / 60.0)
	if stage.collected != 2 or stage.combo != 2 or stage.style_bonus != 1:
		printerr("STYLE BONUS FAIL: chained collection")
		quit(1)
		return
	stage._physics_process(4.6)
	if stage.combo != 0 or stage.chain_timer > 0.0:
		printerr("STYLE BONUS FAIL: chain expiry")
		quit(1)
		return
	stage.restart()
	if stage.style_bonus != 0 or stage.near_style_count != 0 or stage.collected != 0:
		printerr("STYLE BONUS FAIL: restart reset")
		quit(1)
		return
	stage.queue_free()
	print("STYLE BONUS: OK")
	quit(0)
