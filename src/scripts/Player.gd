extends CharacterBody2D
class_name Player

## プレイヤーキャラクターの制御クラス
## 歩行アニメーション、移動、位置リセット機能を提供

@export var idle_bob_speed: float = GameConstants.PLAYER_IDLE_BOB_SPEED
@export var idle_bob_height: float = GameConstants.PLAYER_IDLE_BOB_HEIGHT

@onready var sprite: Sprite2D = $Sprite2D
@onready var walk_timer: Timer = $WalkAnimationTimer

var initial_position: Vector2
var time_passed: float = 0.0
var is_idle: bool = true

# 歩行アニメーション用
var walk_sprites: Array[Texture2D] = []
var current_frame: int = 0

signal position_changed(new_position: Vector2)
signal player_reset()

func _ready():
	initial_position = position
	_setup_walk_animation()
	_log_debug("Player initialized at position: %s" % position)

func _physics_process(delta):
	# 地面の上を歩くため浮遊アニメーションは停止
	pass

func _setup_walk_animation() -> void:
	"""歩行アニメーション用のスプライトを読み込み"""
	walk_sprites.clear()
	
	# スプライトの基本設定
	if sprite:
		sprite.scale = Vector2(GameConstants.PLAYER_SPRITE_SCALE, GameConstants.PLAYER_SPRITE_SCALE)
		sprite.flip_h = GameConstants.PLAYER_SPRITE_FLIP_H
		_log_debug("Set sprite scale: %f, flip_h: %s" % [GameConstants.PLAYER_SPRITE_SCALE, GameConstants.PLAYER_SPRITE_FLIP_H])
	
	# 歩行スプライトを読み込み
	for sprite_path in GameConstants.PLAYER_WALK_SPRITES:
		var texture = _load_texture_safe(sprite_path)
		if texture:
			walk_sprites.append(texture)
			_log_debug("Loaded walk sprite: %s" % sprite_path)
	
	# 初期テクスチャ設定
	if walk_sprites.size() > 0 and sprite:
		sprite.texture = walk_sprites[0]
		_log_debug("Set initial sprite texture")
	
	# アニメーション速度設定
	if walk_timer:
		walk_timer.wait_time = 1.0 / GameConstants.PLAYER_ANIMATION_SPEED
		_log_debug("Walk animation timer set to: %f seconds" % walk_timer.wait_time)

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
	print("[Player] ERROR: %s" % message)

func _update_idle_animation(delta: float) -> void:
	"""アイドルアニメーションの更新（位置の浮遊）"""
	time_passed += delta
	var bob_offset = sin(time_passed * idle_bob_speed) * idle_bob_height
	position.y = initial_position.y + bob_offset

func _on_walk_animation_timer_timeout():
	"""歩行アニメーションフレームの切り替え"""
	if walk_sprites.size() <= 1:
		return
	
	current_frame = (current_frame + 1) % walk_sprites.size()
	sprite.texture = walk_sprites[current_frame]
	_log_debug("Walk animation frame: %d/%d" % [current_frame, walk_sprites.size() - 1])

## 指定位置への移動
func move_to_position(new_pos: Vector2) -> void:
	if not _is_valid_position(new_pos):
		_log_debug("Invalid position specified: %s" % new_pos)
		return
	
	position = new_pos
	initial_position = new_pos
	time_passed = 0.0
	position_changed.emit(new_pos)
	_log_debug("Player moved to: %s" % new_pos)

## 相対移動（右）
func move_right(distance: float = GameConstants.PLAYER_MOVE_DISTANCE) -> void:
	var new_pos = Vector2(position.x + distance, position.y)
	move_to_position(new_pos)

## 相対移動（左）
func move_left(distance: float = GameConstants.PLAYER_MOVE_DISTANCE) -> void:
	var new_pos = Vector2(position.x - distance, position.y)
	move_to_position(new_pos)

## 中央位置へのリセット
func reset_to_center() -> void:
	move_to_position(GameConstants.PLAYER_DEFAULT_POSITION)
	player_reset.emit()
	_log_debug("Player reset to center")

## 現在位置の取得
func get_current_position() -> Vector2:
	return position

## 位置の有効性チェック
func _is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= GameConstants.SCREEN_WIDTH and \
		   pos.y >= 0 and pos.y <= GameConstants.SCREEN_HEIGHT

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[Player] %s" % message)