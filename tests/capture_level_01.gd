extends SceneTree

func _initialize() -> void:
	call_deferred("capture_level")

func capture_level() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.selected_level = 1
	scene.show_screen("game")
	await process_frame
	await process_frame
	await process_frame
	await create_timer(1.0).timeout
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png("res://tests/level_01_preview.png")
	print("LEVEL_ONE_CAPTURE: ", error, " ", image.get_size())
	quit(0 if error == OK else 1)
