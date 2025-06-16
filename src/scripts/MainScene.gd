extends Control

## メインシーン管理クラス - BattleManagerリファクタリング版
## ゲームのコア機能を統合管理（BattleManager使用）
## 
## 主要責任:
## - 味方キャラ制御: GreenCharacter(みどりくん) + RedCharacter(あかさん)
## - Enemyシステム: 複数Enemy同時攻撃（5秒間隔無限出現）
## - UI管理（距離・ゴールド表示）
## - スクロール管理（戦闘時停止制御）
## - オートセーブ（30秒間隔）
## - 戦闘状態管理はBattleManagerに委譲

@onready var player: Player = $PlayArea/Player  # GreenCharacter (みどりくん)
@onready var red_character: Node2D = null  # RedCharacter (あかさん) - 解放後に動的追加
@onready var background_scroller: BackgroundScroller = $PlayArea/BackgroundScroller
@onready var ground_scroller: GroundScroller = $PlayArea/GroundScroller
@onready var distance_label: Label = $PlayArea/DistanceLabel
@onready var gold_label: Label = $PlayArea/GoldUI/GoldLabel
@onready var game_over_screen: Control = $GameOverScreen
@onready var tab_system: TabSystem = $UIArea/TabSystem
@onready var upgrade_ui: UpgradeUI = $UIArea/TabSystem/ContentArea/UpgradeContent/UpgradeUI
@onready var weapon_ui: WeaponUI = $UIArea/TabSystem/ContentArea/WeaponContent/WeaponUI

var scroll_manager: ScrollManager
var battle_manager: BattleManager
var traveled_distance: float = 0.0

# システムタイマー
var enemy_spawn_timer: Timer
var autosave_timer: Timer

# エネミーシーンの参照
const BasicEnemyScene = preload("res://src/scenes/BasicEnemy.tscn")
const MageEnemyScene = preload("res://src/scenes/MageEnemy.tscn")
const RedCharacterScene = preload("res://src/scenes/RedCharacter.tscn")

func _ready():
	_log_debug("MainScene loaded - Auto Rogue Game Started!")
	_setup_scroll_manager()
	_setup_battle_manager()
	_setup_player_signals()
	_setup_red_character_if_unlocked()
	_setup_scroll_signals()
	_setup_distance_tracking()
	_setup_gold_display()
	_setup_player_stats_signals()
	_setup_upgrade_ui()
	_setup_enemy_spawn_timer()
	_setup_autosave_timer()
	_load_player_data()
	
	# オートセーブ実行
	SaveManager.autosave()
	
	# シーン開始時のフェードイン（SceneTransitionが自動的に処理）
	
	# BattleManagerの初期化を完了
	call_deferred("_on_ready_complete")

func _process(delta):
	if not battle_manager.is_battle_active():
		_update_traveled_distance(delta)
	battle_manager.update_battle_proximity()
	
	# RedCharacterの独立戦闘開始チェック（GreenCharacterより射程が長いため）
	_check_red_character_combat_start()

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

## バトル管理の初期設定
func _setup_battle_manager() -> void:
	battle_manager = BattleManager.new()
	add_child(battle_manager)
	
	# BattleManagerシグナル接続
	battle_manager.battle_started.connect(_on_battle_started)
	battle_manager.battle_ended.connect(_on_battle_ended)
	battle_manager.enemy_added_to_approach.connect(_on_enemy_added_to_approach)
	battle_manager.enemy_added_to_battle.connect(_on_enemy_added_to_battle)
	battle_manager.enemy_removed_from_battle.connect(_on_enemy_removed_from_battle)
	battle_manager.target_changed.connect(_on_target_changed)
	
	_log_debug("BattleManager initialized")

## BattleManagerへのキャラクター初期化を待つ
func _on_ready_complete() -> void:
	"""BattleManagerにキャラクター参照を設定"""
	battle_manager.initialize(player, red_character, scroll_manager)
	_log_debug("BattleManager initialized with characters")

## プレイヤーシグナルの設定
func _setup_player_signals() -> void:
	if not player:
		_log_error("Player not found")
		return
	
	player.position_changed.connect(_on_player_position_changed)
	player.player_reset.connect(_on_player_reset)
	player.attack_started.connect(_on_player_attack_started)
	player.attack_hit.connect(_on_player_attack_hit)
	player.attack_finished.connect(_on_player_attack_finished)
	player.player_died.connect(_on_player_died)
	player.coin_collected.connect(_on_player_coin_collected)
	_log_debug("Player signals connected")

