extends Control

## メインシーン管理クラス
## プレイヤー制御、UI管理、スクロール管理、テスト実行を担当

@onready var player: Player = $PlayArea/Player
@onready var background_scroller: BackgroundScroller = $PlayArea/BackgroundScroller
@onready var ground_scroller: GroundScroller = $PlayArea/GroundScroller
@onready var distance_label: Label = $PlayArea/DistanceLabel

var scroll_manager: ScrollManager
var traveled_distance: float = 0.0
var enemy_spawned: bool = false
var is_in_battle: bool = false
var current_enemy: EnemyBase = null

# エネミーシーンの参照
const BasicEnemyScene = preload("res://src/scenes/BasicEnemy.tscn")

func _ready():
	_log_debug("MainScene loaded - Auto Rogue Game Started!")
	_setup_scroll_manager()
	_setup_player_signals()
	_setup_scroll_signals()
	_setup_distance_tracking()

func _process(delta):
	if not is_in_battle:
		_update_traveled_distance(delta)
	_check_player_enemy_proximity()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == GameConstants.TEST_KEY:
			_run_player_tests()

## スクロール管理の初期設定
func _setup_scroll_manager() -> void:
	scroll_manager = ScrollManager.new()
	add_child(scroll_manager)
	
	# スクローラーを登録
	if background_scroller:
		scroll_manager.add_scroller(background_scroller)
	if ground_scroller:
		scroll_manager.add_scroller(ground_scroller)
	
	# シグナル接続
	scroll_manager.scroll_speed_changed.connect(_on_scroll_speed_changed)
	_log_debug("ScrollManager initialized with %d scrollers" % scroll_manager.get_scroller_count())

## プレイヤーシグナルの設定
func _setup_player_signals() -> void:
	if not player:
		_log_error("Player not found")
		return
	
	player.position_changed.connect(_on_player_position_changed)
	player.player_reset.connect(_on_player_reset)
	player.attack_started.connect(_on_player_attack_started)
	player.attack_finished.connect(_on_player_attack_finished)
	player.player_died.connect(_on_player_died)
	_log_debug("Player signals connected")

## スクロールシグナルの設定
func _setup_scroll_signals() -> void:
	if background_scroller:
		background_scroller.background_looped.connect(_on_background_looped)
	if ground_scroller:
		ground_scroller.ground_looped.connect(_on_ground_looped)
	_log_debug("Scroll signals connected")

## 距離トラッキングの設定
func _setup_distance_tracking() -> void:
	traveled_distance = 0.0
	_update_distance_display()
	_log_debug("Distance tracking initialized")

## 移動距離の更新
func _update_traveled_distance(delta: float) -> void:
	traveled_distance += GameConstants.PLAYER_TRAVEL_SPEED * delta
	_update_distance_display()
	_check_enemy_spawn()

## 距離表示の更新
func _update_distance_display() -> void:
	if distance_label:
		distance_label.text = "%d m" % int(traveled_distance)

## 敵の出現チェック
func _check_enemy_spawn() -> void:
	if not enemy_spawned and traveled_distance >= GameConstants.ENEMY_SPAWN_DISTANCE:
		_spawn_enemy()
		enemy_spawned = true

## 敵をスポーンさせる
func _spawn_enemy() -> void:
	# 現在は基本敵のみスポーン（将来的に種類を選択可能に）
	var enemy_instance = BasicEnemyScene.instantiate()
	if enemy_instance:
		# 画面右端外側から出現、地面上に配置
		var spawn_position = Vector2(
			GameConstants.ENEMY_SPAWN_X,
			GameConstants.GROUND_Y_POSITION - GameConstants.GROUND_HEIGHT / 2.0 - 21.0  # プレイヤーと同じ高さ
		)
		enemy_instance.position = spawn_position
		
		# シグナル接続
		enemy_instance.enemy_reached_target.connect(_on_enemy_reached_target)
		enemy_instance.enemy_destroyed.connect(_on_enemy_destroyed)
		enemy_instance.enemy_battle_state_changed.connect(_on_enemy_battle_state_changed)
		enemy_instance.enemy_died.connect(_on_enemy_died)
		enemy_instance.enemy_attacked_player.connect(_on_enemy_attacked_player)
		
		# PlayAreaに追加
		$PlayArea.add_child(enemy_instance)
		current_enemy = enemy_instance
		_log_debug("BasicEnemy spawned at distance: %d m" % int(traveled_distance))

## プレイヤーと敵の接近判定
func _check_player_enemy_proximity() -> void:
	if current_enemy and is_instance_valid(current_enemy) and player:
		var distance = player.position.distance_to(current_enemy.position)
		
		if not is_in_battle and distance <= GameConstants.ENEMY_ENCOUNTER_DISTANCE:
			_start_battle()
		# 戦闘開始後は距離に関係なく、敵が死ぬまで戦闘継続
		# 戦闘終了は敵の死亡シグナルでのみ行う

