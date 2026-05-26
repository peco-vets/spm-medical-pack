---
name: plan-orchestrate
description: 計画ドキュメントを読み、ステップに分解し、ECC カタログからステップごとのエージェントチェーンを設計し、ペースト可能な /orchestrate カスタムプロンプトを発行する。生成のみ — /orchestrate 自体を呼び出すことはない。マルチステップ計画があり、チェーンを手で組まずに orchestrate で駆動したい場合に使用 (Read a plan document, decompose into steps, design per-step agent chain from ECC catalogue, emit ready-to-paste /orchestrate custom prompts; generative only)。
origin: ECC
---

# Plan Orchestrate

計画ドキュメントを `/orchestrate custom` に橋渡しし、ステップごとに 1 つのペースト可能呼び出しを発行する。スキルは生成のみ — `/orchestrate` を決して実行しない。ユーザーは準備ができたら各行をペーストする。

## 起動するタイミング

- ユーザーがマルチステップ計画ドキュメント (PRD、RFC、実装計画) を持ち、`/orchestrate` で駆動したい場合
- ユーザーが「orchestrate this plan」、「give me orchestrate prompts for each step」、「compose chains for this plan」と発言
- ステップバイステップ計画は存在するが、ユーザーがステップごとにエージェントを手動で選びたくない

スキップする場合:
- 作業が 1 つのアドホックステップ → `/orchestrate custom` を直接呼ぶ
- 計画が読めないか空。明示的な番号付けの欠如だけではスキップ条件にならない — 以下の「明確なステップなし」エッジケースを参照

## 入力

```
<plan-doc-path> [--lang=python|typescript|go|rust|cpp|java|kotlin|flutter|auto] [--scope=all|step:<n>|range:<a>-<b>] [--dry-run]
```

- `<plan-doc-path>` — 必須。相対または絶対パス (`@docs/...` 受け入れ)
- `--lang` — レビュアー言語バリアント。デフォルトは `auto` (プロジェクトから検出)
- `--scope` — 発行されるステップを制限。デフォルトは `all`
- `--dry-run` — 分解 + チェーン根拠のみを出力。最終プロンプトは発行しない

## 権威ある `/orchestrate` 形状 (逸脱しない)

```
{ORCH_CMD} custom "<agent1>,<agent2>,...,<agentN>" "<task description>"
```

ここで `{ORCH_CMD}` はフェーズ 0 で決定される (以下参照)。発行された出力内のコマンド文字列は **常に 1 つの具体的形式を使う** — 両方を使わず、プレースホルダを使わない。

- `custom` はシーケンシャルチェーン。各エージェントの HANDOFF が次に供給される
- カンマ区切りエージェントリスト。スペースなしを優先、1 スペースは許容
- `--mode` / `--gate` / `--agents=...` フラグは存在しない — 決して発明しない
- エージェント名はこのスキルのカタログから来る。タスク説明内の埋め込まれたダブルクォートは `\"` としてエスケープする

## ECC インストール形式と名前空間

2 つのインストール形式が **両方の** スラッシュコマンドとすべてのエージェント名のプレフィックスを決定する。2 つは同期を維持しなければならない — 出力ごとに 1 つの形式、決して混在させない:

`<claude-home>` を Claude Code ホームディレクトリとする: macOS/Linux では `~/.claude`、Windows では `%USERPROFILE%\.claude`。ホストプラットフォームがユーザーホームディレクトリを解決するのと同じ方法で解決する (`~` をハードコードしない)。

| 形式 | 検出 | `{ORCH_CMD}` | エージェント名形式 |
|---|---|---|---|
| プラグインインストール (1.9.0+) | `<claude-home>/plugins/marketplaces/everything-claude-code/` が存在 | `/everything-claude-code:orchestrate` | `everything-claude-code:<name>` |
| レガシー素のインストール | 上記が不在。エージェントファイルが `<claude-home>/agents/` 以下 | `/orchestrate` | `<name>` |

なぜこれが重要か: プラグインインストール下では、エージェントは `everything-claude-code:tdd-guide` として登録される。素の名前はあいまい一致を強制し、並列呼び出し下で断続的に失敗する。レガシー下では、プレフィックス付き形式は登録されず完全に失敗する。

## 利用可能なエージェントカタログ (これらから選ぶ必要がある)

