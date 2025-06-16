extends CharacterBody2D
class_name Player

## GreenCharacter (みどりくん) の制御クラス
## 歩行アニメーション、移動、位置リセット機能を提供

@export var idle_bob_speed: float = GameConstants.PLAYER_IDLE_BOB_SPEED
@export var idle_bob_height: float = GameConstants.PLAYER_IDLE_BOB_HEIGHT

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_sprite: Sprite2D = $WeaponSprite
@onready var walk_timer: Timer = $WalkAnimationTimer
@onready var hp_bar = $HPBar

var initial_position: Vector2
var time_passed: float = 0.0
var is_idle: bool = true
var is_attacking: bool = false

# 歩行アニメーション用
var walk_sprites: Array[Texture2D] = []
var current_frame: int = 0

# 武器・攻撃関連
var weapon_initial_rotation: float = 0.0
var attack_tween: Tween

# HP関連
var max_hp: int = GameConstants.PLAYER_MAX_HP
var current_hp: int = GameConstants.PLAYER_DEFAULT_HP

# 攻撃力
var attack_damage: int = GameConstants.PLAYER_DEFAULT_ATTACK_DAMAGE

# コイン関連
var total_coins: int = 0

signal position_changed(new_position: Vector2)
signal player_reset()
signal attack_started()
signal attack_hit()  # 剣が実際に敵に当たるタイミング
signal attack_finished()
signal hp_changed(new_hp: int, max_hp: int)
signal player_died()
signal coin_collected(amount: int, total: int)

func _ready():
	# GreenCharacter (みどりくん) グループに追加
	add_to_group("player")
	initial_position = position
	_setup_walk_animation()
	_setup_weapon()
	_setup_hp_system()
	_initialize_player_stats()
	_log_debug("GreenCharacter (みどりくん) initialized at position: %s" % position)

func _physics_process(delta):
	# 地面の上を歩くため浮遊アニメーションは停止
	pass

func _setup_walk_animation() -> void:
	"""歩行アニメーション用のスプライトを読み込み"""
	walk_sprites.clear()
	
	# スプライトの基本設定
	if sprite:
		sprite.scale = Vector2(GameConstants.PLAYER_SPRITE_SCALE, GameConstants.PLAYER_SPRITE_SCALE)
		sprite.flip_h = GameConstants.PLAYER_SPRITE_FLIP_H
		_log_debug("Set sprite scale: %f, flip_h: %s" % [GameConstants.PLAYER_SPRITE_SCALE, GameConstants.PLAYER_SPRITE_FLIP_H])
	
	# 歩行スプライトを読み込み
	for sprite_path in GameConstants.PLAYER_WALK_SPRITES:
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
		walk_timer.wait_time = 1.0 / GameConstants.PLAYER_ANIMATION_SPEED
		_log_debug("Walk animation timer set to: %f seconds" % walk_timer.wait_time)

## 武器の初期設定
func _setup_weapon() -> void:
	"""武器スプライトの初期設定（WeaponSystemから取得）"""
	_update_weapon_from_system()

