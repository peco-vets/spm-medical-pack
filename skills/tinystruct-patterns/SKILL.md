---
name: tinystruct-patterns
description: tinystruct Java フレームワークでの開発に関するエキスパートガイダンス（expert guidance for tinystruct Java framework）。tinystruct コードベースまたは tinystruct 上に構築された任意のプロジェクトで作業するときに使用する — Application クラス、@Action マップルート、ユニットテスト、ActionRegistry、HTTP/CLI デュアルモード処理、組み込み HTTP サーバ、イベントシステム、Builder/Builders を使った JSON、AbstractData を使ったデータベース永続化、POJO 生成、Server-Sent Events（SSE）、ファイルアップロード、アウトバウンド HTTP ネットワーキングを含む。
origin: ECC
---

# tinystruct 開発パターン

軽量で高性能なフレームワーク **tinystruct** Java フレームワークでモジュールを構築するためのアーキテクチャと実装パターン。CLI と HTTP を同等市民として扱い、`main()` メソッドが不要で最小設定。

## コア原則

**CLI と HTTP は同等市民。** `@Action` でアノテートされた各メソッドは、変更なしでターミナルと Web ブラウザの両方から実行可能であるべき。この「デュアルモード」能力は tinystruct のコア設計哲学である。

## 起動するタイミング

### 使用するタイミング

- `AbstractApplication` を拡張して新しい `Application` モジュールを作成
- `@Action` を使ってルートとコマンドライン アクションを定義
- `Context` 経由でリクエストごとの状態を処理
- ネイティブ `Builder` と `Builders` コンポーネントを使った JSON シリアライゼーション
- `AbstractData` POJO を使ったデータベース永続化
- `generate` コマンドを使ってデータベーステーブルから POJO を生成
- リアルタイムプッシュ用の Server-Sent Events（SSE）の実装
- マルチパートデータ経由のファイルアップロード処理
- `URLRequest` と `HTTPHandler` を使ったアウトバウンド HTTP リクエスト
- `application.properties` でデータベース接続またはシステム設定を構成
- ルーティング衝突（Actions）または CLI 引数パースのデバッグ

## 動作の仕組み

tinystruct フレームワークは `@Action` でアノテートされた任意のメソッドをターミナルと Web 環境の両方にルート可能なエンドポイントとして扱う。アプリケーションは `AbstractApplication` を拡張して作成され、`init()` のようなコアライフサイクルフックとリクエスト `Context` へのアクセスを提供する。

ルーティングは `ActionRegistry` によって処理され、パスセグメントをメソッド引数に自動的にマッピングし、依存関係を注入する。データのみのサービスには、ゼロ依存フットプリントを維持するため、ネイティブ `Builder` と `Builders` コンポーネントを JSON シリアライゼーションに使うべき。データベース層は外部 ORM ライブラリなしの CRUD 操作のため、XML マッピングファイルとペアになった `AbstractData` POJO を使う。

## 例

### 基本アプリケーション（MyService）
```java
public class MyService extends AbstractApplication {
    @Override
    public void init() {
        this.setTemplateRequired(false); // Disable .view lookup for data/API apps
    }

    @Override public String version() { return "1.0.0"; }

    @Action("greet")
    public String greet() {
        return "Hello from tinystruct!";
    }

    // Path parameter: GET /?q=greet/James  OR  bin/dispatcher greet/James
    @Action("greet")
    public String greet(String name) {
        return "Hello, " + name + "!";
    }
}
```

### HTTP モード曖昧性解消（login）
```java
@Action(value = "login", mode = Mode.HTTP_POST)
public String doLogin(Request<?, ?> request) throws ApplicationException {
    request.getSession().setAttribute("userId", "42");
    return "Logged in";
}
```

### ネイティブ JSON データ処理（Builder + Builders）
```java
import org.tinystruct.data.component.Builder;
import org.tinystruct.data.component.Builders;

@Action("api/data")
public String getData() throws ApplicationException {
    Builders dataList = new Builders();
    Builder item = new Builder();
    item.put("id", 1);
    item.put("name", "James");
    dataList.add(item);

    Builder response = new Builder();
    response.put("status", "success");
    response.put("data", dataList);
    return response.toString(); // {"status":"success","data":[{"id":1,"name":"James"}]}
}
```

### SSE（Server-Sent Events）
```java
import org.tinystruct.http.SSEPushManager;

@Action("sse/connect")
public String connect() {
    return "{\"type\":\"connect\",\"message\":\"Connected to SSE\"}";
}

// Push to a specific client
String sessionId = getContext().getId();
Builder msg = new Builder();
msg.put("text", "Hello, user!");
SSEPushManager.getInstance().push(sessionId, msg);

// Broadcast to all
// Broadcast to all
SSEPushManager.getInstance().broadcast(msg);
```

