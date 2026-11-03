extends RefCounted
class_name LevelData

const WORLD_NAMES := ["Sky & Clouds", "Magic Forest", "Crystal World", "Cosmic Space", "Mechanical Factory"]
const WORLD_FA := ["آسمان و ابرها", "جنگل جادویی", "دنیای کریستال", "فضای کیهانی", "کارخانه مکانیکی"]
const WORLD_DESCRIPTIONS := [
	"پرش‌های دقیق بر فراز قلعه‌های معلق و ابرهای درخشان",
	"سکوهای طبیعی ناپایدار، گیاهان تله‌دار و قارچ‌های جهنده",
	"مسیرهای چندمسیره بلورین و سوئیچ‌های تغییر مسیر",
	"دالان‌های بی‌وزنی با گرانش متغیر و پرتل‌های جابه‌جایی",
	"شبکه لیزرهای متقاطع هوشمند، پیستون‌ها و چرخ‌دنده‌های مرگبار"
]
const WORLD_SKILLS_FA := [
	"پرش‌های دقیق · لبه‌های جهت‌دار · سکوهای متحرک",
	"سکوهای ناپایدار · گیاهان تله‌دار · مسیرهای مخفی",
	"مسیرهای چندمسیره · سوئیچ مسیر · چالش سرعت",
	"گرانش متغیر · پرتل‌های جابه‌جایی · فیزیک مدار",
	"لیزرهای هوشمند · زمان‌بندی دقیق · پیستون‌های متحرک"
]
const WORLD_COLORS := [
	Color("38b6ff"), # Sky cyan
	Color("3fe08c"), # Forest emerald
	Color("b566ff"), # Crystal violet
	Color("6a7eff"), # Cosmic indigo
	Color("ff7a29")  # Factory molten orange
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
