extends CharacterBody2D
class_name RedCharacter

## RedCharacter (あかさん) キャラクターの制御クラス
## 魔法攻撃、遠距離戦闘、位置管理機能を提供

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
var attack_timer: Timer
var current_target: Node2D = null

# HP関連
var max_hp: int = 50  # RedCharacter (あかさん) の初期HP
var current_hp: int = 50

# 攻撃力・射程
var attack_damage: int = 10  # RedCharacter (あかさん) の初期攻撃力
var attack_range: float = 300.0  # RedCharacter (あかさん) の攻撃範囲
var attack_interval: float = 1.5  # 魔法攻撃の間隔（秒）

# コイン関連
var total_coins: int = 0

# 戦闘状態
var is_in_combat: bool = false

signal position_changed(new_position: Vector2)
signal character_reset()
signal attack_started()
signal magic_attack_fired(target: Node2D, damage: int)
signal attack_finished()
signal hp_changed(new_hp: int, max_hp: int)
signal character_died()
signal coin_collected(amount: int, total: int)

func _ready():
	# RedCharacter (あかさん) グループに追加
	add_to_group("red_character")
	add_to_group("player")  # プレイヤーとしても認識
	initial_position = position
	_setup_walk_animation()
	_setup_weapon()
	_setup_hp_system()
	_setup_attack_timer()
	_initialize_character_stats()
	_log_debug("RedCharacter (あかさん) initialized at position: %s" % position)

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
	
	# RedCharacter (あかさん) 用の歩行スプライトを読み込み（赤系キャラクター）
	var red_walk_sprites = [
		"res://assets/sprites/kenney_pixel-platformer/Tiles/Characters/tile_0004.png",
		"res://assets/sprites/kenney_pixel-platformer/Tiles/Characters/tile_0005.png"
	]
	
	for sprite_path in red_walk_sprites:
		var texture = _load_texture_safe(sprite_path)
		if texture:
			walk_sprites.append(texture)
			_log_debug("Loaded RedCharacter (あかさん) walk sprite: %s" % sprite_path)
	
	# 初期テクスチャ設定
	if walk_sprites.size() > 0 and sprite:
		sprite.texture = walk_sprites[0]
		_log_debug("Set initial RedCharacter (あかさん) sprite texture")
	
	# アニメーション速度設定
	if walk_timer:
		walk_timer.wait_time = 1.0 / GameConstants.PLAYER_ANIMATION_SPEED
		_log_debug("Walk animation timer set to: %f seconds" % walk_timer.wait_time)

## 武器（杖）の初期設定
func _setup_weapon() -> void:
	"""杖スプライトの初期設定（WeaponSystemから取得）"""
	_update_weapon_from_system()

## WeaponSystemから武器を更新
func _update_weapon_from_system() -> void:
	"""WeaponSystemから現在の武器データを取得して反映"""
	var weapon_system = _get_weapon_system()
	if not weapon_system:
		_fallback_weapon_setup()
		return
	
	var weapon_sprite_path = weapon_system.get_weapon_sprite_path("red")
	var weapon_damage_value = weapon_system.get_weapon_damage("red")
	var weapon_range_value = weapon_system.get_weapon_attack_range("red")
	
	# 武器の完全なデータを取得（レアリティ情報のため）
	var weapon_data = weapon_system.get_character_weapon("red")
	
	# 攻撃力と射程を更新
	attack_damage = weapon_damage_value
	attack_range = weapon_range_value
	
	# 武器スプライト更新
	if weapon_sprite and weapon_sprite_path != "":
		var weapon_texture = _load_texture_safe(weapon_sprite_path)
		if weapon_texture:
			weapon_sprite.texture = weapon_texture
			weapon_sprite.scale = Vector2(GameConstants.PLAYER_WEAPON_SCALE, GameConstants.PLAYER_WEAPON_SCALE)
			weapon_sprite.flip_h = false  # 杖は反転しない
			
			# 杖の中央部分をプレイヤーの手の位置に固定
			var texture_size = weapon_texture.get_size()
			
			# 杖の持ち手部分が回転中心となるよう設定
			weapon_sprite.position = GameConstants.PLAYER_WEAPON_OFFSET
			weapon_sprite.offset = Vector2(-texture_size.x * 0.5, -texture_size.y * 0.7)  # 杖の持ち手付近を中心に
			
			# 杖を敵よりも手前に表示するためz_indexを設定
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
			
			_log_debug("Staff from WeaponSystem: damage=%d, range=%.1f, sprite=%s" % [weapon_damage_value, weapon_range_value, weapon_sprite_path])
			_log_debug("Staff initialized: scale=%f, position=%s, rotation=%f, offset=%s, z_index=%d, color=%s" % [GameConstants.PLAYER_WEAPON_SCALE, GameConstants.PLAYER_WEAPON_OFFSET, weapon_initial_rotation, weapon_sprite.offset, weapon_sprite.z_index, weapon_sprite.modulate])
		else:
			_log_error("Failed to load staff sprite from WeaponSystem: %s" % weapon_sprite_path)
			_fallback_weapon_setup()
	else:
		_log_debug("No staff sprite path from WeaponSystem, using fallback")
		_fallback_weapon_setup()

