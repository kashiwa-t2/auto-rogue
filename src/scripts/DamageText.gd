extends Label
class_name DamageText

## ダメージテキスト表示クラス
## 攻撃時にダメージ数値をアニメーション付きで表示
## 
## 機能:
## - フロート式ダメージ表示
## - プレイヤー/敵別の色分け
## - スケール・フェードアニメーション
## - ランダム移動による視覚効果

var damage_amount: int = 0
var float_tween: Tween
var is_player_damage: bool = true

func _ready():
	# ラベルの初期設定
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

## ダメージテキストの初期化と表示開始
func initialize_damage_text(damage: int, start_position: Vector2, is_player_damage: bool = true) -> void:
	damage_amount = damage
	self.is_player_damage = is_player_damage
	text = str(damage)
	position = start_position
	
	# テキストスタイルの設定
	add_theme_font_size_override("font_size", GameConstants.DAMAGE_TEXT_FONT_SIZE)
	
	# プレイヤーか敵かで色を分ける
	if is_player_damage:
		add_theme_color_override("font_color", GameConstants.DAMAGE_TEXT_PLAYER_COLOR)
	else:
		add_theme_color_override("font_color", GameConstants.DAMAGE_TEXT_ENEMY_COLOR)
	
	add_theme_color_override("font_shadow_color", GameConstants.DAMAGE_TEXT_SHADOW_COLOR)
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	
	# アニメーション開始
	_start_float_animation()
	_log_debug("Damage text initialized: %d at position %s (player: %s)" % [damage, start_position, is_player_damage])

## フロートアニメーションの開始
func _start_float_animation() -> void:
	# 既存のTweenをクリーンアップ
	if float_tween:
		float_tween.kill()
	
	float_tween = create_tween()
	float_tween.set_parallel(true)  # 複数のプロパティを同時にアニメーション
	
	# 初期設定
	modulate.a = 1.0
	scale = Vector2.ONE
	
	# 位置アニメーション（上に浮上）
	var start_pos = position
	
	# プレイヤーと敵でダメージテキストの横移動方向を分ける
	var random_x = 0.0
	if text.begins_with("+"):  # 回復テキストは従来通り両方向に移動
		random_x = randf_range(-GameConstants.DAMAGE_TEXT_FLOAT_RANDOM_X, GameConstants.DAMAGE_TEXT_FLOAT_RANDOM_X)
	elif is_player_damage:
		# プレイヤーのダメージは左側のみ（右側にいかない）
		random_x = randf_range(-GameConstants.DAMAGE_TEXT_FLOAT_RANDOM_X, 0)
	else:
		# 敵のダメージは右側のみ（左側にいかない）
		random_x = randf_range(0, GameConstants.DAMAGE_TEXT_FLOAT_RANDOM_X)
	
	var end_pos = start_pos + Vector2(
		random_x,
		-GameConstants.DAMAGE_TEXT_FLOAT_HEIGHT
	)
	float_tween.tween_property(self, "position", end_pos, GameConstants.DAMAGE_TEXT_DURATION)
	
	# フェードアウトアニメーション
	float_tween.tween_property(self, "modulate:a", 0.0, GameConstants.DAMAGE_TEXT_FADE_DURATION)
	
	# スケールアニメーション（少し拡大してから縮小）
	float_tween.tween_property(self, "scale", Vector2(1.2, 1.2), GameConstants.DAMAGE_TEXT_DURATION * 0.3)
	float_tween.tween_property(self, "scale", Vector2(0.8, 0.8), GameConstants.DAMAGE_TEXT_DURATION * 0.7)
	
	# アニメーション完了時に自動削除
	float_tween.finished.connect(_on_animation_finished)
	
	_log_debug("Damage text float animation started")

## アニメーション完了時の処理
func _on_animation_finished() -> void:
	_log_debug("Damage text animation finished - removing from scene")
	queue_free()

## クリティカルダメージ用のスタイル変更
func set_critical_style() -> void:
	add_theme_font_size_override("font_size", GameConstants.DAMAGE_TEXT_CRITICAL_FONT_SIZE)
	add_theme_color_override("font_color", GameConstants.DAMAGE_TEXT_CRITICAL_COLOR)
	_log_debug("Critical damage style applied")

## ダメージ量の取得
func get_damage_amount() -> int:
	return damage_amount

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[DamageText] %s" % message)