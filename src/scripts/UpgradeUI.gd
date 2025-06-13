extends Control
class_name UpgradeUI

## 育成画面UIクラス
## キャラクターと武器のレベルアップを管理

@onready var character_panel: Control = $UpgradeScrollContainer/UpgradeContainer/CharacterUpgrade
@onready var weapon_panel: Control = $UpgradeScrollContainer/UpgradeContainer/WeaponUpgrade
@onready var attack_speed_panel: Control = $UpgradeScrollContainer/UpgradeContainer/AttackSpeedUpgrade
@onready var potion_effect_panel: Control = $UpgradeScrollContainer/UpgradeContainer/PotionEffectUpgrade

# あかさん関連
@onready var red_unlock_panel: Control = $UpgradeScrollContainer/UpgradeContainer/RedUnlockUpgrade
@onready var red_character_panel: Control = $UpgradeScrollContainer/UpgradeContainer/RedCharacterUpgrade
@onready var red_weapon_panel: Control = $UpgradeScrollContainer/UpgradeContainer/RedWeaponUpgrade

# キャラクター関連
@onready var character_level_label: Label = $UpgradeScrollContainer/UpgradeContainer/CharacterUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var character_hp_label: Label = $UpgradeScrollContainer/UpgradeContainer/CharacterUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var character_cost_label: Label = $UpgradeScrollContainer/UpgradeContainer/CharacterUpgrade/MainContainer/CostContainer/CostLabel
@onready var character_upgrade_button: Button = $UpgradeScrollContainer/UpgradeContainer/CharacterUpgrade/MainContainer/UpgradeButton

# 武器関連
@onready var weapon_level_label: Label = $UpgradeScrollContainer/UpgradeContainer/WeaponUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var weapon_damage_label: Label = $UpgradeScrollContainer/UpgradeContainer/WeaponUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var weapon_cost_label: Label = $UpgradeScrollContainer/UpgradeContainer/WeaponUpgrade/MainContainer/CostContainer/CostLabel
@onready var weapon_upgrade_button: Button = $UpgradeScrollContainer/UpgradeContainer/WeaponUpgrade/MainContainer/UpgradeButton

# 攻撃速度関連
@onready var attack_speed_level_label: Label = $UpgradeScrollContainer/UpgradeContainer/AttackSpeedUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var attack_speed_interval_label: Label = $UpgradeScrollContainer/UpgradeContainer/AttackSpeedUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var attack_speed_cost_label: Label = $UpgradeScrollContainer/UpgradeContainer/AttackSpeedUpgrade/MainContainer/CostContainer/CostLabel
@onready var attack_speed_upgrade_button: Button = $UpgradeScrollContainer/UpgradeContainer/AttackSpeedUpgrade/MainContainer/UpgradeButton

# ポーション効果関連
@onready var potion_effect_level_label: Label = $UpgradeScrollContainer/UpgradeContainer/PotionEffectUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var potion_effect_heal_label: Label = $UpgradeScrollContainer/UpgradeContainer/PotionEffectUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var potion_effect_cost_label: Label = $UpgradeScrollContainer/UpgradeContainer/PotionEffectUpgrade/MainContainer/CostContainer/CostLabel
@onready var potion_effect_upgrade_button: Button = $UpgradeScrollContainer/UpgradeContainer/PotionEffectUpgrade/MainContainer/UpgradeButton

# あかさん解放関連
@onready var red_unlock_cost_label: Label = $UpgradeScrollContainer/UpgradeContainer/RedUnlockUpgrade/MainContainer/CostContainer/CostLabel
@onready var red_unlock_button: Button = $UpgradeScrollContainer/UpgradeContainer/RedUnlockUpgrade/MainContainer/UpgradeButton