## WeaponSystem取得ヘルパー
func _get_weapon_system() -> WeaponSystem:
	"""WeaponSystemインスタンスを取得"""
	# MainSceneのget_weapon_system()メソッドを使用
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_weapon_system"):
		return main_scene.get_weapon_system()
	
	# 直接WeaponUIを探す
	var weapon_ui_nodes = get_tree().get_nodes_in_group("weapon_ui")
	for node in weapon_ui_nodes:
		if node.has_method("get_weapon_system"):
			return node.get_weapon_system()
	
	return null

## フォールバック武器設定
func _fallback_weapon_setup() -> void:
	"""WeaponSystemが利用できない場合のフォールバック武器設定"""
	if not weapon_sprite:
		return
	
	# デフォルトの杖テクスチャを使用
	var default_weapon_path = "res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0130.png"
	var weapon_texture = _load_texture_safe(default_weapon_path)
	if weapon_texture:
		weapon_sprite.texture = weapon_texture
		weapon_sprite.scale = Vector2(GameConstants.PLAYER_WEAPON_SCALE, GameConstants.PLAYER_WEAPON_SCALE)
		weapon_sprite.flip_h = false  # 杖は反転しない
		
		# 杖の中央部分をプレイヤーの手の位置に固定
		var texture_size = weapon_texture.get_size()
		
		# 杖の持ち手部分が回転中心となるよう設定
		weapon_sprite.position = GameConstants.PLAYER_WEAPON_OFFSET
		weapon_sprite.offset = Vector2(-texture_size.x * 0.5, -texture_size.y * 0.7)
		
		# 杖を敵よりも手前に表示するためz_indexを設定
		weapon_sprite.z_index = 10
		
		weapon_sprite.rotation_degrees = GameConstants.PLAYER_WEAPON_INITIAL_ROTATION
		weapon_initial_rotation = GameConstants.PLAYER_WEAPON_INITIAL_ROTATION
		
		# フォールバック時はデフォルトの白色
		weapon_sprite.modulate = Color.WHITE
		
		# フォールバック時の攻撃力・射程はPlayerStatsから取得
		attack_damage = PlayerStats.get_red_character_attack_damage()
		attack_range = PlayerStats.get_red_character_attack_range()
		
		_log_debug("Fallback staff setup completed: damage=%d, range=%.1f, sprite=%s, color=WHITE" % [attack_damage, attack_range, default_weapon_path])
	else:
		_log_error("Failed to load fallback staff sprite: %s" % default_weapon_path)

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

## 攻撃タイマーの設定
func _setup_attack_timer() -> void:
	"""魔法攻撃タイマーの設定"""
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.one_shot = false
	add_child(attack_timer)
	_log_debug("Attack timer initialized: %f seconds" % attack_interval)

## キャラクターステータスの初期化
func _initialize_character_stats() -> void:
	"""RedCharacter (あかさん) のステータスをPlayerStatsから取得"""
	if PlayerStats.red_character_unlocked:
		max_hp = PlayerStats.get_red_character_max_hp()
		current_hp = max_hp
		attack_damage = PlayerStats.get_red_character_attack_damage()
		attack_range = PlayerStats.get_red_character_attack_range()
		
		# HPバーを再初期化
		if hp_bar:
			hp_bar.initialize_hp(current_hp, max_hp)
		
		_log_debug("RedCharacter (あかさん) stats initialized - HP: %d/%d, Attack: %d, Range: %.1f" % [current_hp, max_hp, attack_damage, attack_range])
	else:
		_log_error("Red character not unlocked yet!")

