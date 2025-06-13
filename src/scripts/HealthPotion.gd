extends Node2D
class_name HealthPotion

## 回復薬クラス（視覚効果のみ）
## 敵撃破時に視覚的フィードバックとして表示される

@onready var sprite: Sprite2D = $Sprite2D
@onready var disappear_timer: Timer

var heal_amount: int = 0  # 表示用の回復量
var float_time: float = 0.0
var initial_position: Vector2
var spawn_position: Vector2

# テキスト描画用
var show_value_text: bool = true
var text_font: Font

signal potion_collected(heal_amount: int)

func _ready():
	# 回復量をPlayerStatsから動的に取得（表示用）
	heal_amount = PlayerStats.get_potion_heal_amount()
	
	# スプライトの設定
	_setup_sprite()
	
	# 自動消失タイマーの設定
	_setup_disappear_timer()
	
	# テキストフォントの設定
	_setup_text_font()
	
	# 初期位置を記録
	initial_position = global_position
	spawn_position = global_position
	
	_log_debug("HealthPotion visual effect created at position: %s with heal amount: %d" % [global_position, heal_amount])

func _setup_sprite() -> void:
	"""スプライトの初期設定"""
	if sprite:
		# 回復薬の画像を設定
		var texture = load(GameConstants.HEALTH_POTION_SPRITE)
		if texture:
			sprite.texture = texture
			sprite.scale = Vector2(GameConstants.HEALTH_POTION_SCALE, GameConstants.HEALTH_POTION_SCALE)
		else:
			_log_error("Failed to load health potion sprite: " + GameConstants.HEALTH_POTION_SPRITE)

func _setup_disappear_timer() -> void:
	"""自動消失タイマーの設定"""
	disappear_timer = Timer.new()
	disappear_timer.wait_time = 2.0  # コインと同じ2秒に統一
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

func _process(delta: float) -> void:
	"""フレーム更新処理"""
	_update_float_animation(delta)

func _draw():
	if show_value_text:
		_draw_value_text()

## 回復量テキストの描画
func _draw_value_text() -> void:
	"""_draw()メソッドで回復量テキストを直接描画"""
	var text = "+%d" % heal_amount
	var font_size = 32
	
	# ポーションのサイズとスケールを考慮して位置を計算
	var potion_size = Vector2(16, 16)  # tile_0114.pngの元サイズ
	var scaled_size = potion_size * GameConstants.HEALTH_POTION_SCALE  # 実際の表示サイズ
	
	# テキストをポーションアイコンの右側に配置（元の配置に戻す）
	var text_x = scaled_size.x / 2 + 5  # ポーションの右端から適切な位置
	
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
	var text_color = Color(0.2, 1.0, 0.2, 1.0)  # 緑色
	draw_string(text_font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	
	_log_debug("Heal value text drawn: %s at position: %s (ascent: %f, descent: %f)" % [text, text_position, font_ascent, font_descent])

func _update_float_animation(delta: float) -> void:
	"""浮遊アニメーションの更新"""
	float_time += delta * GameConstants.HEALTH_POTION_FLOAT_SPEED
	var float_offset = sin(float_time) * GameConstants.HEALTH_POTION_FLOAT_HEIGHT
	
	# ポーション全体（アイコン+テキスト）をレベル表示より上に配置
	var base_x = spawn_position.x  # 横位置はそのまま
	var base_y = spawn_position.y + float_offset - 80  # 上側に80px移動してレベル表示より上に配置
	
	position = Vector2(base_x, base_y)

func _on_disappear_timer_timeout() -> void:
	"""自動消失時間経過時の処理"""
	_log_debug("Health potion visual effect lifetime expired, removing from scene")
	_remove_potion()



func _remove_potion() -> void:
	"""回復薬をシーンから削除"""
	queue_free()

## 回復量の取得
func get_heal_amount() -> int:
	return heal_amount

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[HealthPotion] %s" % message)

## エラーログ出力
func _log_error(message: String) -> void:
	print("[HealthPotion] ERROR: %s" % message)