## あかさんの設定（解放済みの場合のみ）
func _setup_red_character_if_unlocked() -> void:
	if PlayerStats.red_character_unlocked:
		_spawn_red_character()
	else:
		_log_debug("Red character not unlocked yet")

## あかさんをスポーン
func _spawn_red_character() -> void:
	if red_character:
		_log_debug("Red character already exists")
		return
	
	# RedCharacterインスタンスを作成
	red_character = RedCharacterScene.instantiate()
	if red_character:
		# あかさんの位置を設定（みどりくんの左後ろに斜めに配置）
		var green_pos = player.position
		var red_position = Vector2(
			green_pos.x - 60,  # 左に60px
			green_pos.y + 30   # 後ろに30px
		)
		red_character.position = red_position
		
		# シグナル接続
		_setup_red_character_signals()
		
		# PlayAreaに追加
		$PlayArea.add_child(red_character)
		
		# ステータスを最新のPlayerStatsから更新（攻撃範囲600など）
		red_character.update_stats_from_player_stats()
		
		# BattleManagerにred_character参照を更新
		if battle_manager:
			battle_manager.update_red_character(red_character)
		
		_log_debug("Red character spawned at position: %s" % red_position)
	else:
		_log_error("Failed to instantiate RedCharacter")

## あかさんシグナルの設定
func _setup_red_character_signals() -> void:
	if not red_character:
		return
	
	red_character.position_changed.connect(_on_red_character_position_changed)
	red_character.character_reset.connect(_on_red_character_reset)
	red_character.attack_started.connect(_on_red_character_attack_started)
	red_character.magic_attack_fired.connect(_on_red_character_magic_attack_fired)
	red_character.attack_finished.connect(_on_red_character_attack_finished)
	red_character.character_died.connect(_on_red_character_died)
	red_character.coin_collected.connect(_on_red_character_coin_collected)
	_log_debug("Red character signals connected")

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

## ゴールド表示の設定
func _setup_gold_display() -> void:
	_update_gold_display()
	_log_debug("Gold display initialized")

## 育成UI の初期設定
func _setup_upgrade_ui() -> void:
	if upgrade_ui:
		upgrade_ui.upgrade_completed.connect(_on_upgrade_completed)
		_log_debug("Upgrade UI initialized")
	else:
		_log_error("Upgrade UI not found!")

## PlayerStatsシグナルの設定
func _setup_player_stats_signals() -> void:
	"""PlayerStatsのシグナルを接続してUI更新を自動化"""
	PlayerStats.coins_changed.connect(_on_coins_changed)
	_log_debug("PlayerStats signals connected - coins_changed")

## 敵スポーンタイマーの設定
func _setup_enemy_spawn_timer() -> void:
	enemy_spawn_timer = Timer.new()
	enemy_spawn_timer.wait_time = GameConstants.ENEMY_SPAWN_INTERVAL
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	enemy_spawn_timer.autostart = true
	add_child(enemy_spawn_timer)
	_log_debug("Enemy spawn timer initialized (interval: %f seconds)" % GameConstants.ENEMY_SPAWN_INTERVAL)

## 移動距離の更新
func _update_traveled_distance(delta: float) -> void:
	traveled_distance += GameConstants.PLAYER_TRAVEL_SPEED * delta
	_update_distance_display()

## 距離表示の更新
func _update_distance_display() -> void:
	if distance_label:
		distance_label.text = "%d m" % int(traveled_distance)

## ゴールド表示の更新
func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "%d" % PlayerStats.total_coins
		_log_debug("Gold display updated: %d coins" % PlayerStats.total_coins)
	
	# 育成UIも更新
	if upgrade_ui:
		upgrade_ui.update_display()

# =============================================================================
# 時間ベース敵出現システム（5秒間隔・無限出現）
# =============================================================================

func _on_enemy_spawn_timer_timeout() -> void:
	"""5秒間隔で敵を自動出現（戦闘状態に関係なく永続的）"""
	_spawn_enemy()
	_log_debug("Enemy spawned by timer")