一般:
- `planner` — 要件再記述、リスク分解、ステップ計画
- `architect` — アーキテクチャ、システム設計、リファクタリング提案
- `tdd-guide` — テスト記述 → 実装 → 80% 以上カバレッジ
- `code-reviewer` — 汎用コードレビュー
- `security-reviewer` — セキュリティ監査、OWASP、シークレットリーク
- `refactor-cleaner` — デッドコード、重複、knip クラスクリーンアップ
- `doc-updater` — ドキュメント、コードマップ、README
- `docs-lookup` — サードパーティライブラリ API ルックアップ (Context7)
- `e2e-runner` — エンドツーエンドテストオーケストレーション
- `database-reviewer` — PostgreSQL スキーマ、マイグレーション、パフォーマンス
- `harness-optimizer` — ローカルエージェントハーネス設定
- `loop-operator` — 長時間実行自律ループ
- `chief-of-staff` — マルチチャネルトリアージ (計画ステップにはほとんど適合しない)

ビルドエラー解決:
- `build-error-resolver` (汎用) / `cpp-build-resolver` / `go-build-resolver` / `java-build-resolver` / `kotlin-build-resolver` / `rust-build-resolver` / `pytorch-build-resolver`

コードレビュアー:
- `python-reviewer` / `typescript-reviewer` / `go-reviewer` / `rust-reviewer` / `cpp-reviewer` / `java-reviewer` / `kotlin-reviewer` / `flutter-reviewer`

スペルを間違えたエージェント名は `/orchestrate` で失敗する。発行前にこのリストと相互チェックする。

## 動作の仕組み

### フェーズ 0 — ECC モード + 言語を検出

1. `<plan-doc-path>` を読む。欠落または空の場合、報告して停止
2. ECC インストール形式を一度検出し `ECC_MODE` に凍結する。アルゴリズム (順番に実行、最初の一致で停止):
   1. `<claude-home>/plugins/marketplaces/everything-claude-code/` が存在 → `ECC_MODE=plugin`
   2. それ以外で `<claude-home>/agents/` が存在し、少なくとも 1 つの ECC エージェントファイル (例: `tdd-guide.md`、`code-reviewer.md`) を含む → `ECC_MODE=legacy`
   3. それ以外 → デフォルトで `ECC_MODE=legacy`、出力の上部に 1 行の警告を発行: `> Warning: could not detect ECC install; defaulting to legacy form. If you use the plugin install, edit the prefixes manually.`
   4. 両方のマーカーが存在 (混在インストール) する場合、`plugin` が勝つ — プラグイン名前空間はあいまい一致なしにエージェント名を解決する唯一のものである

   この時点から、発行されるすべての行はスラッシュコマンドと **すべての** エージェント名の両方で一致するプレフィックスを使う。**同じ出力で両方の形式を発行しない**
3. `--lang` を解決する。`auto` のとき、ポリグロット対応検出を実行:
   - マーカーをプローブ: `pyproject.toml` / `uv.lock` / `requirements.txt` → python; `package.json` → typescript; `go.mod` → go; `Cargo.toml` → rust; `CMakeLists.txt` またはトップレベル `*.cpp` → cpp; `pom.xml` / `build.gradle` (Java) → java; `build.gradle.kts` またはトップレベル Kotlin → kotlin; `pubspec.yaml` → flutter
   - **ポリグロットタイブレーク**: 複数のマーカーが一致する場合、ソースファイル数が他より多い言語を選ぶ (`git ls-files` 経由でカウント、`vendor/`、`node_modules/`、`dist/`、`build/`、`.venv/`、生成ファイル、明らかなテストフィクスチャを除外)。同点または言語がソースファイルの 60% を超えない場合、`lang=unknown` に設定
   - マーカーが一致しない → `lang=unknown` に設定
   - `lang=unknown` はセンチネルである — エージェント名では **ない**。フェーズ 2 ルール 4 と 5 はチェーン構成時に `code-reviewer` / `build-error-resolver` に変換する
4. **PyTorch サブプロファイル** を検出: `lang=python` で、`pyproject.toml` / `requirements.txt` / `uv.lock` のいずれかが `torch` の依存関係を宣言する場合、`pytorch=true` に設定。これは `build` チェーン選択 (以下のフェーズ 2 ルール) のみに影響する。レビュアーは `python-reviewer` のままである
5. **計画で宣言されたエージェント名を正規化**: 計画テキストがエージェントをプラグインプレフィックス形式 (例: `everything-claude-code:tdd-guide`) で参照する場合、検証またはチェーン構成前にプレフィックスを削除して素のカタログ名を取得する。再プレフィックスは出力時の `ECC_MODE` ごと (フェーズ 4) のみに発生する。プレフィックス付き名をチェーン構成に流させない — プラグインモードで二重プレフィックスになる

