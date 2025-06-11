extends ScrollerBase
class_name GroundScroller

## 地面タイルのスクロールシステム
## 単一の地面タイルを無限に横に繋げてスクロールさせる

@export var ground_tile_path: String = GameConstants.GROUND_TILE_PATH

signal ground_looped()

func get_scroller_name() -> String:
	return "GroundScroller"

func initialize_scroller() -> void:
	if ground_tile_path.is_empty():
		_log_error("No ground tile path provided")
		return
	
	_setup_ground_tiles()
	start_scroll()
	_log_debug("Initialized with %d tiles" % sprites.size())

## 地面タイルの初期設定
func _setup_ground_tiles() -> void:
	_clear_sprites()
	
	var ground_texture = _load_texture_safe(ground_tile_path)
	if not ground_texture:
		return
	
	var scale_factor = GameConstants.GROUND_HEIGHT / ground_texture.get_height()
	var scaled_width = ground_texture.get_width() * scale_factor
	tile_width = scaled_width
	
	var tiles_needed = _calculate_tiles_needed(scaled_width)
	_log_debug("Creating %d ground tiles with scale: %f" % [tiles_needed, scale_factor])
	
	for i in range(tiles_needed):
		var sprite = _create_sprite_with_texture(
			ground_texture,
			scale_factor,
			i * scaled_width,
			GameConstants.GROUND_Y_POSITION
		)
		
		if sprite:
			_log_debug("Created ground sprite %d at x: %f" % [i, sprite.position.x])

## ループシグナルの転送
func _check_and_reposition_sprites() -> void:
	super._check_and_reposition_sprites()
	# 基底クラスのscroller_looped シグナルを ground_looped として転送
	if not scroller_looped.is_connected(_on_scroller_looped):
		scroller_looped.connect(_on_scroller_looped)

func _on_scroller_looped() -> void:
	ground_looped.emit()