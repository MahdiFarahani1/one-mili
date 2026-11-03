extends Node

const PATH := "user://one_millimeter_save.json"
const BACKUP := "user://one_millimeter_save.bak"
var data: Dictionary = {}

func _ready() -> void:
	load_game()

func defaults() -> Dictionary:
	return {"version": 1, "crystals": 0, "levels": {}, "attempts": 0, "deaths": 0, "endless_best": 0, "skins": ["classic"], "trails": ["sparkle"], "themes": ["candy"], "skin": "classic", "trail": "sparkle", "theme": "candy", "music": true, "sfx": true, "vibration": true, "achievements": [], "daily": {}}

func load_game() -> void:
	data = defaults()
	for path in [PATH, BACKUP]:
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var json := JSON.new()
		if json.parse(file.get_as_text()) != OK:
			continue
		var parsed: Variant = json.data
		if parsed is Dictionary and parsed.get("version", 0) == 1 and parsed.has("levels"):
			data.merge(parsed, true)
			return

func save_game() -> void:
	if FileAccess.file_exists(PATH):
		var old := FileAccess.open(PATH, FileAccess.READ)
		if old != null:
			var backup := FileAccess.open(BACKUP, FileAccess.WRITE)
			if backup != null:
				backup.store_string(old.get_as_text())
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
		file.flush()

func complete_level(number: int, seconds: float, turns: int, stars: int, collected: int) -> int:
	var key := str(number)
	var previous: Dictionary = data["levels"].get(key, {})
	var old_stars: int = int(previous.get("stars", 0))
	var reward := collected + (stars - old_stars) * 10 + (5 if previous.is_empty() else 0)
	data["crystals"] += max(0, reward)
	data["levels"][key] = {"stars": max(stars, old_stars), "best_time": minf(seconds, float(previous.get("best_time", 9999.0))), "best_turns": mini(turns, int(previous.get("best_turns", 9999)))}
	ensure_daily()
	data["daily"]["progress"] = mini(int(data["daily"]["target"]), int(data["daily"]["progress"]) + 1)
	save_game()
	return reward

func unlocked_level() -> int:
	var n := 1
	while n <= 60 and data["levels"].has(str(n)):
		n += 1
	return mini(n, 60)

func own(category: String, item: String) -> bool:
	return item in data.get(category, [])

func purchase(category: String, item: String, cost: int) -> bool:
	if own(category, item) or int(data["crystals"]) < cost:
		return false
	data["crystals"] -= cost
	data[category].append(item)
	save_game()
	return true

func claim_achievement(id: int) -> int:
	if id in data["achievements"]:
		return 0
	var reward := 30 + id * 10
	data["achievements"].append(id)
	data["crystals"] += reward
	save_game()
	return reward

func daily_claim() -> int:
	ensure_daily()
	var daily: Dictionary = data["daily"]
	if daily.get("claimed", false) or int(daily["progress"]) < int(daily["target"]):
		return 0
	var reward := 25 + int(daily["target"]) * 5
	data["crystals"] += reward
	data["daily"]["claimed"] = true
	save_game()
	return reward

func ensure_daily() -> void:
	var day := Time.get_date_string_from_system()
	if data["daily"].get("day", "") != day:
		data["daily"] = {"day": day, "target": 2 + int(day.replace("-", "")) % 2, "progress": 0, "claimed": false}