### ファイルアップロード
```java
import org.tinystruct.data.FileEntity;

@Action(value = "upload", mode = Mode.HTTP_POST)
public String upload(Request<?, ?> request) throws ApplicationException {
    List<FileEntity> files = request.getAttachments();
    if (files != null) {
        for (FileEntity file : files) {
            System.out.println("Uploaded: " + file.getFilename());
        }
    }
    return "Upload OK";
}
```

## 設定

設定は `src/main/resources/application.properties` で管理される。

```properties
# Database
driver=org.h2.Driver
database.url=jdbc:h2:~/mydb
database.user=sa
database.password=

# Server
default.home.page=hello
server.port=8080

# Locale
default.language=en_US

# Session (Redis for clustered environments)
# default.session.repository=org.tinystruct.http.RedisSessionRepository
# redis.host=127.0.0.1
# redis.port=6379
```

アプリケーションで設定値にアクセス：
```java
String port = this.getConfiguration("server.port");
```

## レッドフラグ & アンチパターン

| 症状 | 正しいパターン |
|---|---|
| `com.google.gson` または `com.fasterxml.jackson` のインポート | `org.tinystruct.data.component.Builder` / `Builders` を使う |
| JSON 配列に `List<Builder>` を使う | ジェネリック型消去問題を回避するため `Builders` を使う |
| `ApplicationRuntimeException: template not found` | API のみのアプリでは `init()` で `setTemplateRequired(false)` を呼ぶ |
| `private` メソッドに `@Action` をアノテート | Action はフレームワークに登録されるために `public` でなければならない |
| アプリで `main(String[] args)` をハードコード | すべてのモジュールのエントリポイントとして `bin/dispatcher` を使う |
| 手動の `ActionRegistry` 登録 | 自動発見のため `@Action` アノテーションを推奨 |
| ランタイムで Action が見つからない | クラスが `--import` 経由でインポートされるか `application.properties` にリストされていることを保証 |
| CLI 引数が見えない | `--key value` で渡し、`getContext().getAttribute("--key")` 経由でアクセス |
| 2 つのメソッドが同じパス、間違ったほうが発火 | 曖昧性解消のため明示的な `mode`（例：`HTTP_GET` vs `HTTP_POST`）を設定 |

## ベストプラクティス

1. **粒度の細かいアプリケーション**：1 つのモノリシッククラスではなく、より小さくフォーカスされたアプリケーションにロジックを分割する。
2. **`init()` でセットアップ**：コンストラクタではなく `init()` をセットアップ（設定、DB）に活用する。`setAction()` を呼ばない — `@Action` アノテーションを使う。
3. **モード認識**：`@Action` の `Mode` パラメータを使って機密操作を `CLI` のみまたは特定の HTTP メソッドに制限する。
4. **Param より Context**：オプションの CLI フラグには、メソッドシグネチャにパラメータを追加するのではなく `getContext().getAttribute("--flag")` を使う。
5. **非同期イベント**：イベントによってトリガされる重いタスクには、イベントハンドラ内で `CompletableFuture.runAsync()` を使う。

## テクニカルリファレンス

詳細なガイドは `references/` ディレクトリで利用可能：

- [Architecture & Config](references/architecture.md) — 抽象化、パッケージマップ、プロパティ
- [Routing & @Action](references/routing.md) — アノテーション詳細、Modes、パラメータ
- [Data Handling](references/data-handling.md) — Builder、Builders、JSON シリアライゼーション & パース
- [Database Persistence](references/database.md) — AbstractData POJO、CRUD、マッピング XML、POJO 生成
- [System & Usage](references/system-usage.md) — Context、Sessions、SSE、ファイルアップロード、イベント、ネットワーキング
- [Testing Patterns](references/testing.md) — JUnit 5 ユニットおよび HTTP 統合テスト

## リファレンスソースファイル（内部）

- `src/main/java/org/tinystruct/AbstractApplication.java` — ライフサイクルフック付きコア基底クラス
- `src/main/java/org/tinystruct/system/annotation/Action.java` — アノテーション & Modes
- `src/main/java/org/tinystruct/application/ActionRegistry.java` — ルーティングエンジン
- `src/main/java/org/tinystruct/data/component/Builder.java` — JSON オブジェクトシリアライザ
- `src/main/java/org/tinystruct/data/component/Builders.java` — JSON 配列シリアライザ
- `src/main/java/org/tinystruct/data/component/AbstractData.java` — CRUD 付き基底 POJO クラス
- `src/main/java/org/tinystruct/data/Mapping.java` — マッピング XML パーサ
- `src/main/java/org/tinystruct/data/tools/MySQLGenerator.java` — POJO ジェネレータリファレンス
- `src/main/java/org/tinystruct/data/component/FieldType.java` — SQL から Java への型マッピング
- `src/main/java/org/tinystruct/data/component/Condition.java` — 流れるような SQL クエリビルダ
- `src/main/java/org/tinystruct/http/SSEPushManager.java` — SSE 接続管理
- `src/test/java/org/tinystruct/application/ActionRegistryTest.java` — レジストリテスト例
- `src/test/java/org/tinystruct/system/HttpServerHttpModeTest.java` — HTTP 統合テストパターン
