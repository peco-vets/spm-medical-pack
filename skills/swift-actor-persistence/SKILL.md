---
name: swift-actor-persistence
description: Swift で actor を使ったスレッドセーフなデータ永続化（thread-safe data persistence in Swift using actors）。インメモリキャッシュとファイルバックストレージを組み合わせ、設計によりデータ競合を排除する。
origin: ECC
---

# スレッドセーフな永続化のための Swift Actor

Swift actor を使ってスレッドセーフなデータ永続化層を構築するパターン。インメモリキャッシュとファイルバックストレージを組み合わせ、コンパイル時にデータ競合を排除する actor モデルを活用する。

## 起動するタイミング

- Swift 5.5+ でデータ永続化層を構築
- 共有可変状態へのスレッドセーフなアクセスが必要
- 手動同期（ロック、DispatchQueue）を排除したい
- ローカルストレージのオフラインファーストアプリを構築

## コアパターン

### Actor ベースのリポジトリ

actor モデルはシリアル化されたアクセスを保証する — データ競合なし、コンパイラで強制される。

```swift
public actor LocalRepository<T: Codable & Identifiable> where T.ID == String {
    private var cache: [String: T] = [:]
    private let fileURL: URL

    public init(directory: URL = .documentsDirectory, filename: String = "data.json") {
        self.fileURL = directory.appendingPathComponent(filename)
        // Synchronous load during init (actor isolation not yet active)
        self.cache = Self.loadSynchronously(from: fileURL)
    }

    // MARK: - Public API

    public func save(_ item: T) throws {
        cache[item.id] = item
        try persistToFile()
    }

    public func delete(_ id: String) throws {
        cache[id] = nil
        try persistToFile()
    }

    public func find(by id: String) -> T? {
        cache[id]
    }

    public func loadAll() -> [T] {
        Array(cache.values)
    }

    // MARK: - Private

    private func persistToFile() throws {
        let data = try JSONEncoder().encode(Array(cache.values))
        try data.write(to: fileURL, options: .atomic)
    }

    private static func loadSynchronously(from url: URL) -> [String: T] {
        guard let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([T].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }
}
```

### 使い方

すべての呼び出しは actor 分離により自動的に async：

```swift
let repository = LocalRepository<Question>()

// Read — fast O(1) lookup from in-memory cache
let question = await repository.find(by: "q-001")
let allQuestions = await repository.loadAll()

// Write — updates cache and persists to file atomically
try await repository.save(newQuestion)
try await repository.delete("q-001")
```

### @Observable ViewModel と組み合わせる

```swift
@Observable
final class QuestionListViewModel {
    private(set) var questions: [Question] = []
    private let repository: LocalRepository<Question>

    init(repository: LocalRepository<Question> = LocalRepository()) {
        self.repository = repository
    }

    func load() async {
        questions = await repository.loadAll()
    }

    func add(_ question: Question) async throws {
        try await repository.save(question)
        questions = await repository.loadAll()
    }
}
```

## 主要設計決定

| 決定 | 根拠 |
|----------|-----------|
| Actor（クラス + ロックではない） | コンパイラ強制のスレッド安全性、手動同期なし |
| インメモリキャッシュ + ファイル永続化 | キャッシュからの高速読み取り、ディスクへの耐久書き込み |
| 同期 init ロード | 非同期初期化の複雑さを回避 |
| ID をキーとする Dictionary | 識別子による O(1) ルックアップ |
| `Codable & Identifiable` のジェネリック | 任意のモデルタイプで再利用可能 |
| アトミックファイル書き込み（`.atomic`） | クラッシュ時の部分書き込みを防止 |

## ベストプラクティス

- actor 境界を越えるすべてのデータに **`Sendable` 型を使う**
- **actor のパブリック API を最小限に保つ** — ドメイン操作のみ公開、永続化詳細ではない
- アプリがクラッシュした際のデータ破損を防ぐため **`.atomic` 書き込みを使う**
- **`init` で同期的にロード** — 非同期イニシャライザはローカルファイルには最小の利益で複雑さを追加する
- リアクティブな UI 更新には **`@Observable` ViewModel と組み合わせる**

## 避けるべきアンチパターン

- 新しい Swift concurrency コードで actor の代わりに `DispatchQueue` や `NSLock` を使う
- 内部キャッシュ Dictionary を外部呼び出し元に公開する
- 検証なしでファイル URL を設定可能にする
- すべての actor メソッド呼び出しが `await` であることを忘れる — 呼び出し元は async コンテキストを扱う必要がある
- actor 分離をバイパスするために `nonisolated` を使う（目的を打ち消す）

## 使用するタイミング

- iOS/macOS アプリのローカルデータストレージ（ユーザーデータ、設定、キャッシュコンテンツ）
- 後でサーバと同期するオフラインファーストアーキテクチャ
- アプリの複数の部分が同時アクセスする共有可変状態
- レガシー `DispatchQueue` ベースのスレッド安全性を、モダン Swift concurrency に置き換える
