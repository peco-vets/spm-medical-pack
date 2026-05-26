---
name: liquid-glass-design
description: iOS 26 Liquid Glass デザインシステム — ブラー、反射、SwiftUI/UIKit/WidgetKit 用のインタラクティブモーフィングを備えた動的グラスマテリアル (iOS 26 Liquid Glass design system — dynamic glass material with blur, reflection, interactive morphing for SwiftUI, UIKit, WidgetKit)。
---

# Liquid Glass デザインシステム (iOS 26)

Apple の Liquid Glass を実装するためのパターン。背後のコンテンツをぼかし、周辺コンテンツから色と光を反射し、タッチとポインタインタラクションに反応する動的マテリアルである。SwiftUI、UIKit、WidgetKit 統合をカバーする。

## 起動するタイミング

- 新しいデザイン言語で iOS 26+ 向けアプリを構築・更新する場合
- グラススタイルのボタン、カード、ツールバー、コンテナを実装する場合
- グラス要素間のモーフィングトランジションを作成する場合
- ウィジェットに Liquid Glass エフェクトを適用する場合
- 既存のブラー/マテリアルエフェクトを新しい Liquid Glass API へ移行する場合

## コアパターン — SwiftUI

### 基本のグラスエフェクト

任意のビューに Liquid Glass を追加する最もシンプルな方法:

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect()  // Default: regular variant, capsule shape
```

### シェイプとティントのカスタマイズ

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(.regular.tint(.orange).interactive(), in: .rect(cornerRadius: 16.0))
```

主なカスタマイズオプション:
- `.regular` — 標準グラスエフェクト
- `.tint(Color)` — 顕著性のためのカラーティント
- `.interactive()` — タッチとポインタインタラクションに反応
- シェイプ: `.capsule` (デフォルト)、`.rect(cornerRadius:)`、`.circle`

### グラスボタンスタイル

```swift
Button("Click Me") { /* action */ }
    .buttonStyle(.glass)

Button("Important") { /* action */ }
    .buttonStyle(.glassProminent)
```

### 複数要素のための GlassEffectContainer

パフォーマンスとモーフィングのために、複数のグラスビューは必ずコンテナでラップする:

```swift
GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "scribble.variable")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()

        Image(systemName: "eraser.fill")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()
    }
}
```

`spacing` パラメータはマージ距離を制御する — より近い要素はそのグラスシェイプをブレンドする。

### グラスエフェクトの結合

`glassEffectUnion` で複数ビューを単一グラスシェイプに結合する:

```swift
@Namespace private var namespace

GlassEffectContainer(spacing: 20.0) {
    HStack(spacing: 20.0) {
        ForEach(symbolSet.indices, id: \.self) { item in
            Image(systemName: symbolSet[item])
                .frame(width: 80.0, height: 80.0)
                .glassEffect()
                .glassEffectUnion(id: item < 2 ? "group1" : "group2", namespace: namespace)
        }
    }
}
```

### モーフィングトランジション

グラス要素の出現/消失時のスムーズなモーフィングを作成する:

```swift
@State private var isExpanded = false
@Namespace private var namespace

GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "scribble.variable")
            .frame(width: 80.0, height: 80.0)
            .glassEffect()
            .glassEffectID("pencil", in: namespace)

        if isExpanded {
            Image(systemName: "eraser.fill")
                .frame(width: 80.0, height: 80.0)
                .glassEffect()
                .glassEffectID("eraser", in: namespace)
        }
    }
}

Button("Toggle") {
    withAnimation { isExpanded.toggle() }
}
.buttonStyle(.glass)
```

### サイドバー下への水平スクロール拡張

水平スクロールコンテンツがサイドバーやインスペクタの下に拡張できるようにするには、`ScrollView` コンテンツがコンテナのリーディング/トレーリングエッジに達することを確認する。レイアウトがエッジまで拡張されると、システムが自動的にサイドバー下スクロール挙動を処理する — 追加のモディファイアは不要である。

## コアパターン — UIKit

### 基本 UIGlassEffect

```swift
let glassEffect = UIGlassEffect()
glassEffect.tintColor = UIColor.systemBlue.withAlphaComponent(0.3)
glassEffect.isInteractive = true

let visualEffectView = UIVisualEffectView(effect: glassEffect)
visualEffectView.translatesAutoresizingMaskIntoConstraints = false
visualEffectView.layer.cornerRadius = 20
visualEffectView.clipsToBounds = true

view.addSubview(visualEffectView)
NSLayoutConstraint.activate([
    visualEffectView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    visualEffectView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    visualEffectView.widthAnchor.constraint(equalToConstant: 200),
    visualEffectView.heightAnchor.constraint(equalToConstant: 120)
])

// Add content to contentView
let label = UILabel()
label.text = "Liquid Glass"
label.translatesAutoresizingMaskIntoConstraints = false
visualEffectView.contentView.addSubview(label)
NSLayoutConstraint.activate([
    label.centerXAnchor.constraint(equalTo: visualEffectView.contentView.centerXAnchor),
    label.centerYAnchor.constraint(equalTo: visualEffectView.contentView.centerYAnchor)
])
```

