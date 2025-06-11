extends Node2D
class_name ScrollerBase

## スクロール要素の基底クラス
## 共通のスクロール処理とスプライト管理を提供

@export var scroll_speed: float = GameConstants.BACKGROUND_SCROLL_SPEED
@export var auto_start: bool = true

var sprites: Array[Sprite2D] = []
var tile_width: float = 0.0
var is_scrolling: bool = false

signal scroller_looped()

func _ready():
	if auto_start:
		initialize_scroller()

func _process(delta):
	if is_scrolling:
		_update_scroll(delta)

## 継承クラスで実装する抽象メソッド
func initialize_scroller() -> void:
	push_error("ScrollerBase.initialize_scroller() must be implemented by subclass")

func get_scroller_name() -> String:
	return "ScrollerBase"

## 共通のスクロール更新処理
func _update_scroll(delta: float) -> void:
	if sprites.is_empty():
		return
	
	# 各スプライトの位置を更新
	for sprite in sprites:
		sprite.position.x -= scroll_speed * delta
	
	# 画面外に出たスプライトを右端に移動
	_check_and_reposition_sprites()

## スプライトの位置調整
func _check_and_reposition_sprites() -> void:
	for sprite in sprites:
		if sprite.position.x <= -tile_width:
			var rightmost_x = _get_rightmost_sprite_position()
			sprite.position.x = rightmost_x + tile_width
			scroller_looped.emit()
			_log_debug("Repositioned sprite to x: %f" % sprite.position.x)

## 最も右にあるスプライトのX座標を取得
func _get_rightmost_sprite_position() -> float:
	var max_x = -INF
	for sprite in sprites:
		if sprite.position.x > max_x:
			max_x = sprite.position.x
	return max_x

## 必要なタイル数の計算
func _calculate_tiles_needed(tile_width_param: float) -> int:
	if tile_width_param <= 0:
		return 0
	
	var screen_coverage = GameConstants.SCREEN_WIDTH + tile_width_param
	return int(ceil(screen_coverage / tile_width_param)) + 1

## スプライト作成の共通処理
func _create_sprite_with_texture(texture: Texture2D, scale_factor: float, pos_x: float, pos_y: float) -> Sprite2D:
	if not texture:
		_log_error("Failed to create sprite: texture is null")
		return null
	
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.position.x = pos_x
	sprite.position.y = pos_y
	
	add_child(sprite)
	sprites.append(sprite)
	return sprite

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

## スクロール制御
func set_scroll_speed(new_speed: float) -> void:
	scroll_speed = new_speed
	_log_debug("Scroll speed changed to: %f" % scroll_speed)

func start_scroll() -> void:
	is_scrolling = true
	set_process(true)
	_log_debug("Scroll started")

func pause_scroll() -> void:
	is_scrolling = false
	set_process(false)
	_log_debug("Scroll paused")

func resume_scroll() -> void:
	is_scrolling = true
	set_process(true)
	_log_debug("Scroll resumed")

func reset_scroll() -> void:
	_clear_sprites()
	initialize_scroller()
	_log_debug("Scroll reset")

## 状態取得
func get_scroll_speed() -> float:
	return scroll_speed

func is_scroll_active() -> bool:
	return is_scrolling

## クリーンアップ
func _clear_sprites() -> void:
	for sprite in sprites:
		if sprite and is_instance_valid(sprite):
			sprite.queue_free()
	sprites.clear()
	tile_width = 0.0

## ログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[%s] %s" % [get_scroller_name(), message])

func _log_error(message: String) -> void:
	print("[%s] ERROR: %s" % [get_scroller_name(), message])