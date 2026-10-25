extends RefCounted

# Market verisi ve satın alma mantığı. Yeni geliştirme/silah eklemek için sadece LIST'e kayıt eklenir.
# target: sahne köküne göre node yolu; satın alınınca target.call(method, amount) çağrılır.
# Fiyat = round(base_cost * cost_growth ^ seviye). max_level 0 = sınırsız.
# requires: o id en az 1 kez alınmadan bu kayıt alınamaz.

# upgrade_icons.png'deki 16x16 karelerin sırası
const ICONS := [
	"karakter", "tabanca", "isin_kilici",
	"hiz", "can", "yaricap", "kalp", "dash",
	"atis_hizi", "mermi_adedi", "mermi_hizi", "mermi_boyutu",
	"kilic_adedi", "donus_hizi", "kilic_boyutu", "yorunge",
]

const CATEGORIES := [
	{ id = "karakter", name = "Karakter", icon = "karakter" },
	{ id = "silah", name = "Tabanca", icon = "tabanca" },
	{ id = "isin_kilici", name = "Işın Kılıcı", icon = "isin_kilici" },
]

const LIST := [
	{ id = "move_speed", category = "karakter", name = "Hareket Hızı", icon = "hiz",
		desc = "Hareket hızı +0.5", base_cost = 12, cost_growth = 1.35, max_level = 5,
		target = "Player", method = "increase_speed", amount = 0.5 },
	{ id = "max_health", category = "karakter", name = "Max Can", icon = "can",
		desc = "+1 can kapasitesi", base_cost = 25, cost_growth = 1.6, max_level = 4,
		target = "Player/Health", method = "increase_max_health", amount = 1 },
	{ id = "pickup_radius", category = "karakter", name = "Toplama Alanı", icon = "yaricap",
		desc = "Altın çekme yarıçapı +0.75", base_cost = 10, cost_growth = 1.3, max_level = 5,
		target = "Player", method = "increase_pickup_radius", amount = 0.75 },
	{ id = "heal", category = "karakter", name = "Can Doldur", icon = "kalp",
		desc = "2 can doldurur", base_cost = 8, cost_growth = 1.2, max_level = 0,
		target = "Player/Health", method = "heal_player", amount = 2 },
	{ id = "dash_cooldown", category = "karakter", name = "Dash", icon = "dash",
		desc = "Dash bekleme süresi -0.15 sn", base_cost = 15, cost_growth = 1.4, max_level = 4,
		target = "Player", method = "decrease_dash_cooldown", amount = 0.15 },

	{ id = "fire_rate", category = "silah", name = "Atış Hızı", icon = "atis_hizi",
		desc = "Atışlar arası süre -0.02 sn", base_cost = 15, cost_growth = 1.35, max_level = 5,
		target = "Player", method = "increase_fire_rate", amount = 0.02 },
	{ id = "bullet_count", category = "silah", name = "Mermi Adedi", icon = "mermi_adedi",
		desc = "Her atışta +1 mermi", base_cost = 40, cost_growth = 1.7, max_level = 4,
		target = "Player", method = "add_bullet", amount = 1 },
	{ id = "bullet_speed", category = "silah", name = "Mermi Hızı", icon = "mermi_hizi",
		desc = "Mermi hızı +4", base_cost = 10, cost_growth = 1.3, max_level = 5,
		target = "Player", method = "increase_bullet_speed", amount = 4.0 },
	{ id = "bullet_size", category = "silah", name = "Mermi Boyutu", icon = "mermi_boyutu",
		desc = "Mermi boyutu +%25", base_cost = 15, cost_growth = 1.4, max_level = 4,
		target = "Player", method = "increase_bullet_size", amount = 0.25 },

	{ id = "saber", category = "isin_kilici", name = "Işın Kılıcı", icon = "kilic_adedi",
		desc = "İlk alım kılıcı açar, sonra +1 kılıç", base_cost = 35, cost_growth = 1.5, max_level = 5,
		target = "Player/SaberOrbit", method = "add_saber", amount = 1 },
	{ id = "saber_speed", category = "isin_kilici", name = "Dönüş Hızı", icon = "donus_hizi",
		desc = "Dönüş hızı +40°/sn", base_cost = 15, cost_growth = 1.35, max_level = 5, requires = "saber",
		target = "Player/SaberOrbit", method = "increase_rotate_speed", amount = 40.0 },
	{ id = "saber_size", category = "isin_kilici", name = "Kılıç Boyutu", icon = "kilic_boyutu",
		desc = "Kılıç boyutu +%20", base_cost = 20, cost_growth = 1.4, max_level = 4, requires = "saber",
		target = "Player/SaberOrbit", method = "increase_saber_size", amount = 0.2 },
	{ id = "saber_radius", category = "isin_kilici", name = "Yörünge", icon = "yorunge",
		desc = "Dönüş yarıçapı +0.3", base_cost = 12, cost_growth = 1.3, max_level = 4, requires = "saber",
		target = "Player/SaberOrbit", method = "increase_radius", amount = 0.3 },
]

# Run boyunca alınan seviyeler (id → seviye); kaydedilmez
var levels := {}


func level(upgrade: Dictionary) -> int:
	return levels.get(upgrade.id, 0)


func cost(upgrade: Dictionary) -> int:
	return roundi(upgrade.base_cost * pow(upgrade.cost_growth, level(upgrade)))


func is_max(upgrade: Dictionary) -> bool:
	return upgrade.max_level > 0 and level(upgrade) >= upgrade.max_level


func is_locked(upgrade: Dictionary) -> bool:
	return upgrade.has("requires") and levels.get(upgrade.requires, 0) == 0


func can_buy(upgrade: Dictionary, gold: int) -> bool:
	return not is_max(upgrade) and not is_locked(upgrade) and gold >= cost(upgrade)


# Alınabiliyorsa seviyeyi artırıp ödenecek fiyatı döner, alınamıyorsa -1
func buy(upgrade: Dictionary, gold: int) -> int:
	if not can_buy(upgrade, gold):
		return -1
	var price := cost(upgrade)
	levels[upgrade.id] = level(upgrade) + 1
	return price
