extends CharacterBody2D
class_name EnemyBase

## エネミー基底クラス
## 全ての敵の共通機能を提供

# 敵タイプの定義
enum EnemyType {
	BASIC,      # 基本的な敵
	FAST,       # 素早い敵
	STRONG,     # 強い敵
	MAGE,       # 魔法使い敵（遠距離攻撃）
	BOSS        # ボス敵
}

@onready var sprite: Sprite2D = $Sprite2D
@onready var walk_timer: Timer = $WalkAnimationTimer
@onready var hp_bar = $HPBar

# レベル表示用
var level_label: Label

# 基本プロパティ
var enemy_type: EnemyType = EnemyType.BASIC
var walk_sprites: Array[Texture2D] = []
var current_frame: int = 0
var is_walking: bool = true
var is_in_battle: bool = false
var initial_position: Vector2
var encounter_distance: float = GameConstants.ENEMY_ENCOUNTER_DISTANCE_BASIC  # 接敵距離

# 戦闘関連
var battle_tween: Tween
var charge_speed: float = 200.0  # 突進速度
var charge_distance: float = 30.0  # 突進距離

# HP関連
var max_hp: int = 50
var current_hp: int = 50

# レベル関連
var enemy_level: int = 1

# シグナル
signal enemy_reached_target()
signal enemy_destroyed()
signal enemy_battle_state_changed(in_battle: bool)
signal enemy_hp_changed(new_hp: int, max_hp: int)
signal enemy_died()
signal enemy_attacked_player(damage: int)

func _ready():
	# 敵グループに追加
	add_to_group("enemy")
	initial_position = position
	_setup_enemy()
	_setup_level_system()
	_setup_hp_system()
	_setup_encounter_distance()
	_log_debug("EnemyBase initialized at position: %s, type: %s, level: %d, encounter distance: %f" % [position, EnemyType.keys()[enemy_type], enemy_level, encounter_distance])

func _physics_process(delta):
	# 敵は常に背景との相対速度で移動（戦闘中でも相対的に移動）
	_move_toward_target(delta)

## 敵の初期設定（派生クラスでオーバーライド）
func _setup_enemy() -> void:
	pass

## レベルシステムの初期化
func _setup_level_system() -> void:
	"""敵のレベル表示を初期化"""
	# レベルをランダムに設定（1-3の範囲）
	enemy_level = randi_range(1, 3)
	
	# レベル表示用Labelを作成
	level_label = Label.new()
	level_label.text = "Lv.%d" % enemy_level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# z_indexを設定してHPバーより前面に表示
	level_label.z_index = 1
	
	# フォントスタイル設定
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color.BLACK)
	level_label.add_theme_color_override("font_shadow_color", Color.WHITE)
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	level_label.add_theme_constant_override("outline_size", 1)
	level_label.add_theme_color_override("font_outline_color", Color.WHITE)
	
	# ノードに追加
	add_child(level_label)
	
	# レベルに応じて敵の能力を調整
	_apply_level_scaling()
	
	_log_debug("Level system initialized: Level %d" % enemy_level)

## レベルに応じた能力スケーリング
func _apply_level_scaling() -> void:
	"""レベルに応じて敵の能力を調整"""
	var level_multiplier = 1.0 + (enemy_level - 1) * 0.5  # レベル1: 1.0倍, レベル2: 1.5倍, レベル3: 2.0倍
	
	# 移動速度を調整
	charge_speed *= level_multiplier

## レベル表示の位置更新
func _update_level_label_position() -> void:
	"""レベル表示をHPバーの上に配置"""
	if level_label and hp_bar:
		# HPバーの位置を基準にレベル表示を配置
		var hp_bar_position = hp_bar.position
		# 間隔を調整: 18px → 21px（HPバーと重ならないように）
		var level_offset = Vector2(0, -21)  # HPバーの21px上に配置
		level_label.position = hp_bar_position + level_offset
		_log_debug("Level label positioned at: %s" % level_label.position)

