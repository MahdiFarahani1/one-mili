extends RefCounted
class_name LevelData

const WORLD_NAMES := ["Candy Clouds", "Jelly Jungle", "Crystal Dreams", "Moonlight Magic", "Toy Factory"]
const WORLD_FA := ["ابرهای آب‌نباتی", "جنگل ژله‌ای", "رویای بلورها", "جادوی مهتاب", "کارخانه اسباب‌بازی"]
const WORLD_COLORS := [Color("ff8fba"), Color("65cf9e"), Color("8a9aff"), Color("a77ff2"), Color("ffbb70")]
const SKINS := ["classic", "fire", "ice", "galaxy", "gold", "rainbow", "ninja", "robot", "ghost", "crystal", "candy", "star", "electric", "moon", "legendary"]
const SKIN_NAMES := ["ژلهٔ کلاسیک", "ژلهٔ آتشین", "ژلهٔ یخی", "کهکشانی", "طلایی", "رنگین‌کمانی", "نینجا", "ربات", "شبح", "بلوری", "آب‌نباتی", "ستاره‌ای", "برقی", "مهتابی", "افسانه‌ای"]
const TRAILS := ["sparkle", "bubble", "fire", "snow", "rainbow", "star", "leaf", "moon", "crystal", "heart"]
const TRAIL_NAMES := ["درخشش", "حباب", "آتش", "برف", "رنگین‌کمان", "ستاره", "برگ", "مهتاب", "بلور", "قلب"]

static func level(number: int) -> Dictionary:
	return preload("res://levels/route_level.gd").build(number)

static func shop_cost(category: String, index: int) -> int:
	if category == "skins":
		return 40 + index * 22
	if category == "trails":
		return 25 + index * 18
	return 200 + index * 80