## ダメージを受ける
func take_damage(damage: int) -> void:
	"""RedCharacter (あかさん) がダメージを受ける"""
	if hp_bar:
		hp_bar.take_damage(damage)
		current_hp = hp_bar.get_current_hp()
		_log_debug("RedCharacter took %d damage, HP: %d/%d" % [damage, current_hp, max_hp])
	
	# ダメージテキストを表示
	_show_damage_text(damage)

## HPを回復
func heal(amount: int) -> void:
	"""RedCharacter (あかさん) のHPを回復"""
	if hp_bar:
		hp_bar.heal(amount)
		current_hp = hp_bar.get_current_hp()
		_log_debug("RedCharacter healed %d HP, HP: %d/%d" % [amount, current_hp, max_hp])

## HP変更イベントハンドラー
func _on_hp_changed(new_hp: int, maximum_hp: int) -> void:
	"""HPが変更された時の処理"""
	current_hp = new_hp
	hp_changed.emit(new_hp, maximum_hp)

## HP枯渇イベントハンドラー
func _on_hp_depleted() -> void:
	"""HPが0になった時の処理"""
	_log_debug("RedCharacter died!")
	character_died.emit()

## 現在のHP取得
func get_current_hp() -> int:
	return current_hp

## 最大HP取得
func get_max_hp() -> int:
	return max_hp

## 生存確認
func is_alive() -> bool:
	return current_hp > 0

## 戦闘開始
func start_combat(target: Node2D) -> void:
	"""戦闘を開始し、定期的に魔法攻撃を行う"""
	if not is_alive() or not PlayerStats.red_character_unlocked:
		return
	
	current_target = target
	is_in_combat = true
	
	# 即座に初回攻撃を実行
	_fire_magic_bullet(target)
	
	# 攻撃タイマーを開始（2回目以降の攻撃用）
	if attack_timer:
		attack_timer.start()
	
	var target_name = "None"
	if target:
		target_name = target.name
	_log_debug("RedCharacter combat started against: %s (IMMEDIATE FIRST ATTACK)" % target_name)

## 戦闘終了
func stop_combat() -> void:
	"""戦闘を終了"""
	is_in_combat = false
	current_target = null
	
	# 攻撃タイマーを停止
	if attack_timer:
		attack_timer.stop()
	
	_log_debug("RedCharacter combat stopped")

## 攻撃タイマータイムアウト
func _on_attack_timer_timeout() -> void:
	"""定期的な魔法攻撃の実行"""
	if is_in_combat and current_target and is_instance_valid(current_target) and is_alive():
		_fire_magic_bullet(current_target)
	else:
		# ターゲットが無効になった場合は戦闘を停止
		stop_combat()

## 魔法弾の発射
func _fire_magic_bullet(_target: Node2D) -> void:
	"""ターゲットに向けて魔法弾を発射"""
	if not is_alive():
		return
	
	# 最も近い敵を検索して距離チェック
	var nearest_enemy = _find_nearest_enemy()
	if not nearest_enemy:
		_log_debug("No enemy found for magic attack")
		return
	
	# 距離チェック（x座標のみ）
	var distance_to_target = abs(position.x - nearest_enemy.position.x)
	if distance_to_target > attack_range:
		_log_debug("Target too far for magic attack: %.1f > %.1f" % [distance_to_target, attack_range])
		return
	
	# 魔法弾を作成（BlueMagicBullet使用）
	var magic_bullet_scene = preload("res://src/scenes/BlueMagicBullet.tscn")
	if not magic_bullet_scene:
		_log_error("Blue magic bullet scene not loaded")
		return
		
	var magic_bullet = magic_bullet_scene.instantiate()
	if not magic_bullet:
		_log_error("Failed to instantiate blue magic bullet")
		return
	
	# 発射位置を設定（あかさんの位置から）
	magic_bullet.position = position
	
	# 親ノード（PlayArea）に追加
	var parent = get_parent()
	if parent:
		parent.add_child(magic_bullet)
		magic_bullet.setup_bullet(nearest_enemy.position, attack_damage)
		_log_debug("Blue magic bullet fired at enemy position: %s" % nearest_enemy.position)
		
		# シグナル発射
		magic_attack_fired.emit(nearest_enemy, attack_damage)
		attack_started.emit()
		
		# 攻撃完了シグナルは即座に発射（魔法攻撃はアニメーション不要）
		call_deferred("_on_magic_attack_finished")
	else:
		_log_error("Cannot fire blue magic bullet: parent node not found")
		magic_bullet.queue_free()

