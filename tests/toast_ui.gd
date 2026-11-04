extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	scene.record_attempts = false
	root.add_child(scene)
	await process_frame
	scene.show_screen("game")
	await process_frame
	scene.pop_toast("test message")
	var first_panel: Panel = scene.toast_panel
	var count_before: int = scene.ui.get_child_count()
	var clear_of_controls: bool = first_panel.position.y + first_panel.size.y < scene.hud_rotate_btn.position.y
	scene.pop_toast("second message")
	var reused: bool = scene.toast_panel == first_panel and scene.ui.get_child_count() == count_before and scene.toast_label.text == "second message"
	await create_timer(1.8).timeout
	var expired: bool = not scene.toast_panel.visible and not scene.toast_label.visible
	scene.show_screen("settings")
	await process_frame
	var cleared: bool = scene.toast_panel == null and scene.toast_label == null
	var passed: bool = clear_of_controls and reused and expired and cleared
	print("TOAST UI: ", "OK" if passed else "FAIL", " clear=", clear_of_controls, " reused=", reused, " expired=", expired, " reset=", cleared)
	scene.queue_free()
	await process_frame
	quit(0 if passed else 1)
