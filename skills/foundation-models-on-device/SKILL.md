---
name: foundation-models-on-device
description: iOS 26+ の Apple FoundationModels フレームワークによるオンデバイス LLM（FoundationModels, on-device LLM, guided generation）。テキスト生成、`@Generable` によるガイド付き生成、ツール呼び出し、スナップショットストリーミング。
---

# FoundationModels: オンデバイス LLM (iOS 26)

FoundationModels フレームワークを使って Apple のオンデバイス言語モデルをアプリへ統合するパターンである。テキスト生成、`@Generable` による構造化出力、カスタムツール呼び出し、スナップショットストリーミングを網羅する。すべてオンデバイス実行のためプライバシーとオフラインに対応する。

## 起動タイミング

- Apple Intelligence のオンデバイス機能を用いた AI 機能の構築
- クラウド依存なしのテキスト生成・要約
- 自然言語入力からの構造化データ抽出
- ドメイン固有 AI アクションのためのカスタムツール呼び出し実装
- 構造化レスポンスをストリーミングしてリアルタイム UI 更新
- プライバシー保護 AI が必要（デバイス外にデータが出ない）

## 中核パターン — 可用性チェック

セッション作成前に必ずモデル可用性をチェックする。

```swift
struct GenerativeView: View {
    private var model = SystemLanguageModel.default

    var body: some View {
        switch model.availability {
        case .available:
            ContentView()
        case .unavailable(.deviceNotEligible):
            Text("Device not eligible for Apple Intelligence")
        case .unavailable(.appleIntelligenceNotEnabled):
            Text("Please enable Apple Intelligence in Settings")
        case .unavailable(.modelNotReady):
            Text("Model is downloading or not ready")
        case .unavailable(let other):
            Text("Model unavailable: \(other)")
        }
    }
}
```

## 中核パターン — 基本セッション

```swift
// Single-turn: create a new session each time
let session = LanguageModelSession()
let response = try await session.respond(to: "What's a good month to visit Paris?")
print(response.content)

// Multi-turn: reuse session for conversation context
let session = LanguageModelSession(instructions: """
    You are a cooking assistant.
    Provide recipe suggestions based on ingredients.
    Keep suggestions brief and practical.
    """)

let first = try await session.respond(to: "I have chicken and rice")
let followUp = try await session.respond(to: "What about a vegetarian option?")
```

instructions の要点:
- モデルの役割を定義する（"You are a mentor"）
- 行うべきことを指定する（"Help extract calendar events"）
- スタイル設定を与える（"Respond as briefly as possible"）
- 安全策を追加する（"Respond with 'I can't help with that' for dangerous requests"）

## 中核パターン — `@Generable` によるガイド付き生成

raw 文字列ではなく構造化 Swift 型を生成する。

### 1. Generable 型の定義

```swift
@Generable(description: "Basic profile information about a cat")
struct CatProfile {
    var name: String

    @Guide(description: "The age of the cat", .range(0...20))
    var age: Int

    @Guide(description: "A one sentence profile about the cat's personality")
    var profile: String
}
```

### 2. 構造化出力の要求

```swift
let response = try await session.respond(
    to: "Generate a cute rescue cat",
    generating: CatProfile.self
)

// Access structured fields directly
print("Name: \(response.content.name)")
print("Age: \(response.content.age)")
print("Profile: \(response.content.profile)")
```

### サポートされる @Guide 制約

- `.range(0...20)` — 数値範囲
- `.count(3)` — 配列要素数
- `description:` — 生成のセマンティックガイダンス

## 中核パターン — ツール呼び出し

ドメイン固有タスクのためにカスタムコードをモデルに呼ばせる。

### 1. ツール定義

```swift
struct RecipeSearchTool: Tool {
    let name = "recipe_search"
    let description = "Search for recipes matching a given term and return a list of results."

    @Generable
    struct Arguments {
        var searchTerm: String
        var numberOfResults: Int
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        let recipes = await searchRecipes(
            term: arguments.searchTerm,
            limit: arguments.numberOfResults
        )
        return .string(recipes.map { "- \($0.name): \($0.description)" }.joined(separator: "\n"))
    }
}
```

