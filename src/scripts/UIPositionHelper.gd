extends RefCounted
class_name UIPositionHelper

## UI要素の位置計算ヘルパークラス
## HPバーやダメージテキストの位置を動的に計算
## 
## 提供機能:
## - スプライトサイズ対応の動的位置計算
## - 透過部分を考慮したスマート配置
## - HPバー・ダメージテキストの最適配置
## - 画面内判定・境界チェック
## - 共通ダメージテキスト表示処理

# テクスチャの不透明領域キャッシュ
static var _texture_bounds_cache: Dictionary = {}

## テクスチャの実際の不透明領域を検出
static func get_texture_opaque_bounds(texture: Texture2D) -> Rect2:
	"""テクスチャの透過部分を除いた実際のコンテンツ領域を返す"""
	if not texture:
		return Rect2()
	
	var texture_path = texture.resource_path
	
	# キャッシュから取得を試す
	if _texture_bounds_cache.has(texture_path):
		return _texture_bounds_cache[texture_path]
	
	var image = texture.get_image()
	if not image:
		# フォールバック: テクスチャ全体を使用
		var full_rect = Rect2(Vector2.ZERO, texture.get_size())
		_texture_bounds_cache[texture_path] = full_rect
		return full_rect
	
	var width = image.get_width()
	var height = image.get_height()
	
	# 不透明ピクセルの境界を検索
	var top_y = height
	var bottom_y = 0
	var left_x = width
	var right_x = 0
	var found_opaque = false
	
	# 各ピクセルをスキャン
	for y in range(height):
		for x in range(width):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.1:  # アルファ値が0.1より大きければ不透明とみなす
				found_opaque = true
				top_y = min(top_y, y)
				bottom_y = max(bottom_y, y)
				left_x = min(left_x, x)
				right_x = max(right_x, x)
	
	var bounds: Rect2
	if found_opaque:
		bounds = Rect2(left_x, top_y, right_x - left_x + 1, bottom_y - top_y + 1)
	else:
		# 不透明ピクセルが見つからない場合はテクスチャ全体を使用
		bounds = Rect2(Vector2.ZERO, texture.get_size())
	
	# キャッシュに保存
	_texture_bounds_cache[texture_path] = bounds
	
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[UIPositionHelper] Texture bounds for %s: %s (texture size: %s)" % [texture_path, bounds, texture.get_size()])
	
	return bounds

## スプライトの中央上部位置を計算
static func calculate_sprite_center_top(sprite: Sprite2D) -> Vector2:
	"""スプライトのテクスチャサイズとスケールから中央上部の位置を計算"""
	if not sprite or not sprite.texture:
		return Vector2.ZERO
	
	var texture_size = sprite.texture.get_size()
	var scaled_size = texture_size * sprite.scale
	return Vector2(-scaled_size.x / 2.0, -scaled_size.y)

## HPバーの配置位置を計算
static func calculate_hp_bar_position(sprite: Sprite2D, entity_name: String) -> Vector2:
	"""スプライトに対するHPバーの適切な配置位置を計算（透過部分を考慮）"""
	if not sprite or not sprite.texture:
		return GameConstants.HP_BAR_OFFSET
	
	# テクスチャの実際の不透明領域を取得
	var opaque_bounds = get_texture_opaque_bounds(sprite.texture)
	var texture_size = sprite.texture.get_size()
	
	# スプライトがcenteredの場合とそうでない場合で計算を分ける
	var sprite_top_y: float
	if sprite.centered:
		# centeredの場合：テクスチャ中心がsprite.positionになる
		var texture_center_y = texture_size.y / 2.0
		var opaque_top_y = opaque_bounds.position.y
		var opaque_offset_from_center = opaque_top_y - texture_center_y
		sprite_top_y = (opaque_offset_from_center - sprite.offset.y) * sprite.scale.y
	else:
		# centeredでない場合：テクスチャ上端がsprite.positionになる
		sprite_top_y = (opaque_bounds.position.y - sprite.offset.y) * sprite.scale.y
	
	# HPバーを実際のキャラクターの上端から20px上に配置
	var hp_bar_offset_y = sprite_top_y - 20
	
	# 詳細なデバッグ情報
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[UIPositionHelper] %s - texture_size: %s, opaque_bounds: %s, scale: %s" % [entity_name, texture_size, opaque_bounds, sprite.scale])
		print("[UIPositionHelper] %s - centered: %s, offset: %s, sprite_top_y: %f, hp_bar_y: %f" % [entity_name, sprite.centered, sprite.offset, sprite_top_y, hp_bar_offset_y])
	
	# HPバーを水平方向の中央に配置
	return Vector2(-GameConstants.HP_BAR_WIDTH / 2.0, hp_bar_offset_y)

## ダメージテキストの配置位置を計算
static func calculate_damage_text_position(sprite: Sprite2D, base_position: Vector2) -> Vector2:
	"""スプライトに対するダメージテキストの適切な配置位置を計算（透過部分を考慮）"""
	if not sprite or not sprite.texture:
		return base_position + Vector2(0, -10)
	
	# テクスチャの実際の不透明領域を取得
	var opaque_bounds = get_texture_opaque_bounds(sprite.texture)
	var texture_size = sprite.texture.get_size()
	
	# 実際のキャラクターの中央上部位置を計算
	var sprite_top_y: float
	if sprite.centered:
		var texture_center_y = texture_size.y / 2.0
		var opaque_top_y = opaque_bounds.position.y
		var opaque_offset_from_center = opaque_top_y - texture_center_y
		sprite_top_y = (opaque_offset_from_center - sprite.offset.y) * sprite.scale.y
	else:
		sprite_top_y = (opaque_bounds.position.y - sprite.offset.y) * sprite.scale.y
	
	# ダメージテキストをキャラクターの10px上に配置
	return base_position + Vector2(0, sprite_top_y - 10)

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