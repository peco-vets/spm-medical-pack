---
name: deep-research
description: firecrawl と exa の MCP を用いた多ソース深掘りリサーチ（deep research, multi-source）。Web を検索し、結果を統合し、出典付きの引用レポートとして配信する。あらゆるトピックについて根拠と引用を伴う徹底的なリサーチをユーザーが求める場合に用いる。
origin: ECC
---

# 深掘りリサーチ（Deep Research）

> **ドリフトしやすいスキルである。** Firecrawl/Exa の MCP ツール名・クォータ・結果フォーマットは変化する。カバレッジを約束したり、ライブのソース数を引用する前に、構成済み MCP ツールと最新の API ドキュメントを必ず確認すること。

firecrawl と exa の MCP ツールを使い、複数の Web ソースから引用付きの徹底的なリサーチレポートを生成する。

## 起動タイミング

- ユーザーが任意のトピックを詳細にリサーチするよう求めた場合
- 競合分析・技術評価・市場規模推定
- 企業・投資家・技術のデューデリジェンス
- 複数ソースの統合を要するあらゆる質問
- ユーザーが "research"、"deep dive"、"investigate"、"what's the current state of" と発言した場合

## MCP 要件

以下のうち少なくとも1つが必要である。
- **firecrawl** — `firecrawl_search`, `firecrawl_scrape`, `firecrawl_crawl`
- **exa** — `web_search_exa`, `web_search_advanced_exa`, `crawling_exa`

両方を組み合わせると最大のカバレッジが得られる。`~/.claude.json` または `~/.codex/config.toml` で構成する。

## ワークフロー

### Step 1: ゴールを理解する

簡潔な確認質問を1〜2件投げる。
- 「目的は学習・意思決定・執筆のどれですか？」
- 「特定の切り口や深さの希望はありますか？」

ユーザーが「とにかく調べて」と言う場合は、合理的なデフォルトで先へ進める。

### Step 2: リサーチを計画する

トピックを3〜5件のサブ問いに分解する。例:
- トピック: "Impact of AI on healthcare"
  - 今日のヘルスケアにおける主要な AI 応用は何か？
  - どんな臨床アウトカムが計測されているか？
  - 規制上の課題は何か？
  - この領域をリードする企業はどこか？
  - 市場規模と成長軌道はどの程度か？

### Step 3: 多ソース検索を実行する

各サブ問いについて、利用可能な MCP ツールで検索する。

**firecrawl の場合:**
```
firecrawl_search(query: "<sub-question keywords>", limit: 8)
```

**exa の場合:**
```
web_search_exa(query: "<sub-question keywords>", numResults: 8)
web_search_advanced_exa(query: "<keywords>", numResults: 5, startPublishedDate: "2025-01-01")
```

**検索戦略:**
- サブ問い1件につき2〜3パターンのキーワードバリエーションを使う
- 汎用クエリとニュース重視クエリを混在させる
- 合計で15〜30件のユニークソースを目指す
- 優先順位: 学術・公式・信頼できるニュース > ブログ > フォーラム

### Step 4: 重要ソースを精読する

最も有望な URL について、本文を取得する。

**firecrawl の場合:**
```
firecrawl_scrape(url: "<url>")
```

**exa の場合:**
```
crawling_exa(url: "<url>", tokensNum: 5000)
```

3〜5件の重要ソースは全文を読み、検索スニペットだけに依拠しない。

### Step 5: 統合してレポートを作成する

レポートを以下の構造にする。

```markdown
# [Topic]: Research Report
*Generated: [date] | Sources: [N] | Confidence: [High/Medium/Low]*

## Executive Summary
[3-5 sentence overview of key findings]

## 1. [First Major Theme]
[Findings with inline citations]
- Key point ([Source Name](url))
- Supporting data ([Source Name](url))

## 2. [Second Major Theme]
...

## 3. [Third Major Theme]
...

## Key Takeaways
- [Actionable insight 1]
- [Actionable insight 2]
- [Actionable insight 3]

## Sources
1. [Title](url) — [one-line summary]
2. ...

## Methodology
Searched [N] queries across web and news. Analyzed [M] sources.
Sub-questions investigated: [list]
```

### Step 6: 配信する

- **短いトピック**: チャットにフルレポートを投稿する
- **長いレポート**: エグゼクティブサマリ＋キーテイクアウェイを投稿し、フル本文はファイルに保存する

## サブエージェントによる並列リサーチ

広範なトピックについては、Claude Code の Task ツールで並列化する。

```
Launch 3 research agents in parallel:
1. Agent 1: Research sub-questions 1-2
2. Agent 2: Research sub-questions 3-4
3. Agent 3: Research sub-question 5 + cross-cutting themes
```

各エージェントが検索・精読・所見を返し、メインセッションが最終レポートに統合する。

## 品質ルール

1. **すべての主張に出典を付ける。** 出典なき断定はしない。
2. **クロスリファレンスする。** 1ソースしか述べていない場合は未検証としてフラグする。
3. **最新性を重視する。** 直近12か月のソースを優先する。
4. **ギャップを正直に示す。** サブ問いに良い情報が見つからなかった場合はそう述べる。
5. **ハルシネーションしない。** 不明な場合は "insufficient data found." と述べる。
6. **事実と推論を分離する。** 推定・予測・意見は明確にラベリングする。

## 例

```
"Research the current state of nuclear fusion energy"
"Deep dive into Rust vs Go for backend services in 2026"
"Research the best strategies for bootstrapping a SaaS business"
"What's happening with the US housing market right now?"
"Investigate the competitive landscape for AI code editors"
```
