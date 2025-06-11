extends EnemyBase
class_name BasicEnemy

## 基本的な敵クラス
## 戦闘時にプレイヤーに向かって突進する

func _setup_enemy() -> void:
	"""基本敵の初期設定"""
	enemy_type = EnemyType.BASIC
	_setup_walk_animation()
	_start_walking()

func _setup_walk_animation() -> void:
	"""歩行アニメーション用のスプライトを読み込み"""
	walk_sprites.clear()
	
	# スプライトの基本設定
	if sprite:
		sprite.scale = Vector2(GameConstants.ENEMY_SPRITE_SCALE, GameConstants.ENEMY_SPRITE_SCALE)
		sprite.flip_h = GameConstants.ENEMY_SPRITE_FLIP_H
		_log_debug("Set sprite scale: %f, flip_h: %s" % [GameConstants.ENEMY_SPRITE_SCALE, GameConstants.ENEMY_SPRITE_FLIP_H])
	
	# 歩行スプライトを読み込み
	for sprite_path in GameConstants.ENEMY_WALK_SPRITES:
		var texture = _load_texture_safe(sprite_path)
		if texture:
			walk_sprites.append(texture)
			_log_debug("Loaded walk sprite: %s" % sprite_path)
	
	# 初期テクスチャ設定
	if walk_sprites.size() > 0 and sprite:
		sprite.texture = walk_sprites[0]
		_log_debug("Set initial sprite texture")
	
	# アニメーション速度設定
	if walk_timer:
		walk_timer.wait_time = 1.0 / GameConstants.ENEMY_ANIMATION_SPEED
		_log_debug("Walk animation timer set to: %f seconds" % walk_timer.wait_time)

func _start_walking() -> void:
	"""歩行開始"""
	is_walking = true
	if walk_timer:
		walk_timer.start()
	_log_debug("Started walking")

## 戦闘開始時の動作
func _start_battle_behavior() -> void:
	"""戦闘開始時にプレイヤーに向かって突進"""
	# 歩行アニメーションタイマーを停止
	if walk_timer:
		walk_timer.stop()
		_log_debug("Walk animation timer stopped for battle")
	_start_charge_animation()

## 戦闘終了時の動作
func _end_battle_behavior() -> void:
	"""戦闘終了時に元の位置に戻る（通常は敵の死亡によってのみ呼ばれる）"""
	_end_charge_animation()
	# 戦闘後は歩行モードに戻らない（敵は死ぬまで戦闘継続）
	_log_debug("Battle behavior ended - enemy should be dead")

## 突進アニメーション開始
func _start_charge_animation() -> void:
	"""プレイヤーに向かって頭突き攻撃するアニメーション"""
	_perform_charge_attack()

## 完全な攻撃サイクルを実行
func _perform_charge_attack() -> void:
	"""突進→戻る→待機を1つのアニメーションで実行"""
	_log_debug("=== Starting FULL attack cycle: charge + return + wait")
	
	# 既存のtweenをクリーンアップ
	if battle_tween:
		battle_tween.kill()
	
	battle_tween = create_tween()
	battle_tween.set_ease(Tween.EASE_OUT)
	battle_tween.set_trans(Tween.TRANS_BACK)
	
	# 現在の位置を記録
	var current_pos = position
	var charge_target = current_pos + Vector2(-charge_distance, 0)
	
	_log_debug("Full attack cycle: charge(0.4s) + return(0.6s) + wait(1.5s) = 2.5s total")
	
	# 完全な攻撃サイクルを順次実行で実装（正しいGodot 4構文）
	battle_tween.tween_property(self, "position", charge_target, 0.4)  # 1. 突進 0.4秒
	battle_tween.tween_property(self, "position", current_pos, 0.6)    # 2. 戻り 0.6秒（0.4秒後に開始）
	battle_tween.tween_interval(1.5)                                   # 3. 待機 1.5秒（1.0秒後に開始）
	
	# 終了時に次の攻撃を開始
	battle_tween.finished.connect(_on_full_attack_cycle_finished)
	
	_log_debug("=== Full attack cycle started (2.5s total)")

## 完全な攻撃サイクル完了時の処理
func _on_full_attack_cycle_finished() -> void:
	"""突進→戻る→待機の全サイクル完了後、次の攻撃を開始"""
	_log_debug("*** FULL ATTACK CYCLE FINISHED! Next attack starting...")
	
	# 接続を安全に切断
	if battle_tween and battle_tween.finished.is_connected(_on_full_attack_cycle_finished):
		battle_tween.finished.disconnect(_on_full_attack_cycle_finished)
	
	# 戦闘継続中なら次の攻撃を開始
	if is_in_battle:
		_perform_charge_attack()
		_log_debug("Starting next attack cycle")
	else:
		_log_debug("Battle ended, stopping attack cycles")

## 突進アニメーション終了
func _end_charge_animation() -> void:
	"""突進アニメーションを終了"""
	if battle_tween:
		battle_tween.kill()
		battle_tween = null
	
	_log_debug("Ended charge animation")

## テクスチャの安全な読み込み
func _load_texture_safe(path: String) -> Texture2D:
	if path.is_empty():
		_log_error("Empty texture path provided")
		return null
	
	var texture = load(path)
	if not texture:
		_log_error("Failed to load texture: %s" % path)
		return null
	
	return texture

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[BasicEnemy] %s" % message)

## エラーログ出力
func _log_error(message: String) -> void:
	print("[BasicEnemy] ERROR: %s" % message)
