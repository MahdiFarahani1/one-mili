extends RefCounted
class_name ChapterChallenge

# Five distinct chapters matching user specifications:
# 1. Sky Islands (جزایر آسمانی) - Precision & narrow landings, spinning blades, floating ruins.
# 2. Magic Forest (جنگل جادویی) - Rhythm, glowing mushrooms, moving plants, fragile branches.
# 3. Crystal Depths (اعماق کریستال) - Route reading, crystalline caves, brittle and ice ledges.
# 4. Cosmic Space (فضای کیهانی) - Gravity mastery, zero-g zones, neon portals, nebulae.
# 5. Mechanical Factory (کارخانه مکانیکی) - Timed lasers, industrial gears, mechanical pistons, full mastery.

const NAMES_FA := [
	"جزایر آسمانی",
	"جنگل جادویی",
	"اعماق کریستال",
	"فضای کیهانی",
	"کارخانه مکانیکی"
]

const TITLES_EN := [
	"Sky Islands",
	"Magic Forest",
	"Crystal Depths",
	"Cosmic Space",
	"Mechanical Factory"
]

const SUBTITLES_FA := [
	"پرواز بر فراز جزایر معلق با فرودهای میلی‌متری",
	"گذر از ریتم تله‌های گیاهی و قارچ‌های شب‌تاب",
	"مسیرخوانی در میان بلورهای درخشان و شکننده",
	"مهار جاذبه در مدارهای بی‌وزنی و پرتال‌های کیهانی",
	"نبرد نهایی با چرخ‌دنده‌ها، پیستون‌ها و لیزرهای سرخ"
]

const SKILLS := [
	"precision",
	"rhythm",
	"route_reading",
	"gravity_control",
	"mastery"
]

const SKILLS_FA := [
	"دقت و فرود باریک",
	"ریتم و زمان‌بندی",
	"مسیرخوانی و سرعت",
	"تسلط بر جاذبه و بی‌وزنی",
	"مهارت تمام‌عیار"
]

const CHAPTER_COLORS := [
	Color("38b6ff"), # Sky cyan
	Color("3fe08c"), # Forest emerald
	Color("b566ff"), # Crystal violet
	Color("6a7eff"), # Cosmic indigo
	Color("ff7a29")  # Factory molten orange
]

static func profile(world: int) -> Dictionary:
	var w := clampi(world, 0, 4)
	return {
		"name": NAMES_FA[w],
		"title_en": TITLES_EN[w],
		"subtitle": SUBTITLES_FA[w],
		"skill": SKILLS[w],
		"skill_fa": SKILLS_FA[w],
		"color": CHAPTER_COLORS[w],
		"gate_penalty": [0.0, 6.0, 12.0, 16.0, 22.0][w],
		"par_time_multiplier": [1.0, 0.95, 0.90, 0.84, 0.78][w],
		"par_turn_multiplier": [1.0, 0.96, 0.92, 0.86, 0.82][w],
	}

static func challenge_hazards(world: int, number: int, gates: Array, axis: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if gates.is_empty() or number < 10:
		return result
	
	for i in gates.size():
		var gate: Dictionary = gates[i]
		if axis == "y":
			var y: float = float(gate["y"])
			var center: float = float(gate["center"])
			var width: float = float(gate["width"])
			# Safely offset hazards to the flanks so the center path remains traversable
			var side := -1.0 if (number + i) % 2 == 0 else 1.0
			var flank_x := clampf(center + side * (width * 0.5 + 46.0), 105.0, 615.0)
			
			match world:
				0:
					# Chapter 1: Precision saw blades on upper gates
					if i == gates.size() - 1 and number >= 8:
						result.append({
							"kind": "saw",
							"center": Vector2(flank_x, y - 55.0),
							"radius": 17.0,
							"phase": float(i) * 0.5
						})
				1:
					# Chapter 2: Oscillating organic plant movers
					if i % 2 == 0:
						result.append({
							"kind": "mover",
							"center": Vector2(flank_x, y - 62.0),
							"radius": 16.0,
							"phase": float(i) * 0.75 + float(number % 4) * 0.3,
							"amplitude": 22.0
						})
				2:
					# Chapter 3: High speed crystalline saw clusters
					if i % 2 == 1 and number != 39:
						result.append({
							"kind": "saw",
							"center": Vector2(flank_x, y - 58.0),
							"radius": 18.0,
							"phase": float(i) * 0.6
						})
				3:
					# Chapter 4: Zero-G anomaly bubbles (kept safely in open space, not overlapping gates)
					if i == 0 and number != 39:
						var bubble_x := 360.0 if center < 300.0 or center > 420.0 else (200.0 if center > 360.0 else 520.0)
						result.append({
							"kind": "zero",
							"center": Vector2(bubble_x, y - 120.0),
							"radius": 56.0,
							"phase": 0.0
						})
					elif i == 1 and number % 4 == 0:
						result.append({
							"kind": "portal",
							"center": Vector2(flank_x, y - 48.0),
							"exit": Vector2(360.0, y - 130.0),
							"phase": 0.0
						})
				4:
					# Chapter 5: Factory mechanical pistons
					if i % 2 == 0:
						result.append({
							"kind": "mover",
							"center": Vector2(flank_x, y - 60.0),
							"radius": 18.0,
							"phase": float(i) * 0.9 + float(number % 3) * 0.4,
							"amplitude": 26.0
						})
		else:
			# Horizontal / sideways stages
			var x: float = float(gate["x"])
			var center_y: float = float(gate["center"])
			var width_y: float = float(gate["width"])
			var side_y := -1.0 if (number + i) % 2 == 0 else 1.0
			var flank_y := clampf(center_y + side_y * (width_y * 0.5 + 46.0), 320.0, 1060.0)
			
			match world:
				1:
					if i % 2 == 0:
						result.append({
							"kind": "mover",
							"center": Vector2(x + 50.0, flank_y),
							"radius": 16.0,
							"phase": float(i) * 0.8,
							"amplitude": 20.0
						})
				3:
					if i == 0:
						result.append({
							"kind": "zero",
							"center": Vector2(x + 60.0, 690.0),
							"radius": 54.0,
							"phase": 0.0
						})
				4:
					if i % 2 == 1:
						result.append({
							"kind": "mover",
							"center": Vector2(x + 50.0, flank_y),
							"radius": 18.0,
							"phase": float(i) * 1.1,
							"amplitude": 24.0
						})
	
	return result
