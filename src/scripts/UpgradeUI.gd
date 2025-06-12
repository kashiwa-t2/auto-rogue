extends Control
class_name UpgradeUI

## 育成画面UIクラス
## キャラクターと武器のレベルアップを管理

@onready var character_panel: Control = $UpgradeContainer/CharacterUpgrade
@onready var weapon_panel: Control = $UpgradeContainer/WeaponUpgrade
@onready var attack_speed_panel: Control = $UpgradeContainer/AttackSpeedUpgrade
@onready var potion_effect_panel: Control = $UpgradeContainer/PotionEffectUpgrade

# キャラクター関連
@onready var character_level_label: Label = $UpgradeContainer/CharacterUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var character_hp_label: Label = $UpgradeContainer/CharacterUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var character_cost_label: Label = $UpgradeContainer/CharacterUpgrade/MainContainer/CostContainer/CostLabel
@onready var character_upgrade_button: Button = $UpgradeContainer/CharacterUpgrade/MainContainer/UpgradeButton

# 武器関連
@onready var weapon_level_label: Label = $UpgradeContainer/WeaponUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var weapon_damage_label: Label = $UpgradeContainer/WeaponUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var weapon_cost_label: Label = $UpgradeContainer/WeaponUpgrade/MainContainer/CostContainer/CostLabel
@onready var weapon_upgrade_button: Button = $UpgradeContainer/WeaponUpgrade/MainContainer/UpgradeButton

# 攻撃速度関連
@onready var attack_speed_level_label: Label = $UpgradeContainer/AttackSpeedUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var attack_speed_interval_label: Label = $UpgradeContainer/AttackSpeedUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var attack_speed_cost_label: Label = $UpgradeContainer/AttackSpeedUpgrade/MainContainer/CostContainer/CostLabel
@onready var attack_speed_upgrade_button: Button = $UpgradeContainer/AttackSpeedUpgrade/MainContainer/UpgradeButton

# ポーション効果関連
@onready var potion_effect_level_label: Label = $UpgradeContainer/PotionEffectUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var potion_effect_heal_label: Label = $UpgradeContainer/PotionEffectUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var potion_effect_cost_label: Label = $UpgradeContainer/PotionEffectUpgrade/MainContainer/CostContainer/CostLabel
@onready var potion_effect_upgrade_button: Button = $UpgradeContainer/PotionEffectUpgrade/MainContainer/UpgradeButton

# コイン表示
@onready var coin_label: Label = $CoinDisplay/CoinLabel

signal upgrade_completed()

func _ready():
	_setup_panels()
	_connect_signals()
	update_display()
	_log_debug("UpgradeUI initialized")

func _setup_panels() -> void:
	"""各パネルの初期設定"""
	# キャラクターパネル
	if character_panel:
		var title_label = character_panel.get_node("MainContainer/Title")
		title_label.text = "キャラクター"
		title_label.modulate = Color(0.8, 1, 0.8, 1)
	
	# 武器パネル
	if weapon_panel:
		var title_label = weapon_panel.get_node("MainContainer/Title")
		title_label.text = "武器"
		title_label.modulate = Color(1, 0.8, 0.8, 1)
	
	# 攻撃速度パネル
	if attack_speed_panel:
		var title_label = attack_speed_panel.get_node("MainContainer/Title")
		title_label.text = "攻撃速度"
		title_label.modulate = Color(0.8, 0.8, 1, 1)
	
	# ポーション効果パネル
	if potion_effect_panel:
		var title_label = potion_effect_panel.get_node("MainContainer/Title")
		title_label.text = "ポーション効果"
		title_label.modulate = Color(1, 0.8, 1, 1)
	
	_log_debug("Panels setup completed")

