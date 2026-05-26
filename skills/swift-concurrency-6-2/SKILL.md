---
name: swift-concurrency-6-2
description: Swift 6.2 Approachable Concurrency — デフォルトでシングルスレッド、明示的なバックグラウンドオフロード用の @concurrent、main actor 型用の分離準拠（single-threaded by default, @concurrent, isolated conformances）。
---

# Swift 6.2 Approachable Concurrency

Swift 6.2 の並行性モデルを採用するパターン。コードはデフォルトでシングルスレッドで実行され、並行性は明示的に導入される。パフォーマンスを犠牲にせずに一般的なデータ競合エラーを排除する。

## 起動するタイミング

- Swift 5.x または 6.0/6.1 プロジェクトを Swift 6.2 に移行
- データ競合安全性のコンパイラエラーの解決
- MainActor ベースのアプリアーキテクチャの設計
- CPU 集約的な作業をバックグラウンドスレッドにオフロード
- MainActor 分離型でプロトコル準拠を実装
- Xcode 26 で Approachable Concurrency ビルド設定を有効化

## コア問題：暗黙的バックグラウンドオフロード

Swift 6.1 以前では、async 関数が暗黙的にバックグラウンドスレッドにオフロードされ、一見安全なコードでもデータ競合エラーを引き起こす可能性があった：

```swift
// Swift 6.1: ERROR
@MainActor
final class StickerModel {
    let photoProcessor = PhotoProcessor()

    func extractSticker(_ item: PhotosPickerItem) async throws -> Sticker? {
        guard let data = try await item.loadTransferable(type: Data.self) else { return nil }

        // Error: Sending 'self.photoProcessor' risks causing data races
        return await photoProcessor.extractSticker(data: data, with: item.itemIdentifier)
    }
}
```

Swift 6.2 はこれを修正する：async 関数はデフォルトで呼び出し元の actor に留まる。

```swift
// Swift 6.2: OK — async stays on MainActor, no data race
@MainActor
final class StickerModel {
    let photoProcessor = PhotoProcessor()

    func extractSticker(_ item: PhotosPickerItem) async throws -> Sticker? {
        guard let data = try await item.loadTransferable(type: Data.self) else { return nil }
        return await photoProcessor.extractSticker(data: data, with: item.itemIdentifier)
    }
}
```

## コアパターン — 分離準拠（Isolated Conformances）

MainActor 型は非分離プロトコルに安全に準拠できるようになった：

```swift
protocol Exportable {
    func export()
}

// Swift 6.1: ERROR — crosses into main actor-isolated code
// Swift 6.2: OK with isolated conformance
extension StickerModel: @MainActor Exportable {
    func export() {
        photoProcessor.exportAsPNG()
    }
}
```

コンパイラは準拠がメイン actor でのみ使用されることを保証する：

```swift
// OK — ImageExporter is also @MainActor
@MainActor
struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // Safe: same actor isolation
    }
}

// ERROR — nonisolated context can't use MainActor conformance
nonisolated struct ImageExporter {
    var items: [any Exportable]

    mutating func add(_ item: StickerModel) {
        items.append(item)  // Error: Main actor-isolated conformance cannot be used here
    }
}
```

## コアパターン — グローバルおよび静的変数

グローバル／静的状態を MainActor で保護：

```swift
// Swift 6.1: ERROR — non-Sendable type may have shared mutable state
final class StickerLibrary {
    static let shared: StickerLibrary = .init()  // Error
}

// Fix: Annotate with @MainActor
@MainActor
final class StickerLibrary {
    static let shared: StickerLibrary = .init()  // OK
}
```

### MainActor デフォルト推論モード

Swift 6.2 は MainActor がデフォルトで推論されるモードを導入する — 手動アノテーション不要：

```swift
// With MainActor default inference enabled:
final class StickerLibrary {
    static let shared: StickerLibrary = .init()  // Implicitly @MainActor
}

final class StickerModel {
    let photoProcessor: PhotoProcessor
    var selection: [PhotosPickerItem]  // Implicitly @MainActor
}

extension StickerModel: Exportable {  // Implicitly @MainActor conformance
    func export() {
        photoProcessor.exportAsPNG()
    }
}
```

このモードはオプトインで、アプリ、スクリプト、その他の実行可能ターゲットに推奨される。

## コアパターン — バックグラウンド作業用の @concurrent