## 敵をスポーンさせる
func _spawn_enemy() -> void:
	# ランダムで敵の種類を決定（70%: Basic, 30%: Mage）
	var enemy_instance
	var enemy_type_name = ""
	
	if randf() < 0.7:
		# 基本敵をスポーン
		enemy_instance = BasicEnemyScene.instantiate()
		enemy_type_name = "BasicEnemy"
	else:
		# 魔法使い敵をスポーン
		enemy_instance = MageEnemyScene.instantiate()
		enemy_type_name = "MageEnemy"
	
	if enemy_instance:
		# 画面右端外側から出現、地面上に配置
		var spawn_position = Vector2(
			GameConstants.ENEMY_SPAWN_X,
			GameConstants.GROUND_Y_POSITION - GameConstants.GROUND_HEIGHT / 2.0 - 21.0  # プレイヤーと同じ高さ
		)
		enemy_instance.position = spawn_position
		
		# シグナル接続（敵インスタンスをバインド）
		enemy_instance.enemy_reached_target.connect(_on_enemy_reached_target.bind(enemy_instance))
		enemy_instance.enemy_destroyed.connect(_on_enemy_destroyed.bind(enemy_instance))
		enemy_instance.enemy_battle_state_changed.connect(_on_enemy_battle_state_changed)
		enemy_instance.enemy_died.connect(_on_enemy_died.bind(enemy_instance))
		enemy_instance.enemy_attacked_player.connect(_on_enemy_attacked_player.bind(enemy_instance))
		
		# PlayAreaに追加
		$PlayArea.add_child(enemy_instance)
		# バトルマネージャーにアクティブ敵として追加
		battle_manager.add_active_enemy(enemy_instance)
		_log_debug("%s spawned by timer at distance: %d m" % [enemy_type_name, int(traveled_distance)])

# =============================================================================
# BattleManagerシグナルハンドラー
# =============================================================================

## BattleManagerシグナルハンドラー
func _on_battle_started() -> void:
	"""BattleManagerからの戦闘開始通知"""
	_start_player_attack()
	
	# あかさんが戦闘状態の場合は戦闘開始
	if red_character and battle_manager.is_red_character_in_battle():
		_start_red_character_combat()
	
	var target = battle_manager.get_green_character_target()
	var target_name = target.name if target else "NULL"
	_log_debug("Battle started! Distance: %d m (Target: %s)" % [int(traveled_distance), target_name])

func _on_battle_ended() -> void:
	"""BattleManagerからの戦闘終了通知"""
	var stats = battle_manager.get_battle_stats()
	_log_debug("Battle ended! Stats: %s" % stats)

func _on_enemy_added_to_approach(enemy: EnemyBase) -> void:
	"""BattleManagerからの敵接近状態通知"""
	_log_debug("Enemy entered approach state: %s" % enemy.name)

func _on_enemy_added_to_battle(enemy: EnemyBase) -> void:
	"""BattleManagerからの敵戦闘状態通知"""
	_log_debug("Enemy entered battle state: %s" % enemy.name)

func _on_enemy_removed_from_battle(enemy: EnemyBase) -> void:
	"""BattleManagerからの敵戦闘離脱通知"""
	_log_debug("Enemy removed from battle: %s" % enemy.name)

func _on_target_changed(character_type: String, new_target: EnemyBase) -> void:
	"""BattleManagerからのターゲット変更通知"""
	var target_name: String
	if new_target:
		target_name = new_target.name
	else:
		target_name = "None"
	_log_debug("%s character target changed to: %s" % [character_type, target_name])

## 敵の戦闘状態変更イベントハンドラー
func _on_enemy_battle_state_changed(in_battle: bool) -> void:
	_log_debug("Enemy battle state changed: %s" % in_battle)

## プレイヤーの攻撃開始
func _start_player_attack() -> void:
	if player and not player.is_player_attacking():
		player.start_attack()

## プレイヤー攻撃イベントハンドラー
func _on_player_attack_started() -> void:
	_log_debug("Player attack animation started")

## プレイヤー攻撃ヒットイベントハンドラー（実際のダメージタイミング）
func _on_player_attack_hit() -> void:
	_log_debug("Player attack hit!")
	# BattleManagerからターゲットを取得
	var target = battle_manager.get_green_character_target()
	if target and is_instance_valid(target) and battle_manager.is_battle_active():
		# プレイヤーの攻撃射程内かチェック
		var distance_to_target = abs(player.position.x - target.position.x)
		if distance_to_target <= GameConstants.PLAYER_ATTACK_RANGE:
			var damage = PlayerStats.get_attack_damage()
			target.take_damage(damage)
			_log_debug("Player dealt %d damage to target enemy (distance: %.1f)" % [damage, distance_to_target])
		else:
			_log_debug("Player attack missed - target too far (distance: %.1f, range: %.1f)" % [distance_to_target, GameConstants.PLAYER_ATTACK_RANGE])
	else:
		_log_debug("Attack hit but no valid target found")