## 接敵距離の設定
func _setup_encounter_distance() -> void:
	"""敵タイプに応じて接敵距離を設定"""
	match enemy_type:
		EnemyType.BASIC:
			encounter_distance = GameConstants.ENEMY_ENCOUNTER_DISTANCE_BASIC
		EnemyType.FAST:
			encounter_distance = GameConstants.ENEMY_ENCOUNTER_DISTANCE_FAST
		EnemyType.STRONG:
			encounter_distance = GameConstants.ENEMY_ENCOUNTER_DISTANCE_STRONG
		EnemyType.MAGE:
			encounter_distance = GameConstants.ENEMY_ENCOUNTER_DISTANCE_MAGE
		EnemyType.BOSS:
			encounter_distance = GameConstants.ENEMY_ENCOUNTER_DISTANCE_BOSS
	_log_debug("Enemy encounter distance set to: %f for type: %s" % [encounter_distance, EnemyType.keys()[enemy_type]])

## 戦闘状態の設定
func set_battle_state(in_battle: bool) -> void:
	if is_in_battle != in_battle:
		is_in_battle = in_battle
		enemy_battle_state_changed.emit(in_battle)
		_log_debug("Battle state changed: %s" % in_battle)
		
		if in_battle:
			_start_battle_behavior()
		else:
			_end_battle_behavior()

## 戦闘開始時の動作（派生クラスでオーバーライド）
func _start_battle_behavior() -> void:
	pass

## 戦闘終了時の動作（派生クラスでオーバーライド）
func _end_battle_behavior() -> void:
	pass

## 左方向への移動
func _move_toward_target(delta: float) -> void:
	# ScrollManagerから現在のスクロール速度を取得（戦闘時は0、通常時は100）
	var scroll_speed = 0.0
	var main_scene = get_node_or_null("/root/MainScene")
	if main_scene and "scroll_manager" in main_scene:
		var scroll_manager = main_scene.scroll_manager
		if scroll_manager and scroll_manager.has_method("get_current_scroll_speed"):
			scroll_speed = scroll_manager.get_current_scroll_speed()
		else:
			scroll_speed = 0.0  # フォールバック：スクロール停止とみなす
	else:
		# フォールバック：スクロール停止とみなす
		scroll_speed = 0.0
	
	# 戦闘状態に応じて相対速度を調整
	var target_relative_speed: float
	if is_in_battle:
		# 戦闘中は背景と同じ速度で相対的に止まる（相対速度0）
		target_relative_speed = 0.0
	else:
		# 通常移動時は設定された相対速度
		target_relative_speed = GameConstants.ENEMY_RELATIVE_SPEED
	
	# 敵の絶対速度 = 目標相対速度 + 背景スクロール速度
	var absolute_speed = target_relative_speed + scroll_speed
	var movement = Vector2(-absolute_speed * delta, 0)
	position += movement
	
	# デバッグログ（戦闘状態変化時のみ）
	if is_in_battle:
		_log_debug("Enemy movement - Scroll: %f, Relative: %f, Absolute: %f, Battle: %s" % [scroll_speed, target_relative_speed, absolute_speed, is_in_battle])
	
	# 目標位置に到達したかチェック
	if position.x <= GameConstants.ENEMY_TARGET_X:
		_on_reached_target()

## 目標位置到達時の処理
func _on_reached_target() -> void:
	is_walking = false
	if walk_timer:
		walk_timer.stop()
	enemy_reached_target.emit()
	_log_debug("Enemy reached target, removing from scene")
	queue_free()

## 歩行アニメーションフレームの切り替え
func _on_walk_animation_timer_timeout():
	# 戦闘中または歩行停止中はアニメーションを更新しない
	if is_in_battle or not is_walking:
		return
		
	if walk_sprites.size() <= 1:
		return
	
	current_frame = (current_frame + 1) % walk_sprites.size()
	sprite.texture = walk_sprites[current_frame]
	_log_debug("Walk animation frame: %d/%d" % [current_frame, walk_sprites.size() - 1])

## 現在位置の取得
func get_current_position() -> Vector2:
	return position

## 接敵距離の取得
func get_encounter_distance() -> float:
	return encounter_distance

