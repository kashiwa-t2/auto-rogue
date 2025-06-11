# auto-rogue

Godot 4.x で開発するスマホ縦画面向けの放置ゲーム

## 開発環境

- Godot 4.3以上
- 解像度: 720x1280 (スマホ縦画面)

## プロジェクト構成

```
auto-rogue/
├── src/
│   ├── scenes/          # シーンファイル(.tscn)
│   │   ├── MainScene.tscn
│   │   └── Player.tscn
│   └── scripts/         # スクリプトファイル(.gd)
│       ├── GameConstants.gd     # 定数管理 (autoload)
│       ├── MainScene.gd         # メインシーン制御
│       ├── Player.gd            # プレイヤー制御
│       ├── TestPlayer.gd        # テスト機能
│       ├── ScrollerBase.gd      # スクロール基底クラス
│       ├── BackgroundScroller.gd # 背景スクロール
│       ├── GroundScroller.gd    # 地面スクロール
│       └── ScrollManager.gd     # スクロール統合管理
├── assets/
│   └── sprites/kenney_pixel-platformer/
│       ├── Tiles/Backgrounds/   # 背景画像 (tile_0008~0011)
│       ├── Tiles/Characters/    # キャラ画像 (tile_0000~0001)  
│       └── Tiles/               # 地面画像 (tile_0022)
└── project.godot
```

## 動作確認

1. Godotエディタでプロジェクトを開く
2. F6キーで実行
3. **ゲーム画面構成**:
   - **上部1/3**: プレイエリア（背景・地面・プレイヤー）
   - **下部2/3**: UIエリア（テストボタン）
4. プレイヤーが地面上で歩行アニメーション
5. 背景・地面が右→左にスクロール

## 主要機能

### スクロールシステム
- **背景スクロール**: 4枚画像の無限ループ
- **地面スクロール**: 1枚タイルの連続表示
- **統一管理**: ScrollManagerによる一元制御
- **速度切り替え**: Toggle Scroll Speedボタン (50/100/200/停止)

### プレイヤーシステム  
- **歩行アニメーション**: 2フレーム切り替え (4fps)
- **3倍スケール**: 視認性の向上
- **地面接地**: 自動位置調整
- **API操作**: move_right/left, reset_to_center

### テスト機能
- **手動テスト**: UI ボタンでの動作確認
- **自動テスト**: F12キーで包括的テスト実行
  - プレイヤー機能テスト
  - スクロールシステムテスト  
  - 定数整合性テスト
  - 統合テスト

## アーキテクチャ

### 階層化設計
1. **ScrollerBase**: 共通スクロール処理の基底クラス
2. **具象スクローラー**: Background/Ground の特化実装
3. **ScrollManager**: 複数スクローラーの統一管理
4. **定数管理**: 論理的グループ分けによる整理

### 主要改善点
- **コード重複解消**: 基底クラスによる共通化
- **統一管理**: ScrollManagerによる制御統合
- **定数整理**: 論理的なグループ分けと命名
- **エラーハンドリング**: ロバストな処理実装
- **テスト拡張**: 包括的なテストカバレッジ

## 今後の拡張予定

- GUT (Godot Unit Test) の導入
- ゲームロジックの追加
- UIの改善