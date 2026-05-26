---
name: council
description: 曖昧な決定、トレードオフ、go/no-go コールのために 4 ボイスのカウンシルを召集する。複数の有効な経路が存在し、選択前に構造化された不一致が必要なときに使う (council, four voices, decision-making, ambiguity, tradeoffs, skeptic, pragmatist, critic, architect)。
origin: ECC
---

# Council

曖昧な決定のために 4 つのアドバイザーを召集する:
- コンテキスト内の Claude ボイス
- Skeptic サブエージェント
- Pragmatist サブエージェント
- Critic サブエージェント

これは **曖昧さの下での意思決定** のためであり、コードレビュー、実装計画、アーキテクチャ設計のためではない。

## 利用するタイミング

カウンシルを使うのは:
- 決定に複数の信頼できる経路があり、明確な勝者がない
- 明示的なトレードオフ表面化が必要
- ユーザーが第二意見、反対、複数の視点を求める
- 会話のアンカリングが真のリスク
- go / no-go コールが敵対的チャレンジから利益を得る

例:
- monorepo vs polyrepo
- 今リリース vs 磨きで保留
- フィーチャーフラグ vs フルロールアウト
- スコープ簡素化 vs 戦略的幅維持

## 利用しないタイミング

| カウンシルの代わりに | 使うもの |
| --- | --- |
| 出力が正しいか検証 | `santa-method` |
| 機能を実装ステップに分割 | `planner` |
| システムアーキテクチャ設計 | `architect` |
| バグやセキュリティのコードレビュー | `code-reviewer` または `santa-method` |
| 直接的な事実質問 | 直接答える |
| 自明な実行タスク | タスクを実行する |

## ロール

| ボイス | レンズ |
| --- | --- |
| Architect | 正確性、保守性、長期的影響 |
| Skeptic | 前提への挑戦、簡素化、仮定の打破 |
| Pragmatist | リリース速度、ユーザー影響、運用現実 |
| Critic | エッジケース、ダウンサイドリスク、失敗モード |

3 つの外部ボイスは進行中の会話全体ではなく、**質問と関連コンテキストのみ** を持つフレッシュなサブエージェントとして起動するべきである。それがアンチアンカリングメカニズムである。

## ワークフロー

### 1. 真の質問を抽出する

決定を 1 つの明示的なプロンプトに削減する:
- 何を決めているか?
- どの制約が重要か?
- 成功として何がカウントされるか?

質問が曖昧なら、カウンシルを召集する前に 1 つの明確化質問を尋ねる。

### 2. 必要なコンテキストのみ集める

決定がコードベース固有なら:
- 関連ファイル・スニペット・issue テキスト・メトリクスを収集
- コンパクトに保つ
- 決定に必要なコンテキストのみ含める

決定が戦略的/一般的なら:
- 答えを実質的に変えない限りリポスニペットをスキップ

### 3. Architect ポジションを最初に形成する

他のボイスを読む前に、書き留める:
- あなたの初期ポジション
- それの 3 つの最強の理由
- 好みの経路の主要リスク

外部ボイスを単に反映するシンセシスにならないように最初にこれを行う。

### 4. 3 つの独立ボイスを並列で起動する

各サブエージェントは取得する:
- 決定質問
- 必要ならコンパクトなコンテキスト
- 厳格なロール
- 不要な会話履歴なし

プロンプト形状:

```text
You are the [ROLE] on a four-voice decision council.

Question:
[decision question]

Context:
[only the relevant snippets or constraints]

Respond with:
1. Position — 1-2 sentences
2. Reasoning — 3 concise bullets
3. Risk — biggest risk in your recommendation
4. Surprise — one thing the other voices may miss

Be direct. No hedging. Keep it under 300 words.
```

ロール強調:
- Skeptic: フレーミングに挑戦、仮定に質問、最もシンプルで信頼できる代替案を提案
- Pragmatist: 速度、シンプルさ、実世界での実行に最適化
- Critic: ダウンサイドリスク、エッジケース、プランが失敗する理由を表面化

### 5. バイアスガードレール付きで統合する

あなたは参加者でもありシンセサイザーでもあるので、これらのルールを使う:
- 理由を説明せずに外部ビューを却下しない
- 外部ボイスが推奨を変えたなら、明示的にそう言う
- 拒否しても最強の反対を常に含める
- 2 つのボイスが初期ポジションに反して整列するなら、それを真のシグナルとして扱う
- 判決前に生のポジションを可視に保つ

### 6. コンパクトな判決を提示する

この出力形状を使う:

```markdown
## Council: [short decision title]

**Architect:** [1-2 sentence position]
[1 line on why]

**Skeptic:** [1-2 sentence position]
[1 line on why]

**Pragmatist:** [1-2 sentence position]
[1 line on why]

**Critic:** [1-2 sentence position]
[1 line on why]

### Verdict
- **Consensus:** [where they align]
- **Strongest dissent:** [most important disagreement]
- **Premise check:** [did the Skeptic challenge the question itself?]
- **Recommendation:** [the synthesized path]
```

電話画面でスキャン可能に保つ。

## 永続化ルール

このスキルから `~/.claude/notes` や他のシャドウパスにアドホックなノートを書か **ない**。

カウンシルが推奨を実質的に変える場合:
- 教訓を正しい耐久性のある場所に保存するために `knowledge-ops` を使う
- または結果がセッションメモリに属する場合は `/save-session` を使う
- または決定がアクティブな実行真実を変える場合は関連 GitHub / Linear issue を直接更新

何か本物を変えるときのみ決定を永続化する。

## マルチラウンドフォローアップ

デフォルトは 1 ラウンド。

ユーザーが別のラウンドを望むなら:
- 新しい質問を焦点を絞って保つ
- 必要な場合のみ前の判決を含める
- アンチアンカリング値を保持するために Skeptic をできるだけクリーンに保つ

## アンチパターン

- コードレビューにカウンシルを使う
- タスクが単に実装作業のときカウンシルを使う
- サブエージェントに会話トランスクリプト全体を与える
- 最終判決で不一致を隠す
- 重要性に関係なくすべての決定をノートとして永続化する

## 関連スキル

- `santa-method` — 敵対的検証
- `knowledge-ops` — 耐久性のある決定デルタを正しく永続化
- `search-first` — 必要ならカウンシル前に外部参照素材を集める
- `architecture-decision-records` — 決定が長期システムポリシーになるとき結果を形式化

## 例

質問:

```text
Should we ship ECC 2.0 as alpha now, or hold until the control-plane UI is more complete?
```

ありそうなカウンシル形:
- Architect は構造的整合性と混乱したサーフェスを避けることを推す
- Skeptic は UI が実際にゲーティング要因か質問する
- Pragmatist は信頼を害さずに今何をリリースできるか尋ねる
- Critic はサポート負担、期待負債、ロールアウト混乱に焦点を当てる

価値は満場一致ではない。価値は選択前に不一致を可読にすることである。