### フェーズ 1 — ステップ分解

優先順位順に「ステップユニット」を識別:

1. 明示的番号付け: `## Step N` / `### Phase N` / `## N. ...` / トップレベル順序付きリスト
2. テーブルの「Step」列
3. `---` 区切りブロックで動詞先頭の見出し
4. それ以外は各 H2 を 1 つのステップとして扱う

ステップごとに `id` (1 ベース)、`title` (≤ 80 文字)、`intent` (1〜3 文)、`tags` を抽出する。

### フェーズ 2 — タグ付けとチェーン選択

意図でタグ付け (マルチタグ可。チェーンは primary + 積み重ねられた secondaries から構築):

以下のトリガー語は大文字小文字を区別せずに一致する。意味がリストされた英語トリガー語に合致する限り、任意の言語の語幹を一致させることでマルチリンガル計画がサポートされる。

| タグ | トリガー語 | デフォルトチェーン |
|---|---|---|
| `design` | architecture、design、choose、evaluate、RFC | `planner,architect` |
| `plan` | plan、breakdown、milestone | `planner` |
| `impl` | implement、build、add、create、port | `tdd-guide,<lang>-reviewer` |
| `test` | test、coverage、e2e、integration | `tdd-guide,e2e-runner` |
| `refactor` | refactor、cleanup、dedupe、split | `architect,refactor-cleaner,<lang>-reviewer` |
| `migration` | migrate、upgrade、rewrite、port | `architect,tdd-guide,<lang>-reviewer` |
| `db` | schema、migration、index、SQL、Postgres、alembic、sqlmodel | `database-reviewer,<lang>-reviewer` |
| `security` | encrypt、auth、secret、OWASP、PII | `security-reviewer,<lang>-reviewer` |
| `build` | build、compile、lint failure、CI | `<lang>-build-resolver` (`build-error-resolver` にフォールバック) |
| `docs` | docs、readme、codemap、changelog | `doc-updater` |
| `lookup` | lookup、reference、API usage | `docs-lookup` |
| `review` | review、audit、verify | `<lang>-reviewer,code-reviewer` |
| `loop` | loop、autonomous、watchdog | `loop-operator` |

チェーン構成ルール:
1. **Primary タグ選択**: ステップが複数のタグに一致するとき、**テーブル順で最初** (テーブルの上 = 最高優先度) が primary。残りは secondaries。構成ルール 2 と 3 は特定のマルチタグ組み合わせを明示的に処理する。それ以外はタグテーブル順で secondary チェーンを追加
2. `impl` + `security` → `tdd-guide,<lang>-reviewer,security-reviewer`
3. `impl` + `db` → `tdd-guide,database-reviewer,<lang>-reviewer`
4. 結果のチェーンを **重複排除** (最初の出現を保持)。例: `review` + `lang=unknown` はルール 5 後 `code-reviewer,code-reviewer` を生む。重複排除でこれを `code-reviewer` に折りたたむ
5. `lang=unknown` のとき `<lang>-reviewer` は `code-reviewer` に解決する
6. `lang=unknown` のとき `<lang>-build-resolver` は `build-error-resolver` に解決する。**特殊ケース**: フェーズ 0 が `pytorch=true` を設定した場合、`<lang>` に関係なく `build` チェーンに `pytorch-build-resolver` を使う。`python-build-resolver` は存在しない。`pytorch=true` なしの `--lang=python` は `build-error-resolver` に解決する
7. **ゼロタグステップ**: トリガー語が一致しない場合、チェーンを `code-reviewer` に設定し、"Chain rationale" に `no tag matched; default review-only chain` と書く
8. 重複排除後のチェーン長 ≤ 4。超過する場合、最弱のタグを最初にドロップ (`lookup` と `docs` が最初)
9. `impl` チェーンで `planner` と `architect` をペアにしない (トークン浪費)。`design` ステップでのみペアにする
10. `impl`、`refactor`、または `migration` でタグ付けされたステップは **reviewer クラス** エージェントで終わる — `<lang>-reviewer`、`code-reviewer`、`security-reviewer`、または `database-reviewer` のいずれか。最もドメイン固有のレビュアーがテール位置を取る (例: ルール 2 の `impl+security` は `security-reviewer` で終わる。ルール 3 の `impl+db` は `<lang>-reviewer` で終わる、なぜなら `database-reviewer` は既にチェーン早期でマイグレーションをゲートしているから)。`test` と `build` ステップは独自のバリデータ (`e2e-runner` とビルドリゾルバそれぞれ) によってゲートされ、追加のレビュアーは不要

