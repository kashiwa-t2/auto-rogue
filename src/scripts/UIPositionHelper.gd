extends RefCounted
class_name UIPositionHelper

## UI要素の位置計算ヘルパークラス
## HPバーやダメージテキストの位置を動的に計算
## 
## 提供機能:
## - スプライトサイズ対応の動的位置計算
## - HPバー・ダメージテキストの最適配置
## - 画面内判定・境界チェック
## - 共通ダメージテキスト表示処理

## スプライトの中央上部位置を計算
static func calculate_sprite_center_top(sprite: Sprite2D) -> Vector2:
	"""スプライトのテクスチャサイズとスケールから中央上部の位置を計算"""
	if not sprite or not sprite.texture:
		return Vector2.ZERO
	
	var texture_size = sprite.texture.get_size()
	var scaled_size = texture_size * sprite.scale
	return Vector2(-scaled_size.x / 2.0, -scaled_size.y)

## HPバーの配置位置を計算
static func calculate_hp_bar_position(sprite: Sprite2D) -> Vector2:
	"""スプライトに対するHPバーの適切な配置位置を計算"""
	if not sprite or not sprite.texture:
		return GameConstants.HP_BAR_OFFSET
	
	var texture_size = sprite.texture.get_size()
	var scaled_size = texture_size * sprite.scale
	# HPバーをスプライトの中央上部に配置（HPバー幅の半分だけ左にずらす）
	return Vector2(-GameConstants.HP_BAR_WIDTH / 2.0, -scaled_size.y - 5)

## ダメージテキストの配置位置を計算
static func calculate_damage_text_position(sprite: Sprite2D, base_position: Vector2) -> Vector2:
	"""スプライトに対するダメージテキストの適切な配置位置を計算"""
	var sprite_center_offset = calculate_sprite_center_top(sprite)
	return base_position + sprite_center_offset + Vector2(0, -10)

## スプライトの境界ボックスを取得
static func get_sprite_bounds(sprite: Sprite2D) -> Rect2:
	"""スプライトの境界ボックス（位置とサイズ）を取得"""
	if not sprite or not sprite.texture:
		return Rect2()
	
	var texture_size = sprite.texture.get_size()
	var scaled_size = texture_size * sprite.scale
	var top_left = sprite.position + Vector2(-scaled_size.x / 2.0, -scaled_size.y)
	return Rect2(top_left, scaled_size)

## UI要素が画面内に収まるかチェック
static func is_position_on_screen(position: Vector2, size: Vector2 = Vector2.ZERO) -> bool:
	"""指定された位置とサイズが画面内に収まるかチェック"""
	var screen_rect = Rect2(Vector2.ZERO, Vector2(GameConstants.SCREEN_WIDTH, GameConstants.SCREEN_HEIGHT))
	var element_rect = Rect2(position, size)
	return screen_rect.encloses(element_rect)

## ダメージテキストを表示
static func show_damage_text(sprite: Sprite2D, damage: int, entity_position: Vector2, parent_node: Node, debug_name: String, is_player_damage: bool = true) -> void:
	"""指定されたスプライトの上にダメージテキストを表示する共通処理"""
	# DamageTextクラスのインスタンスを作成
	var damage_text = preload("res://src/scripts/DamageText.gd").new()
	
	# 表示位置を計算
	var text_position = calculate_damage_text_position(sprite, entity_position)
	
	# 親ノードに追加
	if parent_node:
		parent_node.add_child(damage_text)
		damage_text.initialize_damage_text(damage, text_position, is_player_damage)
		if GameConstants.DEBUG_LOG_ENABLED:
			print("[%s] Damage text displayed: %d at position %s" % [debug_name, damage, text_position])
	else:
		if GameConstants.DEBUG_LOG_ENABLED:
			print("[%s] ERROR: Cannot display damage text: parent node not found" % debug_name)
		damage_text.queue_free()