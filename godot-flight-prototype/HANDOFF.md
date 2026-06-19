# 引き継ぎメモ — レトロフライトシミュレーター（FS4風）

新エージェント / 開発者向けの引き継ぎドキュメントです。  
**最終更新**: 2026-06-19

---

## 1. プロジェクト概要

| 項目 | 内容 |
|---|---|
| 名称 | Retro Flight Sim（FS4 プロトタイプ） |
| 参考ゲーム | Microsoft Flight Simulator 4.0（1989） / subLOGIC 系ワイヤーフレーム |
| リポジトリ | [tarosiba/kakeibo](https://github.com/tarosiba/kakeibo) |
| **最新作業ブランチ** | `cursor/godot-flight-prototype-d61a` |
| プロジェクトパス | `godot-flight-prototype/` |
| 起動シーン | `scenes/main.tscn` |

個人向けに段階的に機能を追加する Godot 4 プロトタイプ。  
FS4 の「ワイヤーフレーム地形 + 下部計器パネル + 低解像度 VGA 感」を再現している。

```bash
git fetch origin
git checkout cursor/godot-flight-prototype-d61a
git pull origin cursor/godot-flight-prototype-d61a
```

---

## 2. 技術スタック

- **エンジン**: Godot 4.3+（GL Compatibility）
- **言語**: GDScript + GLSL（CRT シェーダー）
- **描画**: 2D 即時描画による疑似 3D ワイヤーフレーム
- **解像度**: 内部 320×200 → ウィンドウ 960×600 にスケールアップ
- **Autoload**: `FlightSession`（CRT トグル・レンダー解像度）

---

## 3. 起動方法

```bash
# Godot 4.x をインストール後
# godot-flight-prototype/project.godot を開いて F5
```

---

## 4. 実装済み機能

### コア飛行

- [x] 簡易 Cessna 風フライトモデル（ピッチ・ロール・ヨー・スロットル）
- [x] 失速・揚力・重力・ドラッグの簡易シミュレーション
- [x] 地上着陸・クラッシュ判定
- [x] R キーでリセット

### ビジュアル

- [x] ワイヤーフレーム地形グリッド（丘付き）
- [x] 滑走路ライン
- [x] 水平線・クロスヘア
- [x] 下部計器パネル（姿勢儀・IAS・高度・針路・スロットル）
- [x] 緑リンカー（フォスファー）カラーパレット

### CRT レトロシェーダー（2026-06-19 追加）

- [x] **低解像度 SubViewport**（320×200、nearest フィルタ）
- [x] **バレル歪み**（CRT 曲面）
- [x] **走査線**
- [x] **色収差**（エッジの RGB ずれ）
- [x] **ビネット**
- [x] **ノイズ / フリッカー**
- [x] **フォスファー色ティント**（緑系 CRT）
- [x] **Tab キーで CRT ON/OFF** 切替

---

## 5. 未実装 / 次の候補

- [ ] 空港・ナビゲーション aid（VOR / ILS 風）
- [ ] 複数機種・カスタムコックピット
- [ ] 天候（雲・風）
- [ ] サウンド（エンジン・無線ビープ）
- [ ] タイトル画面・機種選択
- [ ] セーブ / フライトログ
- [ ] CRT シェーダーの設定 UI（曲率・走査線強度スライダー）
- [ ] 実 3D メッシュ地形（現在は 2D 投影ワイヤーフレーム）

---

## 6. 操作一覧

| キー | 動作 |
|---|---|
| W / ↑ | ピッチアップ |
| S / ↓ | ピッチダウン |
| A / ← | 左ロール |
| D / → | 右ロール |
| Q / E | ヨー |
| + / - | スロットル |
| B | ブレーキ（地上） |
| R | フライトリセット |
| Tab | CRT シェーダー切替 |

---

## 7. ファイル構成

```
godot-flight-prototype/
├── HANDOFF.md
├── README.md
├── project.godot
├── shaders/
│   └── crt_retro.gdshader       # ★ CRT ポストプロセス
├── scenes/
│   ├── main.tscn                # SubViewport + CRT オーバーレイ
│   └── flight_game.tscn         # ゲーム本体
└── scripts/
    ├── main.gd                  # ルート（ビューポート管理）
    ├── crt_overlay.gd           # ★ CRT 適用
    ├── flight_game.gd           # 入力・更新ループ
    ├── flight_model.gd          # 飛行物理
    ├── wireframe_view.gd        # 3D ワイヤーフレーム描画
    ├── instrument_panel.gd      # 計器パネル
    └── autoload/
        └── flight_session.gd    # CRT 設定
```

★ = CRT 関連の中核ファイル

---

## 8. CRT パイプライン

```
Main (Control)
├── GameViewportContainer
│   └── SubViewport (320×200, nearest)
│       └── FlightGame
│           ├── WorldView (wireframe)
│           └── InstrumentPanel
└── CrtLayer (CanvasLayer)
    └── CrtOverlay (ColorRect + crt_retro.gdshader)
        └── samples SubViewport texture
```

シェーダーパラメータ（`crt_retro.gdshader`）:

| パラメータ | 既定値 | 説明 |
|---|---|---|
| curvature | 0.12 | 画面の曲面歪み |
| scanline_intensity | 0.28 | 走査線の濃さ |
| scanline_count | 360 | 走査線密度 |
| aberration | 1.8 | 色収差量 |
| vignette | 0.42 | 周辺減光 |
| phosphor_mix | 0.72 | 緑フォスファー色の強さ |

---

## 9. 既知の制約・注意点

- Godot 未インストール環境では実行確認不可（コードレビュー・構造確認のみ）
- 地形は手続き生成グリッドのみ（タイル 9×9）
- 計器は装飾的簡易版（実航空計器の精度はない）
- CRT OFF 時は SubViewport をそのまま表示（ポストプロセスなし）

---

## 10. 開発履歴

| 時期 | 内容 |
|---|---|
| 2026-06-19 前半 | フライトモデル・ワイヤーフレームビュー・計器パネル |
| 2026-06-19 | **CRT レトロシェーダー**・SubViewport パイプライン・Tab 切替 |

---

## 11. 新エージェントへの依頼テンプレート

```markdown
# 引き継ぎ

FS4 風レトロフライトシミュレーターの Godot 4 プロトタイプを継続開発してください。
詳細は `godot-flight-prototype/HANDOFF.md` を参照。

## リポジトリ
- パス: godot-flight-prototype/
- ブランチ: cursor/godot-flight-prototype-d61a

## 現状サマリ
- ワイヤーフレーム飛行ビュー + 計器パネル実装済み
- CRT シェーダー（走査線・歪み・色収差）実装済み

## 今回やってほしいこと
（ここに1つだけ具体的に書く）

## 制約
- 320×200 低解像度 + CRT の見た目を維持
- 変更は最小限の diff に留める
```

---

## 12. 連絡・参照

- Godot 公式: https://godotengine.org/download
- FS4 参考: Microsoft Flight Simulator 4.0 (1989)
