extends Node
class_name ScrollManager

## スクロール要素の統一管理クラス
## 複数のスクローラーを一元的に制御

var scrollers: Array[ScrollerBase] = []

signal scroll_speed_changed(new_speed: float)
signal scroller_added(scroller: ScrollerBase)
signal scroller_removed(scroller: ScrollerBase)

func _ready():
	_log_debug("ScrollManager initialized")

## スクローラーの追加
func add_scroller(scroller: ScrollerBase) -> void:
	if not scroller:
		_log_error("Cannot add null scroller")
		return
	
	if scroller in scrollers:
		_log_debug("Scroller already added: %s" % scroller.get_scroller_name())
		return
	
	scrollers.append(scroller)
	scroller_added.emit(scroller)
	_log_debug("Added scroller: %s" % scroller.get_scroller_name())

## スクローラーの削除
func remove_scroller(scroller: ScrollerBase) -> void:
	if not scroller:
		return
	
	var index = scrollers.find(scroller)
	if index >= 0:
		scrollers.remove_at(index)
		scroller_removed.emit(scroller)
		_log_debug("Removed scroller: %s" % scroller.get_scroller_name())

## 全スクローラーの速度設定
func set_all_scroll_speed(speed: float) -> void:
	for scroller in scrollers:
		if scroller and is_instance_valid(scroller):
			scroller.set_scroll_speed(speed)
	
	scroll_speed_changed.emit(speed)
	_log_debug("Set all scroll speed to: %f" % speed)

## 全スクローラーの一時停止
func pause_all_scrollers() -> void:
	for scroller in scrollers:
		if scroller and is_instance_valid(scroller):
			scroller.pause_scroll()
	_log_debug("Paused all scrollers")

## 全スクローラーの再開
func resume_all_scrollers() -> void:
	for scroller in scrollers:
		if scroller and is_instance_valid(scroller):
			scroller.resume_scroll()
	_log_debug("Resumed all scrollers")

## 全スクローラーのリセット
func reset_all_scrollers() -> void:
	for scroller in scrollers:
		if scroller and is_instance_valid(scroller):
			scroller.reset_scroll()
	_log_debug("Reset all scrollers")

## 現在のスクロール速度を取得
func get_current_scroll_speed() -> float:
	if scrollers.size() > 0 and scrollers[0] and is_instance_valid(scrollers[0]):
		# スクロールが実際に動いている場合のみ速度を返す
		if scrollers[0].is_scroll_active():
			return scrollers[0].get_scroll_speed()
		else:
			return 0.0
	return GameConstants.GROUND_SCROLL_SPEED

## 特定のスクローラーを名前で検索
func get_scroller_by_name(scroller_name: String) -> ScrollerBase:
	for scroller in scrollers:
		if scroller and scroller.get_scroller_name() == scroller_name:
			return scroller
	return null


## 登録されているスクローラー数を取得
func get_scroller_count() -> int:
	return scrollers.size()

## アクティブなスクローラー数を取得
func get_active_scroller_count() -> int:
	var count = 0
	for scroller in scrollers:
		if scroller and is_instance_valid(scroller) and scroller.is_scroll_active():
			count += 1
	return count

## 全スクローラーの状態取得
func get_all_scroller_status() -> Dictionary:
	var status = {}
	for scroller in scrollers:
		if scroller and is_instance_valid(scroller):
			status[scroller.get_scroller_name()] = {
				"speed": scroller.get_scroll_speed(),
				"active": scroller.is_scroll_active(),
				"valid": true
			}
		else:
			status["invalid_scroller"] = {"valid": false}
	return status

## 無効なスクローラーのクリーンアップ
func cleanup_invalid_scrollers() -> void:
	var valid_scrollers: Array[ScrollerBase] = []
	
	for scroller in scrollers:
		if scroller and is_instance_valid(scroller):
			valid_scrollers.append(scroller)
		else:
			_log_debug("Cleaned up invalid scroller")
	
	scrollers = valid_scrollers

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[ScrollManager] %s" % message)

func _log_error(message: String) -> void:
	print("[ScrollManager] ERROR: %s" % message)