### フェーズ 3 — タスク説明の圧縮

各発行 `<task description>` は以下を満たす必要がある:
- 自己完結 (最初のエージェントが計画ドキュメントを開く必要がない)
- `[Plan: <path>#step-<id>]` で始まる
- 1〜3 つの検証可能な受け入れ基準を含む
- **計画がこのステップに対して宣言する場合のみ** Scope ガード (`Out of scope: ...`) を含む。逐語的に継承する。計画にスコープ外ステートメントがない場合、句を完全に省略する — 発明しない
- 200〜600 文字。1 行。埋め込まれた `"` は `\"` としてエスケープ。リテラル改行なし

### フェーズ 4 — 出力

**`ECC_MODE` で決定された形式** を使って Markdown を発行する。出力は全体を通して 1 つの形式を使う — すべての `{ORCH_CMD}` とすべてのエージェント名はフェーズ 0 の一致するプレフィックスで描画される。**両方の形式を発行しない。レンダリングされた出力に "this is plugin form" / "strip the prefix" 指示を含めない**

具体的なレンダリングルール:

- `{ORCH_CMD}` = `plugin` 下で `/everything-claude-code:orchestrate`、`legacy` 下で `/orchestrate`
- `{AGENT(name)}` = `plugin` 下で `everything-claude-code:<name>`、`legacy` 下で `<name>`
- 概要テーブルの「Chain」列は同じ `{AGENT(name)}` レンダリングを使う
- ステップごとの bash ブロックには実行可能コマンドのみを含む。**`# plugin form` や `# legacy form` コメントなし** — 形式は暗黙的で出力全体で均一

出力構造:

````markdown
# Plan-Orchestrate Result

**Plan**: `<path>`
**Lang**: `<detected-or-given>`
**ECC mode**: `<plugin | legacy>`
**Steps**: <N>
**Scope**: <all | step:n | range:a-b>

## Steps overview

| # | Title | Tags | Chain |
|---|---|---|---|
| 1 | ... | impl, db | `{AGENT(tdd-guide)},{AGENT(database-reviewer)},{AGENT(python-reviewer)}` |
| ... | | | |

---

## Step 1 — <title>

**Intent**: <1–3 sentences>
**Tags**: <a, b>
**Chain rationale**: <why this chain; which agent closes the loop>

```bash
{ORCH_CMD} custom "{AGENT(tdd-guide)},{AGENT(database-reviewer)},{AGENT(python-reviewer)}" "[Plan: docs/foo.md#step-1] <compressed task description>; Acceptance: <1–3 items>; Out of scope: <…>"
```
````

> 上記の `{ORCH_CMD}` と `{AGENT(...)}` 記法は、このスキルがランタイムで実行する置換を記述する。実際の発行された Markdown には解決された文字列が含まれ、プレースホルダは決して含まれない。

ユーザーが一度にすべてをペーストできるよう、最終的な "Batch execution" ブロックを順番にすべてのステップのコマンドを集約して追加する。**概要のみモードで Batch ブロックをスキップ** (「大きな計画」エッジケース参照): 概要テーブルのみが発行されている場合、集約するステップごとのコマンドはない。

### フェーズ 5 — セルフチェック (発行前に実行)

