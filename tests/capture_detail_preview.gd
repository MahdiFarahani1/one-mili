extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.record_attempts = false
	root.add_child(scene)
	await process_frame
	scene.selected_level = 1
	scene.show_screen("game")
	scene.stage.record_failures = false
	scene.stage.player.gravity_direction = Vector2.UP
	scene.stage.player.velocity = Vector2.UP * 320.0
	await create_timer(0.34).timeout
	await RenderingServer.frame_post_draw
	var picture := root.get_viewport().get_texture().get_image()
	var error := picture.save_png("res://tests/detail_motion_preview.png")
	scene.queue_free()
	await process_frame
	quit(0 if error == OK else 1)
