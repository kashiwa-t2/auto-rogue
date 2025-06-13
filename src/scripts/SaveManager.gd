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
	var save_data = {
		"coins": PlayerStats.total_coins,
		"character_level": PlayerStats.character_level,
		"weapon_level": PlayerStats.weapon_level,
		"attack_speed_level": PlayerStats.attack_speed_level,
		"potion_effect_level": PlayerStats.potion_effect_level,
		"timestamp": Time.get_ticks_msec(),
		"date": Time.get_datetime_string_from_system()
	}
	
	var file_path = _get_save_file_path()
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("[SaveManager] セーブファイルの作成に失敗しました: ", file_path)
		return false
	
	file.store_var(save_data)
	file.close()
	
	print("[SaveManager] オートセーブ完了")
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
	
	if save_data == null or not save_data.has_all(["coins", "character_level", "weapon_level"]):
		print("[SaveManager] セーブデータが破損しています: ", file_path)
		return false
	
	PlayerStats.total_coins = save_data.coins
	PlayerStats.character_level = save_data.character_level
	PlayerStats.weapon_level = save_data.weapon_level
	
	# 攻撃速度レベルとポーション効果レベルを読み込み（後方互換性のためデフォルト値設定）
	PlayerStats.attack_speed_level = save_data.get("attack_speed_level", 1)
	PlayerStats.potion_effect_level = save_data.get("potion_effect_level", 1)
	
	PlayerStats._update_stats()
	
	print("[SaveManager] ロード完了 - コイン: ", save_data.coins, 
		", キャラLv: ", save_data.character_level, 
		", 武器Lv: ", save_data.weapon_level,
		", 攻撃速度Lv: ", PlayerStats.attack_speed_level,
		", ポーション効果Lv: ", PlayerStats.potion_effect_level)
	
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