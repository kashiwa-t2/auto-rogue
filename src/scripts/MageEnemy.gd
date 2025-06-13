extends EnemyBase
class_name MageEnemy

## 魔法使い敵クラス
## 遠距離攻撃を行う敵
## 
## 特徴:
## - 300ピクセルの遠距離接敵
## - 2秒間隔の魔法弾攻撃
## - 基本敵より遅い移動速度（40vs50）
## - 独立した攻撃タイマー管理

# 魔法弾攻撃関連
var attack_timer: Timer
var attack_cooldown: float = 2.0  # 攻撃間隔
var magic_bullet_scene = preload("res://src/scenes/MagicBullet.tscn")
var is_attacking: bool = false

func _ready():
	enemy_type = EnemyType.MAGE
	super._ready()
	_setup_attack_timer()

## 魔法使い敵の初期設定
func _setup_enemy() -> void:
	# 魔法使い用のスプライトを設定
	walk_sprites = []
	for sprite_path in GameConstants.MAGE_WALK_SPRITES:
		var texture = _load_texture_safe(sprite_path)
		if texture:
			walk_sprites.append(texture)
	
	if walk_sprites.size() > 0:
		sprite.texture = walk_sprites[0]
		sprite.scale = Vector2(GameConstants.ENEMY_SPRITE_SCALE, GameConstants.ENEMY_SPRITE_SCALE)
		sprite.flip_h = GameConstants.ENEMY_SPRITE_FLIP_H
		
		# 歩行アニメーションの設定
		if walk_timer:
			walk_timer.wait_time = 1.0 / GameConstants.ENEMY_ANIMATION_SPEED
			walk_timer.timeout.connect(_on_walk_animation_timer_timeout)
			walk_timer.start()
		
		_log_debug("MageEnemy sprites loaded: %d frames" % walk_sprites.size())
	else:
		_log_error("Failed to load MageEnemy sprites")

## 攻撃タイマーの設定
func _setup_attack_timer() -> void:
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.one_shot = true
	add_child(attack_timer)
	_log_debug("MageEnemy attack timer initialized")

## 戦闘開始時の動作
func _start_battle_behavior() -> void:
	_log_debug("MageEnemy entered battle state")
	if not is_attacking:
		_start_magic_attack()

## 戦闘終了時の動作
func _end_battle_behavior() -> void:
	_log_debug("MageEnemy exited battle state")
	is_attacking = false
	if attack_timer:
		attack_timer.stop()

## 魔法攻撃の開始
func _start_magic_attack() -> void:
	if not is_in_battle or is_attacking:
		return
	
	is_attacking = true
	_fire_magic_bullet()
	
	# 次の攻撃のためにタイマーを開始
	if attack_timer:
		attack_timer.start()

## 魔法弾の発射
func _fire_magic_bullet() -> void:
	if not magic_bullet_scene:
		_log_error("Magic bullet scene not loaded")
		return
	
	var bullet = magic_bullet_scene.instantiate()
	if not bullet:
		_log_error("Failed to instantiate magic bullet")
		return
	
	# 発射位置を設定（魔法使いの位置から）
	bullet.position = position
	
	# プレイヤーを検索してターゲットに設定
	var player = _find_player()
	if player:
		# 親ノード（PlayArea）に追加
		var parent = get_parent()
		if parent:
			parent.add_child(bullet)
			bullet.setup_bullet(player.position, GameConstants.ENEMY_MAGE_ATTACK_DAMAGE)
			_log_debug("Magic bullet fired at player position: %s" % player.position)
		else:
			_log_error("Cannot fire magic bullet: parent node not found")
			bullet.queue_free()
	else:
		_log_error("Cannot fire magic bullet: player not found")
		bullet.queue_free()

## 攻撃タイマーのタイムアウト
func _on_attack_timer_timeout() -> void:
	is_attacking = false
	# 戦闘中なら次の攻撃を開始
	if is_in_battle:
		_start_magic_attack()

## 左方向への移動（魔法使い専用速度）
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
		# 戦闘中（接近・攻撃状態）は背景と同じ速度で相対的に止まる（相対速度0）
		target_relative_speed = 0.0
	else:
		# 通常移動時は魔法使い専用の相対速度
		target_relative_speed = GameConstants.MAGE_RELATIVE_SPEED  # 40.0
	
	# 敵の絶対速度 = 目標相対速度 + 背景スクロール速度
	var absolute_speed = target_relative_speed + scroll_speed
	var movement = Vector2(-absolute_speed * delta, 0)
	position += movement
	
	# デバッグログ（戦闘状態時）
	if is_in_battle:
		_log_debug("Mage movement - Scroll: %f, Relative: %f, Absolute: %f, Battle: %s" % [scroll_speed, target_relative_speed, absolute_speed, is_in_battle])
	
	# 目標位置に到達したかチェック
	if position.x <= GameConstants.ENEMY_TARGET_X:
		_on_reached_target()

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[MageEnemy] %s" % message)