## WeaponSystemから武器を更新
func _update_weapon_from_system() -> void:
	"""WeaponSystemから現在の武器データを取得して反映"""
	_log_debug("=== Starting weapon update from WeaponSystem ===")
	
	# WeaponSystemの取得を試行
	var weapon_system = _get_weapon_system()
	if not weapon_system:
		_log_error("WeaponSystem not available, using fallback")
		_fallback_weapon_setup()
		return
	
	_log_debug("WeaponSystem obtained successfully: %s" % weapon_system)
	
	# 武器データの取得
	var weapon_sprite_path = weapon_system.get_weapon_sprite_path("green")
	var weapon_damage_value = weapon_system.get_weapon_damage("green")
	var weapon_range_value = weapon_system.get_weapon_attack_range("green")
	
	# 武器の完全なデータを取得（レアリティ情報のため）
	var weapon_data = weapon_system.get_character_weapon("green")
	
	_log_debug("Weapon data from WeaponSystem - Path: '%s', Damage: %d, Range: %.1f" % [weapon_sprite_path, weapon_damage_value, weapon_range_value])
	if weapon_data:
		_log_debug("Weapon rarity: %s" % weapon_data.rarity)
	
	# 攻撃力と射程を更新
	attack_damage = weapon_damage_value
	_log_debug("Attack damage updated to: %d" % attack_damage)
	
	# weapon_spriteノードの存在確認
	if not weapon_sprite:
		_log_error("weapon_sprite node is null! Cannot update weapon visuals.")
		return
	
	_log_debug("weapon_sprite node exists: %s" % weapon_sprite)
	
	# 武器スプライト更新
	if weapon_sprite_path != "":
		_log_debug("Attempting to update weapon sprite to: %s" % weapon_sprite_path)
		var weapon_texture = _load_texture_safe(weapon_sprite_path)
		if weapon_texture:
			_log_debug("Weapon texture loaded successfully, updating sprite...")
			
			# 以前のテクスチャを記録
			var previous_texture = weapon_sprite.texture
			_log_debug("Previous texture: %s" % previous_texture)
			
			# 新しいテクスチャを設定
			weapon_sprite.texture = weapon_texture
			_log_debug("Weapon sprite texture updated! New texture: %s" % weapon_sprite.texture)
			
			# スプライト設定を更新
			weapon_sprite.scale = Vector2(GameConstants.PLAYER_WEAPON_SCALE, GameConstants.PLAYER_WEAPON_SCALE)
			weapon_sprite.flip_h = true  # 剣の刃を正しい方向に向ける
			
			# 剣の柄（画像の中央下）をプレイヤーの腰の位置に固定
			var texture_size = weapon_texture.get_size()
			
			# 剣の柄の中央部分が回転中心となるよう設定
			weapon_sprite.position = GameConstants.PLAYER_WEAPON_OFFSET
			weapon_sprite.offset = Vector2(-texture_size.x * 0.2, -texture_size.y * 0.5)  # 柄の中央付近を回転中心に
			
			# 剣を敵よりも手前に表示するためz_indexを設定
			weapon_sprite.z_index = 10
			
			weapon_sprite.rotation_degrees = GameConstants.PLAYER_WEAPON_INITIAL_ROTATION
			weapon_initial_rotation = GameConstants.PLAYER_WEAPON_INITIAL_ROTATION
			
			# レアリティ色を適用
			if weapon_data and weapon_system:
				var rarity_color = weapon_system.get_rarity_color(weapon_data.rarity)
				weapon_sprite.modulate = rarity_color
				_log_debug("Applied rarity color: %s for rarity: %s" % [rarity_color, weapon_data.rarity])
			else:
				weapon_sprite.modulate = Color.WHITE
				_log_debug("No rarity data available, using default white color")
			
			_log_debug("Weapon visual update completed successfully!")
			_log_debug("Final weapon state - Texture: %s, Scale: %s, Position: %s, Z-index: %d, Color: %s" % [weapon_sprite.texture, weapon_sprite.scale, weapon_sprite.position, weapon_sprite.z_index, weapon_sprite.modulate])
		else:
			_log_error("Failed to load weapon sprite from WeaponSystem: %s" % weapon_sprite_path)
			_fallback_weapon_setup()
	else:
		_log_debug("Empty weapon sprite path from WeaponSystem, using fallback")
		_fallback_weapon_setup()
	
	_log_debug("=== Weapon update from WeaponSystem completed ===")

