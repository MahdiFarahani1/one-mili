extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.record_attempts = false
	root.add_child(scene)
	await process_frame
	for page in ["splash", "menu", "worlds", "levels", "shop"]:
		scene.show_screen(page)
		await process_frame
		await process_frame
		await create_timer(0.2).timeout
		var image := root.get_viewport().get_texture().get_image()
		var path := "res://tests/neon_%s.png" % page
		var error := image.save_png(path)
		print("NEON_CAPTURE ", page, " ", error, " ", image.get_size())
		if error != OK:
			quit(1)
			return
	for tab in ["trails", "themes"]:
		scene.show_shop_tab(tab)
		await process_frame
		await process_frame
		var image := root.get_viewport().get_texture().get_image()
		var error := image.save_png("res://tests/neon_shop_%s.png" % tab)
		print("NEON_CAPTURE shop_", tab, " ", error, " ", image.get_size())
		if error != OK:
			quit(1)
			return
	scene.selected_world = 2
	scene.show_screen("levels")
	await process_frame
	await process_frame
	var crystal_image := root.get_viewport().get_texture().get_image()
	var crystal_error := crystal_image.save_png("res://tests/neon_levels_crystal.png")
	print("NEON_CAPTURE levels_crystal ", crystal_error, " ", crystal_image.get_size())
	if crystal_error != OK:
		quit(1)
		return
	for page in ["custom", "game"]:
		scene.show_screen(page)
		if page == "game":
			scene.stage.record_failures = false
		await process_frame
		await process_frame
		await create_timer(0.2).timeout
		var image := root.get_viewport().get_texture().get_image()
		var error := image.save_png("res://tests/neon_%s.png" % page)
		print("NEON_CAPTURE ", page, " ", error, " ", image.get_size())
		if error != OK:
			quit(1)
			return
	scene.queue_free()
	await process_frame
	quit(0)