func _on_player_attack_finished() -> void:
	_log_debug("Player attack finished")
	# 戦闘中なら次の攻撃を開始
	if battle_manager.is_battle_active():
		# 攻撃速度レベルに基づく動的な攻撃間隔
		var attack_interval = PlayerStats.get_attack_interval()
		await get_tree().create_timer(attack_interval).timeout
		if battle_manager.is_battle_active():  # まだ戦闘中かチェック
			_start_player_attack()
			_log_debug("Next attack started with interval: %.2fs" % attack_interval)

## 敵イベントハンドラー
func _on_enemy_reached_target(enemy: EnemyBase) -> void:
	if enemy:
		battle_manager.remove_active_enemy(enemy)
		_log_debug("Enemy reached target and was removed")

func _on_enemy_destroyed(enemy: EnemyBase) -> void:
	if enemy:
		battle_manager.remove_active_enemy(enemy)
		_log_debug("Enemy was destroyed")

## 敵死亡イベントハンドラー
func _on_enemy_died(enemy: EnemyBase) -> void:
	_log_debug("Enemy died!")
	if enemy:
		battle_manager.remove_active_enemy(enemy)
		var stats = battle_manager.get_battle_stats()
		_log_debug("Enemy removed - Battle stats: %s" % stats)

## 敵がプレイヤーを攻撃したイベントハンドラー
func _on_enemy_attacked_player(damage: int, enemy: EnemyBase) -> void:
	# 敵が戦闘状態かどうかは敵自身が管理しているので、ここでは単純にダメージを受ける
	if enemy and player and is_instance_valid(player):
		player.take_damage(damage)
		_log_debug("Enemy %s attacked player for %d damage" % [enemy.name, damage])

## プレイヤー死亡イベントハンドラー
func _on_player_died() -> void:
	_log_debug("Green character died!")
	
	# あかさんが生きている場合はゲーム継続
	if red_character and is_instance_valid(red_character) and red_character.is_alive() and PlayerStats.red_character_unlocked:
		_log_debug("Game continues - red character still alive")
		# みどりくんを非表示にするだけ
		if player and is_instance_valid(player):
			player.visible = false
		return
	
	# 全キャラクターが死亡した場合はゲームオーバー
	_trigger_game_over()

## ゲームオーバー処理
func _trigger_game_over() -> void:
	_log_debug("All characters died! Game over.")
	# スクロール停止
	if scroll_manager:
		scroll_manager.pause_all_scrollers()
	
	# ゲームオーバー画面を表示
	if game_over_screen:
		var total_coins = PlayerStats.total_coins
		game_over_screen.show_game_over(traveled_distance, total_coins)
	
	# 全キャラクターを削除
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	
	if red_character and is_instance_valid(red_character):
		red_character.queue_free()
		red_character = null
	
	_log_debug("Game Over - All characters have been defeated!")

## プレイヤーコイン収集イベントハンドラー
func _on_player_coin_collected(amount: int, total: int) -> void:
	_log_debug("RECEIVED coin_collected signal! Amount: %d, Total: %d" % [amount, total])
	# PlayerStatsに反映
	PlayerStats.add_coins(amount)
	_update_gold_display()
	_log_debug("PlayerStats updated with %d coins. Total: %d" % [amount, PlayerStats.total_coins])

## プレイヤーデータの読み込み
func _load_player_data() -> void:
	"""ゲーム開始時にプレイヤーデータを読み込み"""
	# TODO: 将来的にはセーブファイルから読み込み
	# 現在はデフォルト値で初期化
	_log_debug("Player data loaded from defaults")

## コイン収集完了イベントハンドラー
func _on_coin_collected(value: int) -> void:
	_log_debug("Coin collection animation completed! Value: %d" % value)
	# 追加のUI更新があればここで実行

## コイン変更イベントハンドラー
func _on_coins_changed(new_amount: int) -> void:
	"""PlayerStatsのコイン変更時にUIを自動更新"""
	_log_debug("Coins changed to: %d, updating UI..." % new_amount)
	_update_gold_display()

