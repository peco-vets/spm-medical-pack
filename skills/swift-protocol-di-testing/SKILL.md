---
name: swift-protocol-di-testing
description: テスト可能な Swift コードのためのプロトコルベース依存性注入（protocol-based dependency injection for testable Swift code）。フォーカスされたプロトコルと Swift Testing を使ってファイルシステム、ネットワーク、外部 API をモックする。
origin: ECC
---

# テスト用 Swift プロトコルベース依存性注入

外部依存（ファイルシステム、ネットワーク、iCloud）を小さくフォーカスされたプロトコルの背後に抽象化することで Swift コードをテスト可能にするパターン。I/O なしの決定的テストを可能にする。

## 起動するタイミング

- ファイルシステム、ネットワーク、または外部 API にアクセスする Swift コードを書く
- 実際の失敗をトリガせずにエラー処理パスをテストする必要がある
- 環境（アプリ、テスト、SwiftUI プレビュー）全体で動作するモジュールを構築
- Swift 並行性（actor、Sendable）でテスト可能なアーキテクチャを設計

## コアパターン

### 1. 小さくフォーカスされたプロトコルを定義する

各プロトコルは厳密に 1 つの外部関心事を扱う。

```swift
// File system access
public protocol FileSystemProviding: Sendable {
    func containerURL(for purpose: Purpose) -> URL?
}

// File read/write operations
public protocol FileAccessorProviding: Sendable {
    func read(from url: URL) throws -> Data
    func write(_ data: Data, to url: URL) throws
    func fileExists(at url: URL) -> Bool
}

// Bookmark storage (e.g., for sandboxed apps)
public protocol BookmarkStorageProviding: Sendable {
    func saveBookmark(_ data: Data, for key: String) throws
    func loadBookmark(for key: String) throws -> Data?
}
```

### 2. デフォルト（本番）実装を作る

```swift
public struct DefaultFileSystemProvider: FileSystemProviding {
    public init() {}

    public func containerURL(for purpose: Purpose) -> URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)
    }
}

public struct DefaultFileAccessor: FileAccessorProviding {
    public init() {}

    public func read(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    public func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    public func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
```

### 3. テスト用のモック実装を作る

```swift
public final class MockFileAccessor: FileAccessorProviding, @unchecked Sendable {
    public var files: [URL: Data] = [:]
    public var readError: Error?
    public var writeError: Error?

    public init() {}

    public func read(from url: URL) throws -> Data {
        if let error = readError { throw error }
        guard let data = files[url] else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return data
    }

    public func write(_ data: Data, to url: URL) throws {
        if let error = writeError { throw error }
        files[url] = data
    }

    public func fileExists(at url: URL) -> Bool {
        files[url] != nil
    }
}
```

### 4. デフォルトパラメータで依存性を注入する

本番コードはデフォルトを使い、テストはモックを注入する。

```swift
public actor SyncManager {
    private let fileSystem: FileSystemProviding
    private let fileAccessor: FileAccessorProviding

    public init(
        fileSystem: FileSystemProviding = DefaultFileSystemProvider(),
        fileAccessor: FileAccessorProviding = DefaultFileAccessor()
    ) {
        self.fileSystem = fileSystem
        self.fileAccessor = fileAccessor
    }

    public func sync() async throws {
        guard let containerURL = fileSystem.containerURL(for: .sync) else {
            throw SyncError.containerNotAvailable
        }
        let data = try fileAccessor.read(
            from: containerURL.appendingPathComponent("data.json")
        )
        // Process data...
    }
}
```

### 5. Swift Testing でテストを書く

```swift
import Testing

@Test("Sync manager handles missing container")
func testMissingContainer() async {
    let mockFileSystem = MockFileSystemProvider(containerURL: nil)
    let manager = SyncManager(fileSystem: mockFileSystem)

    await #expect(throws: SyncError.containerNotAvailable) {
        try await manager.sync()
    }
}

@Test("Sync manager reads data correctly")
func testReadData() async throws {
    let mockFileAccessor = MockFileAccessor()
    mockFileAccessor.files[testURL] = testData

    let manager = SyncManager(fileAccessor: mockFileAccessor)
    let result = try await manager.loadData()

    #expect(result == expectedData)
}

@Test("Sync manager handles read errors gracefully")
func testReadError() async {
    let mockFileAccessor = MockFileAccessor()
    mockFileAccessor.readError = CocoaError(.fileReadCorruptFile)

    let manager = SyncManager(fileAccessor: mockFileAccessor)

    await #expect(throws: SyncError.self) {
        try await manager.sync()
    }
}
```

## ベストプラクティス

- **単一責任**：各プロトコルは 1 つの関心事を扱うべき — 多くのメソッドを持つ「神プロトコル」を作らない
- **Sendable 準拠**：プロトコルが actor 境界を越えて使われるときに必要
- **デフォルトパラメータ**：本番コードはデフォルトで実実装を使う。テストのみがモックを指定する必要がある
- **エラーシミュレーション**：失敗パステスト用に設定可能なエラープロパティでモックを設計する
- **境界のみモック**：外部依存（ファイルシステム、ネットワーク、API）をモックし、内部型ではない

## 避けるべきアンチパターン

- すべての外部アクセスをカバーする単一の大きなプロトコルを作る
- 外部依存のない内部型をモックする
- 適切な依存性注入の代わりに `#if DEBUG` 条件を使う
- actor で使うときに `Sendable` 準拠を忘れる
- 過剰設計：型に外部依存がなければ、プロトコルは不要

## 使用するタイミング

- ファイルシステム、ネットワーク、または外部 API に触れる任意の Swift コード
- 実環境でトリガしにくいエラー処理パスのテスト
- アプリ、テスト、SwiftUI プレビューコンテキストで動作する必要があるモジュールの構築
- テスト可能なアーキテクチャが必要な Swift 並行性（actor、構造化並行性）を使うアプリ