## WeaponSystem取得ヘルパー
func _get_weapon_system() -> WeaponSystem:
	"""WeaponSystemインスタンスを取得"""
	_log_debug("--- Attempting to get WeaponSystem ---")
	
	# Method 1: MainSceneのget_weapon_system()メソッドを使用
	var main_scene = get_tree().current_scene
	_log_debug("Current scene: %s" % main_scene)
	
	if main_scene and main_scene.has_method("get_weapon_system"):
		_log_debug("MainScene has get_weapon_system method, calling it...")
		var weapon_system = main_scene.get_weapon_system()
		_log_debug("MainScene.get_weapon_system() returned: %s" % weapon_system)
		if weapon_system:
			_log_debug("✓ WeaponSystem obtained from MainScene successfully!")
			return weapon_system
	else:
		_log_debug("MainScene does not have get_weapon_system method or is null")
	
	# Method 2: 直接WeaponUIを探す（グループ経由）
	_log_debug("Method 2: Trying direct WeaponUI search via group...")
	var weapon_ui_nodes = get_tree().get_nodes_in_group("weapon_ui")
	_log_debug("Found %d weapon_ui nodes: %s" % [weapon_ui_nodes.size(), weapon_ui_nodes])
	
	for node in weapon_ui_nodes:
		_log_debug("Checking WeaponUI node: %s" % node)
		if node.has_method("get_weapon_system"):
			_log_debug("WeaponUI node has get_weapon_system method, calling it...")
			var weapon_system = node.get_weapon_system()
			_log_debug("WeaponUI.get_weapon_system() returned: %s" % weapon_system)
			if weapon_system:
				_log_debug("✓ WeaponSystem obtained from WeaponUI group successfully!")
				return weapon_system
		else:
			_log_debug("WeaponUI node does not have get_weapon_system method")
	
	# Method 3: パス経由でWeaponUIを直接取得
	_log_debug("Method 3: Trying direct path to WeaponUI...")
	if main_scene:
		var weapon_ui_path = "UIArea/TabSystem/ContentArea/WeaponContent/WeaponUI"
		var weapon_ui = main_scene.get_node_or_null(weapon_ui_path)
		_log_debug("WeaponUI via path '%s': %s" % [weapon_ui_path, weapon_ui])
		
		if weapon_ui and weapon_ui.has_method("get_weapon_system"):
			_log_debug("WeaponUI found via path, getting weapon system...")
			var weapon_system = weapon_ui.get_weapon_system()
			_log_debug("WeaponUI path method returned: %s" % weapon_system)
			if weapon_system:
				_log_debug("✓ WeaponSystem obtained via path successfully!")
				return weapon_system
	
	# Method 4: 親ノードを辿ってMainSceneを探す
	_log_debug("Method 4: Traversing parent nodes to find MainScene...")
	var current_node = self
	while current_node:
		_log_debug("Checking node: %s (type: %s)" % [current_node, current_node.get_class()])
		if current_node.has_method("get_weapon_system"):
			_log_debug("Found node with get_weapon_system method!")
			var weapon_system = current_node.get_weapon_system()
			if weapon_system:
				_log_debug("✓ WeaponSystem obtained via parent traversal!")
				return weapon_system
		current_node = current_node.get_parent()
	
	_log_error("❌ Failed to obtain WeaponSystem from any source!")
	return null

## フォールバック武器設定
func _fallback_weapon_setup() -> void:
	"""WeaponSystemが利用できない場合のフォールバック武器設定"""
	if not weapon_sprite:
		return
	
	# デフォルトの剣テクスチャを使用
	var default_weapon_path = "res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0103.png"
	var weapon_texture = _load_texture_safe(default_weapon_path)
	if weapon_texture:
		weapon_sprite.texture = weapon_texture
		weapon_sprite.scale = Vector2(GameConstants.PLAYER_WEAPON_SCALE, GameConstants.PLAYER_WEAPON_SCALE)
		weapon_sprite.flip_h = true
		
		# 剣の柄（画像の中央下）をプレイヤーの腰の位置に固定
		var texture_size = weapon_texture.get_size()
		
		# 剣の柄の中央部分が回転中心となるよう設定
		weapon_sprite.position = GameConstants.PLAYER_WEAPON_OFFSET
		weapon_sprite.offset = Vector2(-texture_size.x * 0.2, -texture_size.y * 0.5)
		
		# 剣を敵よりも手前に表示するためz_indexを設定
		weapon_sprite.z_index = 10
		
		weapon_sprite.rotation_degrees = GameConstants.PLAYER_WEAPON_INITIAL_ROTATION
		weapon_initial_rotation = GameConstants.PLAYER_WEAPON_INITIAL_ROTATION
		
		# フォールバック時はデフォルトの白色
		weapon_sprite.modulate = Color.WHITE
		
		# フォールバック時の攻撃力はPlayerStatsから取得
		attack_damage = PlayerStats.get_attack_damage()
		
		_log_debug("Fallback weapon setup completed: damage=%d, sprite=%s, color=WHITE" % [attack_damage, default_weapon_path])
	else:
		_log_error("Failed to load fallback weapon sprite: %s" % default_weapon_path)

