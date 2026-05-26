---
name: team-builder
description: 並列チームの編成とディスパッチのためのインタラクティブエージェントピッカー（interactive agent picker for composing and dispatching parallel teams）
origin: community
---

# Team Builder

オンデマンドでエージェントチームを閲覧および編成するためのインタラクティブメニュー。フラットまたはドメインサブディレクトリのエージェントコレクションで動作する。

## 使用するタイミング

- 複数のエージェントペルソナ（markdown ファイル）があり、タスクにどれを使うか選びたい
- 異なるドメインからアドホックなチームを編成したい（例：Security + SEO + Architecture）
- 決定する前に利用可能なエージェントを閲覧したい

## 前提条件

エージェントファイルはペルソナプロンプト（アイデンティティ、ルール、ワークフロー、成果物）を含む markdown ファイルである必要がある。最初の `# Heading` はエージェント名として使われ、最初の段落は説明として使われる。

フラットとサブディレクトリレイアウトの両方がサポートされる：

**サブディレクトリレイアウト** — ドメインはフォルダ名から推論される：

```
agents/
├── engineering/
│   ├── security-engineer.md
│   └── software-architect.md
├── marketing/
│   └── seo-specialist.md
└── sales/
    └── discovery-coach.md
```

**フラットレイアウト** — ドメインは共有ファイル名プレフィックスから推論される。プレフィックスが 2+ ファイルで共有されるとドメインとしてカウントされる。ユニークなプレフィックスのファイルは「General」に。注意：アルゴリズムは最初の `-` で分割するので、複数単語のドメイン（例：`product-management`）は代わりにサブディレクトリレイアウトを使うべき：

```
agents/
├── engineering-security-engineer.md
├── engineering-software-architect.md
├── marketing-seo-specialist.md
├── marketing-content-strategist.md
├── sales-discovery-coach.md
└── sales-outbound-strategist.md
```

## 設定

エージェントは 2 つの方法で発見され、エージェント名でマージ・重複排除される：

1. **`claude agents` コマンド**（主要） — `claude agents` を実行して CLI が知るすべてのエージェントを取得する。ユーザーエージェント、プラグインエージェント（例：`everything-claude-code:architect`）、組み込みエージェントを含む。パス設定なしで ECC マーケットプレイスインストールを自動的にカバーする。
2. **ファイル glob**（フォールバック、エージェントコンテンツ読み取り用） — エージェント markdown ファイルは以下から読み取られる：
   - `./agents/**/*.md` + `./agents/*.md` — プロジェクトローカルエージェント
   - `~/.claude/agents/**/*.md` + `~/.claude/agents/*.md` — グローバルユーザーエージェント

名前が衝突したときは早期のソースが優先する：ユーザーエージェント > プラグインエージェント > 組み込みエージェント。ユーザーが指定した場合、代わりにカスタムパスを使える。

## 動作の仕組み

### ステップ 1：利用可能なエージェントを発見

`claude agents` を実行して完全なエージェントリストを取得する。各行をパースする：
- **プラグインエージェント**は `plugin-name:` でプレフィックスされる（例：`everything-claude-code:security-reviewer`）。`:` の後の部分をエージェント名として、プラグイン名をドメインとして使う。
- **ユーザーエージェント**はプレフィックスなし。`~/.claude/agents/` または `./agents/` から対応する markdown ファイルを読み、名前と説明を抽出する。
- **組み込みエージェント**（例：`Explore`、`Plan`）はユーザーが明示的に含めるよう求めない限りスキップされる。

markdown ファイルからロードされたユーザーエージェントには：
- **サブディレクトリレイアウト：** 親フォルダ名からドメインを抽出
- **フラットレイアウト：** すべてのファイル名プレフィックス（最初の `-` の前のテキスト）を収集する。プレフィックスは 2 つ以上のファイル名に現れる場合にのみドメインとして適格（例：`engineering-security-engineer.md` と `engineering-software-architect.md` が両方 `engineering` で始まる → Engineering ドメイン）。ユニークなプレフィックスのファイル（例：`code-reviewer.md`、`tdd-guide.md`）は「General」にグループ化される
- 最初の `# Heading` からエージェント名を抽出する。見出しが見つからなければ、ファイル名から名前を導出する（`.md` を除去、ハイフンをスペースに置き換え、タイトルケース）
- 見出し後の最初の段落から 1 行サマリを抽出する

