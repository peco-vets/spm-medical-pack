---
name: laravel-plugin-discovery
description: LaraPlugins.io MCP 経由で Laravel パッケージを発見・評価する。プラグイン検索、パッケージのヘルス状態確認、Laravel/PHP 互換性評価を行う場合に使用 (Discover and evaluate Laravel packages via LaraPlugins.io MCP; find plugins, check package health, assess Laravel/PHP compatibility)。
origin: ECC
---

# Laravel プラグイン発見

LaraPlugins.io MCP サーバーを使って、健全な Laravel パッケージを見つけ、評価し、選択する。

## 使用するタイミング

- ユーザーが特定機能 (例: 「auth」「permissions」「admin panel」) のための Laravel パッケージを探している場合
- ユーザーが「〜にはどのパッケージを使うべきか」または「〜のための Laravel パッケージはあるか」と尋ねた場合
- ユーザーがパッケージが活発にメンテナンスされているか確認したい場合
- ユーザーが Laravel バージョン互換性を確認する必要がある場合
- ユーザーがプロジェクトに追加する前にパッケージのヘルスを評価したい場合

## MCP 要件

LaraPlugins MCP サーバーが設定されている必要がある。`~/.claude.json` mcpServers に追加する。

```json
"laraplugins": {
  "type": "http",
  "url": "https://laraplugins.io/mcp/plugins"
}
```

API キーは不要 — サーバーは Laravel コミュニティに無料で提供されている。

## MCP ツール

LaraPlugins MCP は 2 つの主要ツールを提供する。

### SearchPluginTool

キーワード、ヘルススコア、ベンダー、バージョン互換性でパッケージを検索する。

**パラメータ:**
- `text_search` (string, optional): 検索キーワード (例: "permission"、"admin"、"api")
- `health_score` (string, optional): ヘルスバンドでフィルタ — `Healthy`、`Medium`、`Unhealthy`、または `Unrated`
- `laravel_compatibility` (string, optional): Laravel バージョンでフィルタ — `"5"`、`"6"`、`"7"`、`"8"`、`"9"`、`"10"`、`"11"`、`"12"`、`"13"`
- `php_compatibility` (string, optional): PHP バージョンでフィルタ — `"7.4"`、`"8.0"`、`"8.1"`、`"8.2"`、`"8.3"`、`"8.4"`、`"8.5"`
- `vendor_filter` (string, optional): ベンダー名でフィルタ (例: "spatie"、"laravel")
- `page` (number, optional): ページネーション用のページ番号

### GetPluginDetailsTool

特定パッケージの詳細メトリクス、readme コンテンツ、バージョン履歴を取得する。

**パラメータ:**
- `package` (string, required): フル Composer パッケージ名 (例: "spatie/laravel-permission")
- `include_versions` (boolean, optional): レスポンスにバージョン履歴を含める

---

## 動作の仕組み

### パッケージの発見

ユーザーが機能のためのパッケージを発見したい場合:

1. 関連キーワードで `SearchPluginTool` を使用
2. ヘルススコア、Laravel バージョン、PHP バージョンでフィルタを適用
3. パッケージ名、説明、ヘルスインジケータと結果をレビュー

### パッケージの評価

ユーザーが特定パッケージを評価したい場合:

1. パッケージ名で `GetPluginDetailsTool` を使用
2. ヘルススコア、最終更新日、Laravel バージョンサポートをレビュー
3. ベンダー評判とリスクインジケータを確認

### 互換性の確認

ユーザーが Laravel または PHP バージョン互換性を必要とする場合:

1. `laravel_compatibility` フィルタをユーザーのバージョンに設定して検索
2. または特定パッケージの詳細を取得してサポートバージョンを確認

---

## 例

### 例: 認証パッケージを見つける

```
SearchPluginTool({
  text_search: "authentication",
  health_score: "Healthy"
})
```

ヘルシーステータスで "authentication" にマッチするパッケージを返す:
- spatie/laravel-permission
- laravel/breeze
- laravel/passport
- など