## HPシステムの初期設定
func _setup_hp_system() -> void:
	"""HPシステムとHPバーの初期化"""
	if hp_bar:
		# スプライトサイズから中央位置を計算してHPバー位置を設定
		_update_hp_bar_position()
		hp_bar.initialize_hp(current_hp, max_hp)
		hp_bar.hp_changed.connect(_on_hp_changed)
		hp_bar.hp_depleted.connect(_on_hp_depleted)
		_log_debug("HP system initialized: %d/%d" % [current_hp, max_hp])
	else:
		_log_error("HP bar node not found")

## GreenCharacter (みどりくん) ステータスの初期化
func _initialize_player_stats() -> void:
	"""GreenCharacter (みどりくん) のステータスをPlayerStatsから取得"""
	max_hp = PlayerStats.get_max_hp()
	current_hp = max_hp
	attack_damage = PlayerStats.get_attack_damage()
	
	# HPバーを再初期化
	if hp_bar:
		hp_bar.initialize_hp(current_hp, max_hp)
	
	_log_debug("GreenCharacter (みどりくん) stats initialized - HP: %d/%d, Attack: %d" % [current_hp, max_hp, attack_damage])

## ダメージを受ける
func take_damage(damage: int) -> void:
	"""GreenCharacter (みどりくん) がダメージを受ける"""
	if hp_bar:
		hp_bar.take_damage(damage)
		current_hp = hp_bar.get_current_hp()
		_log_debug("GreenCharacter (みどりくん) took %d damage, HP: %d/%d" % [damage, current_hp, max_hp])
	
	# ダメージテキストを表示
	_show_damage_text(damage)

## HPを回復
func heal(amount: int) -> void:
	"""GreenCharacter (みどりくん) のHPを回復"""
	if hp_bar:
		hp_bar.heal(amount)
		current_hp = hp_bar.get_current_hp()
		_log_debug("GreenCharacter (みどりくん) healed %d HP, HP: %d/%d" % [amount, current_hp, max_hp])

## HP変更イベントハンドラー
func _on_hp_changed(new_hp: int, maximum_hp: int) -> void:
	"""HPが変更された時の処理"""
	current_hp = new_hp
	hp_changed.emit(new_hp, maximum_hp)

## HP枯渇イベントハンドラー
func _on_hp_depleted() -> void:
	"""HPが0になった時の処理"""
	_log_debug("GreenCharacter (みどりくん) died!")
	player_died.emit()

## 現在のHP取得
func get_current_hp() -> int:
	return current_hp

## 最大HP取得
func get_max_hp() -> int:
	return max_hp

## 生存確認
func is_alive() -> bool:
	return current_hp > 0

## ダメージテキストの表示
func _show_damage_text(damage: int) -> void:
	"""GreenCharacter (みどりくん) の上にダメージ数値をアニメーション付きで表示"""
	# DamageTextクラスのインスタンスを作成
	var damage_text = preload("res://src/scripts/DamageText.gd").new()
	
	# 表示位置を計算
	var text_position = UIPositionHelper.calculate_damage_text_position(sprite, position)
	
	# 親ノードに追加
	var parent = get_parent()
	if parent:
		parent.add_child(damage_text)
		damage_text.initialize_damage_text(damage, text_position, true)  # GreenCharacterダメージ = 白色

