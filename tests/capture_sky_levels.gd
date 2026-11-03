extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.record_attempts = false
	root.add_child(scene)
	await process_frame
	for number in [2, 5, 8, 11, 12]:
		scene.selected_level = number
		scene.endless_run = false
		scene.show_screen("game")
		scene.stage.record_failures = false
		await process_frame
		await process_frame
		await create_timer(0.12).timeout
		var image := root.get_viewport().get_texture().get_image()
		var error := image.save_png("res://tests/sky_level_%02d.png" % number)
		print("SKY CAPTURE ", number, " ", error, " ", image.get_size())
		if error != OK:
			quit(1)
			return
	scene.show_screen("settings")
	await process_frame
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png("res://tests/neon_settings.png")
	print("SETTINGS CAPTURE ", error, " ", image.get_size())
	scene.queue_free()
	await process_frame
	quit(0 if error == OK else 1)
