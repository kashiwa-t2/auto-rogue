extends CanvasLayer

## シーン遷移管理クラス（シングルトン）
## フェードイン・フェードアウトでスムーズな画面遷移を実現

var fade_rect: ColorRect

func _ready():
	# フェード用のColorRectを作成
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade_rect)
	
	# 最初は透明に
	fade_rect.modulate.a = 0.0
	
	_log_debug("SceneTransition initialized")

## フェードアウト→シーン変更→フェードインを実行
func change_scene(scene_path: String, fade_out_duration: float = 0.5, fade_in_duration: float = 0.5) -> void:
	_log_debug("Starting scene transition to: %s" % scene_path)
	
	# フェードアウト
	await fade_out(fade_out_duration)
	
	# シーンを変更
	get_tree().change_scene_to_file(scene_path)
	
	# 少し待つ（新しいシーンの_ready()が完了するのを待つ）
	await get_tree().create_timer(0.1).timeout
	
	# フェードイン
	await fade_in(fade_in_duration)
	
	_log_debug("Scene transition completed")

## フェードアウト（画面を黒くする）
func fade_out(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

## フェードイン（画面を明るくする）
func fade_in(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished

## 即座にフェードをリセット（デバッグ用）
func reset_fade() -> void:
	fade_rect.modulate.a = 0.0

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[SceneTransition] %s" % message)