`claude agents` 実行とファイル位置プロービング後にエージェントが見つからない場合、ユーザーに通知：「No agents found. Run `claude agents` to verify your setup.」次に停止。

### ステップ 2：ドメインメニューを提示

```
Available agent domains:
1. Engineering — Software Architect, Security Engineer
2. Marketing — SEO Specialist
3. Sales — Discovery Coach, Outbound Strategist

Pick domains or name specific agents (e.g., "1,3" or "security + seo"):
```

- エージェントゼロのドメイン（空ディレクトリ）はスキップ
- ドメインごとのエージェント数を表示

### ステップ 3：選択を処理

柔軟な入力を受け入れる：
- 数字：「1,3」は Engineering と Sales のすべてのエージェントを選択
- 名前：「security + seo」は発見されたエージェントに対してファジーマッチ
- 「all from engineering」はそのドメインのすべてのエージェントを選択

5 エージェントを超えて選択された場合、アルファベット順にリストし、ユーザーに絞り込むよう求める：「You selected N agents (max 5). Pick which to keep, or say 'first 5' to use the first five alphabetically.」

選択を確認：
```
Selected: Security Engineer + SEO Specialist
What should they work on? (describe the task):
```

### ステップ 4：エージェントを並列起動

1. 各選択されたエージェントの markdown ファイルを読む
2. まだ提供されていなければタスク記述を求める
3. Agent ツールを使ってすべてのエージェントを並列起動：
   - `subagent_type: "general-purpose"`
   - `prompt: "{agent file content}\n\nTask: {task description}"`
   - 各エージェントは独立して実行 — エージェント間通信は不要
4. エージェントが失敗（エラー、タイムアウト、空の出力）した場合、失敗をインラインで記録（例：「Security Engineer: failed — [reason]」）し、成功したエージェントの結果で続行

### ステップ 5：結果を合成

すべての出力を収集し、統一レポートを提示：
- エージェント別にグループ化された結果
- 合成セクションでハイライト：
  - エージェント間の合意
  - 推奨間の矛盾または緊張
  - 推奨される次のステップ

1 エージェントのみが選択されたら、合成をスキップし出力を直接提示。

## ルール

- **動的発見のみ。** エージェントリストをハードコードしない。ディレクトリ内の新しいファイルはメニューに自動表示される。
- **チームあたり最大 5 エージェント。** 5 を超えるとリターンが減少し過度のトークン使用が生じる。選択時に強制する。
- **並列ディスパッチ。** すべてのエージェントが同時に実行 — Agent ツールの並列呼び出しパターンを使う。
- **TeamCreate ではなく並列 Agent 呼び出し。** このスキルは独立した作業のため並列 Agent ツール呼び出しを使う。TeamCreate（マルチエージェント対話用の Claude Code ツール）はエージェントが討論または互いに応答する必要があるときのみ必要。

## 例

```
User: team builder

Claude:
Available agent domains:
1. Engineering (2) — Software Architect, Security Engineer
2. Marketing (1) — SEO Specialist
3. Sales (4) — Discovery Coach, Outbound Strategist, Proposal Strategist, Sales Engineer
4. Support (1) — Executive Summary

Pick domains or name specific agents:

User: security + seo

Claude:
Selected: Security Engineer + SEO Specialist
What should they work on?

User: Review my Next.js e-commerce site before launch

[Both agents spawn in parallel, each applying their specialty to the codebase]

Claude:
## Security Engineer Findings
- [findings...]

## SEO Specialist Findings
- [findings...]

## Synthesis
Both agents agree on: [...]
Tension: Security recommends CSP that blocks inline styles, SEO needs inline schema markup. Resolution: [...]
Next steps: [...]
```
