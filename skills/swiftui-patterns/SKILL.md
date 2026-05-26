---
name: swiftui-patterns
description: SwiftUI のアーキテクチャパターン、@Observable による状態管理、ビュー構成、ナビゲーション、パフォーマンス最適化、モダン iOS/macOS UI ベストプラクティス（SwiftUI architecture, state management, view composition, navigation, performance）。
---

# SwiftUI パターン

Apple プラットフォームで宣言的かつパフォーマンスの良いユーザーインターフェースを構築するモダン SwiftUI パターン。Observation フレームワーク、ビュー構成、型安全なナビゲーション、パフォーマンス最適化をカバーする。

## 起動するタイミング

- SwiftUI ビューの構築と状態管理（`@State`、`@Observable`、`@Binding`）
- `NavigationStack` でのナビゲーションフロー設計
- ビューモデルとデータフローの構造化
- リストと複雑なレイアウトのレンダリングパフォーマンス最適化
- SwiftUI での環境値と依存性注入の処理

## 状態管理

### プロパティラッパーの選択

ふさわしい最もシンプルなラッパーを選ぶ：

| ラッパー | ユースケース |
|---------|----------|
| `@State` | ビューローカルの値型（トグル、フォームフィールド、シート提示） |
| `@Binding` | 親の `@State` への双方向リファレンス |
| `@Observable` クラス + `@State` | 複数プロパティを持つ所有モデル |
| `@Observable` クラス（ラッパーなし） | 親から渡された読み取り専用リファレンス |
| `@Bindable` | `@Observable` プロパティへの双方向バインディング |
| `@Environment` | `.environment()` 経由で注入された共有依存 |

### @Observable ViewModel

`ObservableObject` ではなく `@Observable` を使う — プロパティレベルの変更を追跡するので、SwiftUI は変更されたプロパティを読むビューのみを再レンダリングする：

```swift
@Observable
final class ItemListViewModel {
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    var searchText = ""

    private let repository: any ItemRepository

    init(repository: any ItemRepository = DefaultItemRepository()) {
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = (try? await repository.fetchAll()) ?? []
    }
}
```

### ViewModel を消費するビュー

```swift
struct ItemListView: View {
    @State private var viewModel: ItemListViewModel

    init(viewModel: ItemListViewModel = ItemListViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
        }
        .searchable(text: $viewModel.searchText)
        .overlay { if viewModel.isLoading { ProgressView() } }
        .task { await viewModel.load() }
    }
}
```

### 環境注入

`@EnvironmentObject` を `@Environment` で置き換える：

```swift
// Inject
ContentView()
    .environment(authManager)

// Consume
struct ProfileView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        Text(auth.currentUser?.name ?? "Guest")
    }
}
```

## ビュー構成

### 無効化を制限するためにサブビューを抽出

ビューを小さくフォーカスされた struct に分割する。状態が変更されると、その状態を読むサブビューのみが再レンダリングされる：

```swift
struct OrderView: View {
    @State private var viewModel = OrderViewModel()

    var body: some View {
        VStack {
            OrderHeader(title: viewModel.title)
            OrderItemList(items: viewModel.items)
            OrderTotal(total: viewModel.total)
        }
    }
}
```

### 再利用可能なスタイリング用 ViewModifier

```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
```

## ナビゲーション

### 型安全 NavigationStack

プログラム的、型安全なルーティングには `NavigationStack` と `NavigationPath` を使う：

```swift
@Observable
final class Router {
    var path = NavigationPath()

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}

enum Destination: Hashable {
    case detail(Item.ID)
    case settings
    case profile(User.ID)
}

struct RootView: View {
    @State private var router = Router()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Destination.self) { dest in
                    switch dest {
                    case .detail(let id): ItemDetailView(itemID: id)
                    case .settings: SettingsView()
                    case .profile(let id): ProfileView(userID: id)
                    }
                }
        }
        .environment(router)
    }
}
```

## パフォーマンス

### 大きなコレクションには遅延コンテナを使う

`LazyVStack` と `LazyHStack` は可視のときのみビューを作成する：

```swift
ScrollView {
    LazyVStack(spacing: 8) {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### 安定した識別子

`ForEach` では常に安定したユニークな ID を使う — 配列インデックスを使わない：

```swift
// Use Identifiable conformance or explicit id
ForEach(items, id: \.stableID) { item in
    ItemRow(item: item)
}
```

### body での高価な作業を避ける

- `body` 内で I/O、ネットワーク呼び出し、または重い計算を実行しない
- 非同期作業には `.task {}` を使う — ビューが消えると自動的にキャンセルされる
- スクロールビューで `.sensoryFeedback()` と `.geometryGroup()` を控えめに使う
- リストで `.shadow()`、`.blur()`、`.mask()` を最小化 — オフスクリーンレンダリングをトリガする

### Equatable 準拠

body が高価なビューには、不要な再レンダリングをスキップするため `Equatable` に準拠する：

```swift
struct ExpensiveChartView: View, Equatable {
    let dataPoints: [DataPoint] // DataPoint must conform to Equatable

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dataPoints == rhs.dataPoints
    }

    var body: some View {
        // Complex chart rendering
    }
}
```

## プレビュー

高速反復のためインラインモックデータ付きで `#Preview` マクロを使う：

```swift
#Preview("Empty state") {
    ItemListView(viewModel: ItemListViewModel(repository: EmptyMockRepository()))
}

#Preview("Loaded") {
    ItemListView(viewModel: ItemListViewModel(repository: PopulatedMockRepository()))
}
```

## 避けるべきアンチパターン

- 新しいコードで `ObservableObject` / `@Published` / `@StateObject` / `@EnvironmentObject` を使う — `@Observable` に移行する
- `body` や `init` で非同期作業を直接置く — `.task {}` または明示的なロードメソッドを使う
- データを所有しない子ビュー内に `@State` としてビューモデルを作る — 代わりに親から渡す
- `AnyView` 型消去を使う — 条件付きビューには `@ViewBuilder` または `Group` を推奨
- actor との間でデータを渡すときに `Sendable` 要件を無視する

## 参照

スキル参照：actor ベースの永続化パターンには `swift-actor-persistence`。
スキル参照：プロトコルベース DI と Swift Testing でのテストには `swift-protocol-di-testing`。
