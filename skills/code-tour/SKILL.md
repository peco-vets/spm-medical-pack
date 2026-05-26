---
name: code-tour
description: 実ファイルと行アンカー付きのペルソナターゲット型ステップバイステップウォークスルーである CodeTour `.tour` ファイルを作成する。オンボーディングツアー、アーキテクチャウォークスルー、PR ツアー、RCA ツアー、構造化された「これがどう動くか説明して」リクエストに使う (code tour, walkthrough, onboarding, architecture, PR review, RCA, CodeTour)。
origin: ECC
---

# Code Tour

実ファイルと行範囲に直接開く、コードベースウォークスルーのための **CodeTour** `.tour` ファイルを作成する。ツアーは `.tours/` にあり、アドホックな Markdown ノートではなく CodeTour フォーマット用である。

良いツアーは特定の読者向けのナラティブである:
- 彼らが何を見ているか
- なぜそれが重要か
- 次にどの道を辿るべきか

`.tour` JSON ファイルのみを作成する。このスキルの一部としてソースコードを変更しない。

## 利用するタイミング

このスキルを使う場面:
- ユーザーがコードツアー・オンボーディングツアー・アーキテクチャウォークスルー・PR ツアーを求める
- ユーザーが「X がどう動くか説明して」と言い、再利用可能なガイド付きアーティファクトを望む
- ユーザーが新エンジニアやレビューアのランプアップパスを望む
- フラットな要約よりガイドシーケンスがタスクに適している

例:
- 新メンテナのオンボーディング
- 1 つのサービスやパッケージのアーキテクチャツアー
- 変更ファイルにアンカーされた PR レビューウォークスルー
- 失敗パスを示す RCA ツアー
- 信頼境界と主要チェックのセキュリティレビューツアー

## 利用しないタイミング

| code-tour の代わりに | 使うもの |
| --- | --- |
| 1 回限りのチャットでの説明で十分 | 直接答える |
| ユーザーが `.tour` アーティファクトではなく散文ドキュメントを望む | `documentation-lookup` またはリポジトリドキュメント編集 |
| タスクが実装やリファクタリング | 実装作業を行う |
| タスクがツアーアーティファクトなしの広範なコードベースオンボーディング | `codebase-onboarding` |

## ワークフロー

### 1. 発見

何かを書く前にリポジトリを探索する:
- README とパッケージ/アプリのエントリポイント
- フォルダ構造
- 関連する設定ファイル
- ツアーが PR 重点なら変更ファイル

コードの形を理解する前にステップを書き始めないこと。

### 2. 読者を推測する

リクエストからペルソナと深度を決定する。

| リクエスト形状 | ペルソナ | 推奨深度 |
| --- | --- | --- |
| 「オンボーディング」「新人」 | `new-joiner` | 9-13 ステップ |
| 「クイックツアー」「vibe check」 | `vibecoder` | 5-8 ステップ |
| 「アーキテクチャ」 | `architect` | 14-18 ステップ |
| 「この PR をツアー」 | `pr-reviewer` | 7-11 ステップ |
| 「なぜこれが壊れたか」 | `rca-investigator` | 7-11 ステップ |
| 「セキュリティレビュー」 | `security-reviewer` | 7-11 ステップ |
| 「この機能がどう動くか説明」 | `feature-explainer` | 7-11 ステップ |
| 「このパスをデバッグ」 | `bug-fixer` | 7-11 ステップ |

### 3. アンカーを読んで検証する

すべてのファイルパスと行アンカーは実在しなければならない:
- ファイルが存在することを確認
- 行番号が範囲内であることを確認
- selection を使う場合、正確なブロックを検証
- ファイルが揮発性ならパターンベースのアンカーを優先

決して行番号を推測しない。

### 4. `.tour` を書く

以下に書く:

```text
.tours/<persona>-<focus>.tour
```

パスを決定論的で読みやすく保つ。

### 5. 検証

