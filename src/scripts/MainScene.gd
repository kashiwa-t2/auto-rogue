extends Control

## メインシーン管理クラス
## ゲームのコア機能を統合管理
## 
## 主要責任:
## - プレイヤー制御とシグナル管理
## - 複数敵同時攻撃システム（5秒間隔無限出現）
## - UI管理（距離・ゴールド表示）
## - スクロール管理（戦闘時停止制御）
## - オートセーブ（30秒間隔）
## - 戦闘状態管理（複数敵vs1プレイヤー）

@onready var player: Player = $PlayArea/Player
@onready var background_scroller: BackgroundScroller = $PlayArea/BackgroundScroller
@onready var ground_scroller: GroundScroller = $PlayArea/GroundScroller
@onready var distance_label: Label = $PlayArea/DistanceLabel
@onready var gold_label: Label = $PlayArea/GoldUI/GoldLabel
@onready var game_over_screen: Control = $GameOverScreen
@onready var upgrade_ui: UpgradeUI = $UIArea/UpgradeUI

var scroll_manager: ScrollManager
var traveled_distance: float = 0.0
var is_in_battle: bool = false

# 複数敵同時攻撃システム
var enemy_spawn_timer: Timer
var active_enemies: Array[EnemyBase] = []          # 全アクティブ敵
var approaching_enemies: Array[EnemyBase] = []     # 接近中の敵（敵の接敵距離内、プレイヤー攻撃射程外）
var battle_enemies: Array[EnemyBase] = []          # 戦闘中の敵（プレイヤー攻撃射程内）
var current_attack_target: EnemyBase = null       # 現在攻撃対象の敵（1体のみ）

# オートセーブ
var autosave_timer: Timer

# エネミーシーンの参照
const BasicEnemyScene = preload("res://src/scenes/BasicEnemy.tscn")
const MageEnemyScene = preload("res://src/scenes/MageEnemy.tscn")

func _ready():
	_log_debug("MainScene loaded - Auto Rogue Game Started!")
	_setup_scroll_manager()
	_setup_player_signals()
	_setup_scroll_signals()
	_setup_distance_tracking()
	_setup_gold_display()
	_setup_upgrade_ui()
	_setup_enemy_spawn_timer()
	_setup_autosave_timer()
	_load_player_data()
	
	# オートセーブ実行
	SaveManager.autosave()
	
	# シーン開始時のフェードイン（SceneTransitionが自動的に処理）

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
	player.attack_hit.connect(_on_player_attack_hit)
	player.attack_finished.connect(_on_player_attack_finished)
	player.player_died.connect(_on_player_died)
	player.coin_collected.connect(_on_player_coin_collected)
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
	active_enemies.clear()
	approaching_enemies.clear()
	battle_enemies.clear()
	current_attack_target = null
	is_in_battle = false
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
	_log_debug("Enemy spawned by timer (Active enemies: %d)" % active_enemies.size())

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
		# アクティブ敵リストに追加
		active_enemies.append(enemy_instance)
		_log_debug("%s spawned by timer at distance: %d m (Active enemies: %d)" % [enemy_type_name, int(traveled_distance), active_enemies.size()])

# =============================================================================
# 複数敵同時攻撃システム（複数敵vs1プレイヤー・攻撃優先順位制御）
# =============================================================================

func _check_player_enemy_proximity() -> void:
	if not player:
		return
	
	# 無効な敵を配列から削除
	active_enemies = active_enemies.filter(func(enemy): return is_instance_valid(enemy))
	approaching_enemies = approaching_enemies.filter(func(enemy): return is_instance_valid(enemy))
	battle_enemies = battle_enemies.filter(func(enemy): return is_instance_valid(enemy))
	
	# 敵の距離を2段階で判定
	for enemy in active_enemies:
		var distance = player.position.distance_to(enemy.position)
		var enemy_encounter_distance = enemy.get_encounter_distance()
		
		# ステップ1: プレイヤーの攻撃射程内（80px）→ 戦闘状態
		if distance <= GameConstants.PLAYER_ATTACK_RANGE:
			if enemy not in battle_enemies:
				_add_enemy_to_battle(enemy)
				# 接近状態からも削除
				if enemy in approaching_enemies:
					approaching_enemies.erase(enemy)
		
		# ステップ2: 敵の接敵距離内（例：魔法使い300px）→ 接近状態
		elif distance <= enemy_encounter_distance:
			if enemy not in approaching_enemies and enemy not in battle_enemies:
				_add_enemy_to_approach(enemy)
	
	# 攻撃ターゲットの更新（戦闘開始前に必須）
	_update_attack_target()
	
	# 戦闘状態の管理（プレイヤー攻撃射程内の敵がいる場合のみ戦闘状態）
	if battle_enemies.size() > 0 and not is_in_battle:
		_start_battle()
	elif battle_enemies.size() == 0 and is_in_battle:
		_end_battle()

