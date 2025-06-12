extends Control
class_name TitleScene

## タイトル画面の制御クラス
## ゲーム開始・シーン遷移を管理

@onready var start_button: Button = $TitleContainer/ButtonContainer/StartButton
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var subtitle_label: Label = $TitleContainer/SubtitleLabel

var is_transitioning: bool = false

signal start_game_requested()

func _ready():
	_setup_ui()
	_connect_signals()
	_log_debug("TitleScene initialized")

func _setup_ui() -> void:
	"""UI要素の初期設定"""
	# ボタンのフォーカスを設定
	if start_button:
		start_button.grab_focus()
		_log_debug("Start button focused")
	
	# タイトルのアニメーション（オプション）
	_animate_title_entrance()

func _connect_signals() -> void:
	"""シグナルの接続"""
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
		_log_debug("Connected start button signal")

func _animate_title_entrance() -> void:
	"""タイトル画面の登場アニメーション"""
	# タイトルラベルのフェードイン
	if title_label:
		title_label.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
		_log_debug("Title fade-in animation started")
	
	# サブタイトルのフェードイン（遅延）
	if subtitle_label:
		subtitle_label.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_interval(0.5)
		tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.8)
		_log_debug("Subtitle fade-in animation started")
	
	# ボタンのフェードイン（さらに遅延）
	if start_button:
		start_button.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_interval(1.0)
		tween.tween_property(start_button, "modulate:a", 1.0, 0.5)
		_log_debug("Button fade-in animation started")

func _on_start_button_pressed() -> void:
	"""ゲーム開始ボタンが押された時の処理"""
	if is_transitioning:
		return
	
	is_transitioning = true
	_log_debug("Start button pressed, transitioning to game...")
	
	# ボタン押下時のアニメーション
	if start_button:
		start_button.disabled = true
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(start_button, "scale", Vector2(0.95, 0.95), 0.1)
		tween.tween_property(start_button, "modulate:a", 0.5, 0.1)
		await tween.finished
	
	# シーン遷移
	_transition_to_game()

func _transition_to_game() -> void:
	"""ゲームシーンへの遷移"""
	_log_debug("Transitioning to MainScene...")
	
	# SceneTransitionを使用してスムーズに遷移
	await SceneTransition.change_scene("res://src/scenes/MainScene.tscn", 0.5, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	"""未処理の入力イベント処理"""
	# エンターキーでもゲーム開始
	if event.is_action_pressed("ui_accept") and not is_transitioning:
		_on_start_button_pressed()

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[TitleScene] %s" % message)

## エラーログ出力
func _log_error(message: String) -> void:
	print("[TitleScene] ERROR: %s" % message)