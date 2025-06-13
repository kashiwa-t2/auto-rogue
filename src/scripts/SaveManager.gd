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
	
	# 最低限必要なフィールドのチェック
	if save_data == null or not save_data.has_all(["total_coins", "character_level", "weapon_level"]):
		print("[SaveManager] セーブデータが破損しています: ", file_path)
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