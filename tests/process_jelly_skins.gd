extends SceneTree

func _initialize() -> void:
	var source := Image.new()
	if source.load("res://assets/sprites/jelly_body.png") != OK:
		push_error("Missing jelly body art")
		quit(1)
		return
	var variants := {
		"classic": [0.0, 1.0, 1.0], "fire": [-0.44, 1.2, 1.0],
		"ice": [-0.03, 0.7, 1.05], "galaxy": [0.22, 1.2, 0.84],
		"gold": [-0.36, 1.05, 1.06], "rainbow": [0.10, 1.25, 1.0],
		"ninja": [0.22, 0.7, 0.58], "robot": [0.02, 0.22, 0.87],
		"ghost": [0.0, 0.18, 1.15], "crystal": [-0.02, 1.2, 1.05],
		"candy": [0.39, 0.8, 1.08], "star": [-0.33, 1.0, 1.12],
		"electric": [-0.27, 1.1, 1.1], "moon": [0.17, 0.9, 0.9],
		"legendary": [0.34, 1.15, 1.08]
	}
	for name in variants:
		var image: Image = source.duplicate()
		var settings: Array = variants[name]
		for y in image.get_height():
			for x in image.get_width():
				var color: Color = image.get_pixel(x, y)
				if color.a < 0.01: continue
				var hue := wrapf(color.h + float(settings[0]), 0.0, 1.0)
				var saturation := clampf(color.s * float(settings[1]), 0.0, 1.0)
				var value := clampf(color.v * float(settings[2]), 0.0, 1.0)
				image.set_pixel(x, y, Color.from_hsv(hue, saturation, value, color.a))
		image.save_png("res://assets/sprites/jelly_%s.png" % name)
		print("SKIN:", name)
	quit()
