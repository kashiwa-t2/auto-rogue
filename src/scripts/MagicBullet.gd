extends Area2D
class_name MagicBullet

## 魔法弾クラス
## 魔法使い敵が発射する遠距離攻撃弾

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# 弾の設定
var bullet_speed: float = 300.0  # 弾の移動速度
var damage: int = 20  # ダメージ量（固定で20）
var target_position: Vector2
var direction: Vector2
var has_hit: bool = false

# ライフタイム
var lifetime: float = 3.0  # 3秒で自動削除
var lifetime_timer: Timer

func _ready():
	_setup_sprite()
	_setup_lifetime_timer()
	_log_debug("MagicBullet initialized")

## スプライトの設定
func _setup_sprite() -> void:
	if sprite:
		var texture = load(GameConstants.MAGE_MAGIC_BULLET_SPRITE)
		if texture:
			sprite.texture = texture
			sprite.scale = Vector2(1.0, 1.0)  # サイズを半分に変更
			_log_debug("Magic bullet sprite loaded")
		else:
			_log_error("Failed to load magic bullet sprite")

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
	target_position = target_pos
	damage = 20  # 常に20ダメージに固定
	
	# プレイヤーへの方向を計算
	direction = (target_position - position).normalized()
	
	_log_debug("Magic bullet setup - Target: %s, Damage: 20" % [target_position])

func _process(delta):
	# 既にヒットしている場合は処理しない
	if has_hit:
		return
	
	# 弾を目標方向に移動（単純な位置更新）
	position += direction * bullet_speed * delta
	
	# プレイヤーとの距離をチェック（20ピクセル以内で即座に当たり判定）
	var player = _find_player()
	if player:
		var distance_to_player = position.distance_to(player.position)
		
		if distance_to_player <= 20.0:
			# 初めて20以下になった時に即座にダメージと削除
			_log_debug("HITTING PLAYER! Distance: %.1f" % distance_to_player)
			has_hit = true
			
			# ダメージ処理
			player.take_damage(20)
			_log_debug("Damage dealt to player: 20")
			
			# 即座に削除
			_destroy_immediately()
			return
	
	# 画面外に出たら削除
	if position.x < -100 or position.x > 800 or position.y < -100 or position.y > 1400:
		_destroy_immediately()

## ライフタイム終了時の処理
func _on_lifetime_timeout() -> void:
	_log_debug("Magic bullet lifetime expired")
	_destroy_immediately()

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

## エラーログ出力
func _log_error(message: String) -> void:
	print("[MagicBullet] ERROR: %s" % message)

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[MagicBullet] %s" % message)