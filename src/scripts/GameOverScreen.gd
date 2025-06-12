extends Control
class_name GameOverScreen

## ゲームオーバー画面の制御クラス
## ゲーム終了時の結果表示とタイトルへの遷移を管理

@onready var overlay: ColorRect = $Overlay
@onready var container: VBoxContainer = $Container
@onready var game_over_label: Label = $Container/GameOverLabel
@onready var result_label: Label = $Container/ResultLabel
@onready var coin_result_label: Label = $Container/CoinResultLabel
@onready var return_button: Button = $Container/ButtonContainer/ReturnButton

var final_distance: float = 0.0
var final_coins: int = 0

signal return_to_title_requested()

func _ready():
	# 最初は非表示
	visible = false
	_connect_signals()
	_log_debug("GameOverScreen initialized")

func _connect_signals() -> void:
	"""シグナルの接続"""
	if return_button:
		return_button.pressed.connect(_on_return_button_pressed)

## ゲームオーバー画面を表示
func show_game_over(distance: float, coins: int) -> void:
	"""ゲームオーバー画面を表示する"""
	final_distance = distance
	final_coins = coins
	
	# 結果を表示
	if result_label:
		result_label.text = "到達距離: %d m" % int(distance)
	
	if coin_result_label:
		coin_result_label.text = "獲得コイン: %d 枚" % coins
	
	# 表示
	visible = true
	
	# フェードインアニメーション
	_animate_entrance()
	
	_log_debug("Showing game over screen - Distance: %dm, Coins: %d" % [int(distance), coins])

func _animate_entrance() -> void:
	"""登場アニメーション"""
	# オーバーレイのフェードイン
	if overlay:
		overlay.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(overlay, "modulate:a", 0.8, 0.5)
	
	# コンテナのスケールアニメーション
	if container:
		container.scale = Vector2(0.8, 0.8)
		container.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(container, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(container, "modulate:a", 1.0, 0.3)
		await tween.finished
		
		# ボタンにフォーカス
		if return_button:
			return_button.grab_focus()

func _on_return_button_pressed() -> void:
	"""タイトルに戻るボタンが押された時の処理"""
	_log_debug("Return to title button pressed")
	
	# ボタンを無効化
	if return_button:
		return_button.disabled = true
	
	# タイトル画面へ遷移
	await SceneTransition.change_scene("res://src/scenes/TitleScene.tscn", 0.5, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	"""未処理の入力イベント処理"""
	# エンターキーでもタイトルに戻る
	if visible and event.is_action_pressed("ui_accept"):
		_on_return_button_pressed()

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[GameOverScreen] %s" % message)