## 魔法攻撃完了
func _on_magic_attack_finished() -> void:
	"""魔法攻撃完了時の処理"""
	attack_finished.emit()
	_log_debug("Magic attack finished")

## ダメージテキストの表示
func _show_damage_text(damage: int) -> void:
	"""RedCharacter (あかさん) の上にダメージ数値をアニメーション付きで表示"""
	# DamageTextクラスのインスタンスを作成
	var damage_text = preload("res://src/scripts/DamageText.gd").new()
	
	# 表示位置を計算
	var text_position = UIPositionHelper.calculate_damage_text_position(sprite, position)
	
	# 親ノードに追加
	var parent = get_parent()
	if parent:
		parent.add_child(damage_text)
		damage_text.initialize_damage_text(damage, text_position, true)  # プレイヤーダメージ = 白色

## HPバー位置の更新
func _update_hp_bar_position() -> void:
	"""スプライトサイズに基づいてHPバー位置を動的に計算"""
	if not hp_bar:
		return
	
	var hp_bar_offset = UIPositionHelper.calculate_hp_bar_position(sprite, "RedCharacter")
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
	_update_weapon_from_system()
	_log_debug("RedCharacter weapon data refreshed")

## PlayerStatsからステータスを更新
func update_stats_from_player_stats() -> void:
	"""PlayerStatsシングルトンから最新のステータスを取得して更新"""
	if not PlayerStats.red_character_unlocked:
		return
	
	# 最大HPを更新
	max_hp = PlayerStats.get_red_character_max_hp()
	# 現在HPが最大HPを超える場合は調整
	if current_hp > max_hp:
		current_hp = max_hp
	
	# 攻撃力を更新（WeaponSystemから取得）
	attack_damage = PlayerStats.get_red_character_attack_damage()
	
	# 攻撃範囲を更新（WeaponSystemから取得）
	attack_range = PlayerStats.get_red_character_attack_range()
	
	# 武器データを更新
	refresh_weapon_data()
	
	# コイン数を同期
	total_coins = PlayerStats.total_coins
	
	# HPバーを更新
	if hp_bar:
		hp_bar.initialize_hp(current_hp, max_hp)
	
	# HPシグナルを発火
	hp_changed.emit(current_hp, max_hp)
	
	_log_debug("Stats updated from PlayerStats - HP: %d/%d, Attack: %d, Range: %.1f, Coins: %d" % [current_hp, max_hp, attack_damage, attack_range, total_coins])

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
	_log_debug("RedCharacter moved to: %s" % new_pos)

## 攻撃中かどうかを確認（魔法攻撃は連続的）
func is_character_attacking() -> bool:
	return is_in_combat

## 現在位置の取得
func get_current_position() -> Vector2:
	return position

## 位置の有効性チェック
func _is_valid_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x <= GameConstants.SCREEN_WIDTH and \
		   pos.y >= 0 and pos.y <= GameConstants.SCREEN_HEIGHT

## プレイヤーノードを検索
func _find_player() -> Node2D:
	"""プレイヤーノードを検索"""
	# グループからプレイヤーを検索
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node2D
	
	# パス検索
	var player_by_path = get_node_or_null("../../Player")
	if player_by_path:
		return player_by_path as Node2D
	
	# 親を辿ってPlayAreaを見つけてからプレイヤーを取得
	var current = get_parent()
	while current:
		if current.name == "PlayArea":
			var player_node = current.get_node_or_null("Player")
			if player_node:
				return player_node as Node2D
		current = current.get_parent()
	
	return null

## 最も近い敵ノードを検索
func _find_nearest_enemy() -> Node2D:
	"""最も近い敵ノードを検索"""
	# グループから敵を検索
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return null
	
	var nearest_enemy = null
	var shortest_distance = 999999.0
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = position.distance_to(enemy.position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_enemy = enemy
	
	return nearest_enemy as Node2D

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[RedCharacter(あかさん)] %s" % message)

## エラーログ出力
func _log_error(message: String) -> void:
	print("[RedCharacter(あかさん)] ERROR: %s" % message)

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
