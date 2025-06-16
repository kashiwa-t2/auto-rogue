extends Control
class_name WeaponUI

## 武器UI管理クラス
## キャラクター別武器装備・強化画面

# キャラクター選択
@onready var character_tabs: TabContainer = $WeaponContainer/CharacterTabs
@onready var green_character_tab: Control = $WeaponContainer/CharacterTabs/GreenCharacterTab
@onready var red_character_tab: Control = $WeaponContainer/CharacterTabs/RedCharacterTab

# みどりくん武器UI
@onready var green_weapon_icon: TextureRect = $WeaponContainer/CharacterTabs/GreenCharacterTab/WeaponInfo/WeaponIcon
@onready var green_weapon_name: Label = $WeaponContainer/CharacterTabs/GreenCharacterTab/WeaponInfo/WeaponName
@onready var green_weapon_level: Label = $WeaponContainer/CharacterTabs/GreenCharacterTab/WeaponInfo/WeaponLevel
@onready var green_weapon_damage: Label = $WeaponContainer/CharacterTabs/GreenCharacterTab/WeaponInfo/WeaponDamage
@onready var green_upgrade_button: Button = $WeaponContainer/CharacterTabs/GreenCharacterTab/UpgradeContainer/UpgradeButton
@onready var green_upgrade_cost: Label = $WeaponContainer/CharacterTabs/GreenCharacterTab/UpgradeContainer/CostLabel

# あかさん武器UI
@onready var red_weapon_icon: TextureRect = $WeaponContainer/CharacterTabs/RedCharacterTab/WeaponInfo/WeaponIcon
@onready var red_weapon_name: Label = $WeaponContainer/CharacterTabs/RedCharacterTab/WeaponInfo/WeaponName
@onready var red_weapon_level: Label = $WeaponContainer/CharacterTabs/RedCharacterTab/WeaponInfo/WeaponLevel
@onready var red_weapon_damage: Label = $WeaponContainer/CharacterTabs/RedCharacterTab/WeaponInfo/WeaponDamage
@onready var red_upgrade_button: Button = $WeaponContainer/CharacterTabs/RedCharacterTab/UpgradeContainer/UpgradeButton
@onready var red_upgrade_cost: Label = $WeaponContainer/CharacterTabs/RedCharacterTab/UpgradeContainer/CostLabel

# 武器リスト
@onready var weapon_list: ItemList = $WeaponContainer/WeaponList

# 武器システム参照
var weapon_system: WeaponSystem

# シグナル
signal weapon_upgraded(character_name: String)

func _ready():
	add_to_group("weapon_ui")
	_setup_weapon_system()
	_setup_ui_signals()
	_update_display()
	
	# PlayerStatsとの同期（ロード済みの武器レベルを復元）
	# WeaponSystemの完全な初期化を待つためcall_deferred()を使用
	_log_debug("🔄 WeaponUI._ready() scheduling weapon level sync...")
	call_deferred("_sync_weapon_levels_after_initialization")

## 武器システム初期化
func _setup_weapon_system() -> void:
	weapon_system = WeaponSystem.new()
	add_child(weapon_system)
	
	# 武器システムシグナル接続
	weapon_system.weapon_equipped.connect(_on_weapon_equipped)
	weapon_system.weapon_upgraded.connect(_on_weapon_upgraded)

## UIシグナル設定
func _setup_ui_signals() -> void:
	if green_upgrade_button:
		green_upgrade_button.pressed.connect(_on_green_upgrade_pressed)
	if red_upgrade_button:
		red_upgrade_button.pressed.connect(_on_red_upgrade_pressed)
	if weapon_list:
		weapon_list.item_selected.connect(_on_weapon_selected)
	if character_tabs:
		character_tabs.tab_changed.connect(_on_character_tab_changed)

## 表示更新
func _update_display() -> void:
	_update_character_weapon_display("green")
	_update_character_weapon_display("red")
	_update_weapon_list()

## キャラクター武器表示更新
func _update_character_weapon_display(character_name: String) -> void:
	var weapon = weapon_system.get_character_weapon(character_name)
	if not weapon:
		return
	
	match character_name:
		"green":
			_update_weapon_ui_elements(
				green_weapon_icon, green_weapon_name, green_weapon_level,
				green_weapon_damage, green_upgrade_cost, green_upgrade_button,
				weapon
			)
		"red":
			if PlayerStats.red_character_unlocked:
				_update_weapon_ui_elements(
					red_weapon_icon, red_weapon_name, red_weapon_level,
					red_weapon_damage, red_upgrade_cost, red_upgrade_button,
					weapon
				)

