extends SceneTree

# Çalıştırma: godot --headless -s tests/test_upgrades.gd

const Upgrades = preload("res://scripts/upgrades.gd")


func _initialize() -> void:
	# Başarısız assert fonksiyonu yarıda keser; o zaman çıkış kodu 1 olsun
	create_timer(10.0).timeout.connect(quit.bind(1))

	var shop := Upgrades.new()
	var speed := _find("move_speed")

	# Fiyat her seviyede cost_growth katı artar
	assert(shop.cost(speed) == 12)
	assert(shop.buy(speed, 100) == 12)
	assert(shop.level(speed) == 1)
	assert(shop.cost(speed) == roundi(12 * 1.35)) # 16
	assert(shop.cost(speed) > 12)

	# Yetersiz altın: seviye değişmez
	assert(shop.buy(speed, 5) == -1)
	assert(shop.level(speed) == 1)

	# MAX seviyede alınamaz
	for i in speed.max_level - 1:
		assert(shop.buy(speed, 9999) > 0)
	assert(shop.is_max(speed))
	assert(shop.buy(speed, 9999) == -1)
	assert(shop.level(speed) == speed.max_level)

	# max_level 0 = sınırsız
	var heal := _find("heal")
	for i in 20:
		assert(shop.buy(heal, 999999) > 0)
	assert(not shop.is_max(heal))

	# Kılıç geliştirmeleri kılıç açılmadan alınamaz
	var saber_speed := _find("saber_speed")
	assert(shop.buy(saber_speed, 9999) == -1)
	assert(shop.buy(_find("saber"), 9999) > 0)
	assert(shop.buy(saber_speed, 9999) > 0)

	# Her kaydın hedef metodu sahnede var
	var game: Node = load("res://scenes/game.tscn").instantiate()
	for upgrade in Upgrades.LIST:
		assert(Upgrades.ICONS.has(upgrade.icon), upgrade.id)
		assert(game.get_node(upgrade.target).has_method(upgrade.method), upgrade.id)
	game.free()

	print("test_upgrades: OK")
	quit()


func _find(id: String) -> Dictionary:
	for upgrade in Upgrades.LIST:
		if upgrade.id == id:
			return upgrade
	assert(false, id)
	return {}
