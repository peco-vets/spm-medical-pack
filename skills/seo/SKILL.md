---
name: seo
description: テクニカル SEO、オンページ最適化、構造化データ、Core Web Vitals、コンテンツ戦略にわたる SEO 改善の監査・計画・実装（audit, plan, implement SEO improvements）。ユーザーが検索可視性向上、SEO 改善、スキーママークアップ、sitemap/robots 作業、またはキーワードマッピングを望むときに使用する。
origin: ECC
---

# SEO

ギミックではなく、技術的正確性、パフォーマンス、コンテンツ関連性を通じて検索可視性を改善する。

## 使用するタイミング

このスキルを使うのは：
- クロール可能性、インデックス可能性、カノニカル、リダイレクトの監査
- タイトルタグ、メタディスクリプション、見出し構造の改善
- 構造化データの追加または検証
- Core Web Vitals の改善
- キーワード調査と URL へのキーワードマッピング
- 内部リンクまたは sitemap／robots 変更の計画

## 動作の仕組み

### 原則

1. コンテンツ最適化の前に技術的ブロッカーを修正する
2. 1 ページに 1 つの明確な主要検索意図を持たせる
3. 操作的パターンよりも長期的な品質シグナルを推奨
4. インデックスがモバイルファーストなので、モバイルファースト前提が重要
5. 推奨はページ固有で実装可能であるべき

### テクニカル SEO チェックリスト

#### クロール可能性

- `robots.txt` は重要なページを許可し低価値サーフェスをブロックする
- 重要なページを意図せず `noindex` にしない
- 重要なページは浅いクリック深度内で到達可能であるべき
- 2 ホップを超えるリダイレクトチェーンを避ける
- カノニカルタグは自己整合的で非ループであるべき

#### インデックス可能性

- 優先 URL フォーマットは一貫であるべき
- 多言語ページには正しい hreflang が必要（使用時）
- サイトマップは意図された公開サーフェスを反映すべき
- 重複 URL がカノニカル制御なしに競合しないこと

#### パフォーマンス

- LCP < 2.5s
- INP < 200ms
- CLS < 0.1
- 一般的な修正：ヒーローアセットのプリロード、レンダリングブロック作業の削減、レイアウトスペースの確保、重い JS のトリミング

#### 構造化データ

- ホームページ：適切な場合は organization または business スキーマ
- 編集ページ：`Article` / `BlogPosting`
- 商品ページ：`Product` と `Offer`
- 内部ページ：`BreadcrumbList`
- Q&A セクション：コンテンツが本当にマッチする場合のみ `FAQPage`

### オンページルール

#### タイトルタグ

- 約 50-60 文字を目指す
- 主要キーワードまたは概念を前方に置く
- ボット用に詰め込まず、人間にとって読みやすくする

#### メタディスクリプション

- 約 120-160 文字を目指す
- ページを正直に記述する
- 主要トピックを自然に含める

#### 見出し構造

- 1 つの明確な `H1`
- `H2` と `H3` は実際のコンテンツ階層を反映すべき
- 視覚的スタイリングだけのために構造をスキップしない

### キーワードマッピング

1. 検索意図を定義する
2. 現実的なキーワードバリアントを収集する
3. 意図マッチ、可能性のある価値、競合で優先順位付けする
4. 1 つの主要キーワード／テーマを 1 つの URL にマップする
5. カニバリゼーションを検出して回避する

### 内部リンク

- ランクさせたいページに強いページからリンクする
- 説明的なアンカーテキストを使う
- より具体的なものが可能な場合、一般的なアンカーを避ける
- 新しいページから関連既存ページへのリンクをバックフィルする

## 例

### タイトル式

```text
Primary Topic - Specific Modifier | Brand
```

### メタディスクリプション式

```text
Action + topic + value proposition + one supporting detail
```

### JSON-LD の例

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Page Title Here",
  "author": {
    "@type": "Person",
    "name": "Author Name"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Brand Name"
  }
}
```

### 監査出力の形

```text
[HIGH] Duplicate title tags on product pages
Location: src/routes/products/[slug].tsx
Issue: Dynamic titles collapse to the same default string, which weakens relevance and creates duplicate signals.
Fix: Generate a unique title per product using the product name and primary category.
```

## アンチパターン

| アンチパターン | 修正 |
| --- | --- |
| キーワード詰め込み | まずユーザーのために書く |
| 薄いほぼ重複ページ | 統合または差別化する |
| 実際に存在しないコンテンツのスキーマ | スキーマを現実にマッチさせる |
| 実際のページをチェックせずにコンテンツアドバイス | 先に実ページを読む |
| 一般的な「SEO 改善」出力 | すべての推奨をページまたはアセットに結びつける |

## 関連スキル

- `seo-specialist`
- `frontend-patterns`
- `brand-voice`
- `market-research`