## レベルアップ完了イベントハンドラー
func _on_upgrade_completed() -> void:
	_log_debug("Upgrade completed! Updating character stats...")
	
	# あかさんが新たに解放されたかチェック
	if PlayerStats.red_character_unlocked and not red_character:
		_spawn_red_character()
	
	# みどりくんのステータスを更新
	if player:
		var old_max_hp = player.max_hp
		var new_max_hp = PlayerStats.get_max_hp()
		var hp_increase = new_max_hp - old_max_hp
		
		# 最大HPを更新し、現在HPも増加分だけ追加
		player.max_hp = new_max_hp
		player.current_hp += hp_increase
		
		# 現在HPが最大HPを超えないようにクランプ
		player.current_hp = min(player.current_hp, player.max_hp)
		
		# HPバーも更新
		if player.hp_bar:
			player.hp_bar.initialize_hp(player.current_hp, player.max_hp)
		_log_debug("Green character HP updated: %d/%d (increased by %d)" % [player.current_hp, player.max_hp, hp_increase])
	
	# あかさんのステータスを更新
	if red_character and is_instance_valid(red_character) and PlayerStats.red_character_unlocked:
		red_character.update_stats_from_player_stats()
		_log_debug("Red character stats updated")
	
	_update_gold_display()

# =============================================================================
# レガシー関数（互換性のため保持）
# =============================================================================

## RedCharacterの独立戦闘開始チェック
func _check_red_character_combat_start() -> void:
	"""RedCharacterの戦闘状態をチェックし、必要に応じて戦闘開始"""
	if not red_character or not is_instance_valid(red_character) or not PlayerStats.red_character_unlocked:
		return
	
	# RedCharacterが戦闘状態で、まだ攻撃していない場合
	if battle_manager.is_red_character_in_battle() and not red_character.is_character_attacking():
		_start_red_character_combat()
		_log_debug("RedCharacter combat started independently (longer range)")

## あかさんの戦闘開始
func _start_red_character_combat() -> void:
	"""あかさんの戦闘を開始"""
	if not red_character or not is_instance_valid(red_character):
		return
	
	# BattleManagerからターゲットを取得
	var target = battle_manager.get_red_character_target()
	
	# ターゲットがいる場合は戦闘開始
	if target:
		var distance = abs(red_character.position.x - target.position.x)
		red_character.start_combat(target)
		_log_debug("Red character combat started against: %s (distance: %.1f)" % [target.name, distance])
	else:
		_log_debug("Red character has no target for combat")

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

## オートセーブタイマーのセットアップ
func _setup_autosave_timer() -> void:
	"""オートセーブタイマーの設定"""
	autosave_timer = Timer.new()
	autosave_timer.wait_time = 30.0  # 30秒間隔でオートセーブ
	autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(autosave_timer)
	autosave_timer.start()
	_log_debug("Autosave timer setup completed - 30 second intervals")

## オートセーブタイマータイムアウト時の処理
func _on_autosave_timer_timeout() -> void:
	"""定期的なオートセーブ実行"""
	SaveManager.autosave()
	_log_debug("Autosave executed")

# =============================================================================
# 複数キャラクター管理システム - BattleManagerに移行済み
# =============================================================================

# =============================================================================
# あかさんイベントハンドラー
# =============================================================================

func _on_red_character_position_changed(new_position: Vector2) -> void:
	_log_debug("Red character position changed to: %s" % new_position)

func _on_red_character_reset() -> void:
	_log_debug("Red character was reset")

func _on_red_character_attack_started() -> void:
	_log_debug("Red character attack started")

func _on_red_character_magic_attack_fired(target: Node2D, damage: int) -> void:
	var target_name = "null"
	if target:
		target_name = target.name
	_log_debug("Red character fired magic attack at %s for %d damage" % [target_name, damage])

func _on_red_character_attack_finished() -> void:
	_log_debug("Red character attack finished")

func _on_red_character_died() -> void:
	_log_debug("Red character died!")
	# あかさんの戦闘停止
	if red_character:
		red_character.stop_combat()
	
	# みどりくんが生きている場合はゲーム継続
	if player and is_instance_valid(player) and player.is_alive():
		_log_debug("Game continues - green character still alive")
		# あかさんを非表示にするだけ
		if red_character and is_instance_valid(red_character):
			red_character.visible = false
		return
	
	# 全キャラクターが死亡した場合はゲームオーバー
	_trigger_game_over()

func _on_red_character_coin_collected(amount: int, total: int) -> void:
	_log_debug("Red character collected coin! Amount: %d, Total: %d" % [amount, total])
	# PlayerStatsに反映
	PlayerStats.add_coins(amount)
	_update_gold_display()

## WeaponSystem取得
func get_weapon_system() -> WeaponSystem:
	"""WeaponSystemを取得"""
	if weapon_ui and weapon_ui.has_method("get_weapon_system"):
		return weapon_ui.get_weapon_system()
	return null

## ログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[MainScene] %s" % message)

func _log_error(message: String) -> void:
	print("[MainScene] ERROR: %s" % message)