# あかさんキャラクター関連
@onready var red_character_level_label: Label = $UpgradeScrollContainer/UpgradeContainer/RedCharacterUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var red_character_hp_label: Label = $UpgradeScrollContainer/UpgradeContainer/RedCharacterUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var red_character_cost_label: Label = $UpgradeScrollContainer/UpgradeContainer/RedCharacterUpgrade/MainContainer/CostContainer/CostLabel
@onready var red_character_upgrade_button: Button = $UpgradeScrollContainer/UpgradeContainer/RedCharacterUpgrade/MainContainer/UpgradeButton

# あかさん武器関連
@onready var red_weapon_level_label: Label = $UpgradeScrollContainer/UpgradeContainer/RedWeaponUpgrade/MainContainer/InfoContainer/LevelLabel
@onready var red_weapon_damage_label: Label = $UpgradeScrollContainer/UpgradeContainer/RedWeaponUpgrade/MainContainer/InfoContainer/EffectLabel
@onready var red_weapon_cost_label: Label = $UpgradeScrollContainer/UpgradeContainer/RedWeaponUpgrade/MainContainer/CostContainer/CostLabel
@onready var red_weapon_upgrade_button: Button = $UpgradeScrollContainer/UpgradeContainer/RedWeaponUpgrade/MainContainer/UpgradeButton

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
	
	# あかさん解放パネル
	if red_unlock_panel:
		var title_label = red_unlock_panel.get_node("MainContainer/Title")
		title_label.text = "あかさん解放"
		title_label.modulate = Color(1, 0.4, 0.4, 1)
		# 効果ラベルを説明テキストに変更
		var effect_label = red_unlock_panel.get_node("MainContainer/InfoContainer/EffectLabel")
		effect_label.text = "魔法攻撃キャラクター"
		# レベルラベルを非表示
		var level_label = red_unlock_panel.get_node("MainContainer/InfoContainer/LevelLabel")
		level_label.visible = false
	
	# あかさんキャラクターパネル
	if red_character_panel:
		var title_label = red_character_panel.get_node("MainContainer/Title")
		title_label.text = "あかさん"
		title_label.modulate = Color(1, 0.5, 0.5, 1)
	
	# あかさん武器パネル
	if red_weapon_panel:
		var title_label = red_weapon_panel.get_node("MainContainer/Title")
		title_label.text = "あかさんの杖"
		title_label.modulate = Color(0.8, 0.5, 1, 1)
	
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
	
	# あかさん関連シグナル
	if red_unlock_button:
		red_unlock_button.pressed.connect(_on_red_unlock_pressed)
	if red_character_upgrade_button:
		red_character_upgrade_button.pressed.connect(_on_red_character_upgrade_pressed)
	if red_weapon_upgrade_button:
		red_weapon_upgrade_button.pressed.connect(_on_red_weapon_upgrade_pressed)

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
	
	# あかさん関連情報
	_update_red_character_display()
	
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
	
	# あかさん解放ボタン
	if red_unlock_button:
		red_unlock_button.disabled = PlayerStats.red_character_unlocked or PlayerStats.total_coins < PlayerStats.get_red_character_unlock_cost()
		if red_unlock_button.disabled:
			red_unlock_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			red_unlock_button.modulate = Color.WHITE
	
	# あかさんキャラクターボタン
	if red_character_upgrade_button:
		red_character_upgrade_button.disabled = not PlayerStats.red_character_unlocked or PlayerStats.total_coins < PlayerStats.get_red_character_level_up_cost()
		if red_character_upgrade_button.disabled:
			red_character_upgrade_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			red_character_upgrade_button.modulate = Color.WHITE
	
	# あかさん武器ボタン
	if red_weapon_upgrade_button:
		red_weapon_upgrade_button.disabled = not PlayerStats.red_character_unlocked or PlayerStats.total_coins < PlayerStats.get_red_weapon_level_up_cost()
		if red_weapon_upgrade_button.disabled:
			red_weapon_upgrade_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
		else:
			red_weapon_upgrade_button.modulate = Color.WHITE

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

