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
	var attack_range: float = 80.0
	var special_effect: String = ""
	var icon_path: String
	var sprite_path: String
	
	func _init(weapon_id: String, weapon_name: String, type: WeaponType, weapon_rarity: WeaponRarity, damage: int, range: float, icon: String, sprite: String = ""):
		id = weapon_id
		name = weapon_name
		weapon_type = type
		rarity = weapon_rarity
		base_damage = damage
		attack_range = range
		icon_path = icon
		sprite_path = sprite if sprite != "" else icon
	
	func get_damage_at_level() -> int:
		return base_damage + (level - 1) * 5
	
	func get_attack_range() -> float:
		return attack_range
	
	func get_upgrade_cost() -> int:
		return level * 50

# キャラクター装備管理
var green_character_weapon: WeaponData = null
var red_character_weapon: WeaponData = null

# 利用可能武器データベース
var weapon_database: Dictionary = {}

# 復元状態フラグ
var is_levels_restored: bool = false

# シグナル
signal weapon_equipped(character_name: String, weapon: WeaponData)
signal weapon_upgraded(character_name: String, weapon: WeaponData)

func _ready():
	_log_debug("🏁 WeaponSystem._ready() started")
	_log_debug("🔍 PlayerStats available: %s" % (PlayerStats != null))
	if PlayerStats:
		_log_debug("📊 PlayerStats.weapon_system_levels size: %d" % PlayerStats.weapon_system_levels.size())
		_log_debug("📋 PlayerStats.weapon_system_levels: %s" % PlayerStats.weapon_system_levels)
	
	_initialize_weapon_database()
	_setup_default_weapons()
	
	# 初期化完了後、保存済み武器レベルを復元
	_log_debug("⏳ Scheduling weapon level restoration...")
	call_deferred("_restore_saved_weapon_levels")
	
	_log_debug("✅ WeaponSystem._ready() completed")

## 武器データベース初期化
func _initialize_weapon_database() -> void:
	_log_debug("🗃️ Initializing weapon database...")
	
	# みどりくん用剣
	weapon_database["basic_sword"] = WeaponData.new(
		"basic_sword", "ベーシックソード", WeaponType.SWORD, WeaponRarity.COMMON, 10, 80.0,
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0103.png",
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0103.png"  # プレイエリア用のスプライト
	)
	
	weapon_database["steel_sword"] = WeaponData.new(
		"steel_sword", "スチールソード", WeaponType.SWORD, WeaponRarity.RARE, 15, 85.0,
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0104.png",  # 異なるアイコン
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0104.png"  # プレイエリア用の異なるスプライト
	)
	
	weapon_database["fire_sword"] = WeaponData.new(
		"fire_sword", "ファイアソード", WeaponType.SWORD, WeaponRarity.EPIC, 20, 90.0,
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0105.png",  # さらに異なるアイコン
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0105.png"  # プレイエリア用のスプライト
	)
	
	# あかさん用杖
	weapon_database["basic_staff"] = WeaponData.new(
		"basic_staff", "ベーシックスタッフ", WeaponType.STAFF, WeaponRarity.COMMON, 8, 280.0,
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0130.png",
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0130.png"  # プレイエリア用のスプライト
	)
	
	weapon_database["magic_staff"] = WeaponData.new(
		"magic_staff", "マジックスタッフ", WeaponType.STAFF, WeaponRarity.RARE, 12, 320.0,
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0131.png",  # 異なるアイコン
		"res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0131.png"  # プレイエリア用の異なるスプライト
	)
	
	_log_debug("✅ Weapon database initialized with %d weapons:" % weapon_database.size())
	for weapon_id in weapon_database:
		var weapon = weapon_database[weapon_id]
		_log_debug("  - %s: %s (Level %d, Type: %s, Rarity: %s)" % [weapon_id, weapon.name, weapon.level, WeaponType.keys()[weapon.weapon_type], WeaponRarity.keys()[weapon.rarity]])

## デフォルト武器装備
func _setup_default_weapons() -> void:
	green_character_weapon = weapon_database["basic_sword"]
	red_character_weapon = weapon_database["basic_staff"]
	
	_log_debug("🗡️ Default weapons equipped:")
	_log_debug("  - Green: %s Level %d" % [green_character_weapon.name, green_character_weapon.level])
	_log_debug("  - Red: %s Level %d" % [red_character_weapon.name, red_character_weapon.level])