### 2. ツール付きセッション生成

```swift
let session = LanguageModelSession(tools: [RecipeSearchTool()])
let response = try await session.respond(to: "Find me some pasta recipes")
```

### 3. ツールエラー処理

```swift
do {
    let answer = try await session.respond(to: "Find a recipe for tomato soup.")
} catch let error as LanguageModelSession.ToolCallError {
    print(error.tool.name)
    if case .databaseIsEmpty = error.underlyingError as? RecipeSearchToolError {
        // Handle specific tool error
    }
}
```

## 中核パターン — スナップショットストリーミング

`PartiallyGenerated` 型でリアルタイム UI 向けに構造化レスポンスをストリーミングする。

```swift
@Generable
struct TripIdeas {
    @Guide(description: "Ideas for upcoming trips")
    var ideas: [String]
}

let stream = session.streamResponse(
    to: "What are some exciting trip ideas?",
    generating: TripIdeas.self
)

for try await partial in stream {
    // partial: TripIdeas.PartiallyGenerated (all properties Optional)
    print(partial)
}
```

### SwiftUI 統合

```swift
@State private var partialResult: TripIdeas.PartiallyGenerated?
@State private var errorMessage: String?

var body: some View {
    List {
        ForEach(partialResult?.ideas ?? [], id: \.self) { idea in
            Text(idea)
        }
    }
    .overlay {
        if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
    }
    .task {
        do {
            let stream = session.streamResponse(to: prompt, generating: TripIdeas.self)
            for try await partial in stream {
                partialResult = partial
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

## 主要な設計判断

| 判断 | 理由 |
|----------|-----------|
| オンデバイス実行 | プライバシー — データが端末外に出ない、オフライン動作 |
| 4,096 トークン上限 | オンデバイスモデル制約。大きなデータはセッション横断で分割 |
| スナップショットストリーミング（差分ではない） | 構造化出力に適する。各スナップショットは完全な部分状態 |
| `@Generable` マクロ | 構造化生成のコンパイル時安全。`PartiallyGenerated` 型を自動生成 |
| セッションあたり1リクエスト | `isResponding` が並行リクエストを防止。必要なら複数セッションを作る |
| `response.content`（`.output` ではない） | 正しい API — 結果は `.content` プロパティ経由でアクセス |

## ベストプラクティス

- **必ずセッション作成前に `model.availability` をチェック** — すべての非可用ケースを処理する
- **`instructions` でモデル挙動をガイド** — プロンプトより優先される
- **新リクエスト送信前に `isResponding` を確認** — セッションは1リクエストずつ扱う
- **結果は `response.content`** にアクセスする（`.output` ではない）
- **大きな入力をチャンクに分割** — 4,096 トークン上限は instructions + prompt + output の合計に適用
- **構造化出力には `@Generable`** を使う — raw 文字列パースより強い保証
- **`GenerationOptions(temperature:)`** で創造性を調整する（高いほど創造的）
- **Instruments で監視** — Xcode Instruments でリクエスト性能をプロファイルする

## 避けるべきアンチパターン

- `model.availability` 未確認でのセッション生成
- 4,096 トークンコンテキストウィンドウを超える入力の送信
- 単一セッションでの並行リクエスト
- レスポンスデータアクセスに `.output` を使う（`.content` を使う）
- `@Generable` 構造化出力で済む場面で raw 文字列レスポンスをパースする
- 単一プロンプトで複雑な多段ロジックを構築する — フォーカスされた複数プロンプトに分割する
- モデルが常に利用可能と仮定する — デバイス適格性と設定は様々である

## 利用シーン

- プライバシー敏感アプリ向けのオンデバイステキスト生成
- ユーザー入力からの構造化データ抽出（フォーム、自然言語コマンド）
- オフライン動作が必要な AI 支援機能
- 生成コンテンツを段階表示するストリーミング UI
- ツール呼び出し経由のドメイン固有 AI アクション（検索・計算・参照）