### 複数要素のための UIGlassContainerEffect

```swift
let containerEffect = UIGlassContainerEffect()
containerEffect.spacing = 40.0

let containerView = UIVisualEffectView(effect: containerEffect)

let firstGlass = UIVisualEffectView(effect: UIGlassEffect())
let secondGlass = UIVisualEffectView(effect: UIGlassEffect())

containerView.contentView.addSubview(firstGlass)
containerView.contentView.addSubview(secondGlass)
```

### スクロールエッジエフェクト

```swift
scrollView.topEdgeEffect.style = .automatic
scrollView.bottomEdgeEffect.style = .hard
scrollView.leftEdgeEffect.isHidden = true
```

### ツールバーグラス統合

```swift
let favoriteButton = UIBarButtonItem(image: UIImage(systemName: "heart"), style: .plain, target: self, action: #selector(favoriteAction))
favoriteButton.hidesSharedBackground = true  // Opt out of shared glass background
```

## コアパターン — WidgetKit

### レンダリングモード検出

```swift
struct MyWidgetView: View {
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        if renderingMode == .accented {
            // Tinted mode: white-tinted, themed glass background
        } else {
            // Full color mode: standard appearance
        }
    }
}
```

### 視覚階層のためのアクセントグループ

```swift
HStack {
    VStack(alignment: .leading) {
        Text("Title")
            .widgetAccentable()  // Accent group
        Text("Subtitle")
            // Primary group (default)
    }
    Image(systemName: "star.fill")
        .widgetAccentable()  // Accent group
}
```

### アクセントモードでの画像レンダリング

```swift
Image("myImage")
    .widgetAccentedRenderingMode(.monochrome)
```

### コンテナ背景

```swift
VStack { /* content */ }
    .containerBackground(for: .widget) {
        Color.blue.opacity(0.2)
    }
```

## 主要なデザイン決定

| 決定 | 理由 |
|----------|-----------|
| GlassEffectContainer ラッピング | パフォーマンス最適化、グラス要素間のモーフィングを可能にする |
| `spacing` パラメータ | マージ距離を制御 — ブレンドのために要素がどれだけ近づくべきか微調整 |
| `@Namespace` + `glassEffectID` | ビュー階層変更時のスムーズなモーフィングトランジションを可能にする |
| `interactive()` モディファイア | タッチ/ポインタ反応への明示的オプトイン — すべてのグラスが反応すべきではない |
| UIKit の UIGlassContainerEffect | 一貫性のための SwiftUI と同じコンテナパターン |
| ウィジェットのアクセントレンダリングモード | ユーザーがティント Home Screen を選択するとシステムがティントグラスを適用 |

## ベストプラクティス

- 複数の兄弟ビューにグラスを適用する場合は**必ず GlassEffectContainer を使う** — モーフィングを可能にしレンダリングパフォーマンスを向上させる
- 他の外観モディファイア (frame、font、padding) の**後で `.glassEffect()` を適用**する
- ユーザーインタラクションに反応する要素 (ボタン、トグル可能アイテム) でのみ **`.interactive()` を使う**
- グラスエフェクトがいつマージされるかを制御するためにコンテナの **spacing を慎重に選ぶ**
- ビュー階層を変更する際にスムーズなモーフィングトランジションを可能にするために **`withAnimation` を使う**
- **外観をまたいでテスト** — ライトモード、ダークモード、アクセント/ティントモード
- **アクセシビリティコントラストを確保** — グラス上のテキストは読みやすくあるべき

## 避けるべきアンチパターン

- GlassEffectContainer なしで複数のスタンドアロン `.glassEffect()` ビューを使う
- グラスエフェクトのネストが多すぎ — パフォーマンスと視覚的明瞭性を低下させる
- すべてのビューにグラスを適用 — インタラクティブ要素、ツールバー、カード用に予約する
- UIKit で角丸を使う際の `clipsToBounds = true` を忘れる
- ウィジェットでアクセントレンダリングモードを無視 — ティント Home Screen 外観が崩れる
- グラスの後ろに不透明背景を使う — 透明エフェクトを台無しにする

## 使用するタイミング

- 新しい iOS 26 デザインのナビゲーションバー、ツールバー、タブバー
- フローティングアクションボタンとカードスタイルコンテナ
- 視覚的深さとタッチフィードバックを必要とするインタラクティブコントロール
- システムの Liquid Glass 外観に統合すべきウィジェット
- 関連 UI 状態間のモーフィングトランジション
