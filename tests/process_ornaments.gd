extends SceneTree

const NAMES := ["sky_shrine", "forest_tree", "crystal_obelisk", "cosmic_observatory", "factory_drone"]

func _initialize() -> void:
	for name in NAMES:
		var image := Image.new()
		var source := "res://assets/ornaments/raw/%s.png" % name
		if image.load(source) != OK:
			push_error("Cannot load " + source)
			quit(1)
			return
		var used := image.get_used_rect().grow(12)
		used = used.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		image = image.get_region(used)
		var scale := 512.0 / float(maxi(image.get_width(), image.get_height()))
		image.resize(maxi(1, roundi(image.get_width() * scale)), maxi(1, roundi(image.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
		var target := "res://assets/ornaments/%s.png" % name
		if image.save_png(target) != OK:
			push_error("Cannot write " + target)
			quit(1)
			return
		print("ORNAMENT ", name, " ", image.get_size())
	quit(0)
