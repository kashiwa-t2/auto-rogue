extends Node

## 味方キャラクターステータス管理クラス（シングルトン）
## GreenCharacter(みどりくん) & RedCharacter(あかさん)のレベル・コイン・強化状態を永続管理
## 
## 管理項目:
## - 味方キャラクターのレベル: キャラ・武器・攻撃速度・ポーション効果
## - コイン残高管理（共通）
## - レベルアップコスト計算
## - ステータス値の動的計算

# GreenCharacter (みどりくん) レベル関連
var character_level: int = 1
var weapon_level: int = 1
var attack_speed_level: int = 1
var potion_effect_level: int = 1

# RedCharacter (あかさん) レベル関連
var red_character_unlocked: bool = false
var red_character_level: int = 1
var red_weapon_level: int = 1

# コイン関連
var total_coins: int = 0

# WeaponSystem武器レベル（個別武器データ）
var weapon_system_levels: Dictionary = {}

# ステータス計算
func get_max_hp() -> int:
	"""GreenCharacter(みどりくん)レベルに基づく最大HPを計算"""
	return GameConstants.PLAYER_MAX_HP + (character_level - 1) * GameConstants.HP_PER_CHARACTER_LEVEL

func get_attack_damage() -> int:
	"""GreenCharacter(みどりくん)武器レベルに基づく攻撃力を計算"""
	# WeaponSystemが利用可能な場合はそちらを使用、フォールバック用に従来計算も保持
	var weapon_system = _get_weapon_system()
	if weapon_system:
		return weapon_system.get_weapon_damage("green")
	return GameConstants.PLAYER_DEFAULT_ATTACK_DAMAGE + (weapon_level - 1) * GameConstants.DAMAGE_PER_WEAPON_LEVEL

func get_attack_interval() -> float:
	"""GreenCharacter(みどりくん)攻撃速度レベルに基づく攻撃間隔を計算"""
	var interval = GameConstants.BASE_ATTACK_INTERVAL - (attack_speed_level - 1) * GameConstants.ATTACK_SPEED_REDUCTION_PER_LEVEL
	return max(interval, GameConstants.MIN_ATTACK_INTERVAL)

func get_potion_heal_amount() -> int:
	"""GreenCharacter(みどりくん)ポーション効果レベルに基づく回復量を計算"""
	return GameConstants.HEALTH_POTION_HEAL_AMOUNT + (potion_effect_level - 1) * GameConstants.POTION_HEAL_INCREASE_PER_LEVEL

# あかさんステータス計算
func get_red_character_max_hp() -> int:
	"""RedCharacter(あかさん)のレベルに基づく最大HPを計算"""
	return 50 + (red_character_level - 1) * 20  # 初期HP50、レベルごとに20増加

func get_red_character_attack_damage() -> int:
	"""RedCharacter(あかさん)の武器レベルに基づく攻撃力を計算"""
	# WeaponSystemが利用可能な場合はそちらを使用、フォールバック用に従来計算も保持
	var weapon_system = _get_weapon_system()
	if weapon_system:
		return weapon_system.get_weapon_damage("red")
	return 10 + (red_weapon_level - 1) * 3  # 初期ダメージ10、レベルごとに3増加

func get_red_character_attack_range() -> float:
	"""RedCharacter(あかさん)の攻撃範囲を取得"""
	return 300.0  # 固定攻撃範囲300px

# レベルアップコスト計算
func get_character_level_up_cost() -> int:
	"""キャラクターレベルアップに必要なコイン数"""
	return GameConstants.BASE_CHARACTER_LEVEL_UP_COST * character_level

func get_weapon_level_up_cost() -> int:
	"""武器レベルアップに必要なコイン数"""
	return GameConstants.BASE_WEAPON_LEVEL_UP_COST * weapon_level

func get_attack_speed_level_up_cost() -> int:
	"""攻撃速度レベルアップに必要なコイン数"""
	return GameConstants.BASE_ATTACK_SPEED_LEVEL_UP_COST * attack_speed_level

func get_potion_effect_level_up_cost() -> int:
	"""ポーション効果レベルアップに必要なコイン数"""
	return GameConstants.BASE_POTION_LEVEL_UP_COST * potion_effect_level

