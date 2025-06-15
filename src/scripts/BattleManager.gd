extends Node
class_name BattleManager

## バトル管理専用クラス
## 戦闘状態管理、距離判定、攻撃調整の統一管理
## 
## 責任:
## - 複数Enemy vs 味方キャラクターの戦闘状態管理
## - 距離ベースの戦闘開始/終了判定
## - ターゲット選択と優先順位管理
## - 戦闘フロー制御とイベント通知

# =============================================================================
# Enemy管理配列
# =============================================================================
var active_enemies: Array[EnemyBase] = []          # 全アクティブEnemy
var approaching_enemies: Array[EnemyBase] = []     # 接近中Enemy（Enemy接敵距離内、味方攻撃射程外）
var battle_enemies: Array[EnemyBase] = []          # 戦闘中Enemy（味方攻撃射程内）

# =============================================================================
# 戦闘状態管理
# =============================================================================
var is_in_battle: bool = false                    # 全体戦闘状態
var green_character_in_battle: bool = false       # GreenCharacter戦闘状態
var red_character_in_battle: bool = false         # RedCharacter戦闘状態

# =============================================================================
# ターゲット管理
# =============================================================================
var current_attack_target: EnemyBase = null       # GreenCharacter攻撃ターゲット
var red_character_attack_target: EnemyBase = null # RedCharacter攻撃ターゲット

# =============================================================================
# 参照管理
# =============================================================================
var green_character: Node2D = null                # GreenCharacter参照
var red_character: Node2D = null                  # RedCharacter参照
var scroll_manager: ScrollManager = null          # スクロール管理参照

# =============================================================================
# シグナル定義
# =============================================================================
signal battle_started()                           # 戦闘開始通知
signal battle_ended()                             # 戦闘終了通知
signal enemy_added_to_approach(enemy: EnemyBase)  # 敵接近状態通知
signal enemy_added_to_battle(enemy: EnemyBase)    # 敵戦闘状態通知
signal enemy_removed_from_battle(enemy: EnemyBase) # 敵戦闘離脱通知
signal target_changed(character_type: String, new_target: EnemyBase) # ターゲット変更通知

func _ready():
	_log_debug("BattleManager initialized")

# =============================================================================
# 初期化・設定
# =============================================================================

## 初期化: 味方キャラクターとスクロール管理の参照を設定
func initialize(green_char: Node2D, red_char: Node2D, scroll_mgr: ScrollManager) -> void:
	green_character = green_char
	red_character = red_char
	scroll_manager = scroll_mgr
	_reset_battle_state()
	_log_debug("BattleManager initialized with characters and scroll manager")

## RedCharacter参照の動的更新
func update_red_character(red_char: Node2D) -> void:
	red_character = red_char
	var char_name: String
	if red_character:
		char_name = red_character.name
	else:
		char_name = "null"
	_log_debug("BattleManager red character reference updated: %s" % char_name)

## バトル状態リセット
func _reset_battle_state() -> void:
	active_enemies.clear()
	approaching_enemies.clear()
	battle_enemies.clear()
	current_attack_target = null
	red_character_attack_target = null
	is_in_battle = false
	green_character_in_battle = false
	red_character_in_battle = false

# =============================================================================
# 距離判定・戦闘状態管理（メインロジック）
# =============================================================================

## メイン処理: 味方キャラとEnemyの距離判定・戦闘状態更新
func update_battle_proximity() -> void:
	if not green_character:
		return
	
	# 無効なEnemyを配列から削除
	_cleanup_invalid_enemies()
	
	# 各Enemyの距離を2段階で判定
	for enemy in active_enemies:
		_process_enemy_proximity(enemy)
	
	# 攻撃ターゲットの更新
	_update_attack_targets()
	
	# キャラクター戦闘状態の確認
	_check_character_battle_states()
	
	# 戦闘状態の管理
	_manage_overall_battle_state()

