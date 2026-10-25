extends Control

# Wave arası market; ağaç durmuşken çalışır (UI process_mode = Always).
# Kartlar Upgrades.LIST'ten kurulur: yeni geliştirme eklemek için sadece veri değişir.

const Upgrades = preload("res://scripts/upgrades.gd")
const TintButton = preload("res://scripts/tint_button.gd")
const ICON_SHEET = preload("res://assets/sprites/ui/upgrade_icons_sheet.png")
const CARD_SHEET = preload("res://assets/sprites/ui/upgrade_card_sheet_x4.png")
const FLASH_SHEET = preload("res://assets/sprites/ui/buy_flash_sheet.png")
const COIN_SHEET = preload("res://assets/sprites/pickups/gold_coin_sheet.png")

const SLIDE_TIME := 0.3
const SLIDE_OFFSET := 120.0

# upgrade_card_sheet_x4: 96x96 kareler; satırlar normal, hover (5 kare), disabled, max
const CARD_FRAME := 96
const CARD_MARGIN := 24
const HOVER_FRAMES := 5
const HOVER_FRAME_TIME := 0.09
# next_wave_button_sheet: 84x24, normal satırı 4 karelik nabız
const BUTTON_FRAMES := 4
const BUTTON_FRAME_TIME := 0.15

@export var columns: HBoxContainer
@export var gold_text: Label
@export var next_wave_button: TextureButton

var _upgrades := Upgrades.new()
var _cards: Array[Dictionary] = []
var _game_manager: Node
var _anim_time := 0.0
var _gold_tween: Tween

var _style_normal := _card_style(0)
var _style_hover := _card_style(1)
var _style_disabled := _card_style(2)
var _style_max := _card_style(3)


func _ready() -> void:
	_game_manager = get_tree().get_first_node_in_group("game_manager")

	for category in Upgrades.CATEGORIES:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 12)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		columns.add_child(column)

		var header := HBoxContainer.new()
		header.alignment = BoxContainer.ALIGNMENT_CENTER
		header.add_child(_icon(category.icon, 56))
		header.add_child(_label(category.name, 48))
		column.add_child(header)

		for upgrade in Upgrades.LIST:
			if upgrade.category == category.id:
				column.add_child(_make_card(upgrade))


func _process(delta: float) -> void:
	if not visible:
		return
	# Hover kartının çerçevesi ve butonun nabzı
	_anim_time += delta
	_style_hover.region_rect.position.x = (int(_anim_time / HOVER_FRAME_TIME) % HOVER_FRAMES) * CARD_FRAME
	var normal := next_wave_button.texture_normal as AtlasTexture
	normal.region.position.x = (int(_anim_time / BUTTON_FRAME_TIME) % BUTTON_FRAMES) * normal.region.size.x


# Aşağıdan kayarak + fade ile gelir
func open() -> void:
	_set_gold_text(_game_manager.gold)
	_refresh()
	visible = true
	await _slide(SLIDE_OFFSET, 0.0, 0.0, 1.0)


# Kapanırken tersi
func close() -> void:
	await _slide(0.0, SLIDE_OFFSET, 1.0, 0.0)
	visible = false


func _slide(from_y: float, to_y: float, from_alpha: float, to_alpha: float) -> void:
	position.y = from_y
	modulate.a = from_alpha
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", to_y, SLIDE_TIME)
	tween.tween_property(self, "modulate:a", to_alpha, SLIDE_TIME)
	await tween.finished


func _buy(upgrade: Dictionary, card: Dictionary) -> void:
	var old_gold: int = _game_manager.gold
	var price := _upgrades.buy(upgrade, old_gold)
	if price < 0:
		return

	_game_manager.spend_gold(price)
	get_tree().current_scene.get_node(upgrade.target).call(upgrade.method, upgrade.amount)

	_count_gold(old_gold, _game_manager.gold)
	_flash(card)
	_refresh()


