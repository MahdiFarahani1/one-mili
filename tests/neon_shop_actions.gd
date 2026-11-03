extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func find_item_button(scene: Control, item_id: String) -> Button:
	for card in scene.ui.find_children("*", "PanelContainer", true, false):
		if str(card.get_meta("shop_item", "")) == item_id:
			for control in card.find_children("*", "Button", true, false):
				return control as Button
	return null

func run() -> void:
	var saved_files := {}
	for path in ["user://one_millimeter_save.json", "user://one_millimeter_save.bak"]:
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			saved_files[path] = file.get_buffer(file.get_length())
	var save: Node = root.get_node("Save")
	var original_data: Dictionary = save.data.duplicate(true)
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	save.data = save.defaults()
	save.data["crystals"] = 100
	scene.current_shop_tab = "skins"
	scene.show_screen("shop")
	await process_frame
	var failed := false
	var buy := find_item_button(scene, "fire")
	if buy == null or buy.disabled:
		failed = true
	else:
		buy.pressed.emit()
		await process_frame
		if not save.own("skins", "fire") or int(save.data["crystals"]) != 45:
			failed = true
		var equip := find_item_button(scene, "fire")
		if equip == null or equip.disabled:
			failed = true
		else:
			equip.pressed.emit()
			await process_frame
			if str(save.data["skin"]) != "fire":
				failed = true
	for path in ["user://one_millimeter_save.json", "user://one_millimeter_save.bak"]:
		if saved_files.has(path):
			var restored := FileAccess.open(path, FileAccess.WRITE)
			restored.store_buffer(saved_files[path])
			restored.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save.data = original_data
	await create_timer(1.5).timeout
	scene.queue_free()
	await process_frame
	var sound: Variant = root.get_node("Sound")
	sound.player.stop()
	sound.music_player.stop()
	sound.player.stream = null
	sound.music_player.stream = null
	sound.cache.clear()
	await process_frame
	print("NEON SHOP ACTIONS: ", "FAIL" if failed else "OK")
	quit(1 if failed else 0)