## 武器装備
func equip_weapon(character_name: String, weapon_id: String) -> bool:
	_log_debug("🔄 Attempting to equip weapon: %s to %s" % [weapon_id, character_name])
	
	if not weapon_database.has(weapon_id):
		_log_debug("❌ Weapon not found in database: %s" % weapon_id)
		print("[WeaponSystem] ERROR: Weapon not found: %s" % weapon_id)
		return false
	
	var weapon = weapon_database[weapon_id]
	_log_debug("🗡️ Found weapon: %s (%s) Level %d, Type: %s" % [weapon.id, weapon.name, weapon.level, WeaponType.keys()[weapon.weapon_type]])
	
	match character_name:
		"green":
			if weapon.weapon_type == WeaponType.SWORD:
				var old_weapon = green_character_weapon
				green_character_weapon = weapon
				_log_debug("✅ Equipped %s to green character (was: %s)" % [weapon.name, old_weapon.name if old_weapon else "none"])
				_log_debug("🎯 Green weapon change: %s Level %d → %s Level %d" % [old_weapon.name if old_weapon else "none", old_weapon.level if old_weapon else 0, weapon.name, weapon.level])
				weapon_equipped.emit(character_name, weapon)
				return true
			else:
				_log_debug("❌ Invalid weapon type for green character: %s (expected SWORD)" % WeaponType.keys()[weapon.weapon_type])
		"red":
			if weapon.weapon_type == WeaponType.STAFF:
				var old_weapon = red_character_weapon
				red_character_weapon = weapon
				_log_debug("✅ Equipped %s to red character (was: %s)" % [weapon.name, old_weapon.name if old_weapon else "none"])
				_log_debug("🎯 Red weapon change: %s Level %d → %s Level %d" % [old_weapon.name if old_weapon else "none", old_weapon.level if old_weapon else 0, weapon.name, weapon.level])
				weapon_equipped.emit(character_name, weapon)
				return true
			else:
				_log_debug("❌ Invalid weapon type for red character: %s (expected STAFF)" % WeaponType.keys()[weapon.weapon_type])
	
	_log_debug("❌ Weapon equip failed for %s: %s" % [character_name, weapon_id])
	print("[WeaponSystem] ERROR: Invalid weapon type for character: %s" % character_name)
	return false

## 武器強化
func upgrade_weapon(character_name: String) -> bool:
	_log_debug("🔼 Attempting weapon upgrade for character: %s" % character_name)
	
	var weapon: WeaponData = null
	
	match character_name:
		"green":
			weapon = green_character_weapon
		"red":
			weapon = red_character_weapon
	
	if not weapon:
		_log_debug("❌ No weapon found for character: %s" % character_name)
		return false
	
	var cost = weapon.get_upgrade_cost()
	var current_coins = PlayerStats.total_coins
	_log_debug("💰 Current coins: %d, Upgrade cost: %d, Weapon: %s (Level %d)" % [current_coins, cost, weapon.name, weapon.level])
	
	if PlayerStats.spend_coins_no_save(cost):
		var old_level = weapon.level
		weapon.level += 1
		
		_log_debug("⬆️ Weapon upgraded: %s Level %d → %d" % [weapon.name, old_level, weapon.level])
		
		# PlayerStatsに武器レベル変更を通知
		_update_player_stats_weapon_level(weapon.id, weapon.level)
		
		# 武器アップグレード後は確実に復元済み状態とする
		is_levels_restored = true
		_log_debug("🏁 WeaponSystem marked as levels restored (after upgrade)")
		
		# 武器レベル更新後に手動でセーブ実行
		_log_debug("💾 Saving weapon upgrade after level update...")
		SaveManager.save_game()
		_log_debug("✅ Weapon upgrade saved: %s Level %d" % [weapon.name, weapon.level])
		
		weapon_upgraded.emit(character_name, weapon)
		print("[WeaponSystem] ✅ Weapon upgraded: %s Level %d" % [weapon.name, weapon.level])
		return true
	else:
		_log_debug("❌ Insufficient coins for upgrade: %d < %d" % [current_coins, cost])
	
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

## 武器攻撃範囲取得
func get_weapon_attack_range(character_name: String) -> float:
	var weapon = get_character_weapon(character_name)
	if weapon:
		return weapon.get_attack_range()
	return 80.0  # デフォルト値

## 武器スプライトパス取得
func get_weapon_sprite_path(character_name: String) -> String:
	var weapon = get_character_weapon(character_name)
	if weapon:
		return weapon.sprite_path
	return ""

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

## PlayerStatsに武器レベル変更を通知
func _update_player_stats_weapon_level(weapon_id: String, new_level: int) -> void:
	"""WeaponSystemで武器レベルが変更された時にPlayerStatsに反映"""
	if PlayerStats.has_method("update_weapon_system_level"):
		PlayerStats.update_weapon_system_level(weapon_id, new_level)
		_log_debug("Notified PlayerStats of weapon level change: %s -> %d" % [weapon_id, new_level])
	else:
		_log_debug("PlayerStats does not have update_weapon_system_level method")

## テスト用：全武器レベルを上げる
func _debug_level_up_all_weapons() -> void:
	"""デバッグ用：全武器のレベルを上げる"""
	_log_debug("🧪 DEBUG: Leveling up all weapons for testing...")
	
	for weapon_id in weapon_database:
		var weapon = weapon_database[weapon_id]
		var old_level = weapon.level
		weapon.level += 1
		_log_debug("⬆️ DEBUG: %s (%s) Level %d → %d" % [weapon_id, weapon.name, old_level, weapon.level])
	
	_log_debug("✅ DEBUG: All weapons leveled up")