# あかさんレベルアップコスト計算
func get_red_character_unlock_cost() -> int:
	"""あかさん解放に必要なコイン数"""
	return 1000

func get_red_character_level_up_cost() -> int:
	"""あかさんレベルアップに必要なコイン数"""
	return 15 * red_character_level  # 基本コスト15

func get_red_weapon_level_up_cost() -> int:
	"""あかさんの武器レベルアップに必要なコイン数"""
	return 12 * red_weapon_level  # 基本コスト12

# レベルアップ処理
func level_up_character() -> bool:
	"""キャラクターをレベルアップ（成功時true）"""
	var cost = get_character_level_up_cost()
	if total_coins >= cost:
		total_coins -= cost
		character_level += 1
		_log_debug("Character leveled up to %d! Cost: %d coins" % [character_level, cost])
		# コイン消費時にオートセーブ実行
		SaveManager.autosave()
		return true
	return false

func level_up_weapon() -> bool:
	"""武器をレベルアップ（成功時true）"""
	var cost = get_weapon_level_up_cost()
	if total_coins >= cost:
		total_coins -= cost
		weapon_level += 1
		_log_debug("Weapon leveled up to %d! Cost: %d coins" % [weapon_level, cost])
		# コイン消費時にオートセーブ実行
		SaveManager.autosave()
		return true
	return false

func level_up_attack_speed() -> bool:
	"""攻撃速度をレベルアップ（成功時true）"""
	var cost = get_attack_speed_level_up_cost()
	if total_coins >= cost:
		total_coins -= cost
		attack_speed_level += 1
		_log_debug("Attack speed leveled up to %d! Cost: %d coins" % [attack_speed_level, cost])
		# コイン消費時にオートセーブ実行
		SaveManager.autosave()
		return true
	return false

func level_up_potion_effect() -> bool:
	"""ポーション効果をレベルアップ（成功時true）"""
	var cost = get_potion_effect_level_up_cost()
	if total_coins >= cost:
		total_coins -= cost
		potion_effect_level += 1
		_log_debug("Potion effect leveled up to %d! Cost: %d coins" % [potion_effect_level, cost])
		# コイン消費時にオートセーブ実行
		SaveManager.autosave()
		return true
	return false

# あかさんレベルアップ処理
func unlock_red_character() -> bool:
	"""あかさんを解放（成功時true）"""
	if red_character_unlocked:
		return false  # 既に解放済み
	
	var cost = get_red_character_unlock_cost()
	if total_coins >= cost:
		total_coins -= cost
		red_character_unlocked = true
		_log_debug("Red character unlocked! Cost: %d coins" % cost)
		# コイン消費時にオートセーブ実行
		SaveManager.autosave()
		return true
	return false

func level_up_red_character() -> bool:
	"""あかさんをレベルアップ（成功時true）"""
	if not red_character_unlocked:
		return false
		
	var cost = get_red_character_level_up_cost()
	if total_coins >= cost:
		total_coins -= cost
		red_character_level += 1
		_log_debug("Red character leveled up to %d! Cost: %d coins" % [red_character_level, cost])
		# コイン消費時にオートセーブ実行
		SaveManager.autosave()
		return true
	return false

func level_up_red_weapon() -> bool:
	"""あかさんの武器をレベルアップ（成功時true）"""
	if not red_character_unlocked:
		return false
		
	var cost = get_red_weapon_level_up_cost()
	if total_coins >= cost:
		total_coins -= cost
		red_weapon_level += 1
		_log_debug("Red weapon leveled up to %d! Cost: %d coins" % [red_weapon_level, cost])
		# コイン消費時にオートセーブ実行
		SaveManager.autosave()
		return true
	return false

# コイン管理
func add_coins(amount: int) -> void:
	"""コインを追加"""
	total_coins += amount
	_log_debug("Added %d coins. Total: %d" % [amount, total_coins])

func spend_coins(amount: int) -> bool:
	"""コインを消費（成功時true）"""
	if total_coins >= amount:
		total_coins -= amount
		_log_debug("Spent %d coins. Remaining: %d" % [amount, total_coins])
		# コイン消費時にオートセーブ実行
		SaveManager.autosave()
		return true
	return false

