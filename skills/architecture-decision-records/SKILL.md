---
name: architecture-decision-records
description: Claude Code セッション中になされたアーキテクチャ判断を構造化された ADR として記録する。判断の瞬間を自動検出し、コンテキスト・検討された代替案・根拠を記録する。将来の開発者がコードベースの形を理解できるように ADR ログを維持する (architecture decision records, ADR, decision log, rationale, alternatives)。
origin: ECC
---

# Architecture Decision Records

コーディングセッション中に発生するアーキテクチャ判断を記録する。判断が Slack スレッド・PR コメント・誰かの記憶にしか残らないのではなく、このスキルはコードの隣に置かれる構造化された ADR ドキュメントを生成する。

## 起動するタイミング

- ユーザーが明示的に「この判断を記録しよう」または「これを ADR にして」と言う
- ユーザーが重要な代替案 (フレームワーク・ライブラリ・パターン・データベース・API 設計) から選択する
- ユーザーが「〜することにした」または「Y ではなく X をやる理由は…」と言う
- ユーザーが「なぜ X を選んだか」と尋ねる (既存 ADR を読む)
- アーキテクチャのトレードオフが議論されるプランニングフェーズ中

## ADR フォーマット

AI 支援開発に合わせて適応された Michael Nygard 提唱の軽量 ADR フォーマットを使う:

```markdown
# ADR-NNNN: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: proposed | accepted | deprecated | superseded by ADR-NNNN
**Deciders**: [who was involved]

## Context

What is the issue that we're seeing that is motivating this decision or change?

[2-5 sentences describing the situation, constraints, and forces at play]

## Decision

What is the change that we're proposing and/or doing?

[1-3 sentences stating the decision clearly]

## Alternatives Considered

### Alternative 1: [Name]
- **Pros**: [benefits]
- **Cons**: [drawbacks]
- **Why not**: [specific reason this was rejected]

### Alternative 2: [Name]
- **Pros**: [benefits]
- **Cons**: [drawbacks]
- **Why not**: [specific reason this was rejected]

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive
- [benefit 1]
- [benefit 2]

### Negative
- [trade-off 1]
- [trade-off 2]

### Risks
- [risk and mitigation]
```

## ワークフロー

### 新規 ADR の取得

判断の瞬間が検出された場合:

1. **初期化 (初回のみ)** — `docs/adr/` が存在しないなら、ディレクトリ、インデックステーブルのヘッダ (下記 ADR インデックスフォーマット参照) をシードした `README.md`、手動使用用の空の `template.md` を作成する前にユーザーに確認を求める。明示的同意なしにファイルを作成しない。
2. **判断を特定する** — 行われている中核的なアーキテクチャ選択を抽出する
3. **コンテキストを集める** — 何の問題がこれを促したか? どんな制約があるか?
4. **代替案を文書化する** — 他にどんな選択肢が検討されたか? なぜ却下されたか?
5. **帰結を述べる** — トレードオフは何か? 何が容易/困難になるか?
6. **番号を割り当てる** — `docs/adr/` の既存 ADR をスキャンしインクリメントする
7. **確認して書く** — ドラフト ADR をユーザーに提示してレビューしてもらう。明示的承認後にのみ `docs/adr/NNNN-decision-title.md` に書く。ユーザーが拒否したら、ファイルを書かずにドラフトを破棄する。
8. **インデックスを更新する** — `docs/adr/README.md` に追記する

### 既存 ADR を読む

ユーザーが「なぜ X を選んだか」と尋ねるとき:

1. `docs/adr/` が存在するか確認する — なければ次のように応じる: 「このプロジェクトに ADR は見つかりません。アーキテクチャ判断の記録を開始しますか?」
2. 存在すれば、`docs/adr/README.md` のインデックスを関連エントリで走査する
3. 一致する ADR ファイルを読み、Context と Decision セクションを提示する
4. 一致が見つからなければ次のように応じる: 「その判断の ADR は見つかりません。今記録しますか?」

### ADR ディレクトリ構造

```
docs/
└── adr/
    ├── README.md              ← index of all ADRs
    ├── 0001-use-nextjs.md
    ├── 0002-postgres-over-mongo.md
    ├── 0003-rest-over-graphql.md
    └── template.md            ← blank template for manual use
```

### ADR インデックスフォーマット

```markdown
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-use-nextjs.md) | Use Next.js as frontend framework | accepted | 2026-01-15 |
| [0002](0002-postgres-over-mongo.md) | PostgreSQL over MongoDB for primary datastore | accepted | 2026-01-20 |
| [0003](0003-rest-over-graphql.md) | REST API over GraphQL | accepted | 2026-02-01 |
```

## 判断検出シグナル

会話の中でアーキテクチャ判断を示すこれらのパターンを監視する:

**明示的シグナル**
- 「X で行こう」
- 「Y ではなく X を使うべきだ」
- 「トレードオフを取る価値がある。なぜなら…」
- 「これを ADR として記録して」

**暗黙的シグナル** (ADR の記録を提案する — ユーザー確認なしに自動作成しない)
- 2 つのフレームワークやライブラリを比較して結論に達する
- 根拠を述べてデータベーススキーマ設計の選択を行う
- アーキテクチャパターン (モノリス vs マイクロサービス・REST vs GraphQL) の間で判断する
- 認証/認可戦略を決定する
- 代替案を評価した後にデプロイインフラを選択する

## 良い ADR とは

### やる
- **具体的に** — 「ORM を使う」ではなく「Prisma ORM を使う」
- **理由を記録する** — what より why が重要
- **却下された代替案を含める** — 将来の開発者は何が検討されたかを知る必要がある
- **帰結を正直に述べる** — どの判断にもトレードオフがある
- **短く保つ** — ADR は 2 分で読める長さに
- **現在形を使う** — 「We will use X」ではなく「We use X」

### やらない
- 些細な判断を記録する — 変数名や書式の選択は ADR 不要
- エッセイを書く — Context セクションが 10 行を超えたら長すぎる
- 代替案を省く — 「ただ選んだ」は妥当な根拠ではない
- マークなしにバックフィルする — 過去の判断を記録する場合、元の日付を記す
- ADR を陳腐化させる — 置き換えられた判断は置換先を参照すべき

## ADR ライフサイクル

```
proposed → accepted → [deprecated | superseded by ADR-NNNN]
```

- **proposed**: 判断は議論中、まだコミットされていない
- **accepted**: 判断は有効で従われている
- **deprecated**: 判断はもはや関連がない (例: 機能削除)
- **superseded**: 新しい ADR がこれを置き換える (常に置換先をリンクする)

## 記録に値する判断カテゴリ

| カテゴリ | 例 |
|----------|---------|
| **技術選択** | フレームワーク・言語・データベース・クラウドプロバイダ |
| **アーキテクチャパターン** | モノリス vs マイクロサービス・イベント駆動・CQRS |
| **API 設計** | REST vs GraphQL・バージョニング戦略・認証メカニズム |
| **データモデリング** | スキーマ設計・正規化判断・キャッシュ戦略 |
| **インフラ** | デプロイモデル・CI/CD パイプライン・モニタリングスタック |
| **セキュリティ** | 認証戦略・暗号化アプローチ・シークレット管理 |
| **テスト** | テストフレームワーク・カバレッジ目標・E2E vs 統合のバランス |
| **プロセス** | ブランチング戦略・レビュープロセス・リリース頻度 |

## 他スキルとの統合

- **プランナーエージェント**: プランナーがアーキテクチャ変更を提案するとき、ADR 作成を提案する
- **コードレビューアエージェント**: 対応する ADR なしにアーキテクチャ変更を導入する PR をフラグする
