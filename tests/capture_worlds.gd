extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.record_attempts = false
	root.add_child(scene)
	await process_frame
	for level in [1, 5, 13, 24, 25, 36, 37, 48, 49, 60]:
		scene.selected_level = level
		scene.show_screen("game")
		scene.stage.record_failures = false
		await process_frame
		await process_frame
		await create_timer(0.12).timeout
		var image := root.get_viewport().get_texture().get_image()
		var error := image.save_png("res://tests/world_%d.png" % level)
		print("WORLD CAPTURE:", level, " ", image.get_size())
		if error != OK:
			quit(1)
			return
	scene.queue_free()
	await process_frame
	quit(0)
