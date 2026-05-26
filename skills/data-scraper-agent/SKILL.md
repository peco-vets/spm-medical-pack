---
name: data-scraper-agent
description: 任意の公開ソース (ジョブボード、価格、ニュース、GitHub、スポーツ、何でも) のための完全自動化された AI 駆動データ収集エージェントを構築する。スケジュールでスクレイピングし、無料 LLM (Gemini Flash) でデータをエンリッチし、結果を Notion/Sheets/Supabase に保存し、ユーザーフィードバックから学習する。GitHub Actions で 100% 無料で実行される。ユーザーが任意の公開データを自動的にモニタ、収集、追跡したいときに使う (data scraper agent, automated, Gemini, GitHub Actions, Notion, Sheets, Supabase, monitoring)。
origin: community
---

# Data Scraper Agent

任意の公開データソースのための本番対応の AI 駆動データ収集エージェントを構築する。
スケジュールで実行され、無料 LLM で結果をエンリッチし、データベースに保存し、時間とともに改善する。

**スタック: Python · Gemini Flash (無料) · GitHub Actions (無料) · Notion / Sheets / Supabase**

## 起動するタイミング

- ユーザーが任意の公開 Web サイトや API をスクレイプまたはモニタしたい
- ユーザーが「ボットを構築...」「X をモニタして」「... からデータを収集」と言う
- ユーザーがジョブ、価格、ニュース、レポ、スポーツスコア、イベント、リスティングを追跡したい
- ユーザーがホスティング料金なしにデータ収集を自動化する方法を尋ねる
- ユーザーが自身の決定に基づいて時間とともに賢くなるエージェントを望む

## コアコンセプト

### 3 つの層

すべてのデータスクレイパエージェントは 3 つの層を持つ:

```
COLLECT → ENRICH → STORE
  │           │        │
Scraper    AI (LLM)  Database
runs on    scores/   Notion /
schedule   summarises Sheets /
           & classifies Supabase
```

### 無料スタック

| 層 | ツール | 理由 |
|---|---|---|
| **スクレイピング** | `requests` + `BeautifulSoup` | コストなし、80% の公開サイトをカバー |
| **JS レンダーサイト** | `playwright` (無料) | HTML スクレイピング失敗時 |
| **AI エンリッチメント** | Gemini Flash REST API 経由 | 500 req/日、1M トークン/日 — 無料 |
| **ストレージ** | Notion API | 無料ティア、レビュー用優れた UI |
| **スケジュール** | GitHub Actions cron | パブリックリポで無料 |
| **学習** | リポ内 JSON フィードバックファイル | インフラゼロ、git に永続化 |

### AI モデルフォールバックチェーン

クォータ枯渇時に Gemini モデル全体で自動フォールバックするエージェントを構築する:

```
gemini-2.0-flash-lite (30 RPM) →
gemini-2.0-flash (15 RPM) →
gemini-2.5-flash (10 RPM) →
gemini-flash-lite-latest (フォールバック)
```

### 効率のためのバッチ API 呼び出し

決してアイテムごとに 1 回 LLM を呼ばない。常にバッチする:

```python
# BAD: 33 API calls for 33 items
for item in items:
    result = call_ai(item)  # 33 calls → hits rate limit

# GOOD: 7 API calls for 33 items (batch size 5)
for batch in chunks(items, size=5):
    results = call_ai(batch)  # 7 calls → stays within free tier
```

(本スキルの実装詳細 — Python コード、Gemini クライアント、AI パイプライン、フィードバック学習、Notion ストレージ、main.py オーケストレーション、GitHub Actions ワークフロー、config.yaml テンプレート、スクレイピングパターン、無料ティア制限 — はすべて技術コードのため英語のまま保持される。)

## ワークフロー要約

### Step 1: 目標を理解する

ユーザーに尋ねる:
1. **何を収集するか**: データソース? URL / API / RSS / 公開エンドポイント?
2. **何を抽出するか**: どのフィールドが重要か? タイトル、価格、URL、日付、スコア?
3. **どう保存するか**: 結果はどこに? Notion、Google Sheets、Supabase、ローカルファイル?
4. **どうエンリッチするか**: AI に各アイテムをスコア、要約、分類、マッチさせたいか?
5. **頻度**: どれくらいの頻度で実行するか? 毎時、毎日、毎週?

### Step 2: アーキテクチャを設計

