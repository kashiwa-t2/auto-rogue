extends RefCounted
class_name GameUtils

## 汎用ゲームユーティリティクラス
## テクスチャ読み込み、プレイヤー検索、その他共通機能を提供

## テクスチャの安全な読み込み
static func load_texture_safe(path: String, error_tag: String = "GameUtils") -> Texture2D:
	if path.is_empty():
		GameLogger.log_error(error_tag, "Empty texture path provided")
		return null
	
	var texture = load(path)
	if not texture:
		GameLogger.log_error(error_tag, "Failed to load texture: %s" % path)
		return null
	
	GameLogger.log_debug(error_tag, "Successfully loaded texture: %s" % path)
	return texture

## プレイヤーノードを検索
static func find_player(from_node: Node, error_tag: String = "GameUtils") -> Node2D:
	if not from_node:
		GameLogger.log_error(error_tag, "Cannot search for player: from_node is null")
		return null
	
	# 1. グループからプレイヤーを検索
	var players = from_node.get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		GameLogger.log_debug(error_tag, "Player found in group")
		return players[0] as Node2D
	
	# 2. パス検索
	var player_by_path = from_node.get_node_or_null("../../Player")
	if player_by_path:
		GameLogger.log_debug(error_tag, "Player found by relative path")
		return player_by_path as Node2D
	
	# 3. 親を辿ってPlayAreaを見つけてからプレイヤーを取得
	var current = from_node.get_parent()
	while current:
		if current.name == "PlayArea":
			var player_node = current.get_node_or_null("Player")
			if player_node:
				GameLogger.log_debug(error_tag, "Player found in PlayArea")
				return player_node as Node2D
		current = current.get_parent()
	
	GameLogger.log_error(error_tag, "Player not found")
	return null

## ノードの有効性チェック
static func is_valid_node(node: Node) -> bool:
	return node != null and is_instance_valid(node)

## ノードを安全に削除
static func safe_queue_free(node: Node, error_tag: String = "GameUtils") -> void:
	if is_valid_node(node):
		node.queue_free()
		GameLogger.log_debug(error_tag, "Node safely queued for deletion")
	else:
		GameLogger.log_warning(error_tag, "Attempted to delete invalid node")

## 配列から無効なノードを削除
static func cleanup_invalid_nodes(nodes: Array) -> Array:
	return nodes.filter(func(node): return is_valid_node(node))

## 位置が画面内かチェック
static func is_position_on_screen(position: Vector2, margin: float = 0.0) -> bool:
	var screen_rect = Rect2(
		Vector2(-margin, -margin),
		Vector2(GameConstants.SCREEN_WIDTH + margin * 2, GameConstants.SCREEN_HEIGHT + margin * 2)
	)
	return screen_rect.has_point(position)

## ランダムな範囲内の値を取得
static func random_range_f(min_val: float, max_val: float) -> float:
	return randf_range(min_val, max_val)

static func random_range_i(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)

## ランダムなVector2オフセットを生成
static func random_offset(max_x: float, max_y: float) -> Vector2:
	return Vector2(
		random_range_f(-max_x, max_x),
		random_range_f(-max_y, max_y)
	)

## 値を指定範囲内にクランプ
static func clamp_value(value: float, min_val: float, max_val: float) -> float:
	return clampf(value, min_val, max_val)

## 配列要素をランダムに選択
static func random_choice(array: Array):
	if array.is_empty():
		return null
	return array[randi() % array.size()]

## デバッグ情報の出力
static func print_node_tree(node: Node, depth: int = 0, max_depth: int = 3) -> void:
	if not GameConstants.DEBUG_LOG_ENABLED or depth > max_depth:
		return
	
	var indent = "  ".repeat(depth)
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	
	for child in node.get_children():
		print_node_tree(child, depth + 1, max_depth)