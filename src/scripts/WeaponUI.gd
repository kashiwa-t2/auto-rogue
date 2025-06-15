extends Control
class_name WeaponUI

## 武器UI管理クラス
## キャラクター別武器装備・強化画面

# キャラクター選択
@onready var character_tabs: TabContainer = $WeaponContainer/CharacterTabs
@onready var green_character_tab: Control = $WeaponContainer/CharacterTabs/GreenCharacterTab
@onready var red_character_tab: Control = $WeaponContainer/CharacterTabs/RedCharacterTab

# みどりくん武器UI
@onready var green_weapon_icon: TextureRect = $WeaponContainer/CharacterTabs/GreenCharacterTab/WeaponInfo/WeaponIcon
@onready var green_weapon_name: Label = $WeaponContainer/CharacterTabs/GreenCharacterTab/WeaponInfo/WeaponName
@onready var green_weapon_level: Label = $WeaponContainer/CharacterTabs/GreenCharacterTab/WeaponInfo/WeaponLevel
@onready var green_weapon_damage: Label = $WeaponContainer/CharacterTabs/GreenCharacterTab/WeaponInfo/WeaponDamage
@onready var green_upgrade_button: Button = $WeaponContainer/CharacterTabs/GreenCharacterTab/UpgradeContainer/UpgradeButton
@onready var green_upgrade_cost: Label = $WeaponContainer/CharacterTabs/GreenCharacterTab/UpgradeContainer/CostLabel

# あかさん武器UI
@onready var red_weapon_icon: TextureRect = $WeaponContainer/CharacterTabs/RedCharacterTab/WeaponInfo/WeaponIcon
@onready var red_weapon_name: Label = $WeaponContainer/CharacterTabs/RedCharacterTab/WeaponInfo/WeaponName
@onready var red_weapon_level: Label = $WeaponContainer/CharacterTabs/RedCharacterTab/WeaponInfo/WeaponLevel
@onready var red_weapon_damage: Label = $WeaponContainer/CharacterTabs/RedCharacterTab/WeaponInfo/WeaponDamage
@onready var red_upgrade_button: Button = $WeaponContainer/CharacterTabs/RedCharacterTab/UpgradeContainer/UpgradeButton
@onready var red_upgrade_cost: Label = $WeaponContainer/CharacterTabs/RedCharacterTab/UpgradeContainer/CostLabel

# 武器リスト
@onready var weapon_list: ItemList = $WeaponContainer/WeaponList

# 武器システム参照
var weapon_system: WeaponSystem

# シグナル
signal weapon_upgraded(character_name: String)

func _ready():
	add_to_group("weapon_ui")
	_setup_weapon_system()
	_setup_ui_signals()
	_update_display()
	
	# PlayerStatsとの同期
	PlayerStats.sync_weapon_levels_to_weapon_system()

## 武器システム初期化
func _setup_weapon_system() -> void:
	weapon_system = WeaponSystem.new()
	add_child(weapon_system)
	
	# 武器システムシグナル接続
	weapon_system.weapon_equipped.connect(_on_weapon_equipped)
	weapon_system.weapon_upgraded.connect(_on_weapon_upgraded)

## UIシグナル設定
func _setup_ui_signals() -> void:
	if green_upgrade_button:
		green_upgrade_button.pressed.connect(_on_green_upgrade_pressed)
	if red_upgrade_button:
		red_upgrade_button.pressed.connect(_on_red_upgrade_pressed)
	if weapon_list:
		weapon_list.item_selected.connect(_on_weapon_selected)

## 表示更新
func _update_display() -> void:
	_update_character_weapon_display("green")
	_update_character_weapon_display("red")
	_update_weapon_list()

## キャラクター武器表示更新
func _update_character_weapon_display(character_name: String) -> void:
	var weapon = weapon_system.get_character_weapon(character_name)
	if not weapon:
		return
	
	match character_name:
		"green":
			_update_weapon_ui_elements(
				green_weapon_icon, green_weapon_name, green_weapon_level,
				green_weapon_damage, green_upgrade_cost, green_upgrade_button,
				weapon
			)
		"red":
			if PlayerStats.red_character_unlocked:
				_update_weapon_ui_elements(
					red_weapon_icon, red_weapon_name, red_weapon_level,
					red_weapon_damage, red_upgrade_cost, red_upgrade_button,
					weapon
				)