## テスト用：武器レベル表示
func _debug_show_all_weapon_levels() -> void:
	"""デバッグ用：全武器のレベルを表示"""
	_log_debug("📊 DEBUG: Current weapon levels:")
	for weapon_id in weapon_database:
		var weapon = weapon_database[weapon_id]
		var equipped_status = ""
		if green_character_weapon and green_character_weapon.id == weapon_id:
			equipped_status = " [EQUIPPED-GREEN]"
		elif red_character_weapon and red_character_weapon.id == weapon_id:
			equipped_status = " [EQUIPPED-RED]"
		_log_debug("  - %s (%s): Level %d%s" % [weapon_id, weapon.name, weapon.level, equipped_status])

## テスト用：全武器を装備してアップグレード
func _debug_test_all_weapons() -> void:
	"""デバッグ用：全武器を順番に装備してアップグレードテスト"""
	_log_debug("🧪 DEBUG: Testing all weapon equip and upgrade...")
	
	# Green character weapons test
	var green_weapons = get_available_weapons("green")
	_log_debug("🟢 Testing %d green weapons:" % green_weapons.size())
	for weapon in green_weapons:
		_log_debug("  🔄 Testing weapon: %s (Level %d)" % [weapon.id, weapon.level])
		
		# Equip weapon
		var equip_result = equip_weapon("green", weapon.id)
		_log_debug("    Equip result: %s" % equip_result)
		
		# Check current equipped weapon
		var current_weapon = get_character_weapon("green")
		if current_weapon:
			_log_debug("    Currently equipped: %s (Level %d)" % [current_weapon.id, current_weapon.level])
		
		# Upgrade weapon multiple times
		for i in range(3):
			var old_level = current_weapon.level if current_weapon else 0
			PlayerStats.total_coins += 1000  # Ensure enough coins
			var upgrade_result = upgrade_weapon("green")
			var new_level = current_weapon.level if current_weapon else 0
			_log_debug("    Upgrade %d: %s (Level %d → %d)" % [i+1, upgrade_result, old_level, new_level])
	
	# Red character weapons test (if unlocked)
	if PlayerStats.red_character_unlocked:
		var red_weapons = get_available_weapons("red")
		_log_debug("🔴 Testing %d red weapons:" % red_weapons.size())
		for weapon in red_weapons:
			_log_debug("  🔄 Testing weapon: %s (Level %d)" % [weapon.id, weapon.level])
			
			# Equip weapon
			var equip_result = equip_weapon("red", weapon.id)
			_log_debug("    Equip result: %s" % equip_result)
			
			# Check current equipped weapon
			var current_weapon = get_character_weapon("red")
			if current_weapon:
				_log_debug("    Currently equipped: %s (Level %d)" % [current_weapon.id, current_weapon.level])
			
			# Upgrade weapon multiple times
			for i in range(3):
				var old_level = current_weapon.level if current_weapon else 0
				PlayerStats.total_coins += 1000  # Ensure enough coins
				var upgrade_result = upgrade_weapon("red")
				var new_level = current_weapon.level if current_weapon else 0
				_log_debug("    Upgrade %d: %s (Level %d → %d)" % [i+1, upgrade_result, old_level, new_level])
	
	_log_debug("🧪 DEBUG: All weapons test completed")
	_debug_show_all_weapon_levels()

## 保存済み武器レベルの復元
func _restore_saved_weapon_levels() -> void:
	"""PlayerStatsから保存済み武器レベルを復元"""
	_log_debug("🔄 Restoring saved weapon levels...")
	
	if not PlayerStats:
		_log_debug("❌ PlayerStats not available")
		return
	
	var saved_levels = PlayerStats.weapon_system_levels
	if saved_levels.size() == 0:
		_log_debug("📭 No saved weapon levels found - marking as restored (new game)")
		is_levels_restored = true
		return
	
	_log_debug("📊 Found %d saved weapon levels: %s" % [saved_levels.size(), saved_levels])
	
	var restored_count = 0
	for weapon_id in saved_levels:
		var saved_level = saved_levels[weapon_id]
		if weapon_database.has(weapon_id):
			var weapon = weapon_database[weapon_id]
			var old_level = weapon.level
			weapon.level = saved_level
			restored_count += 1
			
			if saved_level > 1:
				_log_debug("🔓 RESTORED: %s (%s) Level %d → %d ⭐" % [weapon_id, weapon.name, old_level, saved_level])
			else:
				_log_debug("🔓 Restored: %s (%s) Level %d → %d (basic)" % [weapon_id, weapon.name, old_level, saved_level])
		else:
			_log_debug("⚠️ Saved weapon %s not found in database" % weapon_id)
	
	_log_debug("✅ Weapon level restoration completed: %d/%d weapons restored" % [restored_count, saved_levels.size()])
	
	# 復元完了フラグを設定
	is_levels_restored = true
	_log_debug("🏁 WeaponSystem marked as levels restored")
	
	# 復元後の状態を表示
	_debug_show_all_weapon_levels()

## デバッグログ
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[WeaponSystem] %s" % message)