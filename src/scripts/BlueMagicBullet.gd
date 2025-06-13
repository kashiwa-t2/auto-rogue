extends Area2D
class_name BlueMagicBullet

## 青い魔法弾クラス
## RedCharacter (あかさん) が発射する遠距離攻撃弾

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# 弾の設定
var bullet_speed: float = 400.0  # 弾の移動速度（敵より速く）
var damage: int = 10  # ダメージ量（あかさんのレベルに応じて設定）
var target_enemy: Node2D = null
var direction: Vector2
var has_hit: bool = false

# ライフタイム
var lifetime: float = 3.0  # 3秒で自動削除
var lifetime_timer: Timer


func _ready():
	_setup_sprite()
	_setup_collision()
	_setup_lifetime_timer()
	_log_debug("BlueMagicBullet initialized")

## スプライトの設定
func _setup_sprite() -> void:
	if sprite:
		var texture = load("res://assets/sprites/ai/magic_bullet_blue.png")
		if texture:
			sprite.texture = texture
			sprite.scale = Vector2(1.0, 1.0)  # 通常サイズ
			sprite.z_index = 100  # 他の要素の前面に表示
			# あかさん用の青い弾なので視覚的に区別可能
			_log_debug("Blue magic bullet sprite loaded (scale: 1.0, z_index: 100)")
		else:
			_log_error("Failed to load blue magic bullet sprite")
	else:
		_log_error("Sprite node not found in BlueMagicBullet")

## コリジョンの設定
func _setup_collision() -> void:
	if collision_shape:
		var shape = CircleShape2D.new()
		shape.radius = 8  # 小さな当たり判定
		collision_shape.shape = shape
		_log_debug("Blue magic bullet collision setup completed")

## ライフタイムタイマーの設定
func _setup_lifetime_timer() -> void:
	lifetime_timer = Timer.new()
	lifetime_timer.wait_time = lifetime
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.one_shot = true
	add_child(lifetime_timer)
	lifetime_timer.start()

## 弾の初期設定
func setup_bullet(target_pos: Vector2, bullet_damage: int) -> void:
	damage = bullet_damage
	
	# ターゲット位置への方向を計算
	direction = (target_pos - position).normalized()
	
	_log_debug("Blue magic bullet setup - Target: %s, Damage: %d" % [target_pos, damage])

func _process(delta):
	if has_hit:
		return
	
	# 弾を目標方向に移動（MagicBulletと同じ方式）
	position += direction * bullet_speed * delta
	
	# 敵との距離をチェック（20ピクセル以内で即座に当たり判定）
	var nearest_enemy = _find_nearest_enemy()
	if nearest_enemy:
		var distance_to_enemy = position.distance_to(nearest_enemy.position)
		
		if distance_to_enemy <= 20.0:
			# 初めて20以下になった時に即座にダメージと削除
			_log_debug("HITTING ENEMY! Distance: %.1f" % distance_to_enemy)
			has_hit = true
			
			# ダメージ処理
			nearest_enemy.take_damage(damage)
			_log_debug("Damage dealt to enemy: %d" % damage)
			
			# 即座に削除
			_destroy_immediately()
			return
	
	# 画面外に出たら削除
	if position.x < -100 or position.x > 800 or position.y < -100 or position.y > 1400:
		_destroy_immediately()
	
	# デバッグ：移動をログ出力（最初の1秒のみ）
	if lifetime_timer and lifetime_timer.time_left > 2.0:
		_log_debug("Bullet moving: to %s (direction: %s, speed: %.1f)" % [position, direction, bullet_speed])


## 最も近い敵ノードを検索
func _find_nearest_enemy() -> Node2D:
	"""最も近い敵ノードを検索"""
	# グループから敵を検索
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return null
	
	var nearest_enemy = null
	var shortest_distance = 999999.0
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = position.distance_to(enemy.position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_enemy = enemy
	
	return nearest_enemy as Node2D

## 弾の即座削除
func _destroy_immediately() -> void:
	# 既に削除処理中の場合は重複実行を防ぐ
	if not is_inside_tree():
		return
	
	_log_debug("Destroying bullet immediately")
	
	# タイマー停止
	if lifetime_timer and is_instance_valid(lifetime_timer):
		lifetime_timer.stop()
	
	# 全処理を即座に停止
	has_hit = true
	set_process(false)
	
	# 衝突判定を無効化
	monitoring = false
	monitorable = false
	if collision_shape:
		collision_shape.disabled = true
	
	# 完全に非表示にして画面外に移動
	visible = false
	position = Vector2(-99999, -99999)
	
	# 親から削除して即座に削除
	if get_parent():
		get_parent().remove_child(self)
	queue_free()

## ライフタイム終了
func _on_lifetime_timeout() -> void:
	_log_debug("Blue magic bullet lifetime expired")
	_destroy_immediately()

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[BlueMagicBullet] %s" % message)

## エラーログ出力
func _log_error(message: String) -> void:
	print("[BlueMagicBullet] ERROR: %s" % message)