## 武器UI要素更新
func _update_weapon_ui_elements(icon: TextureRect, name_label: Label, level_label: Label, 
								damage_label: Label, cost_label: Label, upgrade_button: Button,
								weapon: WeaponSystem.WeaponData) -> void:
	if not weapon:
		return
	
	# アイコン設定
	if icon:
		var texture = load(weapon.icon_path) as Texture2D
		if texture:
			icon.texture = texture
		# レアリティ色適用
		icon.modulate = weapon_system.get_rarity_color(weapon.rarity)
	
	# 名前とレベル
	if name_label:
		name_label.text = weapon.name
	if level_label:
		level_label.text = "Lv.%d" % weapon.level
	
	# ダメージ
	if damage_label:
		damage_label.text = "攻撃力: %d" % weapon.get_damage_at_level()
	
	# アップグレードコストとボタン
	var cost = weapon.get_upgrade_cost()
	if cost_label:
		cost_label.text = "%d コイン" % cost
	if upgrade_button:
		upgrade_button.disabled = PlayerStats.total_coins < cost

## 武器リスト更新
func _update_weapon_list() -> void:
	if not weapon_list:
		return
	
	weapon_list.clear()
	
	# みどりくん用武器
	var green_weapons = weapon_system.get_available_weapons("green")
	for weapon in green_weapons:
		weapon_list.add_item("%s (剣)" % weapon.name)
		var item_index = weapon_list.get_item_count() - 1
		weapon_list.set_item_metadata(item_index, {"character": "green", "weapon_id": weapon.id})
		
		# 装備中の武器をハイライト
		var current_weapon = weapon_system.get_character_weapon("green")
		if current_weapon and current_weapon.id == weapon.id:
			weapon_list.set_item_custom_fg_color(item_index, Color.YELLOW)
	
	# あかさん用武器（解放済みの場合）
	if PlayerStats.red_character_unlocked:
		var red_weapons = weapon_system.get_available_weapons("red")
		for weapon in red_weapons:
			weapon_list.add_item("%s (杖)" % weapon.name)
			var item_index = weapon_list.get_item_count() - 1
			weapon_list.set_item_metadata(item_index, {"character": "red", "weapon_id": weapon.id})
			
			# 装備中の武器をハイライト
			var current_weapon = weapon_system.get_character_weapon("red")
			if current_weapon and current_weapon.id == weapon.id:
				weapon_list.set_item_custom_fg_color(item_index, Color.YELLOW)

## イベントハンドラー
func _on_green_upgrade_pressed() -> void:
	if weapon_system.upgrade_weapon("green"):
		weapon_upgraded.emit("green")
		_update_display()
		_log_debug("Green character weapon upgraded")

func _on_red_upgrade_pressed() -> void:
	if weapon_system.upgrade_weapon("red"):
		weapon_upgraded.emit("red")
		_update_display()
		_log_debug("Red character weapon upgraded")

func _on_weapon_selected(index: int) -> void:
	var metadata = weapon_list.get_item_metadata(index)
	if metadata:
		var character_name = metadata.character
		var weapon_id = metadata.weapon_id
		
		if weapon_system.equip_weapon(character_name, weapon_id):
			_update_display()
			_log_debug("Weapon equipped: %s to %s" % [weapon_id, character_name])

func _on_weapon_equipped(character_name: String, weapon: WeaponSystem.WeaponData) -> void:
	_log_debug("Weapon equipped: %s to %s" % [weapon.name, character_name])
	_update_display()

func _on_weapon_upgraded(character_name: String, weapon: WeaponSystem.WeaponData) -> void:
	_log_debug("Weapon upgraded: %s Level %d" % [weapon.name, weapon.level])

## 外部更新要求
func refresh_display() -> void:
	_update_display()

## WeaponSystem取得
func get_weapon_system() -> WeaponSystem:
	return weapon_system

## デバッグログ
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[WeaponUI] %s" % message)