# データ保存/読み込み
func save_data() -> Dictionary:
	"""セーブデータを辞書形式で返す"""
	_log_debug("💾 Preparing save data...")
	
	# Pre-save verification
	_log_debug("🔍 Pre-save weapon levels verification:")
	_debug_verify_weapon_levels()
	
	# WeaponSystemから最新の武器レベルを取得して同期
	_log_debug("🔄 Syncing weapon levels from WeaponSystem before save...")
	_sync_weapon_levels_from_weapon_system()
	
	# Post-sync verification
	_log_debug("🔍 Post-sync weapon levels verification:")
	_debug_verify_weapon_levels()
	
	var save_dict = {
		"character_level": character_level,
		"weapon_level": weapon_level,
		"attack_speed_level": attack_speed_level,
		"potion_effect_level": potion_effect_level,
		"total_coins": total_coins,
		"red_character_unlocked": red_character_unlocked,
		"red_character_level": red_character_level,
		"red_weapon_level": red_weapon_level,
		"weapon_system_levels": weapon_system_levels
	}
	
	_log_debug("📊 Save data prepared:")
	_log_debug("  - Character Level: %d" % character_level)
	_log_debug("  - Legacy Weapon Level: %d" % weapon_level)
	_log_debug("  - Legacy Red Weapon Level: %d" % red_weapon_level)
	_log_debug("  - Total Coins: %d" % total_coins)
	_log_debug("  - Red Character Unlocked: %s" % red_character_unlocked)
	_log_debug("  - Weapon System Levels (%d weapons): %s" % [weapon_system_levels.size(), weapon_system_levels])
	
	# Final verification of what will be saved
	_log_debug("📋 FINAL: Weapon levels that will be saved:")
	for weapon_id in weapon_system_levels:
		var level = weapon_system_levels[weapon_id]
		var status = "⭐ UPGRADED" if level > 1 else "🔹 BASIC"
		_log_debug("  - %s: Level %d %s" % [weapon_id, level, status])
	
	return save_dict

func load_data(data: Dictionary) -> void:
	"""セーブデータから復元"""
	_log_debug("📂 PlayerStats.load_data() called")
	_log_debug("🔍 Input data keys: %s" % data.keys())
	
	character_level = data.get("character_level", 1)
	weapon_level = data.get("weapon_level", 1)
	attack_speed_level = data.get("attack_speed_level", 1)
	potion_effect_level = data.get("potion_effect_level", 1)
	total_coins = data.get("total_coins", 0)
	red_character_unlocked = data.get("red_character_unlocked", false)
	red_character_level = data.get("red_character_level", 1)
	red_weapon_level = data.get("red_weapon_level", 1)
	
	# weapon_system_levelsの復元
	var loaded_weapon_levels = data.get("weapon_system_levels", {})
	weapon_system_levels = loaded_weapon_levels
	_log_debug("📊 Loaded weapon_system_levels: %s" % weapon_system_levels)
	
	# Detailed logging of loaded weapon levels
	_log_debug("📋 LOADED: Weapon levels from save data:")
	for weapon_id in weapon_system_levels:
		var level = weapon_system_levels[weapon_id]
		var status = "⭐ UPGRADED" if level > 1 else "🔹 BASIC"
		_log_debug("  - %s: Level %d %s" % [weapon_id, level, status])
	
	# WeaponSystemに武器レベルを復元（WeaponSystemが初期化された後にWeaponUI側で実行される）
	_log_debug("⏳ Weapon level sync will be performed later when WeaponSystem is ready")
	
	_log_debug("✅ Data loaded - Character Lv: %d, Weapon Lv: %d, Attack Speed Lv: %d, Potion Lv: %d, Red Unlocked: %s, Red Lv: %d, Red Weapon Lv: %d, Coins: %d, Weapon System Levels: %d件" % [character_level, weapon_level, attack_speed_level, potion_effect_level, red_character_unlocked, red_character_level, red_weapon_level, total_coins, weapon_system_levels.size()])

# リセット
func reset() -> void:
	"""全データをリセット"""
	character_level = 1
	weapon_level = 1
	attack_speed_level = 1
	potion_effect_level = 1
	total_coins = 0
	red_character_unlocked = false
	red_character_level = 1
	red_weapon_level = 1
	weapon_system_levels.clear()
	_log_debug("Player stats reset to default (including weapon system levels)")

