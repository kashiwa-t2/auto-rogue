extends Control
class_name TitleScene

## タイトル画面の制御クラス
## ゲーム開始・シーン遷移を管理

@onready var start_button: Button = $TitleContainer/ButtonContainer/StartButton
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var subtitle_label: Label = $TitleContainer/SubtitleLabel
@onready var delete_save_button: Button = $DeleteSaveButton
@onready var confirmation_modal: Control = $ConfirmationModal
@onready var yes_button: Button = $ConfirmationModal/ModalContainer/ButtonContainer/YesButton
@onready var no_button: Button = $ConfirmationModal/ModalContainer/ButtonContainer/NoButton

var is_transitioning: bool = false

signal start_game_requested()

func _ready():
	_setup_ui()
	_connect_signals()
	_log_debug("TitleScene initialized")

func _setup_ui() -> void:
	"""UI要素の初期設定"""
	# セーブデータの存在確認とボタンテキスト設定
	var has_save = SaveManager.has_save()
	if has_save:
		start_button.text = "ゲーム続行"
		_log_debug("Autosave detected - button set to continue")
	else:
		start_button.text = "ゲーム開始"
		_log_debug("No autosave - button set to new game")
	
	# 削除ボタンの表示/非表示
	if delete_save_button:
		delete_save_button.visible = has_save
		_log_debug("Delete save button visibility: " + str(has_save))
	
	# 確認モーダルを非表示に設定
	if confirmation_modal:
		confirmation_modal.hide()
	
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
	
	if delete_save_button:
		delete_save_button.pressed.connect(_on_delete_save_button_pressed)
		_log_debug("Connected delete save button signal")
	
	if yes_button:
		yes_button.pressed.connect(_on_yes_button_pressed)
		_log_debug("Connected yes button signal")
	
	if no_button:
		no_button.pressed.connect(_on_no_button_pressed)
		_log_debug("Connected no button signal")

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
		_log_debug("Start button fade-in animation started")

func _on_start_button_pressed() -> void:
	"""ゲーム開始/続行ボタンが押された時の処理"""
	if is_transitioning:
		return
	
	is_transitioning = true
	
	# セーブデータの存在確認
	var has_save = SaveManager.has_save()
	if has_save:
		_log_debug("Start button pressed, loading existing save...")
		SaveManager.load_game()
	else:
		_log_debug("Start button pressed, starting new game...")
		PlayerStats.reset_stats()
	
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

func _on_delete_save_button_pressed() -> void:
	"""セーブ削除ボタンが押された時の処理"""
	if is_transitioning:
		return
	
	_log_debug("Delete save button pressed, showing confirmation modal")
	_show_confirmation_modal()

func _show_confirmation_modal() -> void:
	"""確認モーダルを表示"""
	if confirmation_modal:
		confirmation_modal.show()
		# Yesボタンにフォーカス
		if yes_button:
			yes_button.grab_focus()
		_log_debug("Confirmation modal shown")

func _hide_confirmation_modal() -> void:
	"""確認モーダルを非表示"""
	if confirmation_modal:
		confirmation_modal.hide()
		# メインボタンにフォーカスを戻す
		if start_button:
			start_button.grab_focus()
		_log_debug("Confirmation modal hidden")

func _on_yes_button_pressed() -> void:
	"""はいボタンが押された時の処理"""
	_log_debug("Yes button pressed, deleting save data")
	
	# セーブデータを削除
	if SaveManager.delete_save():
		_log_debug("Save data deleted successfully")
		# UIを更新
		_setup_ui()
	else:
		_log_error("Failed to delete save data")
	
	# モーダルを非表示
	_hide_confirmation_modal()

func _on_no_button_pressed() -> void:
	"""いいえボタンが押された時の処理"""
	_log_debug("No button pressed, cancelling deletion")
	# モーダルを非表示
	_hide_confirmation_modal()

func _transition_to_game() -> void:
	"""ゲームシーンへの遷移"""
	_log_debug("Transitioning to MainScene...")
	
	# SceneTransitionを使用してスムーズに遷移
	await SceneTransition.change_scene("res://src/scenes/MainScene.tscn", 0.5, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	"""未処理の入力イベント処理"""
	# ESCキーでモーダルをキャンセル
	if event.is_action_pressed("ui_cancel") and confirmation_modal and confirmation_modal.visible:
		_hide_confirmation_modal()
		return
	
	# エンターキーでもゲーム開始
	if event.is_action_pressed("ui_accept") and not is_transitioning:
		if start_button and start_button.has_focus():
			_on_start_button_pressed()

## デバッグログ出力
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[TitleScene] %s" % message)

## エラーログ出力
func _log_error(message: String) -> void:
	print("[TitleScene] ERROR: %s" % message)