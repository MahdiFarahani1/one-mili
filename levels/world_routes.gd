extends RefCounted

# Authored checkpoint lines for the four later chapters. Each entry follows the
# stage's traversal order; sideways stages use vertical opening centers.
const CENTERS = {
	1: [
		[470.0, 235.0], [255.0, 475.0], [455.0, 260.0], [865.0, 480.0],
		[245.0, 465.0], [475.0, 250.0], [225.0, 475.0], [490.0, 900.0],
		[465.0, 255.0, 450.0], [235.0, 465.0, 245.0], [475.0, 250.0, 455.0], [880.0, 480.0, 900.0]
	],
	2: [
		[245.0, 470.0, 260.0], [470.0, 235.0, 455.0], [255.0, 465.0, 240.0], [890.0, 485.0, 885.0],
		[465.0, 255.0, 475.0], [235.0, 465.0, 245.0], [475.0, 250.0, 460.0], [480.0, 905.0, 490.0],
		[250.0, 475.0, 260.0], [465.0, 235.0, 455.0], [245.0, 465.0, 250.0], [900.0, 485.0, 895.0]
	],
	3: [
		[470.0, 245.0, 455.0], [250.0, 475.0, 240.0], [465.0, 255.0, 470.0], [880.0, 475.0, 895.0],
		[245.0, 465.0, 250.0, 455.0], [475.0, 250.0, 470.0, 240.0], [255.0, 470.0, 245.0, 465.0], [900.0, 485.0, 895.0, 475.0],
		[465.0, 245.0, 475.0, 250.0], [235.0, 465.0, 245.0, 455.0], [475.0, 255.0, 465.0, 240.0], [885.0, 480.0, 905.0, 490.0]
	],
	4: [
		[250.0, 475.0, 245.0, 460.0], [465.0, 250.0, 470.0, 255.0], [245.0, 465.0, 250.0, 475.0], [895.0, 480.0, 900.0, 485.0],
		[475.0, 245.0, 460.0, 250.0], [255.0, 475.0, 245.0, 465.0], [460.0, 250.0, 475.0, 245.0], [890.0, 485.0, 900.0, 480.0],
		[245.0, 465.0, 255.0, 470.0], [475.0, 250.0, 460.0, 245.0], [255.0, 470.0, 245.0, 465.0], [900.0, 485.0, 895.0, 480.0]
	]
}

static func centers(number: int) -> Array:
	var world := (number - 1) / 12
	var local := (number - 1) % 12
	return CENTERS[world][local]

static func material(world: int, local: int, gate_index: int) -> String:
	match world:
		1:
			return ["normal", "sticky", "spring", "fragile"][(local + gate_index) % 4]
		2:
			return ["normal", "ice", "fragile", "ice"][(local + gate_index) % 4]
		3:
			return ["normal", "spring", "ice", "normal"][(local + gate_index) % 4]
		4:
			return ["normal", "fragile", "spring", "ice"][(local + gate_index) % 4]
	return "normal"

static func props(world: int, number: int, gates: Array, axis: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var kinds := [[], ["bloom", "lantern"], ["prism", "rune"], ["satellite", "comet"], ["valve", "vent"]]
	for i in gates.size():
		var gate: Dictionary = gates[i]
		var position: Vector2
		if axis == "x":
			position = Vector2(float(gate["x"]) + 52.0, 335.0 if float(gate["center"]) > 690.0 else 1045.0)
		else:
			position = Vector2(130.0 if float(gate["center"]) > 360.0 else 590.0, float(gate["y"]) - 120.0)
		result.append({"kind": kinds[world][(number + i) % 2], "position": position, "phase": float(i) * 1.4 + float(number) * 0.2})
	return result