## 個別Enemy距離処理
func _process_enemy_proximity(enemy: EnemyBase) -> void:
	if not enemy or not is_instance_valid(enemy):
		return
	
	var green_distance = abs(green_character.position.x - enemy.position.x)
	var enemy_encounter_distance = enemy.get_encounter_distance()
	
	_log_debug("Green distance to %s: %.1f (encounter: %.1f)" % [enemy.name, green_distance, enemy_encounter_distance])
	
	# ステップ1: GreenCharacter攻撃射程内（80px）→ 戦闘状態
	if green_distance <= GameConstants.PLAYER_ATTACK_RANGE:
		if enemy not in battle_enemies:
			_add_enemy_to_battle(enemy)
		# 接近状態からも削除
		if enemy in approaching_enemies:
			approaching_enemies.erase(enemy)
	
	# ステップ2: Enemy接敵距離内 → 接近状態
	elif green_distance <= enemy_encounter_distance:
		if enemy not in approaching_enemies and enemy not in battle_enemies:
			_add_enemy_to_approach(enemy)

## 無効なEnemyを配列から削除
func _cleanup_invalid_enemies() -> void:
	active_enemies = active_enemies.filter(func(enemy): return is_instance_valid(enemy))
	approaching_enemies = approaching_enemies.filter(func(enemy): return is_instance_valid(enemy))
	battle_enemies = battle_enemies.filter(func(enemy): return is_instance_valid(enemy))

# =============================================================================
# Enemy状態管理
# =============================================================================

## 新しいEnemyをアクティブリストに追加
func add_active_enemy(enemy: EnemyBase) -> void:
	if enemy and enemy not in active_enemies:
		active_enemies.append(enemy)
		_log_debug("Enemy added to active list: %s (Total: %d)" % [enemy.name, active_enemies.size()])

## Enemyをアクティブリストから削除
func remove_active_enemy(enemy: EnemyBase) -> void:
	if enemy:
		active_enemies.erase(enemy)
		approaching_enemies.erase(enemy)
		battle_enemies.erase(enemy)
		
		# ターゲットが削除された場合はクリア
		if enemy == current_attack_target:
			current_attack_target = null
		if enemy == red_character_attack_target:
			red_character_attack_target = null
			
		_log_debug("Enemy removed from all lists: %s" % enemy.name)

## Enemyを接近状態に追加
func _add_enemy_to_approach(enemy: EnemyBase) -> void:
	if enemy not in approaching_enemies:
		approaching_enemies.append(enemy)
		enemy.set_battle_state(true)  # Enemy攻撃開始、背景と相対移動
		enemy_added_to_approach.emit(enemy)
		_log_debug("Enemy added to approach state: %s (Total: %d)" % [enemy.name, approaching_enemies.size()])

## Enemyを戦闘状態に追加
func _add_enemy_to_battle(enemy: EnemyBase) -> void:
	if enemy not in battle_enemies:
		battle_enemies.append(enemy)
		enemy.set_battle_state(true)  # Enemy戦闘状態に設定
		enemy_added_to_battle.emit(enemy)
		_log_debug("Enemy added to battle state: %s (Total: %d)" % [enemy.name, battle_enemies.size()])

# =============================================================================
# ターゲット管理
# =============================================================================

## 攻撃ターゲット更新
func _update_attack_targets() -> void:
	_update_green_character_target()
	_update_red_character_target()

## GreenCharacterターゲット更新
func _update_green_character_target() -> void:
	# 戦闘中Enemyがいない場合はターゲットクリア
	if battle_enemies.size() == 0:
		if current_attack_target != null:
			current_attack_target = null
			target_changed.emit("green", null)
		return
	
	# 現在のターゲットが有効で戦闘中なら維持
	if current_attack_target and current_attack_target in battle_enemies and is_instance_valid(current_attack_target):
		return
	
	# 新しいターゲットを設定（先入先攻撃）
	for enemy in battle_enemies:
		if is_instance_valid(enemy):
			current_attack_target = enemy
			target_changed.emit("green", enemy)
			_log_debug("GreenCharacter target updated: %s" % enemy.name)
			return
	
	current_attack_target = null

## RedCharacterターゲット更新
func _update_red_character_target() -> void:
	if not red_character or not is_instance_valid(red_character):
		red_character_attack_target = null
		return
	
	# 現在のターゲットが射程内なら維持
	if red_character_attack_target and is_instance_valid(red_character_attack_target):
		var distance = abs(red_character.position.x - red_character_attack_target.position.x)
		if distance <= red_character.attack_range:
			return
	
	# 新しいターゲットを検索（射程内の最初のEnemy）
	red_character_attack_target = null
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			var distance = abs(red_character.position.x - enemy.position.x)
			if distance <= red_character.attack_range:
				red_character_attack_target = enemy
				target_changed.emit("red", enemy)
				_log_debug("RedCharacter target updated: %s" % enemy.name)
				break