func reset_stats() -> void:
	"""ステータスをリセット（新規ゲーム用）"""
	reset()

func _update_stats() -> void:
	"""ステータス更新（SaveManagerからのロード後に呼び出し）"""
	_log_debug("Stats updated - Character Lv: %d, Weapon Lv: %d, Attack Speed Lv: %d, Potion Lv: %d, Coins: %d" % [character_level, weapon_level, attack_speed_level, potion_effect_level, total_coins])

## WeaponSystem取得ヘルパー
func _get_weapon_system() -> WeaponSystem:
	"""WeaponSystemインスタンスを取得"""
	# MainSceneのWeaponUIからWeaponSystemを取得
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_weapon_system"):
		return main_scene.get_weapon_system()
	
	# WeaponUIから直接取得を試行
	var weapon_ui_nodes = get_tree().get_nodes_in_group("weapon_ui")
	for node in weapon_ui_nodes:
		if node.has_method("get_weapon_system"):
			return node.get_weapon_system()
	
	return null

## WeaponSystemとの統合メソッド
func sync_weapon_levels_to_weapon_system() -> void:
	"""従来の武器レベルをWeaponSystemに同期（公開メソッド）"""
	_sync_weapon_levels_to_weapon_system()

func _sync_weapon_levels_to_weapon_system() -> void:
	"""PlayerStatsからWeaponSystemに武器レベルを復元"""
	_log_debug("🔄 Starting weapon level sync to WeaponSystem...")
	_log_debug("📊 Current weapon_system_levels: %s" % weapon_system_levels)
	
	var weapon_system = _get_weapon_system()
	if not weapon_system:
		_log_debug("❌ WeaponSystem not available for level sync")
		return
	
	_log_debug("✅ WeaponSystem found: %s" % weapon_system)
	_log_debug("🔄 Syncing weapon levels to WeaponSystem from saved data: %s" % weapon_system_levels)
	
	# WeaponSystemの現在の状態をログ出力
	if weapon_system.weapon_database:
		_log_debug("🗃️ WeaponSystem database contains %d weapons" % weapon_system.weapon_database.size())
		for weapon_id in weapon_system.weapon_database:
			var weapon = weapon_system.weapon_database[weapon_id]
			_log_debug("  - %s: Level %d" % [weapon_id, weapon.level])
	else:
		_log_debug("❌ WeaponSystem database is null or empty")
	
	# 保存されたWeaponSystemレベルデータを復元
	var restored_count = 0
	_log_debug("📊 Attempting to restore %d weapon levels from saved data:" % weapon_system_levels.size())
	for weapon_id in weapon_system_levels:
		var level = weapon_system_levels[weapon_id]
		_log_debug("🔄 Processing %s: saved level %d" % [weapon_id, level])
		
		# WeaponSystemの武器データベースから武器を検索
		if weapon_system.weapon_database.has(weapon_id):
			var old_level = weapon_system.weapon_database[weapon_id].level
			var weapon_name = weapon_system.weapon_database[weapon_id].name
			weapon_system.weapon_database[weapon_id].level = level
			
			if level > 1:
				_log_debug("🔓 RESTORED weapon %s (%s): Level %d → %d ⭐" % [weapon_id, weapon_name, old_level, level])
			else:
				_log_debug("🔓 Restored weapon %s (%s): Level %d → %d (basic level)" % [weapon_id, weapon_name, old_level, level])
			restored_count += 1
		else:
			_log_debug("⚠️ Weapon %s not found in database" % weapon_id)
	
	_log_debug("📈 Successfully restored %d/%d weapon levels" % [restored_count, weapon_system_levels.size()])
	
	# データベース内で復元されなかった武器があるかチェック
	_log_debug("🔍 Checking for weapons not in saved data:")
	for weapon_id in weapon_system.weapon_database:
		if not weapon_system_levels.has(weapon_id):
			var weapon = weapon_system.weapon_database[weapon_id]
			_log_debug("⚠️ Weapon %s (%s) was not in saved data, using default level %d" % [weapon_id, weapon.name, weapon.level])
	
	# フォールバック: 従来の武器レベルも同期（後方互換性のため）
	var green_weapon = weapon_system.get_character_weapon("green")
	if green_weapon:
		_log_debug("🟢 Green weapon before sync: %s Level %d" % [green_weapon.name, green_weapon.level])
		
		# weapon_system_levelsに該当武器の情報がない場合は従来のレベルを使用
		if not weapon_system_levels.has(green_weapon.id):
			_log_debug("🔄 Using legacy weapon_level for %s: %d" % [green_weapon.id, weapon_level])
			green_weapon.level = weapon_level
			weapon_system_levels[green_weapon.id] = weapon_level  # 次回のセーブのため
		elif green_weapon.level != weapon_level and weapon_level > green_weapon.level:
			# 従来のレベルの方が高い場合は従来を採用（データ整合性確保）
			_log_debug("🔄 Legacy weapon_level is higher, using: %d" % weapon_level)
			green_weapon.level = weapon_level
			weapon_system_levels[green_weapon.id] = weapon_level
	else:
		_log_debug("❌ Green weapon not found")
	
	# あかさんの武器レベルを同期
	if red_character_unlocked:
		var red_weapon = weapon_system.get_character_weapon("red")
		if red_weapon:
			_log_debug("🔴 Red weapon before sync: %s Level %d" % [red_weapon.name, red_weapon.level])
			
			# weapon_system_levelsに該当武器の情報がない場合は従来のレベルを使用
			if not weapon_system_levels.has(red_weapon.id):
				_log_debug("🔄 Using legacy red_weapon_level for %s: %d" % [red_weapon.id, red_weapon_level])
				red_weapon.level = red_weapon_level
				weapon_system_levels[red_weapon.id] = red_weapon_level  # 次回のセーブのため
			elif red_weapon.level != red_weapon_level and red_weapon_level > red_weapon.level:
				# 従来のレベルの方が高い場合は従来を採用（データ整合性確保）
				_log_debug("🔄 Legacy red_weapon_level is higher, using: %d" % red_weapon_level)
				red_weapon.level = red_weapon_level
				weapon_system_levels[red_weapon.id] = red_weapon_level
		else:
			_log_debug("❌ Red weapon not found")
	
	# 同期後の状態を確認
	_log_debug("🔍 After sync - Current equipped weapons:")
	if green_weapon:
		_log_debug("  - Green: %s Level %d" % [green_weapon.name, green_weapon.level])
	if red_character_unlocked and weapon_system.get_character_weapon("red"):
		var red_weapon = weapon_system.get_character_weapon("red")
		_log_debug("  - Red: %s Level %d" % [red_weapon.name, red_weapon.level])
	
	_log_debug("✅ Weapon level sync to WeaponSystem completed")
	
	# Post-sync verification
	_log_debug("🔍 Post-sync verification:")
	_debug_verify_weapon_levels()