## 戦闘開始（複数敵同時攻撃）
func _start_battle() -> void:
	is_in_battle = true
	_pause_game_progression()
	
	# 攻撃ターゲットが設定されていることを確認
	if current_attack_target:
		_log_debug("Battle started with attack target: %s" % current_attack_target)
	else:
		_log_debug("WARNING: Battle started but no attack target set!")
	
	_start_player_attack()
	
	# 全ての戦闘中敵に戦闘状態を通知
	for enemy in battle_enemies:
		if is_instance_valid(enemy):
			enemy.set_battle_state(true)
	
	_log_debug("Battle started! Distance: %d m (Battle enemies: %d, Target: %s)" % [int(traveled_distance), battle_enemies.size(), "SET" if current_attack_target else "NULL"])

## 戦闘終了
func _end_battle() -> void:
	is_in_battle = false
	_resume_game_progression()
	
	# 戦闘中敵のみ戦闘終了処理（接近中敵は引き続き攻撃状態で相対移動継続）
	var battle_enemies_count = battle_enemies.size()
	for enemy in battle_enemies:
		if is_instance_valid(enemy):
			# 戦闘終了後は接近状態に戻す（背景と相対的に移動）
			enemy.set_battle_state(true)  # 接近中の敵は攻撃状態維持
			_log_debug("Enemy released from battle to approach state")
	
	battle_enemies.clear()
	current_attack_target = null
	
	_log_debug("Battle ended! Released %d enemies from battle (Active: %d, Approaching: %d)" % [battle_enemies_count, active_enemies.size(), approaching_enemies.size()])

## ゲーム進行の停止（背景スクロールのみ）
func _pause_game_progression() -> void:
	if scroll_manager:
		scroll_manager.pause_all_scrollers()
	# 敵は戦闘中でも歩行を継続（背景のみ停止）
	_log_debug("Game progression paused (background scroll only)")

## ゲーム進行の再開（背景スクロールのみ）
func _resume_game_progression() -> void:
	if scroll_manager:
		scroll_manager.resume_all_scrollers()
	# 敵の歩行状態はそのまま維持
	_log_debug("Game progression resumed (background scroll only)")

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
	# 現在の攻撃ターゲットにのみダメージを与える
	if current_attack_target and is_instance_valid(current_attack_target) and is_in_battle:
		# プレイヤーの攻撃射程内かチェック
		var distance_to_target = player.position.distance_to(current_attack_target.position)
		if distance_to_target <= GameConstants.PLAYER_ATTACK_RANGE:
			var damage = PlayerStats.get_attack_damage()
			current_attack_target.take_damage(damage)
			_log_debug("Player dealt %d damage to target enemy (distance: %.1f)" % [damage, distance_to_target])
		else:
			_log_debug("Player attack missed - target too far (distance: %.1f, range: %.1f)" % [distance_to_target, GameConstants.PLAYER_ATTACK_RANGE])
	else:
		_log_debug("Attack hit but no valid target found")

func _on_player_attack_finished() -> void:
	_log_debug("Player attack finished")
	# 戦闘中なら次の攻撃を開始
	if is_in_battle:
		# 攻撃速度レベルに基づく動的な攻撃間隔
		var attack_interval = PlayerStats.get_attack_interval()
		await get_tree().create_timer(attack_interval).timeout
		if is_in_battle:  # まだ戦闘中かチェック
			_start_player_attack()
			_log_debug("Next attack started with interval: %.2fs" % attack_interval)

## 敵イベントハンドラー
func _on_enemy_reached_target(enemy: EnemyBase) -> void:
	if enemy:
		_remove_enemy_from_active_list(enemy)
		_log_debug("Enemy reached target and was removed (Active enemies: %d)" % active_enemies.size())

func _on_enemy_destroyed(enemy: EnemyBase) -> void:
	if enemy:
		_remove_enemy_from_active_list(enemy)
		_log_debug("Enemy was destroyed (Active enemies: %d)" % active_enemies.size())

## 敵死亡イベントハンドラー
func _on_enemy_died(enemy: EnemyBase) -> void:
	_log_debug("Enemy died!")
	if enemy:
		_remove_enemy_from_active_list(enemy)
		# 死亡した敵が現在の攻撃ターゲットの場合、次のターゲットに切り替え
		if enemy == current_attack_target:
			_update_attack_target()
		
		# 全ての生存敵の歩行状態を強制的に確認・修復
		_ensure_all_enemies_walking()
		
		# 戦闘状態の再評価：戦闘中の敵がいなくなった場合は戦闘終了
		# そうでない場合は残りの敵の移動状態を確認
		if battle_enemies.size() == 0:
			# 戦闘終了処理は_check_player_enemy_proximityで自動実行される
			_log_debug("No more battle enemies - battle will end")
		else:
			# まだ戦闘中の敵がいる場合、戦闘外の敵の移動を再開
			_resume_non_battle_enemies_movement()
		
		_log_debug("Enemy removed from lists (Active: %d, Approaching: %d, Battle: %d)" % [active_enemies.size(), approaching_enemies.size(), battle_enemies.size()])