## あかさん関連表示の更新
func _update_red_character_display() -> void:
	""""\u3042\u304b\u3055\u3093\u95a2\u9023\u30d1\u30cd\u30eb\u306e\u8868\u793a\u30fb\u975e\u8868\u793a\u3092\u5236\u5fa1"""
	if PlayerStats.red_character_unlocked:
		# 解放済み：解放パネルを非表示、アップグレードパネルを表示
		if red_unlock_panel:
			red_unlock_panel.visible = false
		if red_character_panel:
			red_character_panel.visible = true
		if red_weapon_panel:
			red_weapon_panel.visible = true
		
		# あかさんキャラクター情報
		if red_character_level_label:
			red_character_level_label.text = "レベル %d" % PlayerStats.red_character_level
		if red_character_hp_label:
			red_character_hp_label.text = "HP: %d → %d" % [
				PlayerStats.get_red_character_max_hp(),
				PlayerStats.get_red_character_max_hp() + 20
			]
		if red_character_cost_label:
			red_character_cost_label.text = "%d" % PlayerStats.get_red_character_level_up_cost()
		
		# あかさん武器情報
		if red_weapon_level_label:
			red_weapon_level_label.text = "レベル %d" % PlayerStats.red_weapon_level
		if red_weapon_damage_label:
			red_weapon_damage_label.text = "攻撃力: %d → %d" % [
				PlayerStats.get_red_character_attack_damage(),
				PlayerStats.get_red_character_attack_damage() + 3
			]
		if red_weapon_cost_label:
			red_weapon_cost_label.text = "%d" % PlayerStats.get_red_weapon_level_up_cost()
	else:
		# 未解放：解放パネルを表示、アップグレードパネルを非表示
		if red_unlock_panel:
			red_unlock_panel.visible = true
		if red_character_panel:
			red_character_panel.visible = false
		if red_weapon_panel:
			red_weapon_panel.visible = false
		
		# 解放コスト表示
		if red_unlock_cost_label:
			red_unlock_cost_label.text = "%d" % PlayerStats.get_red_character_unlock_cost()

## あかさん解放ボタン押下
func _on_red_unlock_pressed() -> void:
	""""\u3042\u304b\u3055\u3093\u89e3\u653e\u30dc\u30bf\u30f3\u62bc\u4e0b"""
	if PlayerStats.unlock_red_character():
		_play_upgrade_animation(red_unlock_panel)
		update_display()
		upgrade_completed.emit()
		_log_debug("あかさん解放成功!")
	else:
		_play_error_animation(red_unlock_button)
		_log_debug("あかさん解放失敗 - コイン不足")

## あかさんキャラクターレベルアップボタン押下
func _on_red_character_upgrade_pressed() -> void:
	""""\u3042\u304b\u3055\u3093\u30ad\u30e3\u30e9\u30af\u30bf\u30fc\u30ec\u30d9\u30eb\u30a2\u30c3\u30d7\u30dc\u30bf\u30f3\u62bc\u4e0b"""
	if PlayerStats.level_up_red_character():
		_play_upgrade_animation(red_character_panel)
		update_display()
		upgrade_completed.emit()
		_log_debug("あかさんキャラクターレベルアップ成功! レベル: %d" % PlayerStats.red_character_level)
	else:
		_play_error_animation(red_character_upgrade_button)
		_log_debug("あかさんキャラクターレベルアップ失敗 - コイン不足")

## あかさん武器レベルアップボタン押下
func _on_red_weapon_upgrade_pressed() -> void:
	""""\u3042\u304b\u3055\u3093\u6b66\u5668\u30ec\u30d9\u30eb\u30a2\u30c3\u30d7\u30dc\u30bf\u30f3\u62bc\u4e0b"""
	if PlayerStats.level_up_red_weapon():
		_play_upgrade_animation(red_weapon_panel)
		update_display()
		upgrade_completed.emit()
		_log_debug("あかさん武器レベルアップ成功! レベル: %d" % PlayerStats.red_weapon_level)
	else:
		_play_error_animation(red_weapon_upgrade_button)
		_log_debug("あかさん武器レベルアップ失敗 - コイン不足")

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[UpgradeUI] %s" % message)