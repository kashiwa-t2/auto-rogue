extends Control
class_name TabSystem

## タブシステム管理クラス
## 画面下部のタブ切り替えUI管理

# タブ定義
enum TabType {
	UPGRADE,    # 育成（左端）
	WEAPON,     # 武器（左から2番目）
	INVENTORY,  # インベントリ
	QUEST,      # クエスト
	SETTINGS    # 設定（右端）
}

# タブボタン参照
@onready var tab_container: HBoxContainer = $TabContainer
@onready var upgrade_tab: Button = $TabContainer/UpgradeTab
@onready var weapon_tab: Button = $TabContainer/WeaponTab
@onready var inventory_tab: Button = $TabContainer/InventoryTab
@onready var quest_tab: Button = $TabContainer/QuestTab
@onready var settings_tab: Button = $TabContainer/SettingsTab

# コンテンツエリア参照
@onready var content_area: Control = $ContentArea
@onready var upgrade_content: Control = $ContentArea/UpgradeContent
@onready var weapon_content: Control = $ContentArea/WeaponContent
@onready var inventory_content: Control = $ContentArea/InventoryContent
@onready var quest_content: Control = $ContentArea/QuestContent
@onready var settings_content: Control = $ContentArea/SettingsContent

# 現在のアクティブタブ
var current_tab: TabType = TabType.UPGRADE

# タブ設定
var tab_size: Vector2 = Vector2(120, 80)  # パズドラ風円形タブ
var active_color: Color = Color.WHITE
var inactive_color: Color = Color(0.7, 0.7, 0.7, 1.0)
var glow_color: Color = Color(1.0, 0.8, 0.0, 0.8)  # ゴールドグロー

# シグナル
signal tab_changed(tab_type: TabType)

func _ready():
	_setup_tabs()
	_setup_tab_signals()
	_show_tab(TabType.UPGRADE)

## タブ初期設定
func _setup_tabs() -> void:
	# タブボタンのサイズと外観設定
	var tabs = [upgrade_tab, weapon_tab, inventory_tab, quest_tab, settings_tab]
	var tab_colors = [
		Color(0.8, 1.0, 0.8, 1.0),  # 育成 - 緑系
		Color(1.0, 0.8, 0.8, 1.0),  # 武器 - 赤系
		Color(1.0, 1.0, 0.8, 1.0),  # インベントリ - 黄系
		Color(0.8, 0.8, 1.0, 1.0),  # クエスト - 青系
		Color(1.0, 0.8, 1.0, 1.0)   # 設定 - 紫系
	]
	
	for i in range(tabs.size()):
		var tab = tabs[i]
		if tab:
			tab.custom_minimum_size = tab_size
			tab.flat = false
			# パズドラ風の丸いボタンスタイル
			_setup_tab_style(tab, tab_colors[i])
			# タブアイコン設定
			_setup_tab_icon(tab, TabType.values()[i])

## パズドラ風タブスタイル設定
func _setup_tab_style(tab: Button, base_color: Color) -> void:
	# StyleBoxFlatでパズドラ風の立体的なボタンを作成
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = base_color
	style_normal.corner_radius_top_left = 40
	style_normal.corner_radius_top_right = 40
	style_normal.corner_radius_bottom_left = 40
	style_normal.corner_radius_bottom_right = 40
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 3
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_color = Color(1, 1, 1, 0.8)
	style_normal.shadow_size = 3
	style_normal.shadow_color = Color(0, 0, 0, 0.3)
	style_normal.shadow_offset = Vector2(2, 2)
	
	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = base_color.darkened(0.2)
	style_pressed.corner_radius_top_left = 40
	style_pressed.corner_radius_top_right = 40
	style_pressed.corner_radius_bottom_left = 40
	style_pressed.corner_radius_bottom_right = 40
	style_pressed.border_width_top = 3
	style_pressed.border_width_bottom = 3
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_color = Color(1, 1, 1, 0.8)
	style_pressed.shadow_size = 1
	style_pressed.shadow_color = Color(0, 0, 0, 0.5)
	style_pressed.shadow_offset = Vector2(1, 1)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = base_color.lightened(0.1)
	style_hover.corner_radius_top_left = 40
	style_hover.corner_radius_top_right = 40
	style_hover.corner_radius_bottom_left = 40
	style_hover.corner_radius_bottom_right = 40
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 3
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_color = glow_color
	style_hover.shadow_size = 5
	style_hover.shadow_color = glow_color
	style_hover.shadow_offset = Vector2(0, 0)
	
	tab.add_theme_stylebox_override("normal", style_normal)
	tab.add_theme_stylebox_override("pressed", style_pressed)
	tab.add_theme_stylebox_override("hover", style_hover)
	tab.add_theme_stylebox_override("focus", style_hover)