func _sync_weapon_levels_from_weapon_system() -> void:
	"""WeaponSystemからPlayerStatsに武器レベルを保存"""
	var weapon_system = _get_weapon_system()
	if not weapon_system:
		_log_debug("❌ WeaponSystem not available for level extraction")
		return
	
	_log_debug("🔄 Extracting weapon levels from WeaponSystem...")
	_log_debug("🗃️ WeaponSystem database contains %d weapons" % weapon_system.weapon_database.size())
	
	# 現在装備されている武器を確認
	var green_equipped = weapon_system.get_character_weapon("green")
	var red_equipped = weapon_system.get_character_weapon("red")
	if green_equipped:
		_log_debug("🟢 Currently equipped Green weapon: %s Level %d" % [green_equipped.name, green_equipped.level])
	if red_equipped:
		_log_debug("🔴 Currently equipped Red weapon: %s Level %d" % [red_equipped.name, red_equipped.level])
	
	# WeaponSystemの全武器レベルを取得
	weapon_system_levels.clear()
	_log_debug("📊 Extracting levels from ALL weapons in database:")
	for weapon_id in weapon_system.weapon_database:
		var weapon = weapon_system.weapon_database[weapon_id]
		weapon_system_levels[weapon_id] = weapon.level
		var equipped_status = ""
		if green_equipped and green_equipped.id == weapon_id:
			equipped_status = " [EQUIPPED-GREEN]"
		elif red_equipped and red_equipped.id == weapon_id:
			equipped_status = " [EQUIPPED-RED]"
		_log_debug("💾 Saved weapon %s (%s) level %d%s" % [weapon_id, weapon.name, weapon.level, equipped_status])
	
	_log_debug("✅ Extracted %d weapon levels for saving:" % weapon_system_levels.size())
	_log_debug("📋 Complete weapon_system_levels: %s" % weapon_system_levels)

