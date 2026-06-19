# Retro Flight Sim (FS4 prototype)

Microsoft Flight Simulator 4 風のワイヤーフレーム飛行シミュレーター prototype for Godot 4.

## 起動

1. Godot 4.3+ で `godot-flight-prototype/project.godot` を開く
2. **F5** で実行

## 操作

| キー | 動作 |
|---|---|
| W / ↑ | ピッチアップ |
| S / ↓ | ピッチダウン |
| A / ← | 左ロール |
| D / → | 右ロール |
| Q / E | ヨー（方向舵） |
| + / - | スロットル |
| B | ブレーキ（地上） |
| R | リセット |
| Tab | CRT シェーダー ON/OFF |

## 画面構成

- 上部: ワイヤーフレーム 3D ビュー（滑走路・地形グリッド）
- 下部: 計器パネル（姿勢・速度・高度・針路・スロットル）
- 全体: 320×200 の低解像度レンダリング + CRT ポストプロセス

詳細は [HANDOFF.md](./HANDOFF.md) を参照。