- [ ] すべてのチェーン内のすべてのエージェントがカタログから来る (計画に現れた `everything-claude-code:` プレフィックスを削除した後。フェーズ 0 ステップ 5 参照)
- [ ] 解決された `{ORCH_CMD}` と解決されたすべての `{AGENT(...)}` は **同じ** 形式 (`plugin` または `legacy`) を使う — 1 つの出力で混在しない
- [ ] レンダリングされた出力に `# plugin form` / `# legacy form` 注釈と "strip the prefix" 指示が残っていない
- [ ] 発明された `--mode` / `--gate` / `--agents=...` フィールドなし
- [ ] 各タスク説明は単一行、ダブルクォートされ、埋め込み `"` がエスケープされている
- [ ] 各タスク説明は `[Plan: <path>#step-<id>]` で始まり受け入れ (1〜3 アイテム) を含む。`Out of scope:` 句は計画から継承された場合のみ存在する
- [ ] フェーズ 2 重複排除後、どのチェーンにも重複エージェントなし
- [ ] チェーン長 ≤ 4
- [ ] `impl`/`refactor`/`migration` でタグ付けされたステップはレビュアークラスエージェント (`<lang>-reviewer`、`code-reviewer`、`security-reviewer`、または `database-reviewer`) で終わる。`test` と `build` は免除 — フェーズ 2 ルール 10 参照
- [ ] ゼロタグステップは `code-reviewer` を根拠 `no tag matched; default review-only chain` で発行
- [ ] 概要テーブルは `--scope` に関係なく計画のすべてのステップをリストする
- [ ] ステップごとの詳細ブロック数が解決された `--scope` に一致する (`--scope=all` のとき完全な計画。`step:n` で 1 ブロック。`range:a-b` で範囲サイズ)。概要のみモードでは、ステップごとのブロックも Batch ブロックも発行されない

## エッジケース

- **明確なステップなし**: H2/H3 分割を優先する。それでもあいまいなら、ドキュメント概要付きで「no structured steps detected」を報告し、ユーザーに概要で実行するか確認する
- **大きな計画 (>1500 行)**: **概要のみモード** に入る — 概要テーブルのみを発行し、ユーザーに詳細の再実行前に `--scope` で絞り込むよう依頼する。このモードでは、ステップごとの詳細ブロックをスキップし Batch 実行ブロックもスキップする
- **ステップが広すぎる** (例: "complete all backend work"): 単一チェーンを強制しない。N.a と N.b への分割を提案し、分割を提案する
- **計画がエージェントを宣言する** (まれ): まず **`everything-claude-code:` プレフィックスを削除** して素のカタログ名を取得 (フェーズ 0 ステップ 5)、その後カタログに対して検証。無効なエージェントを置き換え、"Chain rationale" で説明。素の名前は出力時に `ECC_MODE` ごとに再プレフィックスされる
- **`--lang=auto` が勝者を選べないポリグロットプロジェクト**: `lang=unknown` を設定。レビュアーは `code-reviewer` に解決し、ビルドリゾルバは `build-error-resolver` に解決。フォールバックを "Chain rationale" で言及する

## 例

### 例 1 — プラグインモード、Python 計画

入力:
```
plan-orchestrate @docs/plan/example-feature.md --lang=python
```

期待される出力の抜粋:
````markdown
## Step 2 — Encrypt sensitive UserProfile fields

**Intent**: Introduce an `EncryptedString` SQLAlchemy type and AES-GCM encrypt `birth_datetime` / `location` before persistence; load the key from an environment variable.
**Tags**: impl, security, db
**Chain rationale**: Security-sensitive write path, so `security-reviewer` closes the chain; `database-reviewer` validates the alembic migration; `python-reviewer` covers typing and PEP 8.

```bash
/everything-claude-code:orchestrate custom "everything-claude-code:tdd-guide,everything-claude-code:database-reviewer,everything-claude-code:python-reviewer,everything-claude-code:security-reviewer" "[Plan: docs/plan/example-feature.md#step-2] Implement EncryptedString SQLAlchemy type and migrate UserProfile.birth_datetime/location columns; key from ENV APP_DB_KEY; Acceptance: encrypt/decrypt roundtrip tests pass; alembic upgrade/downgrade clean on empty DB; no plaintext in DB after migrate; Out of scope: cross-tenant profile sharing logic"
```
````

### 例 2 — レガシーモード、同じステップ

`ECC_MODE=legacy` が検出された場合、同じステップは単一の均一なコマンドとして発行される (プラグインプレフィックス形式は出力のどこにも含まれない):

```bash
/orchestrate custom "tdd-guide,database-reviewer,python-reviewer,security-reviewer" "[Plan: docs/plan/example-feature.md#step-2] ..."
```

上記の 2 つの例は 2 つの異なる環境に対する **2 つの可能な出力** を示している。単一のスキル呼び出しはエンドツーエンドで 1 つだけを生成する。

## 注

- 生成のみ。このスキル内から `/orchestrate` を決して呼び出さない
- タスク説明には計画ドキュメントの言語に合わせる (エージェント名は常に英語のまま)
- ユーザーが明示的に依頼しない限り、出力に "Co-Authored-By" 行や絵文字を挿入しない
