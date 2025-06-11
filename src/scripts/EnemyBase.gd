extends CharacterBody2D
class_name EnemyBase

## エネミー基底クラス
## 全ての敵の共通機能を提供

# 敵タイプの定義
enum EnemyType {
	BASIC,      # 基本的な敵
	FAST,       # 素早い敵
	STRONG,     # 強い敵
	BOSS        # ボス敵
}

@onready var sprite: Sprite2D = $Sprite2D
@onready var walk_timer: Timer = $WalkAnimationTimer
@onready var hp_bar = $HPBar

# 基本プロパティ
var enemy_type: EnemyType = EnemyType.BASIC
var walk_sprites: Array[Texture2D] = []
var current_frame: int = 0
var is_walking: bool = true
var is_in_battle: bool = false
var initial_position: Vector2

# 戦闘関連
var battle_tween: Tween
var charge_speed: float = 200.0  # 突進速度
var charge_distance: float = 30.0  # 突進距離

# HP関連
var max_hp: int = 50
var current_hp: int = 50

# シグナル
signal enemy_reached_target()
signal enemy_destroyed()
signal enemy_battle_state_changed(in_battle: bool)
signal enemy_hp_changed(new_hp: int, max_hp: int)
signal enemy_died()

func _ready():
	initial_position = position
	_setup_enemy()
	_setup_hp_system()
	_log_debug("EnemyBase initialized at position: %s, type: %s" % [position, EnemyType.keys()[enemy_type]])

func _physics_process(delta):
	if is_walking and not is_in_battle:
		_move_toward_target(delta)

## 敵の初期設定（派生クラスでオーバーライド）
func _setup_enemy() -> void:
	pass

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
	var movement = Vector2(-GameConstants.ENEMY_WALK_SPEED * delta, 0)
	position += movement
	
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
	if walk_sprites.size() <= 1:
		return
	
	current_frame = (current_frame + 1) % walk_sprites.size()
	sprite.texture = walk_sprites[current_frame]
	_log_debug("Walk animation frame: %d/%d" % [current_frame, walk_sprites.size() - 1])

## 現在位置の取得
func get_current_position() -> Vector2:
	return position

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
	match enemy_type:
		EnemyType.BASIC:
			max_hp = GameConstants.ENEMY_BASIC_HP
		EnemyType.FAST:
			max_hp = GameConstants.ENEMY_FAST_HP
		EnemyType.STRONG:
			max_hp = GameConstants.ENEMY_STRONG_HP
		EnemyType.BOSS:
			max_hp = GameConstants.ENEMY_BOSS_HP
	
	current_hp = max_hp
	
	if hp_bar:
		hp_bar.position = GameConstants.HP_BAR_OFFSET
		hp_bar.initialize_hp(current_hp, max_hp)
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