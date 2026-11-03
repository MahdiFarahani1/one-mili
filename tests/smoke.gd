extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	for page in ["menu", "worlds", "levels", "game", "pause", "victory", "over", "shop", "custom", "achievements", "settings"]:
		scene.show_screen(page)
		await process_frame
		print("SMOKE:", page)
	scene.show_screen("game")
	await process_frame
	if scene.stage != null:
		scene.stage.rotate_gravity()
		scene.stage.restart()
		print("SMOKE: physics stage and restart")
	quit(0)
