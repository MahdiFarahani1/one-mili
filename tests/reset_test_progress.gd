extends SceneTree

# Run only after automated tests, to return the new project to a fresh save.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var save: Node = root.get_node("Save")
	save.data = save.defaults()
	var clean := JSON.stringify(save.data)
	for path in ["user://one_millimeter_save.json", "user://one_millimeter_save.bak"]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(clean)
		file.close()
	print("SAVE RESET: clean")
	quit()
