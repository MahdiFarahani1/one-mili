extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var save: Node = root.get_node("Save")
	var saved_files := {}
	for path in ["user://one_millimeter_save.json", "user://one_millimeter_save.bak"]:
		if FileAccess.file_exists(path):
			var source := FileAccess.open(path, FileAccess.READ)
			saved_files[path] = source.get_buffer(source.get_length())
	var failed := false
	save.data = save.defaults()
	save.data["crystals"] = 100
	if not save.purchase("skins", "fire", 50) or not save.own("skins", "fire") or int(save.data["crystals"]) != 50:
		print("SYSTEM FAIL: purchase")
		failed = true
	save.save_game()
	save.load_game()
	if not save.own("skins", "fire"):
		print("SYSTEM FAIL: persistence")
		failed = true
	save.ensure_daily()
	if save.daily_claim() != 0:
		print("SYSTEM FAIL: daily early claim")
		failed = true
	save.data["daily"]["progress"] = save.data["daily"]["target"]
	if save.daily_claim() <= 0 or save.daily_claim() != 0:
		print("SYSTEM FAIL: daily claim")
		failed = true
	save.data["crystals"] = 123
	save.save_game()
	save.data["crystals"] = 456
	save.save_game()
	var broken := FileAccess.open("user://one_millimeter_save.json", FileAccess.WRITE)
	broken.store_string("broken")
	broken.close()
	save.load_game()
	if int(save.data["crystals"]) != 123:
		print("SYSTEM FAIL: backup recovery ", save.data["crystals"])
		failed = true
	for path in ["user://one_millimeter_save.json", "user://one_millimeter_save.bak"]:
		if saved_files.has(path):
			var restored := FileAccess.open(path, FileAccess.WRITE)
			restored.store_buffer(saved_files[path])
			restored.close()
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("SYSTEMS: ", "FAIL" if failed else "OK")
	quit(1 if failed else 0)
