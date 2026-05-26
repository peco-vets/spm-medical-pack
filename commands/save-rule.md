---
description: ごうさんが「これルール化したい」と思った時、CLAUDE.md にルールを即座に追記する（手動キャプチャ用）。引数にルール本文を渡すか、引数なしで対話的に入力。カテゴリ（コーディング規約・API ルール・セキュリティ・医療法対応・UI/UX・パフォーマンス・デバッグ・その他）も指定可能。
argument-hint: <ルール本文> [--category <カテゴリ>]
allowed-tools: ["Bash", "Read", "Edit", "Write"]
---

# /save-rule — CLAUDE.md にルールを即座追記

ごうさんが開発中に「これは恒久ルールにしたい」と思った時のキャプチャコマンド。CLAUDE.md（`~/.claude/CLAUDE.md` のシンボリックリンク先 = Google Drive 上の実体）に直接追記する。

## 使い方

```
/save-rule TypeScript で any 型禁止
/save-rule API ルートには必ず JWT 認証ミドルウェア --category セキュリティ
/save-rule 診療録の物理削除禁止（論理削除のみ）--category 医療法対応
```

## 実行手順

引数 `$ARGUMENTS` から：
1. ルール本文を抽出
2. `--category <カテゴリ>` 指定があれば該当セクションへ、なければ自動判定または「その他」へ

### Step 1: CLAUDE.md の実体パスを取得
```bash
readlink ~/.claude/CLAUDE.md
```
※ 通常は `/Users/ishiitakeshi/Library/CloudStorage/.../Obsidian Vault/SPM/Claude/CLAUDE.md`

### Step 2: ルール本文と カテゴリ を `$ARGUMENTS` から抽出

引数なしで呼ばれた場合、ごうさんに「どんなルールを追加しますか？」と聞く。

### Step 3: カテゴリの自動判定（カテゴリ未指定時）

ルール本文のキーワードから判定：
- "any 型"、"型"、"interface" → コーディング規約 / TypeScript
- "API"、"認証"、"バリデーション" → API ルール
- "暗号化"、"パスワード"、"監査ログ" → セキュリティ
- "診療"、"カルテ"、"医療"、"飼主" → 医療法対応
- "iPad"、"フォント"、"色"、"UI" → UI/UX
- "クエリ"、"レンダリング"、"キャッシュ" → パフォーマンス
- "console.log"、"警告"、"エラー" → デバッグ
- 上記いずれでもない → その他

### Step 4: CLAUDE.md の該当セクションに追記

該当セクションが既存ならその末尾に1行追加。存在しなければセクション作成。
**必ず Edit で部分追記、Write での全文上書きは禁止**。

各ルール末尾に追記用のメタ情報を1行付ける：
```markdown
- <ルール本文> <!-- added by /save-rule on 2026-MM-DD -->
```

### Step 5: 確認メッセージ

追記後、ごうさんに以下を提示：
```
✅ CLAUDE.md に追加しました（カテゴリ: <カテゴリ>）

追加された行:
  - <ルール本文>

確認: cat ~/.claude/CLAUDE.md | grep "<ルール本文の最初10文字>"
```

## 注意点

- ルールは具体的に書くこと（「セキュリティ大事」ではダメ。「全API POST/PUTでバリデーション必須」のように）
- 既存ルールと矛盾しないかは Claude が事前確認（衝突があれば指摘）
- 追加後 git commit はしない（CLAUDE.md は Google Drive 同期で十分）

## カテゴリ一覧（参考）

| カテゴリ | 該当する CLAUDE.md セクション |
|---|---|
| コーディング規約 / TypeScript | `## コーディング規約 / TypeScript` |
| API ルール | `## APIルール` |
| セキュリティ | `## セキュリティルール（必ず守ること）` |
| UI/UX | `## UI/UXルール` |
| 医療法対応 | `## 医療法対応原則（必ず守る）` |
| パフォーマンス | `## パフォーマンスルール` |
| デバッグ | `## デバッグルール` |
| その他 | `## その他のルール`（無ければ作成）|

## 関連

- [[/distill-recent-session]] — セッション終了後の自動抽出版
- [[/distill-weekly]] — 週次バッチ抽出版