## WeaponSystemからの武器レベル更新
func update_weapon_system_level(weapon_id: String, new_level: int) -> void:
	"""WeaponSystemから通知された武器レベル変更を記録"""
	var old_level = weapon_system_levels.get(weapon_id, 1)
	weapon_system_levels[weapon_id] = new_level
	_log_debug("🔔 WeaponSystem notification: %s Level %d → %d" % [weapon_id, old_level, new_level])
	_log_debug("📊 Current weapon_system_levels: %s" % weapon_system_levels)

## 公開メソッド：武器レベル修復
func fix_weapon_levels() -> void:
	"""武器レベルの問題を修復（公開メソッド）"""
	_log_debug("🔧 === MANUAL WEAPON LEVEL FIX REQUESTED ===")
	_debug_verify_weapon_levels()
	_debug_force_sync_all_weapons()
	_log_debug("✅ === MANUAL WEAPON LEVEL FIX COMPLETED ===")

## 公開メソッド：武器レベル状態表示
func debug_weapon_levels() -> void:
	"""現在の武器レベル状態をログ出力（公開メソッド）"""
	_debug_verify_weapon_levels()

## デバッグ：武器レベル検証
func _debug_verify_weapon_levels() -> void:
	"""デバッグ用：現在の武器レベル状態を詳細検証"""
	_log_debug("🔍 === WEAPON LEVELS VERIFICATION ===")
	
	var weapon_system = _get_weapon_system()
	if not weapon_system:
		_log_debug("❌ WeaponSystem not available for verification")
		return
	
	_log_debug("📊 PlayerStats.weapon_system_levels: %s" % weapon_system_levels)
	_log_debug("🗃️ WeaponSystem database (%d weapons):" % weapon_system.weapon_database.size())
	
	for weapon_id in weapon_system.weapon_database:
		var weapon = weapon_system.weapon_database[weapon_id]
		var stored_level = weapon_system_levels.get(weapon_id, -1)
		var match_status = "✅" if weapon.level == stored_level else "❌ MISMATCH"
		_log_debug("  - %s (%s): DB Level %d, Stored Level %d %s" % [
			weapon_id, weapon.name, weapon.level, stored_level, match_status
		])
	
	# Check for orphaned entries in weapon_system_levels
	_log_debug("🔍 Checking for orphaned entries:")
	for weapon_id in weapon_system_levels:
		if not weapon_system.weapon_database.has(weapon_id):
			_log_debug("  - ⚠️ ORPHAN: %s Level %d (not in database)" % [weapon_id, weapon_system_levels[weapon_id]])
	
	_log_debug("🔍 === VERIFICATION COMPLETED ===")

## デバッグ：武器レベル強制同期
func _debug_force_sync_all_weapons() -> void:
	"""デバッグ用：全武器レベルを強制的に同期"""
	_log_debug("🔧 === FORCE SYNCING ALL WEAPONS ===")
	
	var weapon_system = _get_weapon_system()
	if not weapon_system:
		_log_debug("❌ WeaponSystem not available for force sync")
		return
	
	# Clear and rebuild weapon_system_levels
	weapon_system_levels.clear()
	
	_log_debug("🔄 Force syncing all weapons from database:")
	for weapon_id in weapon_system.weapon_database:
		var weapon = weapon_system.weapon_database[weapon_id]
		weapon_system_levels[weapon_id] = weapon.level
		_log_debug("  - %s: Level %d → stored" % [weapon_id, weapon.level])
	
	_log_debug("✅ Force sync completed. weapon_system_levels: %s" % weapon_system_levels)
	
	# Immediately save after force sync
	_log_debug("💾 Saving after force sync...")
	SaveManager.save_game()
	_log_debug("✅ Save completed after force sync")

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[PlayerStats] %s" % message)