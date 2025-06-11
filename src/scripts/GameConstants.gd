extends Node

## ゲーム全体で使用する定数定義
## 論理的なグループに分けて管理

# =============================================================================
# 画面・レイアウト設定
# =============================================================================
const SCREEN_WIDTH: int = 720
const SCREEN_HEIGHT: int = 1280
const SCREEN_CENTER: Vector2 = Vector2(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)

# プレイエリア設定（画面上部1/3）
const PLAY_AREA_HEIGHT: float = SCREEN_HEIGHT / 3.0
const PLAY_AREA_RECT: Rect2 = Rect2(0, 0, SCREEN_WIDTH, PLAY_AREA_HEIGHT)

# UIエリア設定（画面下部2/3）
const UI_AREA_HEIGHT: float = SCREEN_HEIGHT * 2.0 / 3.0
const UI_AREA_RECT: Rect2 = Rect2(0, PLAY_AREA_HEIGHT, SCREEN_WIDTH, UI_AREA_HEIGHT)

# =============================================================================
# プレイヤー設定
# =============================================================================
# 基本設定
const PLAYER_SPRITE_SCALE: float = 3.0

# アニメーション設定
const PLAYER_WALK_SPRITES: Array[String] = [
	"res://assets/sprites/kenney_pixel-platformer/Tiles/Characters/tile_0000.png",
	"res://assets/sprites/kenney_pixel-platformer/Tiles/Characters/tile_0001.png"
]
const PLAYER_ANIMATION_SPEED: float = 4.0  # フレーム/秒
const PLAYER_SPRITE_FLIP_H: bool = true  # 左右反転

# アイドルアニメーション設定（現在は未使用）
const PLAYER_IDLE_BOB_SPEED: float = 2.0
const PLAYER_IDLE_BOB_HEIGHT: float = 10.0

# 武器設定
const PLAYER_WEAPON_SPRITE: String = "res://assets/sprites/kenney_tiny-dungeon/Tiles/tile_0103.png"
const PLAYER_WEAPON_SCALE: float = 2.0
const PLAYER_WEAPON_OFFSET: Vector2 = Vector2(20, 32)  # プレイヤーの腰の位置（最適な位置に調整）
const PLAYER_WEAPON_INITIAL_ROTATION: float = 30.0  # 武器の初期回転角度（時計回り30度）

# 攻撃設定
const PLAYER_ATTACK_DURATION: float = 0.5  # 攻撃アニメーション時間（秒）
const PLAYER_ATTACK_ROTATION_ANGLE: float = 70.0  # 剣を振る角度（度）- 適度な振り幅

# =============================================================================
# 地面・スクロール設定
# =============================================================================
# 地面設定
const GROUND_TILE_PATH: String = "res://assets/sprites/kenney_pixel-platformer/Tiles/tile_0022.png"
const GROUND_HEIGHT_RATIO: float = 0.2  # プレイエリア高さの20%
const GROUND_HEIGHT: float = PLAY_AREA_HEIGHT * GROUND_HEIGHT_RATIO
const GROUND_Y_POSITION: float = PLAY_AREA_HEIGHT - GROUND_HEIGHT / 2.0

# プレイヤー位置（地面に基づいて計算）
const PLAYER_GROUND_OFFSET: float = 21.0  # 地面上面からのオフセット
const PLAYER_DEFAULT_POSITION: Vector2 = Vector2(150, GROUND_Y_POSITION - GROUND_HEIGHT / 2.0 - PLAYER_GROUND_OFFSET)

# スクロール設定
const DEFAULT_SCROLL_SPEED: float = 100.0  # ピクセル/秒
const BACKGROUND_SCROLL_SPEED: float = DEFAULT_SCROLL_SPEED

# 背景画像パス
const BACKGROUND_TILE_PATHS: Array[String] = [
	"res://assets/sprites/kenney_pixel-platformer/Tiles/Backgrounds/tile_0008.png",
	"res://assets/sprites/kenney_pixel-platformer/Tiles/Backgrounds/tile_0009.png",
	"res://assets/sprites/kenney_pixel-platformer/Tiles/Backgrounds/tile_0010.png",
	"res://assets/sprites/kenney_pixel-platformer/Tiles/Backgrounds/tile_0011.png"
]

# =============================================================================
# 移動距離・進行設定
# =============================================================================
# 移動速度設定
const PLAYER_TRAVEL_SPEED: float = 2.0  # メートル/秒

# =============================================================================
# エネミー設定
# =============================================================================
# 基本設定
const ENEMY_SPRITE_SCALE: float = 3.0
const ENEMY_WALK_SPEED: float = 100.0  # ピクセル/秒

# アニメーション設定
const ENEMY_WALK_SPRITES: Array[String] = [
	"res://assets/sprites/kenney_pixel-platformer/Tiles/Characters/tile_0018.png",
	"res://assets/sprites/kenney_pixel-platformer/Tiles/Characters/tile_0019.png"
]
const ENEMY_ANIMATION_SPEED: float = 4.0  # フレーム/秒
const ENEMY_SPRITE_FLIP_H: bool = false  # 左右反転（左向きに歩く）

# 出現設定
const ENEMY_SPAWN_DISTANCE: float = 1.0  # 1m地点で出現
const ENEMY_SPAWN_X: float = SCREEN_WIDTH + 50.0  # 画面右端外側
const ENEMY_TARGET_X: float = -100.0  # 画面左端外側まで歩く

# 戦闘設定
const ENEMY_ENCOUNTER_DISTANCE: float = 70.0  # 接近判定距離（ピクセル）- 少し離れた位置で戦闘開始

# =============================================================================
# テスト・デバッグ設定
# =============================================================================
# テスト用定数
const TEST_MOVE_DISTANCE: float = 100.0
const TEST_ANIMATION_WAIT_TIME: float = 0.1
const TEST_ANIMATION_THRESHOLD: float = 0.1

# 入力設定
const TEST_KEY: Key = KEY_F12

# デバッグ設定
const DEBUG_LOG_ENABLED: bool = true

# =============================================================================
# HP・戦闘システム設定
# =============================================================================
# プレイヤーHP設定
const PLAYER_DEFAULT_HP: int = 100
const PLAYER_MAX_HP: int = 100

# 敵HP設定
const ENEMY_BASIC_HP: int = 50
const ENEMY_FAST_HP: int = 30
const ENEMY_STRONG_HP: int = 80
const ENEMY_BOSS_HP: int = 200

# HPバー表示設定
const HP_BAR_WIDTH: float = 40.0
const HP_BAR_HEIGHT: float = 6.0
const HP_BAR_OFFSET: Vector2 = Vector2(-20, -35)  # キャラクター上部のオフセット（中央に配置）
const HP_BAR_BACKGROUND_COLOR: Color = Color(0.3, 0.3, 0.3, 0.8)  # 濃いグレー
const HP_BAR_HEALTH_COLOR: Color = Color(0.2, 0.8, 0.2, 1.0)  # 緑
const HP_BAR_DAMAGE_COLOR: Color = Color(0.8, 0.2, 0.2, 1.0)  # 赤

# =============================================================================
# ゲームプレイ設定（将来の拡張用）
# =============================================================================
# 経済設定（MVP後の実装用）
# const GOLD_DROP_BASE: int = 10
# const UPGRADE_COST_BASE: int = 100
