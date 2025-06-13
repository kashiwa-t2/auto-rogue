extends Control
class_name HPBar

## HPバー表示クラス
## キャラクターの上にHPを視覚的に表示

@onready var background: ColorRect
@onready var health_bar: ColorRect

var max_hp: int = 100
var current_hp: int = 100

signal hp_changed(new_hp: int, max_hp: int)
signal hp_depleted()

func _ready():
	_setup_hp_bar()

## HPバーの初期設定
func _setup_hp_bar():
	# HPバーのサイズ設定
	custom_minimum_size = Vector2(GameConstants.HP_BAR_WIDTH, GameConstants.HP_BAR_HEIGHT)
	size = custom_minimum_size
	
	# 背景の設定
	background = ColorRect.new()
	background.color = GameConstants.HP_BAR_BACKGROUND_COLOR
	background.size = Vector2(GameConstants.HP_BAR_WIDTH, GameConstants.HP_BAR_HEIGHT)
	background.position = Vector2.ZERO
	add_child(background)
	
	# HPバーの設定
	health_bar = ColorRect.new()
	health_bar.color = GameConstants.HP_BAR_HEALTH_COLOR
	health_bar.size = Vector2(GameConstants.HP_BAR_WIDTH, GameConstants.HP_BAR_HEIGHT)
	health_bar.position = Vector2.ZERO
	add_child(health_bar)
	
	_log_debug("HPBar initialized with size: %s" % custom_minimum_size)

## HPの初期化
func initialize_hp(initial_hp: int, maximum_hp: int = -1):
	if maximum_hp > 0:
		max_hp = maximum_hp
	else:
		max_hp = initial_hp
	
	current_hp = initial_hp
	_update_visual()
	_log_debug("HP initialized: %d/%d" % [current_hp, max_hp])

## HPにダメージを与える
func take_damage(damage: int):
	var old_hp = current_hp
	current_hp = max(0, current_hp - damage)
	
	_update_visual()
	hp_changed.emit(current_hp, max_hp)
	
	_log_debug("Damage taken: %d, HP: %d/%d" % [damage, current_hp, max_hp])
	
	if current_hp <= 0:
		hp_depleted.emit()
		_log_debug("HP depleted!")

## HPを回復
func heal(amount: int):
	var old_hp = current_hp
	current_hp = min(max_hp, current_hp + amount)
	
	_update_visual()
	hp_changed.emit(current_hp, max_hp)
	
	_log_debug("Healed: %d, HP: %d/%d" % [amount, current_hp, max_hp])

## HPバーの見た目を更新
func _update_visual():
	if not health_bar:
		return
	
	var hp_ratio = float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	health_bar.size.x = GameConstants.HP_BAR_WIDTH * hp_ratio
	
	# HPが低いときは色を変更
	if hp_ratio <= 0.3:
		health_bar.color = GameConstants.HP_BAR_DAMAGE_COLOR
	else:
		health_bar.color = GameConstants.HP_BAR_HEALTH_COLOR

## 現在のHP取得
func get_current_hp() -> int:
	return current_hp

## 最大HP取得
func get_max_hp() -> int:
	return max_hp

## HP割合取得
func get_hp_ratio() -> float:
	return float(current_hp) / float(max_hp) if max_hp > 0 else 0.0

## HPバーの表示/非表示
func set_hp_bar_visible(show_bar: bool):
	visible = show_bar

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[HPBar] %s" % message)