extends Node

## プレイヤーステータス管理クラス（シングルトン）
## レベル・コイン・強化状態を永続的に管理

# レベル関連
var character_level: int = 1
var weapon_level: int = 1

# コイン関連
var total_coins: int = 0

# ステータス計算
func get_max_hp() -> int:
	"""キャラクターレベルに基づく最大HPを計算"""
	return GameConstants.PLAYER_MAX_HP + (character_level - 1) * GameConstants.HP_PER_CHARACTER_LEVEL

func get_attack_damage() -> int:
	"""武器レベルに基づく攻撃力を計算"""
	return GameConstants.PLAYER_DEFAULT_ATTACK_DAMAGE + (weapon_level - 1) * GameConstants.DAMAGE_PER_WEAPON_LEVEL

# レベルアップコスト計算
func get_character_level_up_cost() -> int:
	"""キャラクターレベルアップに必要なコイン数"""
	return GameConstants.BASE_CHARACTER_LEVEL_UP_COST * character_level

func get_weapon_level_up_cost() -> int:
	"""武器レベルアップに必要なコイン数"""
	return GameConstants.BASE_WEAPON_LEVEL_UP_COST * weapon_level

# レベルアップ処理
func level_up_character() -> bool:
	"""キャラクターをレベルアップ（成功時true）"""
	var cost = get_character_level_up_cost()
	if total_coins >= cost:
		total_coins -= cost
		character_level += 1
		_log_debug("Character leveled up to %d! Cost: %d coins" % [character_level, cost])
		return true
	return false

func level_up_weapon() -> bool:
	"""武器をレベルアップ（成功時true）"""
	var cost = get_weapon_level_up_cost()
	if total_coins >= cost:
		total_coins -= cost
		weapon_level += 1
		_log_debug("Weapon leveled up to %d! Cost: %d coins" % [weapon_level, cost])
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
		return true
	return false

# データ保存/読み込み
func save_data() -> Dictionary:
	"""セーブデータを辞書形式で返す"""
	return {
		"character_level": character_level,
		"weapon_level": weapon_level,
		"total_coins": total_coins
	}

func load_data(data: Dictionary) -> void:
	"""セーブデータから復元"""
	character_level = data.get("character_level", 1)
	weapon_level = data.get("weapon_level", 1)
	total_coins = data.get("total_coins", 0)
	_log_debug("Data loaded - Character Lv: %d, Weapon Lv: %d, Coins: %d" % [character_level, weapon_level, total_coins])

# リセット
func reset() -> void:
	"""全データをリセット"""
	character_level = 1
	weapon_level = 1
	total_coins = 0
	_log_debug("Player stats reset to default")

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[PlayerStats] %s" % message)