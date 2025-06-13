extends Area2D
class_name Coin

## コインクラス
## 敵を倒した時に出現するコイン・回転アニメーション・プレイヤーへの移動

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_timer: Timer = $AnimationTimer
@onready var collection_area: CollisionShape2D = $CollisionShape2D
@onready var disappear_timer: Timer

var coin_textures: Array[Texture2D] = []
var current_frame: int = 0
var coin_value: int = 1
var move_tween: Tween
var is_collected: bool = false
var target_player: Node2D = null

# アニメーション状態
var spawn_position: Vector2
var float_phase: float = 0.0

# テキスト描画用
var show_value_text: bool = true
var text_font: Font

signal coin_collected(value: int)

func _ready():
	_setup_coin_animation()
	_setup_collision()
	_setup_disappear_timer()
	_setup_text_font()
	_start_spawn_animation()
	_log_debug("Coin initialized at position: %s" % position)

func _process(delta):
	if not is_collected:
		_update_float_animation(delta)

func _draw():
	if show_value_text and not is_collected:
		_draw_value_text()

## コインアニメーションの初期設定
func _setup_coin_animation() -> void:
	"""回転アニメーション用のテクスチャを読み込み"""
	coin_textures.clear()
	
	# コインテクスチャを読み込み
	var coin_paths = [
		"res://assets/sprites/kenney_pixel-platformer/Tiles/tile_0151.png",
		"res://assets/sprites/kenney_pixel-platformer/Tiles/tile_0152.png"
	]
	
	for texture_path in coin_paths:
		var texture = _load_texture_safe(texture_path)
		if texture:
			coin_textures.append(texture)
			_log_debug("Loaded coin texture: %s" % texture_path)
	
	# スプライト設定
	if sprite and coin_textures.size() > 0:
		sprite.texture = coin_textures[0]
		sprite.scale = Vector2(GameConstants.COIN_SCALE, GameConstants.COIN_SCALE)
		sprite.z_index = 15  # プレイヤーや敵より手前に表示
		_log_debug("Coin sprite initialized")
	
	# アニメーションタイマー設定
	if animation_timer:
		animation_timer.wait_time = 1.0 / GameConstants.COIN_ANIMATION_SPEED
		animation_timer.timeout.connect(_on_animation_timer_timeout)
		animation_timer.start()
		_log_debug("Coin animation timer started: %f seconds" % animation_timer.wait_time)

## コリジョンの設定（無効化）
func _setup_collision() -> void:
	"""衝突判定は使用しないが、コリジョンエリアは残す"""
	if collection_area:
		var shape = CircleShape2D.new()
		shape.radius = GameConstants.COIN_COLLECTION_RADIUS
		collection_area.shape = shape
		# 衝突判定を無効化
		collection_area.disabled = true
		_log_debug("Coin collision area disabled")
	
	# シグナル接続は不要（自動取得のため）

## 自動消失タイマーの設定
func _setup_disappear_timer() -> void:
	"""2秒後にコインを自動的に消去するタイマー設定"""
	disappear_timer = Timer.new()
	disappear_timer.wait_time = 2.0
	disappear_timer.one_shot = true
	disappear_timer.timeout.connect(_on_disappear_timer_timeout)
	add_child(disappear_timer)
	disappear_timer.start()
	_log_debug("Disappear timer started: 2.0 seconds")

## テキスト描画フォントの設定
func _setup_text_font() -> void:
	"""_draw()で使用するフォントの設定"""
	# デフォルトフォントを取得
	text_font = ThemeDB.fallback_font
	_log_debug("Text font setup completed")

## スポーン時の自動取得
func _auto_collect_on_spawn() -> void:
	"""コインがスポーンした瞬間にプレイヤーに取得される"""
	# プレイヤーを検索
	var player_node = _find_player()
	if player_node and player_node.has_method("collect_coin"):
		_log_debug("Auto-collecting coin on spawn! Value: %d" % coin_value)
		player_node.collect_coin(coin_value)
		# アニメーション表示は継続（視覚的フィードバック）
		# 2秒後に自動で消える
	else:
		_log_error("Player not found for auto-collection")

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
	
	# 親を辿ってMainSceneを見つけてからプレイヤーを取得
	var current = get_parent()
	while current:
		if current.name == "PlayArea":
			var player_node = current.get_node_or_null("Player")
			if player_node:
				return player_node as Node2D
		current = current.get_parent()
	
	return null