## HPバー位置の更新
func _update_hp_bar_position() -> void:
	"""スプライトサイズに基づいてHPバー位置を動的に計算"""
	if not hp_bar:
		return
	
	var hp_bar_offset = UIPositionHelper.calculate_hp_bar_position(sprite, "Player")
	hp_bar.position = hp_bar_offset
	_log_debug("HP bar position updated: %s" % hp_bar_offset)

## コイン収集
func collect_coin(coin_value: int) -> void:
	"""コインを収集する"""
	_log_debug("BEFORE coin collection - Current total: %d, Adding: %d" % [total_coins, coin_value])
	total_coins += coin_value
	_log_debug("AFTER coin collection - New total: %d" % total_coins)
	coin_collected.emit(coin_value, total_coins)
	_log_debug("Collected coin! Value: %d, Total: %d, Signal emitted!" % [coin_value, total_coins])

## 現在のコイン数取得
func get_total_coins() -> int:
	return total_coins

## 武器データを更新
func refresh_weapon_data() -> void:
	"""WeaponSystemから武器データを再取得して更新"""
	_log_debug("🔄 refresh_weapon_data() called for GreenCharacter")
	_update_weapon_from_system()
	_log_debug("GreenCharacter weapon data refreshed")

## 強制的に武器スプライトを更新
func force_update_weapon_sprite(weapon_sprite_path: String) -> void:
	"""外部から直接武器スプライトを更新（デバッグ・緊急用）"""
	_log_debug("🚀 force_update_weapon_sprite() called with path: %s" % weapon_sprite_path)
	
	if not weapon_sprite:
		_log_error("weapon_sprite node is null! Cannot force update.")
		return
	
	if weapon_sprite_path == "":
		_log_error("Empty weapon sprite path provided!")
		return
	
	var weapon_texture = _load_texture_safe(weapon_sprite_path)
	if weapon_texture:
		_log_debug("Force updating weapon sprite texture...")
		weapon_sprite.texture = weapon_texture
		weapon_sprite.scale = Vector2(GameConstants.PLAYER_WEAPON_SCALE, GameConstants.PLAYER_WEAPON_SCALE)
		weapon_sprite.flip_h = true
		
		var texture_size = weapon_texture.get_size()
		weapon_sprite.position = GameConstants.PLAYER_WEAPON_OFFSET
		weapon_sprite.offset = Vector2(-texture_size.x * 0.2, -texture_size.y * 0.5)
		weapon_sprite.z_index = 10
		weapon_sprite.rotation_degrees = GameConstants.PLAYER_WEAPON_INITIAL_ROTATION
		weapon_initial_rotation = GameConstants.PLAYER_WEAPON_INITIAL_ROTATION
		
		# 現在の武器データからレアリティ色を適用
		var weapon_system = _get_weapon_system()
		if weapon_system:
			var weapon_data = weapon_system.get_character_weapon("green")
			if weapon_data:
				var rarity_color = weapon_system.get_rarity_color(weapon_data.rarity)
				weapon_sprite.modulate = rarity_color
				_log_debug("Applied rarity color in force update: %s for rarity: %s" % [rarity_color, weapon_data.rarity])
			else:
				weapon_sprite.modulate = Color.WHITE
		else:
			weapon_sprite.modulate = Color.WHITE
		
		_log_debug("✅ Weapon sprite force updated successfully!")
	else:
		_log_error("Failed to load weapon texture for force update: %s" % weapon_sprite_path)

