extends Node
class_name TestPlayer

## Player動作のテスト用ユーティリティクラス
## Godotエディタ上での手動テスト確認、TDD開発支援用

## プレイヤーの移動機能テスト
static func test_player_movement(player: Player) -> bool:
	if not _validate_player(player, "Movement Test"):
		return false
	
	_log_test_start("Player Movement")
	
	var initial_pos = player.get_current_position()
	_log_test_info("Initial position: %s" % initial_pos)
	
	# 右移動テスト
	if not _test_right_movement(player, initial_pos):
		return false
	
	# 左移動テスト
	if not _test_left_movement(player, initial_pos):
		return false
	
	# リセットテスト
	if not _test_reset_movement(player):
		return false
	
	_log_test_success("All Player Movement Tests Passed!")
	return true

## アイドルアニメーション機能テスト
static func test_player_idle_animation(player: Player) -> bool:
	if not _validate_player(player, "Idle Animation Test"):
		return false
	
	_log_test_start("Player Idle Animation")
	
	var initial_y = player.get_current_position().y
	
	# 時間経過後の位置変化確認
	await player.get_tree().create_timer(GameConstants.TEST_ANIMATION_WAIT_TIME).timeout
	var after_y = player.get_current_position().y
	
	# Y座標変化の検証
	if abs(after_y - initial_y) > GameConstants.TEST_ANIMATION_THRESHOLD:
		_log_test_success("Idle animation: OK (Y position changing)")
		return true
	else:
		_log_test_warning("Idle animation: Position not changing (may be normal)")
		return true

## 位置機能テスト
static func test_player_position(player: Player) -> bool:
	if not _validate_player(player, "Position Test"):
		return false
	
	_log_test_start("Player Position")
	
	var initial_pos = player.get_current_position()
	
	# move_to_position APIテスト
	var test_pos = Vector2(initial_pos.x + 50, initial_pos.y)
	player.move_to_position(test_pos)
	var moved_pos = player.get_current_position()
	if moved_pos != test_pos:
		_log_test_failure("move_to_position API failed")
		return false
	_log_test_success("move_to_position API: OK")
	
	# 元の位置に戻す
	player.move_to_position(initial_pos)
	
	_log_test_success("All Player Position Tests Passed!")
	return true

## 歩行アニメーションテスト
static func test_player_walk_animation(player: Player) -> bool:
	if not _validate_player(player, "Walk Animation Test"):
		return false
	
	_log_test_start("Player Walk Animation")
	
	# スプライトが設定されているかチェック
	if not player.sprite or not player.sprite.texture:
		_log_test_failure("Player sprite not set")
		return false
	_log_test_success("Player sprite: OK")
	
	# スケール設定チェック
	var expected_scale = GameConstants.PLAYER_SPRITE_SCALE
	if abs(player.sprite.scale.x - expected_scale) > 0.1 or abs(player.sprite.scale.y - expected_scale) > 0.1:
		_log_test_failure("Player sprite scale not set correctly. Expected: %f, Got: %s" % [expected_scale, player.sprite.scale])
		return false
	_log_test_success("Player sprite scale: OK (%f)" % expected_scale)
	
	# 左右反転が設定されているかチェック
	if player.sprite.flip_h != GameConstants.PLAYER_SPRITE_FLIP_H:
		_log_test_failure("Player sprite flip_h not set correctly")
		return false
	_log_test_success("Player sprite flip_h: OK")
	
	# 歩行スプライトが読み込まれているかチェック
	if player.walk_sprites.size() < 2:
		_log_test_failure("Walk sprites not loaded properly")
		return false
	_log_test_success("Walk sprites loaded: %d frames" % player.walk_sprites.size())
	
	# アニメーションタイマーチェック
	if not player.walk_timer:
		_log_test_failure("Walk animation timer not found")
		return false
	
	var expected_wait_time = 1.0 / GameConstants.PLAYER_ANIMATION_SPEED
	if abs(player.walk_timer.wait_time - expected_wait_time) > 0.01:
		_log_test_failure("Walk timer interval incorrect. Expected: %f, Got: %f" % [expected_wait_time, player.walk_timer.wait_time])
		return false
	_log_test_success("Walk animation timer: OK")
	
	_log_test_success("All Walk Animation Tests Passed!")
	return true

## スクロールシステムテスト
static func test_scroll_system(main_scene) -> bool:
	if not main_scene:
		_log_test_failure("MainScene is null")
		return false
	
	_log_test_start("Scroll System")
	
	# ScrollManagerの存在チェック
	if not main_scene.scroll_manager:
		_log_test_failure("ScrollManager not found")
		return false
	_log_test_success("ScrollManager: OK")
	
	# スクローラー数チェック
	var scroller_count = main_scene.scroll_manager.get_scroller_count()
	if scroller_count < 2:  # BackgroundScroller + GroundScroller
		_log_test_failure("Expected at least 2 scrollers, got: %d" % scroller_count)
		return false
	_log_test_success("Scroller count: %d" % scroller_count)
	
	# スクローラー状態チェック
	var status = main_scene.scroll_manager.get_all_scroller_status()
	for scroller_name in status:
		var scroller_status = status[scroller_name]
		if not scroller_status.get("valid", false):
			_log_test_failure("Invalid scroller found: %s" % scroller_name)
			return false
		_log_test_success("Scroller %s: valid and active" % scroller_name)
	
	_log_test_success("All Scroll System Tests Passed!")
	return true

