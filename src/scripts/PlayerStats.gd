extends Node

## プレイヤーステータス管理クラス（シングルトン）
## レベル・コイン・強化状態を永続的に管理

# レベル関連
var character_level: int = 1
var weapon_level: int = 1
var attack_speed_level: int = 1
var potion_effect_level: int = 1

# コイン関連
var total_coins: int = 0

# ステータス計算
func get_max_hp() -> int:
	"""キャラクターレベルに基づく最大HPを計算"""
	return GameConstants.PLAYER_MAX_HP + (character_level - 1) * GameConstants.HP_PER_CHARACTER_LEVEL

func get_attack_damage() -> int:
	"""武器レベルに基づく攻撃力を計算"""
	return GameConstants.PLAYER_DEFAULT_ATTACK_DAMAGE + (weapon_level - 1) * GameConstants.DAMAGE_PER_WEAPON_LEVEL

func get_attack_interval() -> float:
	"""攻撃速度レベルに基づく攻撃間隔を計算"""
	var interval = GameConstants.BASE_ATTACK_INTERVAL - (attack_speed_level - 1) * GameConstants.ATTACK_SPEED_REDUCTION_PER_LEVEL
	return max(interval, GameConstants.MIN_ATTACK_INTERVAL)

func get_potion_heal_amount() -> int:
	"""ポーション効果レベルに基づく回復量を計算"""
	return GameConstants.HEALTH_POTION_HEAL_AMOUNT + (potion_effect_level - 1) * GameConstants.POTION_HEAL_INCREASE_PER_LEVEL

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
		"total_coins": total_coins
	}

func load_data(data: Dictionary) -> void:
	"""セーブデータから復元"""
	character_level = data.get("character_level", 1)
	weapon_level = data.get("weapon_level", 1)
	attack_speed_level = data.get("attack_speed_level", 1)
	potion_effect_level = data.get("potion_effect_level", 1)
	total_coins = data.get("total_coins", 0)
	_log_debug("Data loaded - Character Lv: %d, Weapon Lv: %d, Attack Speed Lv: %d, Potion Lv: %d, Coins: %d" % [character_level, weapon_level, attack_speed_level, potion_effect_level, total_coins])

# リセット
func reset() -> void:
	"""全データをリセット"""
	character_level = 1
	weapon_level = 1
	attack_speed_level = 1
	potion_effect_level = 1
	total_coins = 0
	_log_debug("Player stats reset to default")

func reset_stats() -> void:
	"""ステータスをリセット（新規ゲーム用）"""
	reset()

func _update_stats() -> void:
	"""ステータス更新（SaveManagerからのロード後に呼び出し）"""
	_log_debug("Stats updated - Character Lv: %d, Weapon Lv: %d, Attack Speed Lv: %d, Potion Lv: %d, Coins: %d" % [character_level, weapon_level, attack_speed_level, potion_effect_level, total_coins])

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[PlayerStats] %s" % message)