## PlayerStatsからステータスを更新
func update_stats_from_player_stats() -> void:
	"""PlayerStatsシングルトンから最新のGreenCharacter (みどりくん) ステータスを取得して更新"""
	# 最大HPを更新
	max_hp = PlayerStats.get_max_hp()
	# 現在HPが最大HPを超える場合は調整
	if current_hp > max_hp:
		current_hp = max_hp
	
	# 攻撃力を更新（WeaponSystemから取得）
	attack_damage = PlayerStats.get_attack_damage()
	
	# 武器データを更新
	refresh_weapon_data()
	
	# コイン数を同期
	total_coins = PlayerStats.total_coins
	
	# HPバーを更新
	if hp_bar:
		hp_bar.initialize_hp(current_hp, max_hp)
	
	# HPシグナルを発火
	hp_changed.emit(current_hp, max_hp)
	
	_log_debug("GreenCharacter (みどりくん) stats updated from PlayerStats - HP: %d/%d, Attack: %d, Coins: %d" % [current_hp, max_hp, attack_damage, total_coins])

func _update_idle_animation(delta: float) -> void:
	"""アイドルアニメーションの更新（位置の浮遊）"""
	time_passed += delta
	var bob_offset = sin(time_passed * idle_bob_speed) * idle_bob_height
	position.y = initial_position.y + bob_offset

func _on_walk_animation_timer_timeout():
	"""歩行アニメーションフレームの切り替え"""
	if walk_sprites.size() <= 1:
		return
	
	current_frame = (current_frame + 1) % walk_sprites.size()
	sprite.texture = walk_sprites[current_frame]
	_log_debug("Walk animation frame: %d/%d" % [current_frame, walk_sprites.size() - 1])

## 指定位置への移動
func move_to_position(new_pos: Vector2) -> void:
	if not _is_valid_position(new_pos):
		_log_debug("Invalid position specified: %s" % new_pos)
		return
	
	position = new_pos
	initial_position = new_pos
	time_passed = 0.0
	position_changed.emit(new_pos)
	_log_debug("GreenCharacter (みどりくん) moved to: %s" % new_pos)


## 攻撃アニメーション開始
func start_attack() -> void:
	if is_attacking or not weapon_sprite:
		return
	
	is_attacking = true
	attack_started.emit()
	_log_debug("Attack animation started")
	
	# Tweenを作成
	if attack_tween:
		attack_tween.kill()
	attack_tween = create_tween()
	attack_tween.set_ease(Tween.EASE_OUT)
	attack_tween.set_trans(Tween.TRANS_BACK)
	
	# 剣を振るアニメーション
	var target_rotation = weapon_initial_rotation + GameConstants.PLAYER_ATTACK_ROTATION_ANGLE
	var hit_time = GameConstants.PLAYER_ATTACK_DURATION / 2.0  # 攻撃の中間点でヒット
	
	# 1回目: 初期位置から最大回転まで（ここで敵にヒット）
	attack_tween.tween_property(weapon_sprite, "rotation_degrees", target_rotation, hit_time)
	# 最大回転に到達したタイミングでヒットシグナル発火
	attack_tween.tween_callback(_on_attack_hit)
	# 2回目: 最大回転から初期位置まで
	attack_tween.tween_property(weapon_sprite, "rotation_degrees", weapon_initial_rotation, hit_time)
	
	# アニメーション完了時のコールバック
	attack_tween.finished.connect(_on_attack_finished)

## 攻撃ヒット時の処理
func _on_attack_hit() -> void:
	attack_hit.emit()
	_log_debug("Attack hit - damage should be dealt now")

## 攻撃アニメーション終了
func _on_attack_finished() -> void:
	is_attacking = false
	attack_finished.emit()
	_log_debug("Attack animation finished")
	
	# Tweenのクリーンアップ
	if attack_tween:
		attack_tween.finished.disconnect(_on_attack_finished)
		attack_tween = null

## 攻撃中かどうかを確認
func is_player_attacking() -> bool:
	return is_attacking

## 現在位置の取得
func get_current_position() -> Vector2:
	return position

## 位置の有効性チェック
func _is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= GameConstants.SCREEN_WIDTH and \
		   pos.y >= 0 and pos.y <= GameConstants.SCREEN_HEIGHT

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[GreenCharacter] %s" % message)

## エラーログ出力
func _log_error(message: String) -> void:
	print("[GreenCharacter] ERROR: %s" % message)

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
