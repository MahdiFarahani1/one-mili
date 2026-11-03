extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	for level in [1, 13, 25, 37, 60]:
		scene.selected_level = level
		scene.show_screen("game")
		await process_frame
		await process_frame
		var image := root.get_viewport().get_texture().get_image()
		image.save_png("res://tests/world_%d.png" % level)
		print("WORLD CAPTURE:", level, " ", image.get_size())
	quit()
