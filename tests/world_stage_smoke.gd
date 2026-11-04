extends SceneTree

const Data = preload("res://levels/level_data.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var stage_script: GDScript = load("res://scripts/stage.gd")
	for number in range(13, 61):
		var stage: Node2D = stage_script.new(Data.level(number))
		stage.record_failures = false
		root.add_child(stage)
		stage.queue_redraw()
		await process_frame
		await process_frame
		if stage.player == null or stage.walls.size() != 4 + stage.details["obstacles"].size():
			print("WORLD STAGE FAIL ", number)
			quit(1)
			return
		stage.queue_free()
		await process_frame
	print("WORLD STAGES: OK 48")
	quit(0)
