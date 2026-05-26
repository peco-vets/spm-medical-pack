---
name: gateguard
description: Edit/Write/Bash（MultiEdit を含む）をブロックし、アクション許可前に具体的調査（importer、データスキーマ、ユーザー指示）を要求する事実強制ゲート（GateGuard, fact-forcing gate, pre-action gate）。ゲートなしエージェントに対して +2.25 ポイント測定上の出力品質向上が確認されている。
origin: community
---

# GateGuard — 事実強制プリアクションゲート

編集前に Claude に調査を強制する PreToolUse フックである。自己評価（"Are you sure?"）の代わりに、具体的事実を要求する。調査行為そのものが、自己評価では得られない気付きを生む。

## 起動タイミング

- ファイル編集が複数モジュールに影響するコードベース
- 特定スキーマや日付フォーマットを持つデータファイルを扱うプロジェクト
- AI 生成コードが既存パターンに合致すべきチーム
- Claude が調査せず推測しがちなワークフロー

## 中核コンセプト

LLM の自己評価は機能しない。「ポリシー違反した?」と聞いたら常に "no" が返る。これは実験的に検証されている。

しかし「このモジュールを import しているファイルを全列挙せよ」と聞けば、LLM は Grep と Read を実行せざるを得ない。調査自体が出力を変えるコンテキストを生成する。

**3段階ゲート:**

```
1. DENY  — 最初の Edit/Write/Bash 試行をブロック
2. FORCE — 必要な事実を厳密に指示する
3. ALLOW — 事実提示後にリトライを許可する
```

3段階すべてを行う競合製品はない。多くは deny で止まる。

## 根拠

同一エージェント・同一タスクでの2つの独立 A/B テスト:

| タスク | Gated | Ungated | 差 |
| --- | --- | --- | --- |
| Analytics module | 8.0/10 | 6.5/10 | +1.5 |
| Webhook validator | 10.0/10 | 7.0/10 | +3.0 |
| **平均** | **9.0** | **6.75** | **+2.25** |

両エージェントとも動作しテストに合格するコードを生成する。差は設計の深さである。

## ゲートタイプ

### Edit / MultiEdit ゲート（ファイルごとに最初の編集）

MultiEdit も同一に扱う — バッチ内の各ファイルを個別にゲートする。

```
Before editing {file_path}, present these facts:

1. List ALL files that import/require this file (use Grep)
2. List the public functions/classes affected by this change
3. If this file reads/writes data files, show field names, structure,
   and date format (use redacted or synthetic values, not raw production data)
4. Quote the user's current instruction verbatim
```

### Write ゲート（新規ファイル作成時）

```
Before creating {file_path}, present these facts:

1. Name the file(s) and line(s) that will call this new file
2. Confirm no existing file serves the same purpose (use Glob)
3. If this file reads/writes data files, show field names, structure,
   and date format (use redacted or synthetic values, not raw production data)
4. Quote the user's current instruction verbatim
```

### 破壊的 Bash ゲート（破壊的コマンドごと）

トリガ: `rm -rf`、`git reset --hard`、`git push --force`、`drop table` 等。

```
1. List all files/data this command will modify or delete
2. Write a one-line rollback procedure
3. Quote the user's current instruction verbatim
```

### ルーチン Bash ゲート（セッションに1回）

```
1. The current user request in one sentence
2. What this specific command verifies or produces
```

## クイックスタート

### Option A: ECC フックを使う（インストール不要）

`scripts/hooks/gateguard-fact-force.js` のフックは本プラグインに同梱されている。hooks.json で有効化する。

GateGuard がセットアップや修復作業をブロックする場合は、`ECC_GATEGUARD=off` でセッションを開始する。フックレベル制御には GateGuard フック ID を `ECC_DISABLED_HOOKS` に指定する。

### Option B: 設定付きフルパッケージ

```bash
pip install gateguard-ai
gateguard init
```

これはプロジェクト別設定用に `.gateguard.yml` を追加する（カスタムメッセージ、無視パス、ゲートトグル）。

## アンチパターン

- **自己評価で代用しない。** "Are you sure?" は常に "yes" を返す。実験的に検証済みである
- **データスキーマチェックをスキップしない。** A/B テストの両エージェントが ISO-8601 日付を仮定したが、実データは `%Y/%m/%d %H:%M` を使っていた。データ構造（マスク値で）の確認はこのクラスのバグ全体を防ぐ
- **Bash コマンドすべてをゲートしない。** ルーチン bash はセッションに1回ゲートする。破壊的 bash は毎回ゲートする。このバランスが減速を回避しつつ実リスクを捕捉する

## ベストプラクティス

- ゲートを自然に発火させる。事前にゲート質問へ答えようとしない — 調査自体が品質を改善する
- ゲートメッセージをドメインにカスタマイズする。プロジェクト固有の慣習があればゲートプロンプトに加える
- `.gateguard.yml` で `.venv/`、`node_modules/`、`.git/` などのパスを無視する

## 関連スキル

- `safety-guard` — ランタイム安全チェック（補完的、重複しない）
- `code-reviewer` — 編集後レビュー（GateGuard は編集前調査）
