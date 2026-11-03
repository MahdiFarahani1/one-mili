extends SceneTree

# One-time import preparation: trim transparent borders, then cap texture size.
func _initialize() -> void:
	var names := ["platform_candy", "platform_jungle", "platform_crystal", "platform_moon", "platform_factory", "saw", "portal", "crystal", "laser_emitter", "jelly_body"]
	for name in names:
		var image := Image.new()
		var error := image.load("res://assets/sprites/raw/%s.png" % name)
		if error != OK:
			push_error("Missing sprite source: " + name)
			continue
		var left := image.get_width()
		var top := image.get_height()
		var right := 0
		var bottom := 0
		for y in image.get_height():
			for x in image.get_width():
				if image.get_pixel(x, y).a > 0.04:
					left = mini(left, x)
					top = mini(top, y)
					right = maxi(right, x + 1)
					bottom = maxi(bottom, y + 1)
		if left >= right or top >= bottom:
			push_error("Sprite has no visible pixels: " + name)
			continue
		var trimmed := image.get_region(Rect2i(left, top, right - left, bottom - top))
		var max_dimension := 1200 if name.begins_with("platform") else 512
		var scale_factor := minf(1.0, float(max_dimension) / float(maxi(trimmed.get_width(), trimmed.get_height())))
		if scale_factor < 1.0:
			trimmed.resize(maxi(1, roundi(trimmed.get_width() * scale_factor)), maxi(1, roundi(trimmed.get_height() * scale_factor)), Image.INTERPOLATE_LANCZOS)
		var destination := "res://assets/sprites/%s.png" % name
		if trimmed.save_png(destination) != OK:
			push_error("Could not write: " + destination)
		print(name, " ", image.get_size(), " => ", trimmed.get_size())
	quit()
