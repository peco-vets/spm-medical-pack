---
name: lead-intelligence
description: AI ネイティブのリードインテリジェンスとアウトリーチパイプライン。Apollo、Clay、ZoomInfo をエージェント駆動のシグナルスコアリング、ミューチュアルランキング、ウォームパス発見、ソース由来ボイスモデリング、Email/LinkedIn/X 横断のチャネル固有アウトリーチで置き換える。高価値コンタクトの発見・適格化・到達に使用 (AI-native lead intelligence and outreach pipeline; replaces Apollo, Clay, ZoomInfo with agent-powered signal scoring, mutual ranking, warm path discovery, source-derived voice modeling, channel-specific outreach across email, LinkedIn, X; find, qualify, reach high-value contacts)。
origin: ECC
---

# Lead Intelligence

ソーシャルグラフ解析とウォームパス発見を通じて、高価値コンタクトを発見、スコアリング、到達するエージェント駆動のリードインテリジェンスパイプライン。

## 起動するタイミング

- ユーザーが特定業界でリードやプロスペクトを見つけたい場合
- パートナーシップ、セールス、資金調達のためのアウトリーチリストを構築する場合
- 誰にリーチアウトすべきか、到達への最良経路を調査する場合
- ユーザーが「リードを見つける」「アウトリーチリスト」「誰にリーチアウトすべき」「ウォーム紹介」と発言した場合
- コンタクトリストを関連性でスコアリング・ランキングする必要がある場合
- ウォーム紹介経路を見つけるためにミューチュアル接続をマップしたい場合

## ツール要件

### 必須
- **Exa MCP** — 人、企業、シグナルの深層 Web 検索 (`web_search_exa`)
- **X API** — フォロワー/フォロイング グラフ、ミューチュアル解析、最近のアクティビティ (`X_BEARER_TOKEN`、加えて書き込みコンテキスト認証情報 `X_CONSUMER_KEY`、`X_CONSUMER_SECRET`、`X_ACCESS_TOKEN`、`X_ACCESS_TOKEN_SECRET`)

### 任意 (結果を強化)
- **LinkedIn** — 利用可能であれば直接 API、それ以外は検索、プロフィール検査、ドラフトのためのブラウザ制御
- **Apollo/Clay API** — ユーザーがアクセスを持つ場合の補強クロスリファレンス
- **GitHub MCP** — 開発者中心のリード適格化のため
- **Apple Mail / Mail.app** — 自動送信なしのコールド・ウォームメールドラフト
- **ブラウザ制御** — API カバレッジが欠落・制約される場合の LinkedIn と X 用

## パイプライン概要

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│ 1. Signal   │────>│ 2. Mutual    │────>│ 3. Warm Path    │────>│ 4. Enrich    │────>│ 5. Outreach     │
│    Scoring  │     │    Ranking   │     │    Discovery    │     │              │     │    Draft        │
└─────────────┘     └──────────────┘     └─────────────────┘     └──────────────┘     └─────────────────┘
```

## アウトリーチ前のボイス

汎用セールスコピーからアウトバウンドをドラフトしない。

ユーザーのボイスが重要な場合は、まず `brand-voice` を実行する。このスキル内でアドホックにスタイルを再導出するのではなく、その `VOICE PROFILE` を再利用する。

ライブ X アクセスが利用可能なら、ドラフト前に最近のオリジナル投稿を取得する。そうでなければ、提供例または利用可能な最良のリポジトリ/サイト素材を使う。

## ステージ 1: シグナルスコアリング

ターゲット業種で高シグナルの人を検索する。以下に基づいてそれぞれに重みを割り当てる。

| シグナル | 重み | ソース |
|--------|--------|--------|
| ロール/タイトル整合性 | 30% | Exa、LinkedIn |
| 業界マッチ | 25% | Exa 企業検索 |
| トピックに関する最近のアクティビティ | 20% | X API 検索、Exa |
| フォロワー数 / 影響力 | 10% | X API |
| ロケーション近接性 | 10% | Exa、LinkedIn |
| あなたのコンテンツへのエンゲージメント | 5% | X API インタラクション |

### シグナル検索アプローチ

```python
# Step 1: Define target parameters
target_verticals = ["prediction markets", "AI tooling", "developer tools"]
target_roles = ["founder", "CEO", "CTO", "VP Engineering", "investor", "partner"]
target_locations = ["San Francisco", "New York", "London", "remote"]

# Step 2: Exa deep search for people
for vertical in target_verticals:
    results = web_search_exa(
        query=f"{vertical} {role} founder CEO",
        category="company",
        numResults=20
    )
    # Score each result

