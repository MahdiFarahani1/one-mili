extends RefCounted
class_name LevelData

const WORLD_NAMES := ["Sky Islands", "Magic Forest", "Crystal Depths", "Cosmic Space", "Mechanical Factory"]
const WORLD_FA := ["جزایر آسمانی", "جنگل جادویی", "اعماق کریستال", "فضای کیهانی", "کارخانه مکانیکی"]
const WORLD_DESCRIPTIONS := [
	"پرواز بر فراز جزایر معلق با فرودهای میلی‌متری",
	"گذر از ریتم تله‌های گیاهی و قارچ‌های شب‌تاب",
	"مسیرخوانی در میان بلورهای درخشان و شکننده",
	"مهار جاذبه در مدارهای بی‌وزنی و پرتال‌های کیهانی",
	"نبرد نهایی با چرخ‌دنده‌ها، پیستون‌ها و لیزرهای سرخ"
]
const WORLD_SKILLS_FA := [
	"دقت و فرود باریک",
	"ریتم و زمان‌بندی",
	"مسیرخوانی و سرعت",
	"تسلط بر جاذبه و بی‌وزنی",
	"مهارت تمام‌عیار"
]
const WORLD_COLORS := [
	Color("38b6ff"),
	Color("3fe08c"),
	Color("b566ff"),
	Color("6a7eff"),
	Color("ff7a29")
]

const SKINS := [
	"classic", "fire", "ice", "galaxy", "gold", 
	"rainbow", "ninja", "robot", "ghost", "crystal", 
	"candy", "star", "electric", "moon", "legendary"
]
const SKIN_NAMES := [
	"ژلهٔ کلاسیک", "شعلهٔ آتشین", "یخ قطبی", "سحابی کیهانی", "طلای سلطنتی", 
	"طیف رنگین‌کمان", "نینجای سایه", "مکانیکال ربات", "شبح سرگردان", "بلور کوارتز", 
	"ژلهٔ نئونی", "اختر درخشان", "صاعقهٔ الکتریک", "مهتاب کهن", "ژلهٔ افسانه‌ای"
]

const TRAILS := [
	"sparkle", "bubble", "fire", "snow", "rainbow", 
	"star", "leaf", "moon", "crystal", "heart"
]
const TRAIL_NAMES := [
	"جرقهٔ ستاره", "حباب شفاف", "زبانهٔ آتش", "کولاک برف", "رنگین‌کمان", 
	"غبار کیهانی", "برگ جادویی", "هالهٔ مهتاب", "پرتو بلورین", "تپش قلب"
]

static func level(number: int) -> Dictionary:
	return preload("res://levels/route_level.gd").build(number)

static func shop_cost(category: String, index: int) -> int:
	if category == "skins":
		return 35 + index * 20
	if category == "trails":
		return 20 + index * 15
	return 150 + index * 70