完了前に:
- 参照されるすべてのパスが存在する
- すべての行や selection が有効
- 最初のステップが実ファイルやディレクトリにアンカーされている
- ツアーがファイルリストではなく首尾一貫したストーリーを語る

## ステップタイプ

### Content

控えめに、通常はクロージングステップのみに使う:

```json
{ "title": "Next Steps", "description": "You can now trace the request path end to end." }
```

最初のステップを content のみにしない。

### Directory

モジュールへ読者を案内するために使う:

```json
{ "directory": "src/services", "title": "Service Layer", "description": "The core orchestration logic lives here." }
```

### File + line

これがデフォルトのステップタイプ:

```json
{ "file": "src/auth/middleware.ts", "line": 42, "title": "Auth Gate", "description": "Every protected request passes here first." }
```

### Selection

ファイル全体よりも 1 つのコードブロックが重要なときに使う:

```json
{
  "file": "src/core/pipeline.ts",
  "selection": {
    "start": { "line": 15, "character": 0 },
    "end": { "line": 34, "character": 0 }
  },
  "title": "Request Pipeline",
  "description": "This block wires validation, auth, and downstream execution."
}
```

### Pattern

正確な行がドリフトしうるときに使う:

```json
{ "file": "src/app.ts", "pattern": "export default class App", "title": "Application Entry" }
```

### URI

PR・issue・ドキュメントに役立つときに使う:

```json
{ "uri": "https://github.com/org/repo/pull/456", "title": "The PR" }
```

## ライティングルール: SMIG

各 description は以下に答えるべきである:
- **Situation**: 読者が何を見ているか
- **Mechanism**: それがどう動くか
- **Implication**: このペルソナにとってなぜ重要か
- **Gotcha**: 賢い読者が見逃しうるもの

description はコンパクト・具体的・実コードに根ざしたものに保つ。

## ナラティブ形状

タスクが明らかに何か別のものを必要としない限り、このアークを使う:
1. オリエンテーション
2. モジュールマップ
3. 中核実行パス
4. エッジケースまたは gotcha
5. クロージング / 次の動き

ツアーはインベントリではなくパスのように感じるべきである。

## 例

```json
{
  "$schema": "https://aka.ms/codetour-schema",
  "title": "API Service Tour",
  "description": "Walkthrough of the request path for the payments service.",
  "ref": "main",
  "steps": [
    {
      "directory": "src",
      "title": "Source Root",
      "description": "All runtime code for the service starts here."
    },
    {
      "file": "src/server.ts",
      "line": 12,
      "title": "Entry Point",
      "description": "The server boots here and wires middleware before any route is reached."
    },
    {
      "file": "src/routes/payments.ts",
      "line": 8,
      "title": "Payment Routes",
      "description": "Every payments request enters through this router before hitting service logic."
    },
    {
      "title": "Next Steps",
      "description": "You can now follow any payment request end to end with the main anchors in place."
    }
  ]
}
```

## アンチパターン

| アンチパターン | 修正 |
| --- | --- |
| フラットなファイルリスト | ステップ間に依存性のあるストーリーを語る |
| 汎用的な description | 具体的なコードパスやパターンを名指す |
| 推測されたアンカー | すべてのファイルと行を最初に検証する |
| クイックツアーに対するステップ数が多すぎる | 積極的にカットする |
| 最初のステップが content のみ | 最初のステップを実ファイルやディレクトリにアンカーする |
| ペルソナミスマッチ | 一般的なエンジニアではなく実際の読者向けに書く |

## ベストプラクティス

- ステップ数をリポジトリサイズとペルソナ深度に比例させる
- オリエンテーションには directory ステップ、実体には file ステップを使う
- PR ツアーでは、変更ファイルを最初にカバーする
- モノレポでは、すべてをツアーするのではなく関連パッケージにスコープする
- 振り返りではなく、読者が今できることでクローズする

## 関連スキル

- `codebase-onboarding`
- `coding-standards`
- `council`
- 公式アップストリームフォーマット: `microsoft/codetour`