## エネミーの破棄
func destroy() -> void:
	is_walking = false
	if walk_timer:
		walk_timer.stop()
	if battle_tween:
		battle_tween.kill()
	enemy_destroyed.emit()
	queue_free()

## HPシステムの初期設定
func _setup_hp_system() -> void:
	"""敵のHPシステムとHPバーの初期化"""
	# 敵タイプに応じてHPを設定
	var base_hp: int
	match enemy_type:
		EnemyType.BASIC:
			base_hp = GameConstants.ENEMY_BASIC_HP
		EnemyType.FAST:
			base_hp = GameConstants.ENEMY_FAST_HP
		EnemyType.STRONG:
			base_hp = GameConstants.ENEMY_STRONG_HP
		EnemyType.MAGE:
			base_hp = GameConstants.ENEMY_MAGE_HP
		EnemyType.BOSS:
			base_hp = GameConstants.ENEMY_BOSS_HP
	
	# レベルに応じてHPを調整
	var level_multiplier = 1.0 + (enemy_level - 1) * 0.5  # レベル1: 1.0倍, レベル2: 1.5倍, レベル3: 2.0倍
	max_hp = int(base_hp * level_multiplier)
	current_hp = max_hp
	
	if hp_bar:
		# スプライトサイズから中央位置を計算してHPバー位置を設定
		_update_hp_bar_position()
		hp_bar.initialize_hp(current_hp, max_hp)
		
		# レベル表示の位置をHPバーの上に設定
		_update_level_label_position()
		hp_bar.hp_changed.connect(_on_hp_changed)
		hp_bar.hp_depleted.connect(_on_hp_depleted)
		_log_debug("Enemy HP system initialized: %d/%d" % [current_hp, max_hp])
	else:
		_log_error("HP bar node not found")

## ダメージを受ける
func take_damage(damage: int) -> void:
	"""敵がダメージを受ける"""
	if hp_bar:
		hp_bar.take_damage(damage)
		current_hp = hp_bar.get_current_hp()
		_log_debug("Enemy took %d damage, HP: %d/%d" % [damage, current_hp, max_hp])
	
	# ダメージテキストを表示
	_show_damage_text(damage)

## HPを回復
func heal(amount: int) -> void:
	"""敵のHPを回復"""
	if hp_bar:
		hp_bar.heal(amount)
		current_hp = hp_bar.get_current_hp()
		_log_debug("Enemy healed %d HP, HP: %d/%d" % [amount, current_hp, max_hp])

## HP変更イベントハンドラー
func _on_hp_changed(new_hp: int, maximum_hp: int) -> void:
	"""HPが変更された時の処理"""
	current_hp = new_hp
	enemy_hp_changed.emit(new_hp, maximum_hp)

## HP枯渇イベントハンドラー
func _on_hp_depleted() -> void:
	"""HPが0になった時の処理"""
	_log_debug("Enemy died!")
	_spawn_coin()
	_try_spawn_health_potion()
	enemy_died.emit()
	destroy()

## 現在のHP取得
func get_current_hp() -> int:
	return current_hp

## 最大HP取得
func get_max_hp() -> int:
	return max_hp

## 生存確認
func is_alive() -> bool:
	return current_hp > 0

## ダメージテキストの表示
func _show_damage_text(damage: int) -> void:
	"""敵の上にダメージ数値をアニメーション付きで表示"""
	# DamageTextクラスのインスタンスを作成
	var damage_text = preload("res://src/scripts/DamageText.gd").new()
	
	# 表示位置を計算
	var text_position = UIPositionHelper.calculate_damage_text_position(sprite, position)
	
	# 親ノードに追加
	var parent = get_parent()
	if parent:
		parent.add_child(damage_text)
		damage_text.initialize_damage_text(damage, text_position, false)  # 敵ダメージ = オレンジ色

## HPバー位置の更新
func _update_hp_bar_position() -> void:
	"""スプライトサイズに基づいてHPバー位置を動的に計算"""
	if not hp_bar:
		return
	
	var enemy_name = "Enemy_%s_Lv%d" % [EnemyType.keys()[enemy_type], enemy_level]
	var hp_bar_offset = UIPositionHelper.calculate_hp_bar_position(sprite, enemy_name)
	hp_bar.position = hp_bar_offset
	_log_debug("HP bar position updated: %s" % hp_bar_offset)
	
	# HPバー位置が更新されたら、レベル表示の位置も更新
	_update_level_label_position()