## 価値テキストの描画
func _draw_value_text() -> void:
	"""_draw()メソッドで価値テキストを直接描画"""
	var text = "+%d" % coin_value
	var font_size = 32
	
	# コインのサイズとスケールを考慮して位置を計算
	var coin_size = Vector2(16, 16)  # tile_0151.pngの元サイズ
	var scaled_size = coin_size * GameConstants.COIN_SCALE  # 実際の表示サイズ
	var text_x = scaled_size.x / 2 + 5  # コインの右端から適切な位置（フォント32px対応）
	
	# フォントメトリクスを使って正確な中央配置を計算
	var font_ascent = text_font.get_ascent(font_size)
	var font_descent = text_font.get_descent(font_size)
	
	# 文字の視覚的中央をスプライト中央(Y=0)に合わせるためのベースライン位置
	var text_y = (font_ascent - font_descent) / 2.0 - 2  # 2ピクセル上に調整
	
	var text_position = Vector2(text_x, text_y)
	
	# 影を先に描画
	var shadow_offset = Vector2(1, 1)
	var shadow_color = Color(0.0, 0.0, 0.0, 0.8)
	draw_string(text_font, text_position + shadow_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow_color)
	
	# メインテキストを描画
	var text_color = Color(1.0, 0.8, 0.0, 1.0)  # 金色
	draw_string(text_font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	
	_log_debug("Value text drawn: %s at position: %s (ascent: %f, descent: %f)" % [text, text_position, font_ascent, font_descent])

## スポーンアニメーションの開始
func _start_spawn_animation() -> void:
	"""コイン出現時のアニメーション"""
	spawn_position = position
	
	# 即座に表示（シンプルな実装）
	modulate.a = 1.0
	scale = Vector2.ONE
	_log_debug("Coin spawn animation completed")

## 浮遊アニメーションの更新
func _update_float_animation(delta: float) -> void:
	"""コインの浮遊アニメーション"""
	float_phase += delta * GameConstants.COIN_FLOAT_SPEED
	var float_offset = sin(float_phase) * GameConstants.COIN_FLOAT_HEIGHT
	# コイン全体をレベル表示より上に配置（ポーションより40px下）
	var base_y = spawn_position.y + float_offset - 40  # 上側に40px移動
	position = Vector2(spawn_position.x, base_y)

## アニメーションフレーム切り替え
func _on_animation_timer_timeout() -> void:
	"""コイン回転アニメーションのフレーム切り替え"""
	if coin_textures.size() <= 1 or not sprite:
		return
	
	current_frame = (current_frame + 1) % coin_textures.size()
	sprite.texture = coin_textures[current_frame]

## コイン収集開始（無効化）
func start_collection(player_node: Node2D) -> void:
	"""コイン収集は既にスポーン時に完了しているため無効化"""
	# 何もしない - アニメーションは2秒後に自動で終了
	pass

## カーブを描いてプレイヤーに向かう移動
func _curve_to_player(current_pos: Vector2) -> void:
	"""コインがカーブを描いてプレイヤーに向かう"""
	position = current_pos

## 収集完了時の処理
func _on_collection_finished() -> void:
	"""コイン収集アニメーション完了"""
	coin_collected.emit(coin_value)
	_log_debug("Coin collected! Value: %d" % coin_value)
	queue_free()

## 自動消失タイマーのタイムアウト処理
func _on_disappear_timer_timeout() -> void:
	"""2秒経過後の自動消失処理"""
	if not is_collected:
		queue_free()

## コインの価値設定
func set_coin_value(value: int) -> void:
	"""コインの価値を設定"""
	coin_value = value
	queue_redraw()  # _draw()を再実行してテキストを更新
	_log_debug("Coin value set to: %d" % coin_value)
	# 正しい価値が設定された後に自動取得を実行
	_auto_collect_on_spawn()

## MainSceneとのシグナル接続
func _connect_to_main_scene() -> void:
	"""MainSceneとシグナル接続"""
	# 親を辿ってMainSceneを探す
	var current = get_parent()
	while current and current.name != "MainScene":
		current = current.get_parent()
	
	if current and current.has_method("_on_coin_collected"):
		coin_collected.connect(current._on_coin_collected)
		_log_debug("Connected coin_collected signal to MainScene")
	else:
		_log_debug("MainScene not found or doesn't have _on_coin_collected method")

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

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[Coin] %s" % message)

## エラーログ出力
func _log_error(message: String) -> void:
	print("[Coin] ERROR: %s" % message)