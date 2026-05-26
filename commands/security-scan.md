---
description: エージェント、フック、MCP、パーミッション、シークレットの surface に対して AgentShield を実行する / Run AgentShield against agent, hook, MCP, permission, and secret surfaces.
agent: everything-claude-code:security-reviewer
subtask: true
---

# Security Scan Command

現在のプロジェクトまたはターゲットパスに対して AgentShield を実行し、発見事項を優先順位付き修復計画に変える。

## Usage

`/security-scan [path] [--format text|json|markdown|html] [--min-severity low|medium|high|critical] [--fix]`

- `path`（任意）：現在のプロジェクトをデフォルト。`.claude/` パス、リポジトリルート、またはチェックインされたテンプレートディレクトリを使う。
- `--format`：出力形式。CI には `json`、引き継ぎには `markdown`、スタンドアロンレビューレポートには `html` を使う。
- `--min-severity`：低優先度の発見事項をフィルタする。
- `--fix`：安全で自動修正可能としてマークされた AgentShield の修正のみを適用する。

## 決定論的エンジン

パッケージされたスキャナーを優先する：

```bash
npx ecc-agentshield scan --path "${TARGET_PATH:-.}" --format text
```

ローカルの AgentShield 開発では、AgentShield チェックアウトから実行する：

```bash
npm run scan -- --path "${TARGET_PATH:-.}" --format text
```

発見事項を発明しない。AgentShield 出力を真実のソースとして使い、スキャナーの事実をフォローアップ判断から分離する。

## レビューチェックリスト

1. アクティブな実行時の発見事項をまず特定する：
   - ハードコードされたシークレット
   - 広いパーミッション
   - 実行可能フック
   - シェル、ファイルシステム、リモートトランスポート、または unpinned `npx` を持つ MCP サーバー
   - 防御なしで信頼できないコンテンツを処理するエージェントプロンプト
2. 低信頼度のインベントリを分離する：
   - docs の例
   - テンプレート例
   - プラグインマニフェスト
   - プロジェクトローカルの任意設定
3. 各クリティカルまたは高い発見事項について、以下を返す：
   - ファイルパス
   - 重要度
   - 実行時信頼度
   - なぜそれが重要か
   - 正確な修復
   - 自動修正が安全か
4. `--fix` が要求された場合、修正を適用する前に計画された編集を述べる。
5. 修正後にスキャンを再実行し、before/after スコアを報告する。

## 出力契約

以下を返す：

1. セキュリティグレードとスコア。
2. 重要度と実行時信頼度別のカウント。
3. 正確なパス付きのクリティカル/高い発見事項。
4. 別々にグループ化された低信頼度発見事項。
5. 修復順序。
6. 実行されたコマンドと、スキャンがローカルか、CI か、npx ベースか。

## CI パターン

強制ゲートのために GitHub Actions で AgentShield を使う：

```yaml
- uses: affaan-m/agentshield@v1
  with:
    path: "."
    min-severity: "medium"
    fail-on-findings: true
```

## リンク

- Skill: `skills/security-scan/SKILL.md`
- Agent: `agents/security-reviewer.md`
- Scanner: <https://github.com/affaan-m/agentshield>

## 引数

$ARGUMENTS:
- 任意のターゲットパス
- 任意の AgentShield フラグ