## 武器UI要素更新
func _update_weapon_ui_elements(icon: TextureRect, name_label: Label, level_label: Label, 
								damage_label: Label, cost_label: Label, upgrade_button: Button,
								weapon: WeaponSystem.WeaponData) -> void:
	if not weapon:
		return
	
	# アイコン設定
	if icon:
		var texture = load(weapon.icon_path) as Texture2D
		if texture:
			icon.texture = texture
		# レアリティ色適用
		icon.modulate = weapon_system.get_rarity_color(weapon.rarity)
	
	# 名前とレベル
	if name_label:
		name_label.text = weapon.name
	if level_label:
		level_label.text = "Lv.%d" % weapon.level
	
	# ダメージ
	if damage_label:
		damage_label.text = "攻撃力: %d" % weapon.get_damage_at_level()
	
	# アップグレードコストとボタン
	var cost = weapon.get_upgrade_cost()
	if cost_label:
		cost_label.text = "%d コイン" % cost
	if upgrade_button:
		upgrade_button.disabled = PlayerStats.total_coins < cost

## 武器リスト更新
func _update_weapon_list() -> void:
	if not weapon_list:
		return
	
	weapon_list.clear()
	
	# 現在選択されているタブを取得
	var current_tab = character_tabs.current_tab
	
	# タブに応じて表示する武器を変更
	match current_tab:
		0:  # みどりくんタブ
			_log_debug("🗡️ Updating weapon list for Green Character tab")
			var green_weapons = weapon_system.get_available_weapons("green")
			_log_debug("📋 Found %d green weapons available" % green_weapons.size())
			
			for weapon in green_weapons:
				var display_text = "%s (剣) Lv.%d" % [weapon.name, weapon.level]
				weapon_list.add_item(display_text)
				var item_index = weapon_list.get_item_count() - 1
				weapon_list.set_item_metadata(item_index, {"character": "green", "weapon_id": weapon.id})
				
				_log_debug("📝 Added green weapon: %s (%s) Level %d" % [weapon.id, weapon.name, weapon.level])
				
				# 装備中の武器をハイライト
				var current_weapon = weapon_system.get_character_weapon("green")
				if current_weapon and current_weapon.id == weapon.id:
					weapon_list.set_item_custom_fg_color(item_index, Color.YELLOW)
					_log_debug("⭐ Highlighted equipped weapon: %s" % weapon.name)
		
		1:  # あかさんタブ
			if PlayerStats.red_character_unlocked:
				_log_debug("🔴 Updating weapon list for Red Character tab")
				var red_weapons = weapon_system.get_available_weapons("red")
				_log_debug("📋 Found %d red weapons available" % red_weapons.size())
				
				for weapon in red_weapons:
					var display_text = "%s (杖) Lv.%d" % [weapon.name, weapon.level]
					weapon_list.add_item(display_text)
					var item_index = weapon_list.get_item_count() - 1
					weapon_list.set_item_metadata(item_index, {"character": "red", "weapon_id": weapon.id})
					
					_log_debug("📝 Added red weapon: %s (%s) Level %d" % [weapon.id, weapon.name, weapon.level])
					
					# 装備中の武器をハイライト
					var current_weapon = weapon_system.get_character_weapon("red")
					if current_weapon and current_weapon.id == weapon.id:
						weapon_list.set_item_custom_fg_color(item_index, Color.YELLOW)
						_log_debug("⭐ Highlighted equipped weapon: %s" % weapon.name)
			else:
				# 未解放の場合はメッセージを表示
				_log_debug("🔒 Red character not unlocked, showing lock message")
				weapon_list.add_item("あかさんは未解放です")
				weapon_list.set_item_disabled(0, true)

## イベントハンドラー
func _on_green_upgrade_pressed() -> void:
	if weapon_system.upgrade_weapon("green"):
		weapon_upgraded.emit("green")
		_update_display()
		_refresh_character_weapon_data("green")
		_log_debug("Green character weapon upgraded")

func _on_red_upgrade_pressed() -> void:
	if weapon_system.upgrade_weapon("red"):
		weapon_upgraded.emit("red")
		_update_display()
		_refresh_character_weapon_data("red")
		_log_debug("Red character weapon upgraded")

func _on_weapon_selected(index: int) -> void:
	_log_debug("🔄 Weapon selection changed - index: %d" % index)
	var metadata = weapon_list.get_item_metadata(index)
	if metadata:
		var character_name = metadata.character
		var weapon_id = metadata.weapon_id
		_log_debug("🎯 Selected weapon: %s for %s character" % [weapon_id, character_name])
		
		# 装備前の状態を記録
		var old_weapon = weapon_system.get_character_weapon(character_name)
		if old_weapon:
			_log_debug("🔄 Previous weapon: %s (%s) Level %d" % [old_weapon.id, old_weapon.name, old_weapon.level])
		
		if weapon_system.equip_weapon(character_name, weapon_id):
			_log_debug("✅ Weapon equip successful!")
			
			# 装備後の状態を確認
			var new_weapon = weapon_system.get_character_weapon(character_name)
			if new_weapon:
				_log_debug("🗡️ New weapon equipped: %s (%s) Level %d" % [new_weapon.id, new_weapon.name, new_weapon.level])
			
			_update_display()
			_refresh_character_weapon_data(character_name)
			_log_debug("✅ Weapon equipped: %s to %s" % [weapon_id, character_name])
		else:
			_log_debug("❌ Weapon equip failed: %s to %s" % [weapon_id, character_name])
	else:
		_log_debug("❌ No metadata found for weapon selection")

