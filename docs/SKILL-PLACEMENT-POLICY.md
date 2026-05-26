# スキル配置と Provenance ポリシー

本ドキュメントは生成、インポート、curated スキルがどこに属するか、どう識別されるか、何が出荷されるかを定義する。

## スキル種別と配置

| 種別 | ルートパス | 出荷 | Provenance |
|------|------------|------|------------|
| Curated | `skills/` (repo) | Yes | 不要 |
| Learned | `~/.claude/skills/learned/` | No | 必須 |
| Imported | `~/.claude/skills/imported/` | No | 必須 |
| Evolved | `~/.claude/homunculus/evolved/skills/` (global) または `projects/<hash>/evolved/skills/` (per-project) | No | instinct ソースから継承 |

Curated スキルはリポジトリの `skills/` 配下に存在する。インストールマニフェストは curated パスのみを参照する。生成・インポートスキルはユーザーホームディレクトリ配下に存在し、出荷されない。

## Curated スキル

場所: `skills/<skill-name>/` (ルートに `SKILL.md`)。

- `manifests/install-modules.json` パスに含まれる。
- `scripts/ci/validate-skills.js` で検証される。
- provenance ファイル無し。帰属には SKILL.md frontmatter の `origin` (ECC, community) を使う。

## Learned スキル

場所: `~/.claude/skills/learned/<skill-name>/`。

継続学習 (evaluate-session フック、`/learn` コマンド) により作成される。デフォルトパスは `skills/continuous-learning/config.json` → `learned_skills_path` で設定可能。

- リポジトリ内ではない。出荷されない。
- `SKILL.md` の sibling として `.provenance.json` を持たなければならない。
- ディレクトリが存在するときランタイムでロードされる。

## Imported スキル

場所: `~/.claude/skills/imported/<skill-name>/`。

外部ソース (URL、ファイルコピーなど) からのユーザーインストールスキル。自動インポータはまだ存在しない。配置は規約による。

- リポジトリ内ではない。出荷されない。
- `SKILL.md` の sibling として `.provenance.json` を持たなければならない。

## Evolved スキル (継続学習 v2)

場所: `~/.claude/homunculus/evolved/skills/` (global) または `~/.claude/homunculus/projects/<hash>/evolved/skills/` (per-project)。

クラスタ化された instinct から instinct-cli evolve により生成される。learned/imported とは別個のシステム。

- リポジトリ内ではない。出荷されない。
- ソース instinct から provenance を継承。別個の `.provenance.json` は不要。

## Provenance メタデータ

learned と imported スキルに必須。ファイル: スキルディレクトリ内の `.provenance.json`。

必須フィールド:

| Field | Type | 説明 |
|-------|------|------|
| source | string | 起源 (URL、パス、または識別子) |
| created_at | string | ISO 8601 タイムスタンプ |
| confidence | number | 0-1 |
| author | string | スキルを生成した人または物 |

スキーマ: `schemas/provenance.schema.json`。検証: `scripts/lib/skill-evolution/provenance.js` → `validateProvenance`。

## バリデータ挙動

### validate-skills.js

スコープ: Curated スキルのみ (リポジトリ内 `skills/`)。

- `skills/` が存在しない場合: exit 0 (検証対象無し)。
- 各サブディレクトリ: `SKILL.md` を含む必要があり、空でないこと。
- learned/imported/evolved ルートには触れない。

### validate-install-manifests.js

スコープ: Curated パスのみ。モジュール内の全 `paths` はリポジトリに存在しなければならない。

- 生成/インポートルートはスコープ外。マニフェストは参照しない。
- 欠落パス → エラー。オプショナルパスハンドリング無し。

### 生成ルートを使うスクリプト

`scripts/skills-health.js`、`scripts/lib/skill-evolution/health.js`、セッションフックは `~/.claude/skills/learned` と `~/.claude/skills/imported` を探る。欠落ディレクトリは空として扱われ、エラーは出ない。

## Publishable vs Local-Only

| Publishable | Local-Only |
|-------------|------------|
| `skills/*` (curated) | `~/.claude/skills/learned/*` |
| | `~/.claude/skills/imported/*` |
| | `~/.claude/homunculus/**/evolved/**` |

curated スキルのみがインストールマニフェストに現れ、インストール中にコピーされる。

## 実装ロードマップ

1. ポリシードキュメントと provenance スキーマ (本変更)。
2. learned-skill 書き込みパス (evaluate-session、`/learn` 出力) に provenance 検証を追加し、新 learned スキルが常に `.provenance.json` を得るようにする。
3. instinct-cli evolve を更新し、evolved スキル生成時にオプショナル provenance を書き込む。
4. learned/imported コンテンツを含んではならない任意のリポジトリパス用に `scripts/validate-provenance.js` を CI に追加する (必要なら)。
5. CONTRIBUTING.md またはユーザードキュメントに learned/imported ルートを文書化し、コントリビューターがそれらをコミットしないようにする。
