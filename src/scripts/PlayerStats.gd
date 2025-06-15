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
	return {
		"character_level": character_level,
		"weapon_level": weapon_level,
		"attack_speed_level": attack_speed_level,
		"potion_effect_level": potion_effect_level,
		"total_coins": total_coins,
		"red_character_unlocked": red_character_unlocked,
		"red_character_level": red_character_level,
		"red_weapon_level": red_weapon_level
	}

func load_data(data: Dictionary) -> void:
	"""セーブデータから復元"""
	character_level = data.get("character_level", 1)
	weapon_level = data.get("weapon_level", 1)
	attack_speed_level = data.get("attack_speed_level", 1)
	potion_effect_level = data.get("potion_effect_level", 1)
	total_coins = data.get("total_coins", 0)
	red_character_unlocked = data.get("red_character_unlocked", false)
	red_character_level = data.get("red_character_level", 1)
	red_weapon_level = data.get("red_weapon_level", 1)
	_log_debug("Data loaded - Character Lv: %d, Weapon Lv: %d, Attack Speed Lv: %d, Potion Lv: %d, Red Unlocked: %s, Red Lv: %d, Red Weapon Lv: %d, Coins: %d" % [character_level, weapon_level, attack_speed_level, potion_effect_level, red_character_unlocked, red_character_level, red_weapon_level, total_coins])

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
	_log_debug("Player stats reset to default")

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
	"""従来の武器レベルをWeaponSystemに同期"""
	var weapon_system = _get_weapon_system()
	if not weapon_system:
		return
	
	# みどりくんの武器レベルを同期
	var green_weapon = weapon_system.get_character_weapon("green")
	if green_weapon and green_weapon.level != weapon_level:
		green_weapon.level = weapon_level
		_log_debug("Green weapon level synced to: %d" % weapon_level)
	
	# あかさんの武器レベルを同期
	if red_character_unlocked:
		var red_weapon = weapon_system.get_character_weapon("red")
		if red_weapon and red_weapon.level != red_weapon_level:
			red_weapon.level = red_weapon_level
			_log_debug("Red weapon level synced to: %d" % red_weapon_level)

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[PlayerStats] %s" % message)