# Kart durumları: alınabilir / altın yetmiyor ya da kilitli (soluk) / MAX
func _refresh() -> void:
	for card in _cards:
		var upgrade: Dictionary = card.upgrade
		var level := _upgrades.level(upgrade)
		var maxed := _upgrades.is_max(upgrade)
		var buyable := _upgrades.can_buy(upgrade, _game_manager.gold)

		card.level.text = ("Sv %d/%d" % [level, upgrade.max_level]) if upgrade.max_level > 0 else ("Sv %d" % level)
		card.price.text = "MAX" if maxed else str(_upgrades.cost(upgrade))
		card.coin.visible = not maxed
		card.desc.text = ("Önce %s al" % _name_of(upgrade.requires)) if _upgrades.is_locked(upgrade) else upgrade.desc
		card.button.disabled = not buyable
		card.button.add_theme_stylebox_override("disabled", _style_max if maxed else _style_disabled)
		card.content.modulate.a = 1.0 if buyable or maxed else 0.45


func _make_card(upgrade: Dictionary) -> Button:
	var button := Button.new()
	button.set_script(TintButton)
	button.custom_minimum_size.y = 112
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _style_normal)
	button.add_theme_stylebox_override("pressed", _style_normal)
	button.add_theme_stylebox_override("hover", _style_hover)
	button.add_theme_stylebox_override("hover_pressed", _style_hover)

	# İkon | ad + seviye / açıklama + fiyat
	var content := HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	content.add_theme_constant_override("separation", 16)
	var icon := _icon(upgrade.icon, 64)
	content.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 0)
	content.add_child(info)

	var top := HBoxContainer.new()
	var title := _label(upgrade.name, 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var level := _label("", 32)
	top.add_child(level)
	info.add_child(top)

	var bottom := HBoxContainer.new()
	var desc := _label("", 28)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.add_theme_color_override("font_color", Color(0.12, 0.12, 0.1))
	bottom.add_child(desc)
	var coin := TextureRect.new()
	coin.texture = _atlas(COIN_SHEET, Rect2(8, 8, 16, 16))
	coin.custom_minimum_size = Vector2(32, 32)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(coin)
	var price := _label("", 36)
	bottom.add_child(price)
	info.add_child(bottom)

	button.add_child(content)
	_ignore_mouse(content)

	var card := { upgrade = upgrade, button = button, content = content, icon = icon,
		level = level, desc = desc, coin = coin, price = price }
	_cards.append(card)
	button.pressed.connect(_buy.bind(upgrade, card))
	return button


# Satın alınca kart kısa parlar, ikonun üstünde parlama efekti oynar
func _flash(card: Dictionary) -> void:
	var button: Button = card.button
	var tween := button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	button.modulate = Color(1.6, 1.6, 1.3)
	tween.tween_property(button, "modulate", Color.WHITE, 0.3)

	var atlas := _atlas(FLASH_SHEET, Rect2(0, 0, 32, 32))
	var effect := TextureRect.new()
	effect.texture = atlas
	effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.position = Vector2(-32, -32)
	effect.size = Vector2(128, 128)
	card.icon.add_child(effect)
	var frames := effect.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	frames.tween_method(func(f: float) -> void: atlas.region.position.x = floorf(f) * 32.0, 0.0, 5.99, 0.3)
	frames.tween_callback(effect.queue_free)


# Altın sayacı azalarak sayar
func _count_gold(from: int, to: int) -> void:
	if _gold_tween:
		_gold_tween.kill()
	_gold_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_gold_tween.tween_method(func(v: float) -> void: _set_gold_text(roundi(v)), float(from), float(to), 0.4)


func _set_gold_text(value: int) -> void:
	gold_text.text = str(value)


func _name_of(id: String) -> String:
	for upgrade in Upgrades.LIST:
		if upgrade.id == id:
			return upgrade.name
	return id


func _card_style(row: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = CARD_SHEET
	style.region_rect = Rect2(0, row * CARD_FRAME, CARD_FRAME, CARD_FRAME)
	style.set_texture_margin_all(CARD_MARGIN)
	return style


func _icon(id: String, side: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _atlas(ICON_SHEET, Rect2(Upgrades.ICONS.find(id) * 16, 0, 16, 16))
	rect.custom_minimum_size = Vector2(side, side)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.BLACK)
	return label


func _atlas(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	return atlas


func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
