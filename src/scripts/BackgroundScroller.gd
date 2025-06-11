extends ScrollerBase
class_name BackgroundScroller

## 背景スクロールシステム
## 4枚の背景画像を無限ループでスクロールさせる

@export var tile_paths: Array[String] = GameConstants.BACKGROUND_TILE_PATHS

var current_offset: float = 0.0

signal background_looped()

func get_scroller_name() -> String:
	return "BackgroundScroller"

func initialize_scroller() -> void:
	if tile_paths.is_empty():
		_log_error("No background tile paths provided")
		return
	
	_setup_background_tiles()
	start_scroll()
	_log_debug("Initialized with %d tiles" % sprites.size())

## 背景タイルの初期設定
func _setup_background_tiles() -> void:
	_clear_sprites()
	
	var first_texture = _load_texture_safe(tile_paths[0])
	if not first_texture:
		return
	
	var scale_factor = GameConstants.PLAY_AREA_HEIGHT / first_texture.get_height()
	var scaled_width = first_texture.get_width() * scale_factor
	tile_width = scaled_width
	
	var tiles_needed = _calculate_tiles_needed(scaled_width)
	_log_debug("Creating %d background tiles with scale: %f" % [tiles_needed, scale_factor])
	
	for i in range(tiles_needed):
		var texture_index = i % tile_paths.size()
		var texture = _load_texture_safe(tile_paths[texture_index])
		
		if texture:
			var sprite = _create_sprite_with_texture(
				texture,
				scale_factor,
				i * scaled_width,
				GameConstants.PLAY_AREA_HEIGHT / 2.0
			)
			
			if sprite:
				_log_debug("Created background sprite %d at x: %f" % [i, sprite.position.x])

## スクロール更新のオーバーライド（オフセット追跡付き）
func _update_scroll(delta: float) -> void:
	if sprites.is_empty():
		return
	
	current_offset += scroll_speed * delta
	super._update_scroll(delta)

## ループシグナルの転送
func _check_and_reposition_sprites() -> void:
	super._check_and_reposition_sprites()
	# 基底クラスのscroller_looped シグナルを background_looped として転送
	if not scroller_looped.is_connected(_on_scroller_looped):
		scroller_looped.connect(_on_scroller_looped)

func _on_scroller_looped() -> void:
	background_looped.emit()

## 現在のスクロール位置を取得
func get_scroll_offset() -> float:
	return current_offset

## スクロール位置をリセット
func reset_scroll() -> void:
	current_offset = 0.0
	super.reset_scroll()