# =============================================================================
# 戦闘状態管理
# =============================================================================

## キャラクター戦闘状態確認
func _check_character_battle_states() -> void:
	# GreenCharacter戦闘状態チェック
	green_character_in_battle = false
	if green_character and is_instance_valid(green_character):
		for enemy in battle_enemies:
			if is_instance_valid(enemy):
				var distance = abs(green_character.position.x - enemy.position.x)
				if distance <= GameConstants.PLAYER_ATTACK_RANGE:
					green_character_in_battle = true
					break
	
	# RedCharacter戦闘状態チェック
	red_character_in_battle = false
	if red_character and is_instance_valid(red_character) and PlayerStats.red_character_unlocked:
		for enemy in active_enemies:
			if is_instance_valid(enemy):
				var distance = abs(red_character.position.x - enemy.position.x)
				if distance <= red_character.attack_range:
					red_character_in_battle = true
					break

## 全体戦闘状態管理
func _manage_overall_battle_state() -> void:
	# 戦闘開始判定
	if battle_enemies.size() > 0 and not is_in_battle:
		_start_battle()
	# 戦闘終了判定
	elif battle_enemies.size() == 0 and is_in_battle:
		_end_battle()

## 戦闘開始
func _start_battle() -> void:
	is_in_battle = true
	_pause_game_progression()
	battle_started.emit()
	
	# 戦闘中Enemyに戦闘状態を通知
	for enemy in battle_enemies:
		if is_instance_valid(enemy):
			enemy.set_battle_state(true)
	
	_log_debug("Battle started! (Battle enemies: %d)" % battle_enemies.size())

## 戦闘終了
func _end_battle() -> void:
	is_in_battle = false
	_resume_game_progression()
	battle_ended.emit()
	
	# 戦闘終了後の処理
	battle_enemies.clear()
	current_attack_target = null
	
	_log_debug("Battle ended!")

## ゲーム進行停止（全キャラ戦闘時のみ背景スクロール停止）
func _pause_game_progression() -> void:
	var should_pause = green_character_in_battle
	if red_character and PlayerStats.red_character_unlocked:
		should_pause = should_pause and red_character_in_battle
	
	if should_pause and scroll_manager:
		scroll_manager.pause_all_scrollers()
		_log_debug("Game progression paused - all characters in battle")

## ゲーム進行再開
func _resume_game_progression() -> void:
	if scroll_manager:
		scroll_manager.resume_all_scrollers()
	_log_debug("Game progression resumed")

# =============================================================================
# 公開API
# =============================================================================

## 現在の戦闘状態取得
func is_battle_active() -> bool:
	return is_in_battle

## GreenCharacter戦闘状態取得
func is_green_character_in_battle() -> bool:
	return green_character_in_battle

## RedCharacter戦闘状態取得  
func is_red_character_in_battle() -> bool:
	return red_character_in_battle

## GreenCharacterターゲット取得
func get_green_character_target() -> EnemyBase:
	return current_attack_target

## RedCharacterターゲット取得
func get_red_character_target() -> EnemyBase:
	return red_character_attack_target

## 戦闘統計取得
func get_battle_stats() -> Dictionary:
	var green_target_name: String
	if current_attack_target:
		green_target_name = current_attack_target.name
	else:
		green_target_name = ""
	
	var red_target_name: String
	if red_character_attack_target:
		red_target_name = red_character_attack_target.name
	else:
		red_target_name = ""
	
	return {
		"active_enemies": active_enemies.size(),
		"approaching_enemies": approaching_enemies.size(),
		"battle_enemies": battle_enemies.size(),
		"is_in_battle": is_in_battle,
		"green_in_battle": green_character_in_battle,
		"red_in_battle": red_character_in_battle,
		"green_target": green_target_name,
		"red_target": red_target_name
	}

# =============================================================================
# ログ・デバッグ
# =============================================================================

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[BattleManager] %s" % message)

## エラーログ出力
func _log_error(message: String) -> void:
	print("[BattleManager] ERROR: %s" % message)