## タブアイコン設定
func _setup_tab_icon(tab: Button, tab_type: TabType) -> void:
	# アイコンパスの設定
	var icon_path: String
	match tab_type:
		TabType.UPGRADE:
			icon_path = "res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0114.png"  # ポーション
		TabType.WEAPON:
			icon_path = "res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0103.png"  # 剣
		TabType.INVENTORY:
			icon_path = "res://assets/sprites/kenney_pixel-platformer/Tiles/tile_0151.png"  # コイン
		TabType.QUEST:
			icon_path = "res://assets/sprites/kenney_pixel-platformer/Tiles/tile_0152.png"  # コイン2
		TabType.SETTINGS:
			icon_path = "res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0130.png"  # 杖
	
	# アイコン読み込みと設定
	var texture = load(icon_path) as Texture2D
	if texture:
		tab.icon = texture
		# タブテキストは非表示（アイコンのみ）
		tab.text = ""

## タブシグナル接続
func _setup_tab_signals() -> void:
	if upgrade_tab:
		upgrade_tab.pressed.connect(_on_upgrade_tab_pressed)
	if weapon_tab:
		weapon_tab.pressed.connect(_on_weapon_tab_pressed)
	if inventory_tab:
		inventory_tab.pressed.connect(_on_inventory_tab_pressed)
	if quest_tab:
		quest_tab.pressed.connect(_on_quest_tab_pressed)
	if settings_tab:
		settings_tab.pressed.connect(_on_settings_tab_pressed)

## タブ表示切り替え
func _show_tab(tab_type: TabType) -> void:
	current_tab = tab_type
	
	# 全コンテンツを非表示
	_hide_all_content()
	
	# 全タブの色をリセット
	_reset_tab_colors()
	
	# 選択されたタブとコンテンツを表示
	var selected_tab: Button = null
	match tab_type:
		TabType.UPGRADE:
			if upgrade_content:
				upgrade_content.visible = true
			selected_tab = upgrade_tab
		TabType.WEAPON:
			if weapon_content:
				weapon_content.visible = true
			selected_tab = weapon_tab
		TabType.INVENTORY:
			if inventory_content:
				inventory_content.visible = true
			selected_tab = inventory_tab
		TabType.QUEST:
			if quest_content:
				quest_content.visible = true
			selected_tab = quest_tab
		TabType.SETTINGS:
			if settings_content:
				settings_content.visible = true
			selected_tab = settings_tab
	
	# パズドラ風タブ選択アニメーション
	if selected_tab:
		_play_tab_selection_animation(selected_tab)
	
	tab_changed.emit(tab_type)
	_log_debug("Tab switched to: %s" % TabType.keys()[tab_type])

## 全コンテンツ非表示
func _hide_all_content() -> void:
	var contents = [upgrade_content, weapon_content, inventory_content, quest_content, settings_content]
	for content in contents:
		if content:
			content.visible = false

## タブ色リセット
func _reset_tab_colors() -> void:
	var tabs = [upgrade_tab, weapon_tab, inventory_tab, quest_tab, settings_tab]
	for tab in tabs:
		if tab:
			tab.modulate = inactive_color

## パズドラ風タブ選択アニメーション
func _play_tab_selection_animation(tab: Button) -> void:
	"""選択されたタブのパズドラ風アニメーション"""
	if not tab:
		return
	
	# 弾む選択アニメーション
	var tween = create_tween()
	tween.set_parallel(true)
	
	# スケールアニメーション（弾む効果）
	var original_scale = tab.scale
	tween.tween_property(tab, "scale", original_scale * 1.3, 0.1)
	tween.tween_property(tab, "scale", original_scale * 0.9, 0.1).set_delay(0.1)
	tween.tween_property(tab, "scale", original_scale * 1.1, 0.1).set_delay(0.2)
	tween.tween_property(tab, "scale", original_scale, 0.1).set_delay(0.3)
	
	# 発光効果
	tween.tween_property(tab, "modulate", glow_color, 0.2)
	tween.tween_property(tab, "modulate", active_color, 0.3).set_delay(0.2)
	
	# 回転効果（軽い）
	var original_rotation = tab.rotation
	tween.tween_property(tab, "rotation", original_rotation + deg_to_rad(5), 0.1)
	tween.tween_property(tab, "rotation", original_rotation - deg_to_rad(5), 0.1).set_delay(0.1)
	tween.tween_property(tab, "rotation", original_rotation, 0.2).set_delay(0.2)

## タブボタンイベントハンドラー
func _on_upgrade_tab_pressed() -> void:
	_show_tab(TabType.UPGRADE)

func _on_weapon_tab_pressed() -> void:
	_show_tab(TabType.WEAPON)

func _on_inventory_tab_pressed() -> void:
	_show_tab(TabType.INVENTORY)

func _on_quest_tab_pressed() -> void:
	_show_tab(TabType.QUEST)

func _on_settings_tab_pressed() -> void:
	_show_tab(TabType.SETTINGS)

## 現在のタブ取得
func get_current_tab() -> TabType:
	return current_tab

## プログラムからのタブ切り替え
func switch_to_tab(tab_type: TabType) -> void:
	_show_tab(tab_type)

## デバッグログ
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[TabSystem] %s" % message)