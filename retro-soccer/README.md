# Retro Soccer Proto (Godot 4)

FIFA International Soccer (1993) 風の最小サッカープロトタイプです。  
**3 vs 3**、疑似3D（Y座標スケール）、簡易AI、パス／シュートを含みます。

## 必要環境

- Godot **4.2** 以上

## 起動方法

1. Godot 4 で `retro-soccer/project.godot` を開く
2. **F5** で実行

## 操作

| キー | 動作 |
|------|------|
| WASD / 矢印 | 移動 |
| E | パス（最寄りの味方へ） |
| Space | シュート（ボール保持時） |
| Space 長押し | ダッシュ（ボールなし時） |

## プロジェクト構成

```
retro-soccer/
├── project.godot          # 640x360 低解像度、入力マップ
├── scenes/
│   ├── main.tscn          # フィールド描画、スポーン、UI
│   ├── player.tscn        # CharacterBody2D + 簡易スプライト
│   └── ball.tscn          # Area2D、摩擦付きボール
└── scripts/
    ├── game.gd            # Autoload: スコア、フィールド定数
    ├── main.gd            # マッチ生成
    ├── player.gd          # 操作・AI・奥行きスケール
    └── ball.gd            # キック、ゴール判定
```

## 設計メモ

### 疑似3D（1993年風）

- `Game.depth_scale(y)` で手前ほど大きく表示
- `z_index = y` で前後の重なりを制御

### AI（最小）

- 0.35秒ごとにターゲット再計算
- ルーズボール → 追いかける
- 味方が保持 → ホームポジション寄りにサポート
- 敵が保持 → ボールへ寄る
- 自分が保持 → 相手ゴール方向へ

### 次の拡張候補

1. `StateMachine` で AI を Chase / Support / Mark に分離
2. オフサイドラインと審判
3. セットプレー（キックオフ、ゴールキック）
4. アニメーション付きスプライト
5. CRT / ピクセルシェーダーでレトロ画面