## 戦闘開始
func _start_battle() -> void:
	is_in_battle = true
	_pause_game_progression()
	_start_player_attack()
	
	# 敵に戦闘状態を通知
	if current_enemy:
		current_enemy.set_battle_state(true)
	
	_log_debug("Battle started! Distance: %d m" % int(traveled_distance))

## 戦闘終了
func _end_battle() -> void:
	is_in_battle = false
	_resume_game_progression()
	
	# 敵に戦闘終了を通知
	if current_enemy:
		current_enemy.set_battle_state(false)
	
	_log_debug("Battle ended!")

## ゲーム進行の停止
func _pause_game_progression() -> void:
	if scroll_manager:
		scroll_manager.pause_all_scrollers()
	if current_enemy:
		current_enemy.is_walking = false
	_log_debug("Game progression paused")

## ゲーム進行の再開
func _resume_game_progression() -> void:
	if scroll_manager:
		scroll_manager.resume_all_scrollers()
	if current_enemy:
		current_enemy.is_walking = true
	_log_debug("Game progression resumed")

## 敵の戦闘状態変更イベントハンドラー
func _on_enemy_battle_state_changed(in_battle: bool) -> void:
	_log_debug("Enemy battle state changed: %s" % in_battle)

## プレイヤーの攻撃開始
func _start_player_attack() -> void:
	if player and not player.is_player_attacking():
		player.start_attack()

## プレイヤー攻撃イベントハンドラー
func _on_player_attack_started() -> void:
	_log_debug("Player attack started")
	# 敵にダメージを与える
	if current_enemy and is_instance_valid(current_enemy) and is_in_battle:
		var damage = GameConstants.PLAYER_DEFAULT_ATTACK_DAMAGE
		current_enemy.take_damage(damage)
		_log_debug("Player dealt %d damage to enemy" % damage)

func _on_player_attack_finished() -> void:
	_log_debug("Player attack finished")
	# 戦闘中なら次の攻撃を開始
	if is_in_battle:
		# 少し間を空けてから次の攻撃
		await get_tree().create_timer(0.3).timeout
		if is_in_battle:  # まだ戦闘中かチェック
			_start_player_attack()

## 敵イベントハンドラー
func _on_enemy_reached_target() -> void:
	current_enemy = null
	is_in_battle = false
	_resume_game_progression()
	_log_debug("Enemy reached target and was removed")

func _on_enemy_destroyed() -> void:
	current_enemy = null
	is_in_battle = false
	_resume_game_progression()
	_log_debug("Enemy was destroyed")

## 敵死亡イベントハンドラー
func _on_enemy_died() -> void:
	_log_debug("Enemy died! Battle ended.")
	current_enemy = null
	is_in_battle = false
	_resume_game_progression()

## 敵がプレイヤーを攻撃したイベントハンドラー
func _on_enemy_attacked_player(damage: int) -> void:
	_log_debug("Enemy attacked player for %d damage" % damage)
	if player and is_instance_valid(player):
		player.take_damage(damage)

## プレイヤー死亡イベントハンドラー
func _on_player_died() -> void:
	_log_debug("Player died! Game over.")
	is_in_battle = false
	_pause_game_progression()
	
	# プレイヤーを削除
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	
	# TODO: ゲームオーバー処理を追加（将来の実装）
	_log_debug("Game Over - Player has been defeated!")

## イベントハンドラー
func _on_player_position_changed(new_position: Vector2) -> void:
	_log_debug("Player position changed to: %s" % new_position)

func _on_player_reset() -> void:
	_log_debug("Player was reset to center")

func _on_background_looped() -> void:
	_log_debug("Background looped")

func _on_ground_looped() -> void:
	_log_debug("Ground looped")

func _on_scroll_speed_changed(new_speed: float) -> void:
	_log_debug("Scroll speed changed to: %f" % new_speed)


## テスト実行
func _run_player_tests():
	if not _validate_player():
		_log_error("Cannot run tests: Player not found")
		return
	
	_log_debug("🧪 Starting comprehensive tests...")
	TestPlayer.run_all_tests(player, self)

## バリデーション
func _validate_player() -> bool:
	if not player or not is_instance_valid(player):
		_log_error("Player is not available")
		return false
	return true

## スクロール管理のヘルパーメソッド
func get_scroll_status() -> Dictionary:
	if scroll_manager:
		return scroll_manager.get_all_scroller_status()
	return {}

func pause_all_scrolls() -> void:
	if scroll_manager:
		scroll_manager.pause_all_scrollers()

func resume_all_scrolls() -> void:
	if scroll_manager:
		scroll_manager.resume_all_scrollers()

## ログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[MainScene] %s" % message)

func _log_error(message: String) -> void:
	print("[MainScene] ERROR: %s" % message)