# Step 3: X API search for active voices
x_search = search_recent_tweets(
    query="prediction markets OR AI tooling OR developer tools",
    max_results=100
)
# Extract and score unique authors
```

## ステージ 2: ミューチュアルランキング

スコアリングされた各ターゲットについて、ユーザーのソーシャルグラフを解析して最も温かい経路を見つける。

### ランキングモデル

1. ユーザーの X フォロイングリストと LinkedIn コネクションを取得
2. 高シグナルターゲットごとに、共有コネクションをチェック
3. `social-graph-ranker` モデルを適用してブリッジ価値をスコアリング
4. ミューチュアルを以下でランキング:

| 要因 | 重み |
|--------|--------|
| ターゲットへのコネクション数 | 40% — 最高重み、最多コネクション = 最高ランク |
| ミューチュアルの現在の役職/会社 | 20% — 意思決定者 vs 個人貢献者 |
| ミューチュアルのロケーション | 15% — 同都市 = 紹介容易 |
| 業界整合性 | 15% — 同業種 = 自然な紹介 |
| ミューチュアルの X ハンドル / LinkedIn | 10% — アウトリーチのための識別可能性 |

正規ルール:

```text
Use social-graph-ranker when the user wants the graph math itself,
the bridge ranking as a standalone report, or explicit decay-model tuning.
```

このスキル内では、同じ重み付きブリッジモデルを使う:

```text
B(m) = Σ_{t ∈ T} w(t) · λ^(d(m,t) - 1)
R(m) = B_ext(m) · (1 + β · engagement(m))
```

解釈:
- ティア 1: 高 `R(m)` と直接ブリッジ経路 -> ウォーム紹介の依頼
- ティア 2: 中程度の `R(m)` と 1 ホップブリッジ経路 -> 条件付き紹介の依頼
- ティア 3: 実行可能なブリッジなし -> 同じリードレコードで直接コールドアウトリーチ

### 出力形式

```

If the user explicitly wants the ranking engine broken out, the math visualized, or the network scored outside the full lead workflow, run `social-graph-ranker` as a standalone pass first and feed the result back into this pipeline.
MUTUAL RANKING REPORT
=====================

#1  @mutual_handle (Score: 92)
    Name: Jane Smith
    Role: Partner @ Acme Ventures
    Location: San Francisco
    Connections to targets: 7
    Connected to: @target1, @target2, @target3, @target4, @target5, @target6, @target7
    Best intro path: Jane invested in Target1's company

#2  @mutual_handle2 (Score: 85)
    ...