### 例: Laravel 12 互換パッケージを見つける

```
SearchPluginTool({
  text_search: "admin panel",
  laravel_compatibility: "12"
})
```

Laravel 12 と互換性のあるパッケージを返す。

### 例: パッケージ詳細を取得

```
GetPluginDetailsTool({
  package: "spatie/laravel-permission",
  include_versions: true
})
```

返却内容:
- ヘルススコアと最新活動
- Laravel/PHP バージョンサポート
- ベンダー評判 (リスクスコア)
- バージョン履歴
- 簡単な説明

### 例: ベンダー別にパッケージを見つける

```
SearchPluginTool({
  vendor_filter: "spatie",
  health_score: "Healthy"
})
```

ベンダー "spatie" のヘルシーなパッケージをすべて返す。

---

## フィルタのベストプラクティス

### ヘルススコア別

| ヘルスバンド | 意味 |
|-------------|---------|
| `Healthy` | 活発なメンテナンス、最近の更新 |
| `Medium` | 時折の更新、注意が必要かも |
| `Unhealthy` | 放置されているか頻繁にメンテナンスされていない |
| `Unrated` | まだ評価されていない |

**推奨**: 本番アプリケーションには `Healthy` パッケージを優先する。

### Laravel バージョン別

| バージョン | 注記 |
|---------|-------|
| `13` | 最新 Laravel |
| `12` | 現行安定版 |
| `11` | まだ広く使用 |
| `10` | レガシーだが一般的 |
| `5`-`9` | 非推奨 |

**推奨**: 対象プロジェクトの Laravel バージョンに合わせる。

### フィルタの組み合わせ

```typescript
// Find healthy, Laravel 12 compatible packages for permissions
SearchPluginTool({
  text_search: "permission",
  health_score: "Healthy",
  laravel_compatibility: "12"
})
```

---

## レスポンスの解釈

### 検索結果

各結果には以下が含まれる:
- パッケージ名 (例: `spatie/laravel-permission`)
- 簡単な説明
- ヘルスステータスインジケータ
- Laravel バージョンサポートバッジ

### パッケージ詳細

詳細レスポンスには以下が含まれる:
- **ヘルススコア**: 数値またはバンドインジケータ
- **最終活動**: パッケージが最後に更新された時期
- **Laravel サポート**: バージョン互換性マトリクス
- **PHP サポート**: PHP バージョン互換性
- **リスクスコア**: ベンダー信頼性インジケータ
- **バージョン履歴**: 最近のリリースタイムライン

---

## 一般的なユースケース

| シナリオ | 推奨アプローチ |
|----------|---------------------|
| 「auth にはどのパッケージ?」 | "auth" をヘルシーフィルタで検索 |
| 「spatie/package はまだメンテされている?」 | 詳細取得、ヘルススコア確認 |
| 「Laravel 12 パッケージが必要」 | laravel_compatibility: "12" で検索 |
| 「admin panel パッケージを見つける」 | "admin panel" で検索し結果レビュー |
| 「ベンダー評判確認」 | ベンダーで検索、詳細確認 |

---

## ベストプラクティス

1. **必ずヘルスでフィルタする** — 本番プロジェクトには `health_score: "Healthy"` を使う
2. **Laravel バージョンに合わせる** — `laravel_compatibility` が対象プロジェクトに合うか必ず確認
3. **ベンダー評判を確認する** — 既知のベンダー (spatie、laravel など) のパッケージを優先する
4. **推奨前にレビュー** — 包括的評価には GetPluginDetailsTool を使う
5. **API キー不要** — MCP は無料で認証は不要

---

## 関連スキル

- `laravel-patterns` — Laravel アーキテクチャとパターン
- `laravel-tdd` — Laravel のテスト駆動開発
- `laravel-security` — Laravel セキュリティベストプラクティス
- `documentation-lookup` — 一般的なライブラリドキュメント参照 (Context7)
