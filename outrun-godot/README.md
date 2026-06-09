# Sunset Drive（Godot 4版）

OutRun風の疑似3Dレトロレースゲームです。Godot 4 でプレイできます。  
のんびり走行向けの低速設定で、周囲の交通は車1台・バイク1台のみです。

## 必要環境

- [Godot Engine 4.2 以上](https://godotengine.org/download)（4.3 推奨）

## 起動方法

1. Godot エディタを起動
2. **インポート** → `outrun-godot/project.godot` を選択
3. **F5**（または再生ボタン）でゲーム開始

## 操作

| キー | 操作 |
|------|------|
| **↑ / W** | 加速 |
| **↓ / S** | 減速 |
| **← → / A D** | ハンドル |
| **Space** | ブレーキ |

## 特徴

- 疑似3D道路（セグメントレンダリング）
- ヤシの木・観客・海沿いの風景
- 赤いオープンカー（後方視点）
- レトロHUD（スピードメーター、タイム、ステージ表示など）
- 解像度 640×480 のレトロ表示（ウィンドウは自動拡大）

## プロジェクト構成

```
outrun-godot/
├── project.godot      # プロジェクト設定・入力マップ
├── scenes/game.tscn   # メインシーン
├── scripts/game.gd    # ゲームロジック・描画
└── icon.svg
```

## ブラウザ版

HTML/Canvas 版は `../outrun/index.html` にあります。