```
my-agent/
├── config.yaml              # User customises this (keywords, filters, preferences)
├── profile/
│   └── context.md           # User context the AI uses (resume, interests, criteria)
├── scraper/
│   ├── __init__.py
│   ├── main.py              # Orchestrator: scrape → enrich → store
│   ├── filters.py           # Rule-based pre-filter (fast, before AI)
│   └── sources/
│       ├── __init__.py
│       └── source_name.py   # One file per data source
├── ai/
│   ├── __init__.py
│   ├── client.py            # Gemini REST client with model fallback
│   ├── pipeline.py          # Batch AI analysis
│   ├── jd_fetcher.py        # Fetch full content from URLs (optional)
│   └── memory.py            # Learn from user feedback
├── storage/
│   ├── __init__.py
│   └── notion_sync.py       # Or sheets_sync.py / supabase_sync.py
├── data/
│   └── feedback.json        # User decision history (auto-updated)
├── .env.example
├── setup.py                 # One-time DB/schema creation
├── enrich_existing.py       # Backfill AI scores on old rows
├── requirements.txt
└── .github/
    └── workflows/
        └── scraper.yml      # GitHub Actions schedule
```

### Step 3-10: 実装

各ステップ (スクレイパソース、Gemini AI クライアント、AI パイプライン、フィードバック学習、ストレージ、orchestration、GitHub Actions、config.yaml) のフルコード実装については原版を参照。

## アンチパターン

| アンチパターン | 問題 | 修正 |
|---|---|---|
| アイテムごとに 1 LLM 呼び出し | レート制限を即時ヒット | バッチ 5 アイテム per call |
| ハードコードキーワード | 再利用不可 | すべて `config.yaml` へ |
| レート制限なしスクレイピング | IP ban | `time.sleep(1)` 追加 |
| コード内シークレット | セキュリティリスク | 常に `.env` + GitHub Secrets |
| 重複排除なし | 重複行が蓄積 | プッシュ前に URL チェック |
| `robots.txt` 無視 | 法的/倫理的リスク | クロールルールを尊重、公開 API 利用可能なら使う |
| JS レンダーサイトに `requests` | 空応答 | Playwright を使うか基底 API を探す |
| `maxOutputTokens` 過低 | 切り詰められた JSON、パースエラー | バッチ応答に 2048+ 使用 |

## 無料ティア制限リファレンス

| サービス | 無料制限 | 典型的使用 |
|---|---|---|
| Gemini Flash Lite | 30 RPM、1500 RPD | 3 時間間隔で〜56 req/日 |
| Gemini 2.0 Flash | 15 RPM、1500 RPD | 良いフォールバック |
| Gemini 2.5 Flash | 10 RPM、500 RPD | 控えめに使用 |
| GitHub Actions | 無制限 (パブリックリポ) | 〜20 分/日 |
| Notion API | 無制限 | 〜200 書き込み/日 |
| Supabase | 500MB DB、2GB 転送 | ほとんどのエージェントに十分 |
| Google Sheets API | 300 req/分 | 小エージェントで機能 |

## 品質チェックリスト

エージェントを完了とマークする前に:

- [ ] `config.yaml` がすべてのユーザー向け設定を制御 — ハードコード値なし
- [ ] `profile/context.md` が AI マッチング用のユーザー固有コンテキストを保持
- [ ] すべてのストレージプッシュ前に URL による重複排除
- [ ] Gemini クライアントにモデルフォールバックチェーン (4 モデル) がある
- [ ] バッチサイズ ≤ 5 アイテム per API 呼び出し
- [ ] `maxOutputTokens` ≥ 2048
- [ ] `.env` が `.gitignore` に
- [ ] オンボーディング用 `.env.example` 提供
- [ ] `setup.py` が初回実行時に DB スキーマを作成
- [ ] `enrich_existing.py` が古い行に AI スコアをバックフィル
- [ ] GitHub Actions ワークフローが各実行後 `feedback.json` をコミット
- [ ] README が以下をカバー: 5 分未満のセットアップ、必要シークレット、カスタマイズ

## 実例

```
「Hacker News で AI スタートアップ資金調達ニュースをモニタするエージェントを構築」
「3 つの EC サイトから製品価格をスクレイプし下落時にアラート」
「'llm' または 'agents' タグの新しい GitHub リポを追跡 — 各々を要約」
「LinkedIn と Cutshort から Chief of Staff 求人を集め Notion へ」
「subreddit を私の会社言及投稿でモニタ — 感情を分類」
「私が気にするトピックの新学術論文を arXiv から毎日スクレイプ」
「スポーツ試合結果を追跡し Google Sheets で実行テーブルを保持」
「不動産リスティングウォッチャーを構築 — ₹1Cr 以下の新物件でアラート」
```

完全な実装と参考実装については原版を参照されたい。
