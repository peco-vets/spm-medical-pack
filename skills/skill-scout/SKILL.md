---
name: skill-scout
description: 新しいスキルを作る前に、既存のローカル、マーケットプレイス、GitHub、Web のスキルソースを検索する（search existing skill sources before creating a new skill）。ユーザーがワークフロー用のスキルを作成、構築、フォーク、または見つけたいときに使用する。
origin: community
---

# Skill Scout

新しいスキルを作成する前にこのスキルを使う。目的は、既存のコミュニティまたはマーケットプレイス作業を重複させないようにし、採用前に外部のものを審査することである。

ソース：`redminwang` による古いコミュニティ PR #1232 から救出。

## 使用するタイミング

- ユーザーが「create a skill」「build a skill」「make a skill」「new skill」と言う
- ユーザーが「is there a skill for X?」または「does a skill exist that does Y?」と尋ねる
- ユーザーがワークフローを記述し、新しいスキルの作成を提案しようとしている
- ユーザーが既存スキルをフォークまたは拡張したい

ユーザーが明示的に検索をスキップまたはスクラッチから作成すると言った場合、それを認め、要求された作成ワークフローに進む。

## 動作の仕組み

### ステップ 1 - 意図のキャプチャ

抽出する：

- スキルが実行すべきタスク
- 使用するトリガー条件
- 関連するドメイン、ツール、フレームワーク、データソース
- 3〜5 個の検索キーワードと有用な同義語

### ステップ 2 - ローカルソースの検索

最初にインストール済みとマーケットプレイスのスキル名を検索する。ローカルソースはすでにユーザー環境の一部なので優先する。

```bash
find ~/.claude/skills -maxdepth 2 -name SKILL.md 2>/dev/null | grep -iE "keyword|synonym"
find ~/.claude/plugins/marketplaces -path '*/skills/*/SKILL.md' 2>/dev/null | grep -iE "keyword|synonym"
```

次に frontmatter の説明を検索する：

```bash
grep -RilE "keyword|synonym" ~/.claude/skills ~/.claude/plugins/marketplaces 2>/dev/null
```

### ステップ 3 - リモートソースの検索

利用可能な GitHub と Web 検索ツールを使う。簡潔なクエリを推奨：

```bash
gh search repos "claude code skill keyword" --limit 10 --sort stars
gh search code "name: keyword" --filename SKILL.md --limit 10
```

Web 検索には、最大 3 つのターゲットクエリを使う：

```text
"claude code skill" keyword
"SKILL.md" keyword
"everything-claude-code" keyword
```

### ステップ 4 - 外部マッチの審査

採用またはフォークのために外部スキルを推奨する前に：

- `SKILL.md` の frontmatter と指示を読む
- 予期しないシェルコマンド、ファイル書き込み、ネットワーク呼び出し、クレデンシャル処理、パッケージインストールを探す
- リポジトリが保守されているように見えるかチェックする
- マーケットプレイスのオリジナルを編集するより、新しいローカルブランチにコピーして diff をレビューすることを推奨

### ステップ 5 - 結果のランク付け

候補をランク付けする：

1. スキル名での正確なキーワードマッチ
2. 説明でのキーワードまたは同義語マッチ
3. ローカルインストールまたはマーケットプレイスソース
4. 最近のアクティビティがある保守された GitHub ソース
5. Web のみの言及

最終リストは 10 件で上限。

### ステップ 6 - 決定オプションの提示

ユーザーに短いテーブルを与える：

| Option | Meaning |
| --- | --- |
| Use existing | マッチするスキルをそのまま呼び出すまたはインストール |
| Fork or extend | 最も近いスキルをコピーして修正 |
| Create fresh | 近いマッチがないことを確認した後に新しいスキルを構築 |

ユーザーがそのパスを選択した後、または検索が近いマッチを見つけなかった後にのみ新しいスキルを作成する。

## 例

### 結果テーブル

```markdown
| # | Skill | Source | Why it matches | Gap |
| --- | --- | --- | --- | --- |
| 1 | article-writing | Local ECC | Drafts articles and guides | Not focused on release notes |
| 2 | content-engine | Local ECC | Multi-format content workflow | Heavier than needed |
| 3 | blog-writer | GitHub | Blog writing skill with recent commits | Needs security review |
```

### ユーザー向けサマリ

```markdown
I found two close local matches and one external candidate. The closest fit is
`article-writing`; it covers drafting and revision, but it does not include the
release-note checklist you asked for. I can either use it as-is, fork it into a
release-note variant, or create a fresh skill.
```

## アンチパターン

- 検索が合理的なときに新スキル作成に直接ジャンプしない
- 先に読まずに外部スキルをインストールしない
- 弱いマッチの長いランクなしリストを提示しない
- Web のみの言及を信頼できるソースとして扱わない
- インストール済みマーケットプレイスのオリジナルをその場で編集しない

## 関連

- `search-first` - 一般的な構築前検索ワークフロー
- `skill-stocktake` - 健全性、重複、ギャップのためインストール済みスキルを監査
- `agent-sort` - 既存のエージェントとスキルを分類して整理
