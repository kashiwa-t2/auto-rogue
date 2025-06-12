extends Control
class_name UpgradeUI

## 育成画面UIクラス
## キャラクターと武器のレベルアップを管理

@onready var character_panel: Control = $UpgradeContainer/CharacterUpgrade
@onready var weapon_panel: Control = $UpgradeContainer/WeaponUpgrade

# キャラクター関連
@onready var character_level_label: Label = $UpgradeContainer/CharacterUpgrade/InfoContainer/LevelLabel
@onready var character_hp_label: Label = $UpgradeContainer/CharacterUpgrade/InfoContainer/HPLabel
@onready var character_cost_label: Label = $UpgradeContainer/CharacterUpgrade/CostContainer/CostLabel
@onready var character_upgrade_button: Button = $UpgradeContainer/CharacterUpgrade/UpgradeButton

# 武器関連
@onready var weapon_level_label: Label = $UpgradeContainer/WeaponUpgrade/InfoContainer/LevelLabel
@onready var weapon_damage_label: Label = $UpgradeContainer/WeaponUpgrade/InfoContainer/DamageLabel
@onready var weapon_cost_label: Label = $UpgradeContainer/WeaponUpgrade/CostContainer/CostLabel
@onready var weapon_upgrade_button: Button = $UpgradeContainer/WeaponUpgrade/UpgradeButton

# コイン表示
@onready var coin_label: Label = $CoinDisplay/CoinLabel

signal upgrade_completed()

func _ready():
	_connect_signals()
	update_display()
	_log_debug("UpgradeUI initialized")

func _connect_signals() -> void:
	"""シグナルの接続"""
	if character_upgrade_button:
		character_upgrade_button.pressed.connect(_on_character_upgrade_pressed)
	if weapon_upgrade_button:
		weapon_upgrade_button.pressed.connect(_on_weapon_upgrade_pressed)

func update_display() -> void:
	"""表示を更新"""
	# キャラクター情報
	if character_level_label:
		character_level_label.text = "レベル %d" % PlayerStats.character_level
	if character_hp_label:
		character_hp_label.text = "HP: %d → %d" % [
			PlayerStats.get_max_hp(),
			PlayerStats.get_max_hp() + GameConstants.HP_PER_CHARACTER_LEVEL
		]
	if character_cost_label:
		character_cost_label.text = "%d" % PlayerStats.get_character_level_up_cost()
	
	# 武器情報
	if weapon_level_label:
		weapon_level_label.text = "レベル %d" % PlayerStats.weapon_level
	if weapon_damage_label:
		weapon_damage_label.text = "攻撃力: %d → %d" % [
			PlayerStats.get_attack_damage(),
			PlayerStats.get_attack_damage() + GameConstants.DAMAGE_PER_WEAPON_LEVEL
		]
	if weapon_cost_label:
		weapon_cost_label.text = "%d" % PlayerStats.get_weapon_level_up_cost()
	
	# コイン表示
	if coin_label:
		coin_label.text = "%d" % PlayerStats.total_coins
	
	# ボタンの有効/無効
	_update_button_states()
	
	_log_debug("Display updated - Character Lv: %d, Weapon Lv: %d, Coins: %d" % 
		[PlayerStats.character_level, PlayerStats.weapon_level, PlayerStats.total_coins])

func _update_button_states() -> void:
	"""ボタンの有効/無効状態を更新"""
	if character_upgrade_button:
		character_upgrade_button.disabled = PlayerStats.total_coins < PlayerStats.get_character_level_up_cost()
		if character_upgrade_button.disabled:
			character_upgrade_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			character_upgrade_button.modulate = Color.WHITE
	
	if weapon_upgrade_button:
		weapon_upgrade_button.disabled = PlayerStats.total_coins < PlayerStats.get_weapon_level_up_cost()
		if weapon_upgrade_button.disabled:
			weapon_upgrade_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			weapon_upgrade_button.modulate = Color.WHITE

func _on_character_upgrade_pressed() -> void:
	"""キャラクターレベルアップボタン押下"""
	if PlayerStats.level_up_character():
		_play_upgrade_animation(character_panel)
		update_display()
		upgrade_completed.emit()
		_log_debug("Character upgraded to level %d" % PlayerStats.character_level)
	else:
		_play_error_animation(character_upgrade_button)
		_log_debug("Character upgrade failed - insufficient coins")

func _on_weapon_upgrade_pressed() -> void:
	"""武器レベルアップボタン押下"""
	if PlayerStats.level_up_weapon():
		_play_upgrade_animation(weapon_panel)
		update_display()
		upgrade_completed.emit()
		_log_debug("Weapon upgraded to level %d" % PlayerStats.weapon_level)
	else:
		_play_error_animation(weapon_upgrade_button)
		_log_debug("Weapon upgrade failed - insufficient coins")

func _play_upgrade_animation(panel: Control) -> void:
	"""レベルアップ成功アニメーション"""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	
	# スケールアニメーション
	var original_scale = panel.scale
	tween.tween_property(panel, "scale", original_scale * 1.1, 0.2)
	tween.tween_property(panel, "scale", original_scale, 0.3)
	
	# フラッシュ効果
	var flash_tween = create_tween()
	flash_tween.set_parallel(true)
	flash_tween.tween_property(panel, "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.1)
	flash_tween.tween_property(panel, "modulate", Color.WHITE, 0.4)

func _play_error_animation(button: Button) -> void:
	"""エラーアニメーション（コイン不足）"""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	
	# 横揺れアニメーション
	var original_pos = button.position
	for i in range(3):
		tween.tween_property(button, "position:x", original_pos.x + 5, 0.05)
		tween.tween_property(button, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(button, "position", original_pos, 0.05)

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[UpgradeUI] %s" % message)