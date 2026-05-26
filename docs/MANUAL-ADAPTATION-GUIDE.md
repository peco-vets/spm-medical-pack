# 非ネイティブハーネス向け手動適応ガイド

`.claude/`、`.codex/`、`.opencode/`、`.cursor/`、または `.agent/` レイアウトをネイティブにロードしないハーネス内で ECC 挙動を望む場合に、本ガイドを使う。

これは Grok や他のチャット型インターフェースのように、システムプロンプト、アップロードファイル、貼り付け指示を受け取れるが、リポジトリのネイティブインストールサーフェスを直接実行できないツール向けのフォールバックパスである。

## 使うタイミング

ターゲットハーネスが以下の場合に手動適応を使う:

- リポジトリフォルダを自動ロードしない
- カスタムスラッシュコマンドをサポートしない
- フックをサポートしない
- リポジトリローカルスキルアクティベーションをサポートしない
- 部分的または全くファイルシステム/ツールアクセスが無い

ファーストクラス ECC ターゲットが存在するときは常にそちらを優先する:

- Claude Code
- Codex
- Cursor
- OpenCode
- CodeBuddy
- Antigravity

非ネイティブハーネスで ECC 挙動が必要な場合にのみ本ガイドを使う。

## 何を再現するか

ECC を手動で適応するとき、4 つのことを保持しようとしている:

1. リポジトリ全体をダンプするのではなく、焦点化されたコンテキスト。
2. モデルがワークフローを推測することを期待するのではなく、スキルアクティベーションキュー。
3. ハーネスにスラッシュコマンドシステムが無くてもコマンド意図。
4. ハーネスにネイティブ自動化が無くてもフック規律。

リポジトリのすべてのファイルをミラーしようとしているわけではない。最小限のコンテキストバンドルで有用な挙動を再現しようとしている。

## ECC ネイティブフォールバック

リポジトリ自体からの手動選択をデフォルトとする。

実際に必要なファイルのみから始める:

- 1 つの言語またはフレームワークスキル
- 1 つのワークフロースキル
- タスクが専門的なら 1 つのドメインスキル
- ハーネスが明示的オーケストレーションから恩恵を受ける場合にのみ 1 つのエージェントまたはコマンド

最小限の良い例:

- Python 機能作業:
  - `skills/python-patterns/SKILL.md`
  - `skills/tdd-workflow/SKILL.md`
  - `skills/verification-loop/SKILL.md`
- TypeScript API 作業:
  - `skills/backend-patterns/SKILL.md`
  - `skills/security-review/SKILL.md`
  - `skills/tdd-workflow/SKILL.md`
- コンテンツ/アウトバウンド作業:
  - `skills/brand-voice/SKILL.md`
  - `skills/content-engine/SKILL.md`
  - `skills/crosspost/SKILL.md`

ハーネスがファイルアップロードをサポートするなら、それらのファイルのみをアップロードする。

ハーネスが貼り付けコンテキストのみをサポートするなら、生のフルファイルではなく、関連セクションを抽出して圧縮バンドルを貼り付ける。

## 手動コンテキストパッキング

これを行うのに追加ツールは必要無い。

リポジトリを直接使う:

```bash
cd /path/to/everything-claude-code

sed -n '1,220p' skills/tdd-workflow/SKILL.md > /tmp/ecc-context.md
printf '\n\n---\n\n' >> /tmp/ecc-context.md
sed -n '1,220p' skills/backend-patterns/SKILL.md >> /tmp/ecc-context.md
printf '\n\n---\n\n' >> /tmp/ecc-context.md
sed -n '1,220p' skills/security-review/SKILL.md >> /tmp/ecc-context.md
```

パッキング前に正しいスキルを識別するために `rg` も使える:

```bash
rg -n "When to use|Use when|Trigger" skills -g 'SKILL.md'
```

オプション: `repomix` のようなリポジトリパッカを既に使っている場合、選択されたファイルを 1 つの引き継ぎドキュメントに圧縮するのに役立つ。これは便利ツールであり、canonical な ECC パスではない。

