extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func find_button(container: Control, text_value: String) -> Button:
	for child in container.get_children():
		if child is Button and (child as Button).text.contains(text_value):
			return child as Button
	return null

func count_meta(container: Node, key: String) -> int:
	var result := 0
	for child in container.find_children("*", "Control", true, false):
		if child.has_meta(key):
			result += 1
	return result

func check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	var failures: Array[String] = []
	var scene: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.show_screen("menu")
	await process_frame
	for title in ["بازی", "مراحل", "فروشگاه", "تنظیمات", "جهان‌ها"]:
		check(find_button(scene.ui, title) != null, "menu button " + title, failures)
	var world_entry := find_button(scene.ui, "جهان‌ها")
	if world_entry != null:
		world_entry.pressed.emit()
		await process_frame
		check(scene.screen == "worlds", "menu to worlds", failures)
		check(count_meta(scene.ui, "world_index") == 5, "five worlds", failures)
		for child in scene.ui.get_children():
			if child is Button and child.has_meta("world_index"):
				var world_id := int(child.get_meta("world_index"))
				check(child.disabled == (root.get_node("Save").unlocked_level() < world_id * 12 + 1), "world lock " + str(world_id), failures)
		var first_world: Button = null
		for child in scene.ui.get_children():
			if child is Button and child.has_meta("world_index") and int(child.get_meta("world_index")) == 0:
				first_world = child
				break
		if first_world != null:
			var art: TextureRect = first_world.get_child(0)
			check(art.size == Vector2(340, 169), "world artwork layout", failures)
			first_world.pressed.emit()
			await process_frame
			check(scene.screen == "levels", "world to levels", failures)
			check(count_meta(scene.ui, "level_number") == 12, "twelve level tiles", failures)
			for child in scene.ui.get_children():
				if child is Button and child.has_meta("level_number"):
					check(child.disabled == (int(child.get_meta("level_number")) > root.get_node("Save").unlocked_level()), "level lock " + str(child.get_meta("level_number")), failures)
				if child is Button and child.has_meta("continue_level"):
					check(int(child.get_meta("continue_level")) >= 1 and int(child.get_meta("continue_level")) <= 12, "continue stays in selected world", failures)
		else:
			failures.append("first world card")
	scene.show_screen("shop")
	await process_frame
	for tab_id in ["skins", "trails", "themes"]:
		var tab: Button = null
		for child in scene.ui.get_children():
			if child is Button and child.has_meta("shop_tab") and str(child.get_meta("shop_tab")) == tab_id:
				tab = child
				break
		check(tab != null, "shop tab " + tab_id, failures)
		if tab != null:
			tab.pressed.emit()
			await process_frame
			check(scene.current_shop_tab == tab_id, "shop tab action " + tab_id, failures)
			var expected := 15 if tab_id == "skins" else (10 if tab_id == "trails" else 5)
			check(count_meta(scene.ui, "shop_item") == expected, "shop cards " + tab_id, failures)
	scene.show_screen("settings")
	await process_frame
	check(count_meta(scene.ui, "setting_key") == 3, "three settings switches", failures)
	for key in ["music", "sfx", "vibration"]:
		var found := false
		for child in scene.ui.get_children():
			if child is Button and str(child.get_meta("setting_key", "")) == key:
				found = true
				check((child.text.contains("روشن")) == bool(root.get_node("Save").data.get(key, true)), "setting state " + key, failures)
		check(found, "setting switch " + key, failures)
	print("NEON UI FLOW: ", "OK" if failures.is_empty() else str(failures))
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
	quit(0 if failures.is_empty() else 1)
