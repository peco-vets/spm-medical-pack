---
name: exa-search
description: Web・コード・企業リサーチのための Exa MCP 経由のニューラルサーチ（Exa search, neural search, web search）。Exa のニューラル検索エンジンを使った Web 検索、コード例、企業情報、人物検索、AI ドリブンな深掘りリサーチをユーザーが必要とするときに用いる。
origin: ECC
---

# Exa 検索

> **ドリフトしやすいスキル。** Exa MCP のツール名・パラメータ・アカウント上限は変化しうる。特定の検索モード・カテゴリ・livecrawl 挙動に依存する前に、公開されているツール表面と最新の Exa ドキュメントを確認すること。

Exa MCP サーバ経由で、Web コンテンツ・コード・企業・人物のニューラル検索を行う。

## 起動タイミング

- ユーザーが最新の Web 情報やニュースを必要とする場合
- コード例・API ドキュメント・技術リファレンスの検索
- 企業・競合・市場プレイヤーのリサーチ
- ドメイン内のプロフェッショナルプロファイルや人物の検索
- 開発タスクのバックグラウンドリサーチ実行
- ユーザーが "search for"、"look up"、"find"、"what's the latest on" と発言した場合

## MCP 要件

Exa MCP サーバの構成が必要である。`~/.claude.json` に追加する。

```json
"exa-web-search": {
  "command": "npx",
  "args": ["-y", "exa-mcp-server"],
  "env": { "EXA_API_KEY": "YOUR_EXA_API_KEY_HERE" }
}
```

API キーは [exa.ai](https://exa.ai) で取得する。
本リポジトリの現状の Exa セットアップで公開されているツール表面は: `web_search_exa` と `get_code_context_exa` である。
Exa サーバが追加ツールを公開している場合は、ドキュメントやプロンプトで依存する前に正確な名称を確認すること。

## 中核ツール

### web_search_exa

最新情報・ニュース・事実の汎用 Web 検索。

```
web_search_exa(query: "latest AI developments 2026", numResults: 5)
```

**パラメータ:**

| Param | Type | Default | Notes |
|-------|------|---------|-------|
| `query` | string | required | Search query |
| `numResults` | number | 8 | Number of results |
| `type` | string | `auto` | Search mode |
| `livecrawl` | string | `fallback` | Prefer live crawling when needed |
| `category` | string | none | Optional focus such as `company` or `research paper` |

### get_code_context_exa

GitHub・Stack Overflow・ドキュメントサイトからコード例とドキュメントを検索する。

```
get_code_context_exa(query: "Python asyncio patterns", tokensNum: 3000)
```

**パラメータ:**

| Param | Type | Default | Notes |
|-------|------|---------|-------|
| `query` | string | required | Code or API search query |
| `tokensNum` | number | 5000 | Content tokens (1000-50000) |

## 利用パターン

### クイックルックアップ
```
web_search_exa(query: "Node.js 22 new features", numResults: 3)
```

### コードリサーチ
```
get_code_context_exa(query: "Rust error handling patterns Result type", tokensNum: 3000)
```

### 企業・人物リサーチ
```
web_search_exa(query: "Vercel funding valuation 2026", numResults: 3, category: "company")
web_search_exa(query: "site:linkedin.com/in AI safety researchers Anthropic", numResults: 5)
```

### 技術深掘り
```
web_search_exa(query: "WebAssembly component model status and adoption", numResults: 5)
get_code_context_exa(query: "WebAssembly component model examples", tokensNum: 4000)
```

## ヒント

- 最新情報・企業ルックアップ・広範な発見には `web_search_exa` を使う
- 結果を絞るには `site:`、引用フレーズ、`intitle:` 等の検索オペレータを使う
- フォーカスされたコードスニペットには `tokensNum` を低め（1000〜2000）、包括的なコンテキストには高め（5000+）に設定する
- 一般 Web ページではなく API 利用法やコード例が必要なときは `get_code_context_exa` を使う

## 関連スキル

- `deep-research` — firecrawl + exa を組み合わせる完全リサーチワークフロー
- `market-research` — 意思決定フレームワーク付きビジネス志向リサーチ