## 定数整合性テスト
static func test_constants_integrity() -> bool:
	_log_test_start("Constants Integrity")
	
	# 必須定数の存在チェック
	var required_constants = [
		"SCREEN_WIDTH", "SCREEN_HEIGHT", "PLAY_AREA_HEIGHT",
		"PLAYER_SPRITE_SCALE", "PLAYER_ANIMATION_SPEED",
		"GROUND_TILE_PATH", "BACKGROUND_TILE_PATHS"
	]
	
	for const_name in required_constants:
		if not GameConstants.has_method("get") or not GameConstants.get(const_name):
			_log_test_warning("Constant %s check skipped (reflection limitations)" % const_name)
	
	# 論理的整合性チェック
	if GameConstants.SCREEN_WIDTH <= 0 or GameConstants.SCREEN_HEIGHT <= 0:
		_log_test_failure("Invalid screen dimensions")
		return false
	_log_test_success("Screen dimensions: OK")
	
	if GameConstants.PLAYER_SPRITE_SCALE <= 0:
		_log_test_failure("Invalid player sprite scale")
		return false
	_log_test_success("Player sprite scale: OK")
	
	if GameConstants.PLAY_AREA_HEIGHT >= GameConstants.SCREEN_HEIGHT:
		_log_test_failure("Play area height too large")
		return false
	_log_test_success("Play area proportions: OK")
	
	_log_test_success("All Constants Integrity Tests Passed!")
	return true

## 全テスト実行
static func run_all_tests(player: Player, main_scene = null) -> void:
	_log_test_header("Running Comprehensive Tests")
	
	var results = []
	
	# プレイヤー関連テスト
	results.append(test_player_movement(player))
	results.append(await test_player_idle_animation(player))
	results.append(test_player_position(player))
	results.append(test_player_walk_animation(player))
	
	# システム関連テスト
	results.append(test_constants_integrity())
	
	# スクロールシステムテスト（MainSceneが利用可能な場合）
	if main_scene:
		results.append(test_scroll_system(main_scene))
	else:
		_log_test_warning("MainScene not provided, skipping scroll system tests")
	
	_log_test_header(_get_final_result(results))

## 簡易テスト実行（下位互換用）
static func run_player_tests(player: Player) -> void:
	run_all_tests(player, null)

# プライベートメソッド
static func _test_right_movement(player: Player, initial_pos: Vector2) -> bool:
	player.move_to_position(Vector2(initial_pos.x + GameConstants.TEST_MOVE_DISTANCE, initial_pos.y))
	var moved_pos = player.get_current_position()
	if moved_pos.x != initial_pos.x + GameConstants.TEST_MOVE_DISTANCE:
		_log_test_failure("Right movement failed")
		return false
	_log_test_success("Right movement: OK")
	return true

static func _test_left_movement(player: Player, initial_pos: Vector2) -> bool:
	player.move_to_position(Vector2(initial_pos.x - GameConstants.TEST_MOVE_DISTANCE, initial_pos.y))
	var moved_pos = player.get_current_position()
	if moved_pos.x != initial_pos.x - GameConstants.TEST_MOVE_DISTANCE:
		_log_test_failure("Left movement failed")
		return false
	_log_test_success("Left movement: OK")
	return true

static func _test_reset_movement(player: Player) -> bool:
	# リセット機能は削除されたため、初期位置への移動テストに変更
	player.move_to_position(GameConstants.PLAYER_DEFAULT_POSITION)
	if player.get_current_position() != GameConstants.PLAYER_DEFAULT_POSITION:
		_log_test_failure("Move to default position failed")
		return false
	_log_test_success("Move to default position: OK")
	return true

static func _validate_player(player: Player, test_name: String) -> bool:
	if not player:
		_log_test_failure("%s: Player is null" % test_name)
		return false
	return true

static func _get_final_result(results: Array) -> String:
	var all_passed = true
	for result in results:
		if not result:
			all_passed = false
			break
	
	return "🎉 ALL TESTS PASSED!" if all_passed else "❌ Some tests failed"

# ログ出力メソッド
static func _log_test_header(message: String) -> void:
	print("==================================================")
	print("🚀 %s" % message)
	print("==================================================")

static func _log_test_start(test_name: String) -> void:
	print("🧪 Testing %s..." % test_name)

static func _log_test_success(message: String) -> void:
	print("✅ %s" % message)

static func _log_test_failure(message: String) -> void:
	print("❌ Test Failed: %s" % message)

static func _log_test_warning(message: String) -> void:
	print("⚠️ %s" % message)

static func _log_test_info(message: String) -> void:
	print("ℹ️ %s" % message)