## コインをスポーンする
func _spawn_coin() -> void:
	"""敵死亡時にコインを生成"""
	var coin_scene = preload("res://src/scenes/Coin.tscn")
	var coin_instance = coin_scene.instantiate()
	
	# コイン価値を設定（1-2のランダム）
	var coin_value = GameConstants.COIN_DROP_BASE_VALUE + randi() % (GameConstants.COIN_DROP_RANDOM_BONUS + 1)
	
	# 出現位置を設定（敵の位置に少しランダム性を加える）
	var spawn_offset = Vector2(
		randf_range(-20.0, 20.0),
		randf_range(-10.0, 10.0)
	)
	coin_instance.position = position + spawn_offset
	
	# 親ノード（PlayArea）に追加
	var parent = get_parent()
	if parent:
		parent.add_child(coin_instance)
		# コイン価値を設定（_readyの後に呼び出す）
		coin_instance.call_deferred("set_coin_value", coin_value)
		# MainSceneとのシグナル接続も遅延実行
		coin_instance.call_deferred("_connect_to_main_scene")
		_log_debug("Coin spawned with value: %d at position: %s" % [coin_value, coin_instance.position])
	else:
		_log_error("Cannot spawn coin: parent node not found")
		coin_instance.queue_free()

## 回復薬をスポーンする（20%の確率）
func _try_spawn_health_potion() -> void:
	"""敵死亡時に20%の確率で回復薬を生成し、即座にプレイヤーを回復"""
	# 20%の確率チェック
	if randf() > GameConstants.HEALTH_POTION_DROP_CHANCE:
		return
	
	# プレイヤーを検索して即座に回復
	var player = _find_player()
	if player and player.has_method("heal"):
		var heal_amount = PlayerStats.get_potion_heal_amount()
		player.heal(heal_amount)
		_log_debug("Player healed immediately for %d HP" % heal_amount)
	else:
		_log_error("Player not found for health potion healing")
		return
	
	# 視覚的フィードバック用にHealthPotionシーンを表示
	var health_potion_scene = preload("res://src/scenes/HealthPotion.tscn")
	var health_potion_instance = health_potion_scene.instantiate()
	
	# 出現位置を設定（敵の位置に少しランダム性を加える）
	var spawn_offset = Vector2(
		randf_range(-25.0, 25.0),
		randf_range(-15.0, 15.0)
	)
	health_potion_instance.position = position + spawn_offset
	
	# 親ノード（PlayArea）に追加
	var parent = get_parent()
	if parent:
		parent.add_child(health_potion_instance)
		_log_debug("Health potion visual effect spawned at position: %s" % health_potion_instance.position)
	else:
		_log_error("Cannot spawn health potion visual: parent node not found")
		health_potion_instance.queue_free()

## プレイヤーノードを検索
func _find_player() -> Node2D:
	"""プレイヤーノードを検索"""
	# グループからプレイヤーを検索
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	
	# パス検索
	var player_by_path = get_node_or_null("../../Player")
	if player_by_path:
		return player_by_path as Node2D
	
	# 親を辿ってPlayAreaを見つけてからプレイヤーを取得
	var current = get_parent()
	while current:
		if current.name == "PlayArea":
			var player_node = current.get_node_or_null("Player")
			if player_node:
				return player_node as Node2D
		current = current.get_parent()
	
	return null

## テクスチャの安全な読み込み
func _load_texture_safe(path: String) -> Texture2D:
	if path.is_empty():
		_log_error("Empty texture path provided")
		return null
	
	var texture = load(path)
	if not texture:
		_log_error("Failed to load texture: %s" % path)
		return null
	
	return texture

## エラーログ出力
func _log_error(message: String) -> void:
	print("[EnemyBase] ERROR: %s" % message)

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[EnemyBase] %s" % message)