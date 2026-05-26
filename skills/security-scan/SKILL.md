---
name: security-scan
description: AgentShield を使って Claude Code 設定（.claude/ ディレクトリ）のセキュリティ脆弱性、設定ミス、インジェクションリスクをスキャンする（scan .claude/ for security issues with AgentShield）。CLAUDE.md、settings.json、MCP サーバ、フック、エージェント定義をチェックする。
origin: ECC
---

# Security Scan スキル

[AgentShield](https://github.com/affaan-m/agentshield) を使って Claude Code 設定のセキュリティ問題を監査する。

## 起動するタイミング

- 新しい Claude Code プロジェクトのセットアップ
- `.claude/settings.json`、`CLAUDE.md`、MCP 設定の変更後
- 設定変更のコミット前
- 既存の Claude Code 設定を持つ新しいリポジトリへのオンボーディング時
- 定期的なセキュリティ衛生チェック

## スキャン対象

| ファイル | チェック |
|------|--------|
| `CLAUDE.md` | ハードコードシークレット、自動実行指示、プロンプトインジェクションパターン |
| `settings.json` | 過度に許容的な allow リスト、欠落 deny リスト、危険なバイパスフラグ |
| `mcp.json` | リスクのある MCP サーバ、ハードコード環境シークレット、npx サプライチェーンリスク |
| `hooks/` | 補間によるコマンドインジェクション、データ漏洩、サイレントエラー抑制 |
| `agents/*.md` | 制限のないツールアクセス、プロンプトインジェクションサーフェス、モデル仕様欠落 |

## 前提条件

AgentShield をインストールする必要がある。必要に応じてチェック・インストール：

```bash
# Check if installed
npx ecc-agentshield --version

# Install globally (recommended)
npm install -g ecc-agentshield

# Or run directly via npx (no install needed)
npx ecc-agentshield scan .
```

## 使い方

### 基本スキャン

現在のプロジェクトの `.claude/` ディレクトリに対して実行：

```bash
# Scan current project
npx ecc-agentshield scan

# Scan a specific path
npx ecc-agentshield scan --path /path/to/.claude

# Scan with minimum severity filter
npx ecc-agentshield scan --min-severity medium
```

### 出力フォーマット

```bash
# Terminal output (default) — colored report with grade
npx ecc-agentshield scan

# JSON — for CI/CD integration
npx ecc-agentshield scan --format json

# Markdown — for documentation
npx ecc-agentshield scan --format markdown

# HTML — self-contained dark-theme report
npx ecc-agentshield scan --format html > security-report.html
```

### 自動修正

安全な修正を自動的に適用する（自動修正可能とマークされたもののみ）：

```bash
npx ecc-agentshield scan --fix
```

これにより：
- ハードコードシークレットを環境変数参照に置き換える
- ワイルドカード権限をスコープ付きの代替に締める
- 手動のみの提案は決して変更しない

### Opus 4.6 ディープ解析

より深い解析のため敵対的 3 エージェントパイプラインを実行：

```bash
# Requires ANTHROPIC_API_KEY
export ANTHROPIC_API_KEY=your-key
npx ecc-agentshield scan --opus --stream
```

これは以下を実行する：
1. **Attacker（Red Team）** — 攻撃ベクターを見つける
2. **Defender（Blue Team）** — ハードニングを推奨
3. **Auditor（最終判定）** — 両視点を合成

### 安全な設定の初期化

新しい安全な `.claude/` 設定をゼロから足場化：

```bash
npx ecc-agentshield init
```

作成：
- スコープ付き権限と deny リスト付きの `settings.json`
- セキュリティベストプラクティス付きの `CLAUDE.md`
- `mcp.json` プレースホルダ

### GitHub Action

CI パイプラインに追加：

```yaml
- uses: affaan-m/agentshield@v1
  with:
    path: '.'
    min-severity: 'medium'
    fail-on-findings: true
```

## 重要度レベル

| グレード | スコア | 意味 |
|-------|-------|---------|
| A | 90-100 | 安全な設定 |
| B | 75-89 | 軽微な問題 |
| C | 60-74 | 注意が必要 |
| D | 40-59 | 重要なリスク |
| F | 0-39 | クリティカルな脆弱性 |

## 結果の解釈

### Critical 発見（直ちに修正）
- 設定ファイル内のハードコード API キーまたはトークン
- allow リストの `Bash(*)`（制限のないシェルアクセス）
- `${file}` 補間によるフックのコマンドインジェクション
- シェル実行 MCP サーバ

### High 発見（本番前に修正）
- CLAUDE.md の自動実行指示（プロンプトインジェクションベクター）
- 権限の deny リスト欠落
- 不要な Bash アクセスを持つエージェント

### Medium 発見（推奨）
- フックでのサイレントエラー抑制（`2>/dev/null`、`|| true`）
- PreToolUse セキュリティフック欠落
- MCP サーバ設定の `npx -y` 自動インストール

### Info 発見（認識）
- MCP サーバの説明欠落
- 良いプラクティスとして正しくフラグされた禁止指示

## リンク

- **GitHub**：[github.com/affaan-m/agentshield](https://github.com/affaan-m/agentshield)
- **npm**：[npmjs.com/package/ecc-agentshield](https://www.npmjs.com/package/ecc-agentshield)
