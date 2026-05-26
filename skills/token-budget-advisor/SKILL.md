---
name: token-budget-advisor
description: >-
  回答前にユーザーに、応答の深さをどれだけ消費するかについての情報に基づいた選択肢を提供する（offer informed choice about response depth, token budget）。
  ユーザーが応答長、深さ、またはトークン予算を明示的に制御したいときにこのスキルを使う。
  TRIGGER when: "token budget", "token count", "token usage", "token limit",
  "response length", "answer depth", "short version", "brief answer",
  "detailed answer", "exhaustive answer", "respuesta corta vs larga",
  "cuántos tokens", "ahorrar tokens", "responde al 50%", "dame la versión
  corta", "quiero controlar cuánto usas", またはユーザーが回答サイズや深さの制御を明示的に求める明確なバリアント。
  DO NOT TRIGGER when: ユーザーがすでに現在のセッションでレベルを指定している（維持する）、リクエストが明らかに 1 語の回答、または「token」が応答サイズではなく auth/session/payment トークンを指す場合。
origin: community
---

# Token Budget Advisor（TBA）

Claude が回答する**前**に、応答の深さについての選択肢をユーザーに提供するため、応答フローをインターセプトする。

## 使用するタイミング

- ユーザーが応答の長さや詳細を制御したい
- ユーザーがトークン、予算、深さ、または応答長について言及する
- ユーザーが「short version」「tldr」「brief」「al 25%」「exhaustive」などと言う
- ユーザーが事前に深さ／詳細レベルを選びたいとき

**トリガしない**：ユーザーがすでにこのセッションでレベルを設定している（黙って維持する）、または回答が自明に 1 行。

## 動作の仕組み

### ステップ 1 — 入力トークンを推定

リポジトリの正規コンテキスト予算ヒューリスティクスを使って、プロンプトのトークン数を頭の中で推定する。

[context-budget](../context-budget/SKILL.md) と同じキャリブレーションガイダンスを使う：

- 散文：`words × 1.3`
- コード重視またはミックス／コードブロック：`chars / 4`

ミックスコンテンツには支配的なコンテンツタイプを使い、推定をヒューリスティックに保つ。

### ステップ 2 — 複雑さで応答サイズを推定

プロンプトを分類し、乗数範囲を適用してフル応答ウィンドウを取得：

| 複雑さ   | 乗数範囲 | プロンプトの例                                      |
|--------------|------------------|------------------------------------------------------|
| Simple       | 3× – 8×          | 「X とは何ですか」、yes/no、単一事実                   |
| Medium       | 8× – 20×         | 「X はどう動作しますか」                                  |
| Medium-High  | 10× – 25×        | コンテキスト付きコードリクエスト                           |
| Complex      | 15× – 40×        | 複数部解析、比較、アーキテクチャ      |
| Creative     | 10× – 30×        | ストーリー、エッセイ、ナラティブライティング                  |

応答ウィンドウ = `input_tokens × mult_min` から `input_tokens × mult_max`（ただしモデルの設定された出力トークン制限を超えない）。

### ステップ 3 — 深さオプションを提示

実際の推定数字を使って、回答**前**にこのブロックを提示：

```
Analyzing your prompt...

Input: ~[N] tokens  |  Type: [type]  |  Complexity: [level]  |  Language: [lang]

Choose your depth level:

[1] Essential   (25%)  ->  ~[tokens]   Direct answer only, no preamble
[2] Moderate    (50%)  ->  ~[tokens]   Answer + context + 1 example
[3] Detailed    (75%)  ->  ~[tokens]   Full answer with alternatives
[4] Exhaustive (100%)  ->  ~[tokens]   Everything, no limits

Which level? (1-4 or say "25% depth", "50% depth", "75% depth", "100% depth")

Precision: heuristic estimate ~85-90% accuracy (±15%).
```

レベルトークン推定（応答ウィンドウ内）：
- 25%  → `min + (max - min) × 0.25`
- 50%  → `min + (max - min) × 0.50`
- 75%  → `min + (max - min) × 0.75`
- 100% → `max`

### ステップ 4 — 選択されたレベルで応答

| レベル            | 目標長       | 含める                                             | 省略                                              |
|------------------|---------------------|-----------------------------------------------------|---------------------------------------------------|
| 25% Essential    | 2-4 文最大   | 直接回答、キー結論                       | コンテキスト、例、ニュアンス、代替案           |
| 50% Moderate     | 1-3 段落      | 回答 + 必要なコンテキスト + 1 例              | 詳細解析、エッジケース、参照             |
| 75% Detailed     | 構造化応答 | 複数の例、長所／短所、代替案          | 極端なエッジケース、徹底的な参照         |
| 100% Exhaustive  | 制限なし      | すべて — フル解析、すべてのコード、すべての視点 | 何も省略しない                                        |

## ショートカット — 質問をスキップ

ユーザーがすでにレベルを示している場合、尋ねずに直ちにそのレベルで応答する：

| 発言                                      | レベル |
|----------------------------------------------------|-------|
| "1" / "25% depth" / "short version" / "brief answer" / "tldr"  | 25%   |
| "2" / "50% depth" / "moderate depth" / "balanced answer"        | 50%   |
| "3" / "75% depth" / "detailed answer" / "thorough answer"       | 75%   |
| "4" / "100% depth" / "exhaustive answer" / "full deep dive"     | 100%  |

ユーザーがセッション中に以前レベルを設定していたら、変更されない限り、後続の応答に対して**黙ってそれを維持**する。

## 精度ノート

このスキルはヒューリスティック推定を使う — 実トークナイザはない。精度約 85-90%、変動 ±15%。常に免責事項を表示する。

## 例

### トリガー

- 「先に短いバージョンをください」
- 「あなたの回答は何トークン使いますか」
- 「50% の深さで応答してください」
- 「サマリではなく徹底的な回答が欲しい」
- 「Dame la version corta y luego la detallada」

### トリガしない

- 「JWT トークンとは何ですか」
- 「チェックアウトフローは payment token を使います」
- 「これは正常ですか」
- 「リファクタを完了して」
- ユーザーがすでにこのセッションで深さを選んだ後のフォローアップ質問

## ソース

[TBA — Token Budget Advisor for Claude Code](https://github.com/Xabilimon1/Token-Budget-Advisor-Claude-Code-) からのスタンドアロンスキル。
オリジナルプロジェクトには Python 推定スクリプトも付属するが、このリポジトリはスキルを自己完結型かつヒューリスティックのみに保つ。
