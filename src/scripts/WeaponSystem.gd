extends Node
class_name WeaponSystem

## 武器システム管理クラス
## キャラクター別の武器装備・強化・効果管理

# 武器種類定義
enum WeaponType {
	SWORD,      # 剣（みどりくん用）
	STAFF,      # 杖（あかさん用）
	BOW,        # 弓
	HAMMER,     # ハンマー
	DAGGER      # ダガー
}

# 武器レアリティ
enum WeaponRarity {
	COMMON,     # コモン（白）
	RARE,       # レア（青）
	EPIC,       # エピック（紫）
	LEGENDARY   # レジェンド（金）
}

# 武器データ構造
class WeaponData:
	var id: String
	var name: String
	var weapon_type: WeaponType
	var rarity: WeaponRarity
	var level: int = 1
	var base_damage: int
	var special_effect: String = ""
	var icon_path: String
	
	func _init(weapon_id: String, weapon_name: String, type: WeaponType, weapon_rarity: WeaponRarity, damage: int, icon: String):
		id = weapon_id
		name = weapon_name
		weapon_type = type
		rarity = weapon_rarity
		base_damage = damage
		icon_path = icon
	
	func get_damage_at_level() -> int:
		return base_damage + (level - 1) * 5
	
	func get_upgrade_cost() -> int:
		return level * 50

# キャラクター装備管理
var green_character_weapon: WeaponData = null
var red_character_weapon: WeaponData = null

# 利用可能武器データベース
var weapon_database: Dictionary = {}

# シグナル
signal weapon_equipped(character_name: String, weapon: WeaponData)
signal weapon_upgraded(character_name: String, weapon: WeaponData)

func _ready():
	_initialize_weapon_database()
	_setup_default_weapons()

## 武器データベース初期化
func _initialize_weapon_database() -> void:
	# みどりくん用剣
	weapon_database["basic_sword"] = WeaponData.new(
		"basic_sword", "ベーシックソード", WeaponType.SWORD, WeaponRarity.COMMON, 10,
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0103.png"
	)
	
	weapon_database["steel_sword"] = WeaponData.new(
		"steel_sword", "スチールソード", WeaponType.SWORD, WeaponRarity.RARE, 15,
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0103.png"
	)
	
	# あかさん用杖
	weapon_database["basic_staff"] = WeaponData.new(
		"basic_staff", "ベーシックスタッフ", WeaponType.STAFF, WeaponRarity.COMMON, 8,
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0130.png"
	)
	
	weapon_database["magic_staff"] = WeaponData.new(
		"magic_staff", "マジックスタッフ", WeaponType.STAFF, WeaponRarity.RARE, 12,
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0130.png"
	)

## デフォルト武器装備
func _setup_default_weapons() -> void:
	green_character_weapon = weapon_database["basic_sword"]
	red_character_weapon = weapon_database["basic_staff"]

## 武器装備
func equip_weapon(character_name: String, weapon_id: String) -> bool:
	if not weapon_database.has(weapon_id):
		print("[WeaponSystem] ERROR: Weapon not found: %s" % weapon_id)
		return false
	
	var weapon = weapon_database[weapon_id]
	
	match character_name:
		"green":
			if weapon.weapon_type == WeaponType.SWORD:
				green_character_weapon = weapon
				weapon_equipped.emit(character_name, weapon)
				return true
		"red":
			if weapon.weapon_type == WeaponType.STAFF:
				red_character_weapon = weapon
				weapon_equipped.emit(character_name, weapon)
				return true
	
	print("[WeaponSystem] ERROR: Invalid weapon type for character: %s" % character_name)
	return false

## 武器強化
func upgrade_weapon(character_name: String) -> bool:
	var weapon: WeaponData = null
	
	match character_name:
		"green":
			weapon = green_character_weapon
		"red":
			weapon = red_character_weapon
	
	if not weapon:
		return false
	
	var cost = weapon.get_upgrade_cost()
	if PlayerStats.total_coins >= cost:
		PlayerStats.total_coins -= cost
		weapon.level += 1
		weapon_upgraded.emit(character_name, weapon)
		print("[WeaponSystem] Weapon upgraded: %s Level %d" % [weapon.name, weapon.level])
		return true
	
	return false

## 武器取得
func get_character_weapon(character_name: String) -> WeaponData:
	match character_name:
		"green":
			return green_character_weapon
		"red":
			return red_character_weapon
		_:
			return null

## 武器ダメージ取得
func get_weapon_damage(character_name: String) -> int:
	var weapon = get_character_weapon(character_name)
	if weapon:
		return weapon.get_damage_at_level()
	return 0

## 利用可能武器リスト取得
func get_available_weapons(character_name: String) -> Array[WeaponData]:
	var available: Array[WeaponData] = []
	
	var target_type: WeaponType
	match character_name:
		"green":
			target_type = WeaponType.SWORD
		"red":
			target_type = WeaponType.STAFF
		_:
			return available
	
	for weapon_id in weapon_database:
		var weapon = weapon_database[weapon_id]
		if weapon.weapon_type == target_type:
			available.append(weapon)
	
	return available

## レアリティ色取得
func get_rarity_color(rarity: WeaponRarity) -> Color:
	match rarity:
		WeaponRarity.COMMON:
			return Color.WHITE
		WeaponRarity.RARE:
			return Color.CYAN
		WeaponRarity.EPIC:
			return Color.MAGENTA
		WeaponRarity.LEGENDARY:
			return Color.GOLD
		_:
			return Color.WHITE

## デバッグログ
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[WeaponSystem] %s" % message)