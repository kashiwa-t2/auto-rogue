extends RefCounted
class_name MovementCalculator

## 移動計算統一クラス
## 敵の相対速度計算とスクロール連動を提供

## ScrollManagerから現在のスクロール速度を取得
static func get_current_scroll_speed(from_node: Node, error_tag: String = "MovementCalculator") -> float:
	if not from_node:
		GameLogger.log_error(error_tag, "Cannot get scroll speed: from_node is null")
		return 0.0
	
	var main_scene = from_node.get_node_or_null("/root/MainScene")
	if not main_scene or not "scroll_manager" in main_scene:
		GameLogger.log_debug(error_tag, "MainScene or scroll_manager not found, using fallback")
		return 0.0
	
	var scroll_manager = main_scene.scroll_manager
	if not scroll_manager or not scroll_manager.has_method("get_current_scroll_speed"):
		GameLogger.log_debug(error_tag, "scroll_manager invalid, using fallback")
		return 0.0
	
	var speed = scroll_manager.get_current_scroll_speed()
	GameLogger.log_debug(error_tag, "Current scroll speed: %f" % speed)
	return speed

## 敵の絶対移動速度を計算（相対速度 + スクロール速度）
static func calculate_enemy_absolute_speed(from_node: Node, relative_speed: float, error_tag: String = "MovementCalculator") -> float:
	var scroll_speed = get_current_scroll_speed(from_node, error_tag)
	var absolute_speed = relative_speed + scroll_speed
	
	GameLogger.log_debug(error_tag, "Movement calculation - Relative: %f, Scroll: %f, Absolute: %f" % [relative_speed, scroll_speed, absolute_speed])
	return absolute_speed

## 敵の移動ベクトルを計算
static func calculate_enemy_movement_vector(from_node: Node, relative_speed: float, delta: float, error_tag: String = "MovementCalculator") -> Vector2:
	var absolute_speed = calculate_enemy_absolute_speed(from_node, relative_speed, error_tag)
	return Vector2(-absolute_speed * delta, 0)

## 基本敵の移動計算
static func calculate_basic_enemy_movement(from_node: Node, delta: float, error_tag: String = "BasicEnemy") -> Vector2:
	return calculate_enemy_movement_vector(from_node, GameConstants.ENEMY_RELATIVE_SPEED, delta, error_tag)

## 魔法使い敵の移動計算
static func calculate_mage_enemy_movement(from_node: Node, delta: float, error_tag: String = "MageEnemy") -> Vector2:
	return calculate_enemy_movement_vector(from_node, GameConstants.MAGE_RELATIVE_SPEED, delta, error_tag)

## 敵タイプ別の移動計算
static func calculate_enemy_movement_by_type(from_node: Node, enemy_type: int, delta: float, error_tag: String = "MovementCalculator") -> Vector2:
	var relative_speed: float
	
	match enemy_type:
		0: # EnemyBase.EnemyType.BASIC
			relative_speed = GameConstants.ENEMY_RELATIVE_SPEED
		1: # EnemyBase.EnemyType.FAST
			relative_speed = GameConstants.ENEMY_RELATIVE_SPEED * 1.5  # 1.5倍速
		2: # EnemyBase.EnemyType.STRONG
			relative_speed = GameConstants.ENEMY_RELATIVE_SPEED * 0.8  # 0.8倍速
		3: # EnemyBase.EnemyType.MAGE
			relative_speed = GameConstants.MAGE_RELATIVE_SPEED
		4: # EnemyBase.EnemyType.BOSS
			relative_speed = GameConstants.ENEMY_RELATIVE_SPEED * 0.6  # 0.6倍速
		_:
			GameLogger.log_warning(error_tag, "Unknown enemy type: %d, using default speed" % enemy_type)
			relative_speed = GameConstants.ENEMY_RELATIVE_SPEED
	
	return calculate_enemy_movement_vector(from_node, relative_speed, delta, error_tag)

## プレイヤーとの距離計算
static func calculate_distance_to_player(from_position: Vector2, from_node: Node, error_tag: String = "MovementCalculator") -> float:
	var player = GameUtils.find_player(from_node, error_tag)
	if not player:
		return INF
	
	return from_position.distance_to(player.position)

## 目標位置への到達チェック
static func has_reached_target(current_position: Vector2, target_x: float = GameConstants.ENEMY_TARGET_X) -> bool:
	return current_position.x <= target_x

## 画面外チェック
static func is_off_screen(position: Vector2, margin: float = 100.0) -> bool:
	return not GameUtils.is_position_on_screen(position, margin)