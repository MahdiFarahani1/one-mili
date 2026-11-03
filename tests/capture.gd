extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.show_screen("menu")
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://tests/menu_capture.png")
	scene.show_screen("custom")
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://tests/custom_capture.png")
	scene.show_screen("worlds")
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://tests/worlds_capture.png")
	scene.show_screen("levels")
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://tests/levels_capture.png")
	scene.show_screen("shop")
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://tests/shop_capture.png")
	scene.show_screen("settings")
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://tests/settings_capture.png")
	scene.show_screen("game")
	await process_frame
	await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png("res://tests/game_capture.png")
	print("CAPTURE:", err, " ", image.get_size())
	scene.selected_level = 60
	scene.show_screen("game")
	await process_frame
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://tests/late_capture.png")
	scene.show_screen("victory")
	await process_frame
	root.get_viewport().get_texture().get_image().save_png("res://tests/victory_capture.png")
	quit()
