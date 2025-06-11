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
const PLAYER_MOVE_DISTANCE: float = 50.0
const PLAYER_SIZE: Vector2 = Vector2(64, 64)

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
# テスト・デバッグ設定
# =============================================================================
# テスト用定数
const TEST_MOVE_DISTANCE: float = 100.0
const TEST_ANIMATION_WAIT_TIME: float = 0.1
const TEST_ANIMATION_THRESHOLD: float = 0.1

# UI設定
const TEST_BUTTON_WIDTH: float = 180.0
const TEST_BUTTON_MARGIN: float = 20.0

# 入力設定
const TEST_KEY: Key = KEY_F12

# デバッグ設定
const DEBUG_LOG_ENABLED: bool = true

# =============================================================================
# ゲームプレイ設定（将来の拡張用）
# =============================================================================
# 戦闘設定（MVP後の実装用）
# const PLAYER_DEFAULT_HP: int = 100
# const PLAYER_DEFAULT_ATTACK: int = 10
# const ENEMY_SPAWN_INTERVAL: float = 3.0

# 経済設定（MVP後の実装用）
# const GOLD_DROP_BASE: int = 10
# const UPGRADE_COST_BASE: int = 100