```

## ステージ 3: ウォームパス発見

各ターゲットについて、最短紹介チェーンを見つける:

```
You ──[follows]──> Mutual A ──[invested in]──> Target Company
You ──[follows]──> Mutual B ──[co-founded with]──> Target Person
You ──[met at]──> Event ──[also attended]──> Target Person
```

### パスタイプ (温かさ順)
1. **直接ミューチュアル** — お互いが同じ人をフォロー/知る
2. **ポートフォリオ接続** — ミューチュアルがターゲット企業に投資またはアドバイザー
3. **同僚/同窓** — ミューチュアルが同じ会社で働いたか同じ学校に通った
4. **イベント重複** — 両者が同じカンファレンス/プログラムに参加
5. **コンテンツエンゲージメント** — ターゲットがミューチュアルのコンテンツに反応したか逆もしかり

## ステージ 4: 強化

適格化された各リードについて、以下を取得する:

- フルネーム、現在の役職、会社
- 会社規模、資金調達ステージ、最近のニュース
- 最近の X 投稿 (直近 30 日) — トピック、トーン、興味
- ユーザーとの共通興味 (共有フォロー、類似コンテンツ)
- 最近の会社イベント (製品ローンチ、ファンディングラウンド、採用)

### 強化ソース
- Exa: 企業データ、ニュース、ブログ投稿
- X API: 最近のツイート、bio、フォロワー
- GitHub: オープンソース貢献 (開発者中心のリード用)
- LinkedIn (browser-use 経由): 完全プロフィール、経歴、学歴

## ステージ 5: アウトリーチドラフト

各リードに対してパーソナライズされたアウトリーチを生成する。ドラフトはソース由来のボイスプロファイルと対象チャネルにマッチすべきである。

### チャネルルール

#### Email

- 最高価値のコールドアウトリーチ、ウォーム紹介、投資家アウトリーチ、パートナーシップ依頼に使う
- ローカルデスクトップ制御が利用可能な場合、Apple Mail / Mail.app でのドラフトをデフォルトとする
- ユーザーが明示的に依頼しない限り、まずドラフトを作成し自動送信しない
- 件名は巧妙ではなく平明かつ具体的であるべき

#### LinkedIn

- ターゲットがそこで活発な場合、ミューチュアルグラフコンテキストが LinkedIn でより強い場合、メール信頼度が低い場合に使う
- 利用可能なら API アクセスを優先
- それ以外はブラウザ制御を使ってプロフィール、最近の活動を検査し、メッセージをドラフト
- メールより短く、偽の専門的な温かさを避ける

#### X

- 公開投稿行動が重要な高コンテキストのオペレーター、ビルダー、投資家アウトリーチに使う
- 検索、タイムライン、エンゲージメント分析には API アクセスを優先
- 必要に応じてブラウザ制御にフォールバック
- DM や公開リプライはメールより遥かにタイトであるべきで、ターゲットのタイムラインから実際の何かを参照すべき

#### チャネル選択ヒューリスティック

以下の順で 1 つの主要チャネルを選ぶ:

1. メールによるウォーム紹介
2. 直接メール
3. LinkedIn DM
4. X DM またはリプライ

強い理由があり、ケイデンスがスパムに感じられない場合のみマルチチャネルを使う。

### ウォーム紹介依頼 (ミューチュアルへ)

ゴール:

- 1 つの明確な依頼
- この紹介が意味をなす 1 つの具体的理由
- 必要なら転送しやすいブラーブ

避けるべき:

- 自社の過剰説明
- ソーシャルプルーフの積み上げ
- ファンドレイザーテンプレートのような響き

### 直接コールドアウトリーチ (ターゲットへ)

ゴール:

- 具体的で最近の何かから始める
- なぜフィットが本物なのか説明
- 1 つの低摩擦の依頼

避けるべき:

- 汎用的称賛
- 機能の羅列
- 「ぜひつながりたい」のような広範な依頼
- 強制された修辞的質問

### 実行パターン

各ターゲットに対して以下を生成:

1. 推奨チャネル
2. そのチャネルが最良である理由
3. メッセージドラフト
4. オプショナルなフォローアップドラフト
5. メールが選ばれたチャネルで Apple Mail が利用可能なら、テキストを返すのみでなくドラフトを作成

ブラウザ制御が利用可能な場合:

- LinkedIn: ターゲットプロフィール、最近のアクティビティ、ミューチュアルコンテキストを検査し、メッセージをドラフトまたは準備
- X: 最近の投稿やリプライを検査し、DM や公開リプライの言葉をドラフト

デスクトップ自動化が利用可能な場合:

- Apple Mail: 件名、本文、受信者付きのドラフトメールを作成

ユーザーの明示的承認なしにメッセージを自動送信しない。

### アンチパターン

- パーソナライゼーションのない汎用テンプレート
- 自社全体を説明する長い段落
- 1 つのメッセージ内の複数の依頼
- 具体性のない偽の親しさ
- マージフィールドが見える一括送信メッセージ
- メール、LinkedIn、X で再利用される同一コピー
- 著者の実際のボイスではなくプラットフォーム形状のスロップ

## 設定

ユーザーはこれらの環境変数を設定すべきである:

```bash
# Required
export X_BEARER_TOKEN="..."
export X_ACCESS_TOKEN="..."
export X_ACCESS_TOKEN_SECRET="..."
export X_CONSUMER_KEY="..."
export X_CONSUMER_SECRET="..."
export EXA_API_KEY="..."

# Optional
export LINKEDIN_COOKIE="..." # For browser-use LinkedIn access
export APOLLO_API_KEY="..."  # For Apollo enrichment
```

## エージェント

このスキルには `agents/` サブディレクトリ内の専門エージェントが含まれる:

- **signal-scorer** — 関連性シグナルでプロスペクトを検索しランキング
- **mutual-mapper** — ソーシャルグラフ接続をマップしウォーム経路を見つける
- **enrichment-agent** — 詳細プロフィールと企業データを取得
- **outreach-drafter** — パーソナライズされたメッセージを生成

## 使用例

```
User: find me the top 20 people in prediction markets I should reach out to

Agent workflow:
1. signal-scorer searches Exa and X for prediction market leaders
2. mutual-mapper checks user's X graph for shared connections
3. enrichment-agent pulls company data and recent activity
4. outreach-drafter generates personalized messages for top ranked leads

Output: Ranked list with warm paths, voice profile summary, and channel-specific outreach drafts or drafts-in-app
```

## 関連スキル

- 正規のボイスキャプチャには `brand-voice`
- アウトリーチ前のレビュー優先のネットワーク剪定と拡張には `connections-optimizer`