## 敵がプレイヤーを攻撃したイベントハンドラー
func _on_enemy_attacked_player(damage: int, enemy: EnemyBase) -> void:
	# 接近中・戦闘中の敵からの攻撃は全て受ける
	if enemy and (enemy in approaching_enemies or enemy in battle_enemies):
		_log_debug("Enemy attacked player for %d damage (approaching: %s, battle: %s)" % [damage, enemy in approaching_enemies, enemy in battle_enemies])
		if player and is_instance_valid(player):
			player.take_damage(damage)
	else:
		_log_debug("Non-engaged enemy attack ignored")

## プレイヤー死亡イベントハンドラー
func _on_player_died() -> void:
	_log_debug("Player died! Game over.")
	is_in_battle = false
	_pause_game_progression()
	
	# ゲームオーバー画面を表示
	if game_over_screen:
		var total_coins = 0
		if player and is_instance_valid(player):
			total_coins = player.get_total_coins()
		game_over_screen.show_game_over(traveled_distance, total_coins)
	
	# プレイヤーを削除
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	
	_log_debug("Game Over - Player has been defeated!")

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

## レベルアップ完了イベントハンドラー
func _on_upgrade_completed() -> void:
	_log_debug("Upgrade completed! Updating player stats...")
	# プレイヤーのステータスを更新
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
		_log_debug("Player HP updated: %d/%d (increased by %d)" % [player.current_hp, player.max_hp, hp_increase])
	
	_update_gold_display()

# =============================================================================
# 複数敵同時攻撃システム - 管理関数
# =============================================================================

func _remove_enemy_from_active_list(enemy: EnemyBase) -> void:
	"""敵をアクティブ・接近・戦闘リストから削除"""
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		_log_debug("Enemy removed from active list")
	if enemy in approaching_enemies:
		approaching_enemies.erase(enemy)
		_log_debug("Enemy removed from approaching list")
	if enemy in battle_enemies:
		battle_enemies.erase(enemy)
		_log_debug("Enemy removed from battle list")

func _add_enemy_to_approach(enemy: EnemyBase) -> void:
	"""敵を接近リストに追加（敵の攻撃開始、背景スクロール継続）"""
	if enemy not in approaching_enemies:
		approaching_enemies.append(enemy)
		# 敵は攻撃状態になり、背景と相対的に移動
		enemy.set_battle_state(true)
		_log_debug("Enemy added to approach state (Approaching enemies: %d)" % approaching_enemies.size())

func _add_enemy_to_battle(enemy: EnemyBase) -> void:
	"""敵を戦闘リストに追加（プレイヤー攻撃開始、背景スクロール停止）"""
	if enemy not in battle_enemies:
		battle_enemies.append(enemy)
		# 新しく追加された敵を即座に戦闘状態に設定（背景と相対的に停止）
		enemy.set_battle_state(true)
		_log_debug("Enemy added to battle state (Battle enemies: %d)" % battle_enemies.size())

func _update_attack_target() -> void:
	"""攻撃ターゲットを更新（先に接近した敵を優先）"""
	if battle_enemies.size() == 0:
		current_attack_target = null
		return
	
	# 現在のターゲットが有効で戦闘中なら維持
	if current_attack_target and current_attack_target in battle_enemies and is_instance_valid(current_attack_target):
		return
	
	# 最初の戦闘中敵を新しいターゲットに（先入先攻撃）
	for enemy in battle_enemies:
		if is_instance_valid(enemy):
			current_attack_target = enemy
			_log_debug("Attack target updated to: Enemy (Battle enemies: %d)" % battle_enemies.size())
			return
	
	current_attack_target = null

## 戦闘外の敵の移動を再開
func _resume_non_battle_enemies_movement() -> void:
	"""戦闘中でない敵の移動を再開させる（背景との相対移動で自動管理）"""
	_log_debug("Non-battle enemies will move automatically with relative speed")

## 全ての敵の移動状態を確認・再開
func _ensure_all_enemies_walking() -> void:
	"""全ての生存敵の移動状態を確認（背景との相対移動で自動管理）"""
	_log_debug("All enemies will move automatically with relative speed based on battle state")

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

## ログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[MainScene] %s" % message)

func _log_error(message: String) -> void:
	print("[MainScene] ERROR: %s" % message)
