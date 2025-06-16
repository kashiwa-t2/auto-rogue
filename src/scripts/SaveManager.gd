extends Node

const SAVE_DIR = "user://saves/"
const AUTOSAVE_FILE = "autosave.dat"

func _ready():
	_ensure_save_directory()
	print("[SaveManager] 初期化完了")

func _ensure_save_directory():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("[SaveManager] セーブディレクトリを作成しました")

func save_game() -> bool:
	# PlayerStatsから全ステータスを取得（あかさんデータ含む）
	var save_data = PlayerStats.save_data()
	
	# タイムスタンプ情報を追加
	save_data["timestamp"] = Time.get_ticks_msec()
	save_data["date"] = Time.get_datetime_string_from_system()
	
	# セーブデータの詳細ログ
	print("[SaveManager] 💾 Saving game data:")
	print("  - Character Level: %d" % save_data.get("character_level", 0))
	print("  - Weapon Level: %d" % save_data.get("weapon_level", 0))
	print("  - Total Coins: %d" % save_data.get("total_coins", 0))
	print("  - Weapon System Levels: %s" % save_data.get("weapon_system_levels", {}))
	
	var file_path = _get_save_file_path()
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("[SaveManager] ❌ セーブファイルの作成に失敗しました: ", file_path)
		return false
	
	file.store_var(save_data)
	file.close()
	
	print("[SaveManager] ✅ セーブ完了: %s" % file_path)
	return true

func load_game() -> bool:
	var file_path = _get_save_file_path()
	
	if not FileAccess.file_exists(file_path):
		print("[SaveManager] セーブファイルが存在しません: ", file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("[SaveManager] セーブファイルの読み込みに失敗しました: ", file_path)
		return false
	
	var save_data = file.get_var()
	file.close()
	
	# ロードデータの詳細ログ
	print("[SaveManager] 📂 Loading game data:")
	print("  - Character Level: %d" % save_data.get("character_level", 0))
	print("  - Weapon Level: %d" % save_data.get("weapon_level", 0))
	print("  - Total Coins: %d" % save_data.get("total_coins", 0))
	print("  - Weapon System Levels: %s" % save_data.get("weapon_system_levels", {}))
	
	# 最低限必要なフィールドのチェック
	if save_data == null or not save_data.has_all(["total_coins", "character_level", "weapon_level"]):
		print("[SaveManager] ❌ セーブデータが破損しています: ", file_path)
		return false
	
	# PlayerStatsの統一ロードメソッドを使用（後方互換性あり）
	PlayerStats.load_data(save_data)
	PlayerStats._update_stats()
	
	print("[SaveManager] ロード完了 - コイン: ", PlayerStats.total_coins, 
		", キャラLv: ", PlayerStats.character_level, 
		", 武器Lv: ", PlayerStats.weapon_level,
		", 攻撃速度Lv: ", PlayerStats.attack_speed_level,
		", ポーション効果Lv: ", PlayerStats.potion_effect_level,
		", あかさん解放: ", PlayerStats.red_character_unlocked,
		", あかさんLv: ", PlayerStats.red_character_level,
		", あかさん武器Lv: ", PlayerStats.red_weapon_level)
	
	return true

func autosave():
	save_game()

func has_save() -> bool:
	return FileAccess.file_exists(_get_save_file_path())

func delete_save() -> bool:
	"""セーブデータを削除（成功時true）"""
	var file_path = _get_save_file_path()
	
	if not FileAccess.file_exists(file_path):
		print("[SaveManager] 削除するセーブファイルが存在しません")
		return false
	
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		print("[SaveManager] セーブディレクトリにアクセスできません")
		return false
	
	var error = dir.remove(file_path.get_file())
	if error == OK:
		print("[SaveManager] セーブデータを削除しました")
		return true
	else:
		print("[SaveManager] セーブデータの削除に失敗しました - エラー: ", error)
		return false

func _get_save_file_path() -> String:
	return SAVE_DIR + AUTOSAVE_FILE

## デバッグ用：セーブファイルの中身を詳細表示
func debug_save_file_contents() -> void:
	"""セーブファイルの内容を詳細に表示（デバッグ用）"""
	var file_path = _get_save_file_path()
	
	if not FileAccess.file_exists(file_path):
		print("[SaveManager] 🔍 DEBUG: Save file does not exist: %s" % file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("[SaveManager] 🔍 DEBUG: Failed to open save file: %s" % file_path)
		return
	
	var save_data = file.get_var()
	file.close()
	
	print("[SaveManager] 🔍 === DEBUG: SAVE FILE CONTENTS ===")
	print("  📁 File path: %s" % file_path)
	print("  📊 Keys in save data: %s" % save_data.keys())
	
	for key in save_data.keys():
		var value = save_data[key]
		if key == "weapon_system_levels":
			print("  🗡️ %s: %s" % [key, value])
			if value is Dictionary and value.size() > 0:
				print("    📋 Weapon level details:")
				for weapon_id in value:
					var level = value[weapon_id]
					var status = "⭐ UPGRADED" if level > 1 else "🔹 BASIC"
					print("      - %s: Level %d %s" % [weapon_id, level, status])
			else:
				print("    ⚠️ No weapon levels found in save file!")
		else:
			print("  📊 %s: %s" % [key, value])
	
	print("[SaveManager] 🔍 === END DEBUG ===")

## デバッグ用：PlayerStatsの武器レベル状態確認
func debug_playerstats_weapon_levels() -> void:
	"""PlayerStatsの武器レベル状態を確認（デバッグ用）"""
	print("[SaveManager] 🔍 === DEBUG: PLAYERSTATS WEAPON LEVELS ===")
	print("  📊 PlayerStats.weapon_system_levels: %s" % PlayerStats.weapon_system_levels)
	
	if PlayerStats.weapon_system_levels.size() == 0:
		print("  ⚠️ PlayerStats has NO weapon levels stored!")
	else:
		print("  📋 PlayerStats weapon level details:")
		for weapon_id in PlayerStats.weapon_system_levels:
			var level = PlayerStats.weapon_system_levels[weapon_id]
			var status = "⭐ UPGRADED" if level > 1 else "🔹 BASIC"
			print("    - %s: Level %d %s" % [weapon_id, level, status])
	
	print("[SaveManager] 🔍 === END DEBUG ===")