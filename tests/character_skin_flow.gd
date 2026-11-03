extends SceneTree

const Data = preload("res://levels/level_data.gd")
const JellyScript = preload("res://entities/jelly.gd")
const VisualScript = preload("res://entities/jelly_visual.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var failures: Array[String] = []
	if Data.SKINS != VisualScript.SKIN_IDS:
		failures.append("skin order differs from atlas")
	var atlas: Texture2D = VisualScript.ATLAS
	var image := atlas.get_image()
	if image.get_size().x < 900 or image.get_size().y < 1500:
		failures.append("atlas unexpectedly small")
	else:
		var cell := Vector2(image.get_width() / 3.0, image.get_height() / 5.0)
		for i in Data.SKINS.size():
			var center := Vector2i(int((i % 3 + 0.5) * cell.x), int((i / 3 + 0.5) * cell.y))
			if image.get_pixelv(center).a < 0.5:
				failures.append("empty skin cell " + str(i))
			var jelly = JellyScript.new()
			jelly.skin = Data.SKINS[i]
			jelly.alive = false
			root.add_child(jelly)
			await process_frame
			var visual = jelly.get_node_or_null("Visual")
			if visual == null or visual.skin != Data.SKINS[i]:
				failures.append("preview mapping " + Data.SKINS[i])
			jelly.queue_free()
			await process_frame
	var moving: Jelly = JellyScript.new()
	root.add_child(moving)
	moving.reset(Vector2(100, 100))
	var initial: Vector2 = moving.gravity_direction
	moving.rotate_gravity()
	if moving.gravity_direction == initial or moving.velocity.length() < 70.0:
		failures.append("gravity tap response")
	moving.reset(Vector2(100, 100))
	if moving.velocity != Vector2.ZERO or moving.hit_feedback_cooldown != 0.0 or moving.spring_cooldown != 0.0:
		failures.append("restart clears motion state")
	moving.queue_free()
	await process_frame
	print("CHARACTER SKIN FLOW: ", "OK" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