func _connect_signals() -> void:
	"""シグナルの接続"""
	if character_upgrade_button:
		character_upgrade_button.pressed.connect(_on_character_upgrade_pressed)
	if weapon_upgrade_button:
		weapon_upgrade_button.pressed.connect(_on_weapon_upgrade_pressed)
	if attack_speed_upgrade_button:
		attack_speed_upgrade_button.pressed.connect(_on_attack_speed_upgrade_pressed)
	if potion_effect_upgrade_button:
		potion_effect_upgrade_button.pressed.connect(_on_potion_effect_upgrade_pressed)

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
	
	# 攻撃速度情報
	if attack_speed_level_label:
		attack_speed_level_label.text = "レベル %d" % PlayerStats.attack_speed_level
	if attack_speed_interval_label:
		var current_interval = PlayerStats.get_attack_interval()
		var next_interval = max(current_interval - GameConstants.ATTACK_SPEED_REDUCTION_PER_LEVEL, GameConstants.MIN_ATTACK_INTERVAL)
		attack_speed_interval_label.text = "間隔: %.2fs → %.2fs" % [current_interval, next_interval]
	if attack_speed_cost_label:
		attack_speed_cost_label.text = "%d" % PlayerStats.get_attack_speed_level_up_cost()
	
	# ポーション効果情報
	if potion_effect_level_label:
		potion_effect_level_label.text = "レベル %d" % PlayerStats.potion_effect_level
	if potion_effect_heal_label:
		potion_effect_heal_label.text = "回復量: %d → %d" % [
			PlayerStats.get_potion_heal_amount(),
			PlayerStats.get_potion_heal_amount() + GameConstants.POTION_HEAL_INCREASE_PER_LEVEL
		]
	if potion_effect_cost_label:
		potion_effect_cost_label.text = "%d" % PlayerStats.get_potion_effect_level_up_cost()
	
	# コイン表示
	if coin_label:
		coin_label.text = "%d" % PlayerStats.total_coins
	
	# ボタンの有効/無効
	_update_button_states()
	
	_log_debug("Display updated - Character Lv: %d, Weapon Lv: %d, Attack Speed Lv: %d, Potion Lv: %d, Coins: %d" % 
		[PlayerStats.character_level, PlayerStats.weapon_level, PlayerStats.attack_speed_level, PlayerStats.potion_effect_level, PlayerStats.total_coins])

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
	
	if attack_speed_upgrade_button:
		attack_speed_upgrade_button.disabled = PlayerStats.total_coins < PlayerStats.get_attack_speed_level_up_cost()
		if attack_speed_upgrade_button.disabled:
			attack_speed_upgrade_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			attack_speed_upgrade_button.modulate = Color.WHITE
	
	if potion_effect_upgrade_button:
		potion_effect_upgrade_button.disabled = PlayerStats.total_coins < PlayerStats.get_potion_effect_level_up_cost()
		if potion_effect_upgrade_button.disabled:
			potion_effect_upgrade_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			potion_effect_upgrade_button.modulate = Color.WHITE

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

func _on_attack_speed_upgrade_pressed() -> void:
	"""攻撃速度レベルアップボタン押下"""
	if PlayerStats.level_up_attack_speed():
		_play_upgrade_animation(attack_speed_panel)
		update_display()
		upgrade_completed.emit()
		_log_debug("Attack speed upgraded to level %d" % PlayerStats.attack_speed_level)
	else:
		_play_error_animation(attack_speed_upgrade_button)
		_log_debug("Attack speed upgrade failed - insufficient coins")

func _on_potion_effect_upgrade_pressed() -> void:
	"""ポーション効果レベルアップボタン押下"""
	if PlayerStats.level_up_potion_effect():
		_play_upgrade_animation(potion_effect_panel)
		update_display()
		upgrade_completed.emit()
		_log_debug("Potion effect upgraded to level %d" % PlayerStats.potion_effect_level)
	else:
		_play_error_animation(potion_effect_upgrade_button)
		_log_debug("Potion effect upgrade failed - insufficient coins")

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