実際の並列性が必要な場合、`@concurrent` で明示的にオフロード：

> **重要：** この例は Approachable Concurrency ビルド設定 — SE-0466（MainActor デフォルト分離）と SE-0461（NonisolatedNonsendingByDefault）が必要。これらが有効化されると、`extractSticker` は呼び出し元の actor に留まり、可変状態アクセスを安全にする。**これらの設定がないと、このコードはデータ競合を持つ** — コンパイラがフラグする。

```swift
nonisolated final class PhotoProcessor {
    private var cachedStickers: [String: Sticker] = [:]

    func extractSticker(data: Data, with id: String) async -> Sticker {
        if let sticker = cachedStickers[id] {
            return sticker
        }

        let sticker = await Self.extractSubject(from: data)
        cachedStickers[id] = sticker
        return sticker
    }

    // Offload expensive work to concurrent thread pool
    @concurrent
    static func extractSubject(from data: Data) async -> Sticker { /* ... */ }
}

// Callers must await
let processor = PhotoProcessor()
processedPhotos[item.id] = await processor.extractSticker(data: data, with: item.id)
```

`@concurrent` を使うには：
1. 包含型を `nonisolated` としてマーク
2. 関数に `@concurrent` を追加
3. すでに非同期でなければ `async` を追加
4. 呼び出しサイトに `await` を追加

## 主要設計決定

| 決定 | 根拠 |
|----------|-----------|
| デフォルトでシングルスレッド | ほとんどの自然なコードはデータ競合フリー、並行性はオプトイン |
| async は呼び出し元の actor に留まる | データ競合エラーを引き起こした暗黙的オフロードを排除 |
| 分離準拠 | MainActor 型は安全でない回避策なしでプロトコルに準拠できる |
| `@concurrent` の明示的オプトイン | バックグラウンド実行は偶発的ではなく意図的なパフォーマンス選択 |
| MainActor デフォルト推論 | アプリターゲットのボイラープレート `@MainActor` アノテーションを削減 |
| オプトイン採用 | 非破壊的移行パス — 機能を段階的に有効化 |

## 移行ステップ

1. **Xcode で有効化**：Build Settings の Swift Compiler > Concurrency セクション
2. **SPM で有効化**：パッケージマニフェストの `SwiftSettings` API を使用
3. **移行ツーリングを使用**：swift.org/migration 経由の自動コード変更
4. **MainActor デフォルトから始める**：アプリターゲットで推論モードを有効化
5. **必要に応じて `@concurrent` を追加**：先にプロファイル、次にホットパスをオフロード
6. **徹底的にテスト**：データ競合問題がコンパイル時エラーになる

## ベストプラクティス

- **MainActor から始める** — 最初にシングルスレッドコードを書き、後で最適化
- **CPU 集約作業にのみ `@concurrent` を使う** — 画像処理、圧縮、複雑な計算
- 主にシングルスレッドのアプリターゲットには **MainActor 推論モードを有効化**
- **オフロード前にプロファイル** — Instruments で実際のボトルネックを見つける
- **MainActor でグローバルを保護** — グローバル／静的可変状態には actor 分離が必要
- `nonisolated` 回避策や `@Sendable` ラッパーの代わりに **分離準拠を使う**
- **段階的に移行** — ビルド設定で機能を 1 つずつ有効化

## 避けるべきアンチパターン

- すべての async 関数に `@concurrent` を適用する（ほとんどはバックグラウンド実行を必要としない）
- 分離を理解せずにコンパイラエラーを抑制するために `nonisolated` を使う
- actor が同じ安全性を提供するときにレガシー `DispatchQueue` パターンを保持する
- 並行性関連の Foundation Models コードで `model.availability` チェックをスキップする
- コンパイラと戦う — データ競合を報告した場合、コードには実際の並行性問題がある
- すべての async コードがバックグラウンドで実行されると仮定（Swift 6.2 デフォルト：呼び出し元の actor に留まる）

## 使用するタイミング

- すべての新しい Swift 6.2+ プロジェクト（Approachable Concurrency が推奨デフォルト）
- 既存アプリを Swift 5.x または 6.0/6.1 並行性から移行
- Xcode 26 採用時のデータ競合安全性コンパイラエラーの解決
- MainActor 中心のアプリアーキテクチャ構築（ほとんどの UI アプリ）
- パフォーマンス最適化 — 特定の重い計算をバックグラウンドにオフロード