## 圧縮ルール

別のハーネス用に ECC を手動でパッキングする際:

- タスクフレーミングを保つ
- アクティベーション条件を保つ
- ワークフローステップを保つ
- クリティカルな例を保つ
- まず繰り返し散文を削除する
- 次に無関係なバリアントを削除する
- 1 つか 2 つのスキルで十分な場合、ディレクトリ全体を貼り付けない

より厳密なプロンプト形式が必要なら、本質的部分をコンパクトな構造化ブロックに変換する:

```xml
<skill name="tdd-workflow">
  <when>New feature, bug fix, or refactor that should be test-first.</when>
  <steps>
    <step>Write a failing test.</step>
    <step>Make it pass with the smallest change.</step>
    <step>Refactor and rerun validation.</step>
  </steps>
</skill>
```

## コマンドの再現

ハーネスにスラッシュコマンドシステムが無い場合、システムプロンプトまたはセッション前置きに小さなコマンドレジストリを定義する。

例:

```text
Command registry:
- /plan -> use planner-style reasoning, produce a short execution plan, then act
- /tdd -> follow the tdd-workflow skill
- /review -> switch into code-review mode and enumerate findings first
- /verify -> run a verification loop before claiming completion
```

実際のコマンドを実装しているわけではない。ECC 挙動にマップする明示的呼び出しハンドルをハーネスに与えている。

## フックの再現

ハーネスにネイティブフックが無い場合、フック意図を常時指示に移す。

例:

```text
Before writing code:
1. Check whether a relevant skill should be activated.
2. Check for security-sensitive changes.
3. Prefer tests before implementation when feasible.

Before finalizing:
1. Re-read the user request.
2. Verify the main changed paths.
3. State what was actually validated and what was not.
```

これは真の自動化を再現しないが、ECC の運用規律を捕捉する。

## ハーネス機能マトリクス

| 機能 | ファーストクラス ECC ターゲット | 手動適応ターゲット |
| --- | --- | --- |
| フォルダベースインストール | ネイティブ | 不可 |
| スラッシュコマンド | ネイティブ | プロンプトでシミュレート |
| フック | ネイティブ | プロンプトでシミュレート |
| スキルアクティベーション | ネイティブ | 手動 |
| リポジトリローカルツーリング | ネイティブ | ハーネス依存 |
| コンテキストパッキング | オプション | 必須 |

## 実用 Grok 様セットアップ

1. 最小限の有用バンドルを選ぶ。
2. 選択された ECC スキルファイルを 1 つのアップロードまたは貼り付けブロックにパックする。
3. 短いコマンドレジストリを追加する。
4. 常時「フック意図」指示を追加する。
5. 1 つのタスクから始め、スケールアップする前にハーネスがワークフローに従うことを検証する。

スターター前置きの例:

```text
You are operating with a manually adapted ECC bundle.

Active skills:
- backend-patterns
- tdd-workflow
- security-review

Command registry:
- /plan
- /tdd
- /verify

Before writing code, follow the active skill instructions.
Before finalizing, verify what changed and report any remaining gaps.
```

## 制限事項

手動適応は有用だが、ネイティブターゲットと比較すると依然として二級である。

失うもの:

- 自動インストールと同期
- ネイティブフック実行
- 真のコマンドプラミング
- ランタイムでの信頼できるスキル発見
- 組み込みマルチエージェント/worktree オーケストレーション

つまりルールは単純である:

- 非ネイティブハーネスに ECC 挙動を運ぶには手動適応を使う
- フルシステムが欲しいときは常にネイティブ ECC ターゲットを使う

## 関連作業

- [Issue #1186](https://github.com/affaan-m/everything-claude-code/issues/1186)
- [Discussion #1077](https://github.com/affaan-m/everything-claude-code/discussions/1077)
- [Antigravity Guide](./ANTIGRAVITY-GUIDE.md)
- [Troubleshooting](./TROUBLESHOOTING.md)
