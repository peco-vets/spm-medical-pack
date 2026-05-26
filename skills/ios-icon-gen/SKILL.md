---
name: ios-icon-gen
description: SF Symbols（Apple ネイティブ 5000+）または Iconify API（200+ コレクションから 275k+ オープンソースアイコン）から Xcode asset catalog 向けに iOS アプリアイコンを PNG imageset として生成（ios icon generation, SF Symbols, Iconify, Xcode asset catalog）。iOS プロジェクトでアイコン生成、アイコンアセット作成、asset catalog にアイコン追加、またはアイコン検索のときに用いる。
origin: community
---

# iOS アイコンジェネレータ

2 つのソースから Xcode asset catalog 向け PNG アイコン imageset を生成する。

## 起動タイミング

- iOS/macOS Xcode プロジェクト向けアイコンアセット生成
- オープンソースコレクション横断でのアイコン検索
- asset catalog 用 PNG imageset（1x、2x、3x）作成
- プレースホルダアイコンを本番品質アセットに置換
- 既存 Xcode プロジェクトのアイコンスタイルへのマッチング

## 中核原則

### 1. 2 つのソース、1 つの出力形式

両ソースとも同一の Xcode 互換 imageset を生成する。ニーズに基づいて選ぶ:

| ソース | アイコン数 | 必要 | 適用 |
|--------|-------|----------|----------|
| **Iconify API** | 200+ コレクションから 275,000+ | インターネット | 広範な選択、特定スタイル、オープンソースアイコン |
| **SF Symbols** | 5,000+ Apple シンボル | macOS のみ | Apple ネイティブスタイル、オフライン利用 |

### 2. 常に既存スタイルにマッチさせる

生成前に、サイズ・色・ウェイトの一貫性についてプロジェクトの既存アイコンを確認する。

### 3. 出力構造

両手法とも完全な Xcode imageset を生成する:

```
<output-dir>/<asset-name>.imageset/
  Contents.json
  <asset-name>.png        # 1x (68px default)
  <asset-name>@2x.png     # 2x (136px default)
  <asset-name>@3x.png     # 3x (204px default)
```

## 例

### Step 1: 要件評価

アイコンニーズを判断する: アイコンが表すもの、好みのスタイル、対象色、サイズ。

プロジェクトに既存アイコンがある場合、既存スタイルを確認する:
```bash
# Check dimensions of existing icon
sips -g pixelWidth -g pixelHeight path/to/existing@2x.png
```

### Step 2: アイコン検索

**Iconify API（広範な選択に推奨）:**
```bash
# Search all collections
$SKILL_DIR/scripts/iconify_gen.sh search "receipt"

# Search within a specific collection
$SKILL_DIR/scripts/iconify_gen.sh search "business card" --prefix mdi

# List available collections
$SKILL_DIR/scripts/iconify_gen.sh collections
```

**SF Symbols（Apple ネイティブスタイル向け）:**
SF Symbols アプリを参照するか、一般的な名前を参照する:

| 用途 | シンボル名 |
|----------|-------------|
| Document | `doc.text`, `doc.fill` |
| Receipt | `doc.text.below.ecg`, `receipt` |
| Person | `person.crop.rectangle`, `person.text.rectangle` |
| Camera | `camera`, `camera.fill` |
| Scan | `doc.viewfinder`, `qrcode.viewfinder` |
| Settings | `gearshape`, `slider.horizontal.3` |

### Step 3: プレビュー（オプション）

```bash
# Iconify preview
$SKILL_DIR/scripts/iconify_gen.sh preview mdi:receipt-text-outline
```

### Step 4: 生成

**Iconify API:**
```bash
# Basic generation
$SKILL_DIR/scripts/iconify_gen.sh mdi:receipt-text-outline editTool_expenseReport

# Custom color and output location
$SKILL_DIR/scripts/iconify_gen.sh mdi:receipt-text-outline myIcon --color 007AFF --output ./Assets.xcassets/icons
```

オプション: `--size <pt>`（デフォルト: 68）、`--color <hex>`（デフォルト: 8E8E93）、`--output <dir>`（デフォルト: /tmp/icons）

**SF Symbols:**
```bash
# Basic generation
swift $SKILL_DIR/scripts/generate_icons.swift doc.text.below.ecg editTool_expenseReport

# Custom color, weight, and output
swift $SKILL_DIR/scripts/generate_icons.swift person.crop.rectangle myIcon --color 007AFF --weight regular --output ./Assets.xcassets/icons
```

オプション: `--size <pt>`（デフォルト: 68）、`--color <hex>`（デフォルト: 8E8E93）、`--weight <name>`（デフォルト: thin）、`--output <dir>`（デフォルト: /tmp/icons）

### Step 5: 検証と統合

1. 生成された @2x PNG を読み、視覚的に検証する
2. asset catalog へコピー（直接出力していない場合）:
   ```bash
   cp -r /tmp/icons/<name>.imageset path/to/Assets.xcassets/<group>/
   ```
3. プロジェクトをビルドし、Xcode が新アセットを認識することを検証する

## 人気 Iconify コレクション

| プレフィックス | 名称 | 件数 | スタイル |
|--------|------|-------|-------|
| `mdi` | Material Design Icons | 7400+ | Filled + outline variants |
| `ph` | Phosphor | 9000+ | アイコンあたり 6 ウェイト |
| `solar` | Solar | 7400+ | Bold, linear, outline |
| `tabler` | Tabler Icons | 6000+ | 一貫したストローク幅 |
| `lucide` | Lucide | 1700+ | クリーン、ミニマル |
| `ri` | Remix Icon | 3100+ | Filled + line variants |
| `carbon` | Carbon | 2400+ | IBM デザイン言語 |
| `heroicons` | HeroIcons | 1200+ | Tailwind CSS コンパニオン |

すべて閲覧: <https://icon-sets.iconify.design/>

## スクリプトリファレンス

| スクリプト | ソース | パス |
|--------|--------|------|
| `iconify_gen.sh` | Iconify API（275k+ アイコン） | `$SKILL_DIR/scripts/iconify_gen.sh` |
| `generate_icons.swift` | SF Symbols（5k+ アイコン） | `$SKILL_DIR/scripts/generate_icons.swift` |

## ベストプラクティス

- **生成前に検索** — 最適マッチを見つけるため利用可能アイコンをブラウズする
- **既存プロジェクトスタイルにマッチ** — 新規生成前に既存アイコンの寸法・色・ウェイトを確認する
- **多様性には Iconify** — 200+ コレクションが必要な厳密スタイルを見つけられる
- **Apple 一貫性には SF Symbols** — システム UI と完全に合致する
- **asset catalog へ直接生成** — `--output ./Assets.xcassets/icons` で手動コピーをスキップ
- **視覚的検証** — コミット前に @2x PNG を必ずプレビューする

## アンチパターン

- 既存プロジェクトアイコンスタイルを確認せずにアイコン生成
- プロジェクトに定義された色パレットがあるのにデフォルト色を使う
- 誤ったサイズでの生成（先に既存アイコンを確認する）
- 視覚検証なしの生成アイコンコミット