func _on_weapon_equipped(character_name: String, weapon: WeaponSystem.WeaponData) -> void:
	_log_debug("Weapon equipped: %s to %s" % [weapon.name, character_name])
	_update_display()
	_refresh_character_weapon_data(character_name)

func _on_weapon_upgraded(character_name: String, weapon: WeaponSystem.WeaponData) -> void:
	_log_debug("Weapon upgraded: %s Level %d" % [weapon.name, weapon.level])
	_refresh_character_weapon_data(character_name)

func _on_character_tab_changed(tab_index: int) -> void:
	"""キャラクタータブが変更された時の処理"""
	_log_debug("Character tab changed to index: %d" % tab_index)
	_update_weapon_list()  # タブ変更時に武器リストを更新

## 外部更新要求
func refresh_display() -> void:
	_update_display()

## キャラクターの武器データを更新
func _refresh_character_weapon_data(character_name: String) -> void:
	"""キャラクターの武器データを更新"""
	_log_debug("=== Starting character weapon data refresh for: %s ===" % character_name)
	
	# MainSceneからキャラクターを取得して武器データを更新
	var main_scene = get_tree().current_scene
	if not main_scene:
		_log_error("Cannot refresh weapon data - main scene not found")
		return
	
	_log_debug("Main scene found: %s" % main_scene)
	
	match character_name:
		"green":
			_log_debug("Refreshing green character weapon data...")
			var player = main_scene.get_node_or_null("PlayArea/Player")
			_log_debug("Player node search result: %s" % player)
			
			if player and player.has_method("refresh_weapon_data"):
				_log_debug("Player node found with refresh_weapon_data method, calling it...")
				player.refresh_weapon_data()
				
				# フォールバック: 直接武器スプライトも更新
				if player.has_method("force_update_weapon_sprite") and weapon_system:
					var current_weapon_path = weapon_system.get_weapon_sprite_path("green")
					if current_weapon_path != "":
						_log_debug("Also applying force update as backup...")
						player.force_update_weapon_sprite(current_weapon_path)
				
				_log_debug("✓ Green character weapon data refreshed successfully via WeaponUI")
			else:
				if not player:
					_log_error("Player node not found at path: PlayArea/Player")
				else:
					_log_error("Player node exists but refresh_weapon_data method missing")
		"red":
			_log_debug("Refreshing red character weapon data...")
			# RedCharacterは動的に追加されるためPlayAreaで探す
			var play_area = main_scene.get_node_or_null("PlayArea")
			if play_area:
				_log_debug("PlayArea found: %s" % play_area)
				var red_characters = play_area.get_children().filter(func(node): return node.name.begins_with("RedCharacter") or (node.get_script() != null and "RedCharacter" in str(node.get_script())))
				_log_debug("Found %d RedCharacter candidates: %s" % [red_characters.size(), red_characters])
				
				for red_char in red_characters:
					_log_debug("Checking RedCharacter: %s" % red_char)
					if red_char.has_method("refresh_weapon_data"):
						_log_debug("RedCharacter has refresh_weapon_data method, calling it...")
						red_char.refresh_weapon_data()
						_log_debug("✓ Red character weapon data refreshed successfully via WeaponUI")
						break
					else:
						_log_debug("RedCharacter exists but refresh_weapon_data method missing")
			else:
				_log_error("PlayArea not found at path: PlayArea")
	
	_log_debug("=== Character weapon data refresh completed for: %s ===" % character_name)

## WeaponSystemの完全初期化後に武器レベルを同期
func _sync_weapon_levels_after_initialization() -> void:
	"""WeaponSystemの完全な初期化後に武器レベルを同期"""
	_log_debug("🔄 _sync_weapon_levels_after_initialization() called")
	_log_debug("🗃️ WeaponSystem state: %s" % weapon_system)
	
	if weapon_system and weapon_system.weapon_database:
		_log_debug("✅ WeaponSystem is ready, proceeding with sync...")
		PlayerStats.sync_weapon_levels_to_weapon_system()
		_log_debug("✅ Weapon levels synchronized with PlayerStats after initialization")
		
		# 同期後の表示を更新
		_update_display()
	else:
		_log_debug("❌ WeaponSystem not ready, retrying...")
		# WeaponSystemがまだ準備できていない場合は再試行
		call_deferred("_sync_weapon_levels_after_initialization")

## WeaponSystem取得
func get_weapon_system() -> WeaponSystem:
	return weapon_system

## デバッグログ
func _log_debug(message: String) -> void:
	if GameConstants.DEBUG_LOG_ENABLED:
		print("[WeaponUI] %s" % message)

## エラーログ
func _log_error(message: String) -> void:
	print("[WeaponUI] ERROR: %s" % message)