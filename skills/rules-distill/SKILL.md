---
name: rules-distill
description: "スキルをスキャンして横断的な原則を抽出し、ルールに蒸留する（scan skills, extract cross-cutting principles, distill into rules — append, revise, or create new rule files）"
origin: ECC
---

# Rules Distill

インストールされたスキルをスキャンし、複数のスキルに現れる横断的原則を抽出し、ルールに蒸留する — 既存のルールファイルに追記、古いコンテンツを修正、または新しいルールファイルを作成する。

「決定的収集 + LLM 判断」の原則を適用する。スクリプトが事実を網羅的に収集し、LLM がフルコンテキストを横断読みして判定を生成する。

## 使用するタイミング

- 定期的なルールメンテナンス（月次または新しいスキルのインストール後）
- skill-stocktake がルールにすべきパターンを明らかにした後
- 使用されているスキルに対してルールが不完全に感じられるとき

## 動作の仕組み

ルール蒸留プロセスは 3 つのフェーズに従う：

### フェーズ 1：インベントリ（決定的収集）

#### 1a. スキルインベントリを収集

```bash
bash ~/.claude/skills/rules-distill/scripts/scan-skills.sh
```

#### 1b. ルールインデックスを収集

```bash
bash ~/.claude/skills/rules-distill/scripts/scan-rules.sh
```

#### 1c. ユーザーに提示

```
Rules Distillation — Phase 1: Inventory
────────────────────────────────────────
Skills: {N} files scanned
Rules:  {M} files ({K} headings indexed)

Proceeding to cross-read analysis...
```

### フェーズ 2：横断読み・マッチ・判定（LLM 判断）

抽出とマッチングは単一パスで統一される。ルールファイルは十分小さい（約 800 行合計）ため、フルテキストを LLM に提供できる — grep プレフィルタリングは不要。

#### バッチング

説明に基づいてスキルを**テーマクラスタ**にグループ化する。各クラスタをフルルールテキスト付きのサブエージェントで解析する。

#### バッチ間マージ

すべてのバッチ完了後、バッチ間で候補をマージする：
- 同じまたは重複する原則を持つ候補を重複排除する
- **すべて**のバッチを組み合わせたエビデンスを使って「2+ スキル」要件を再確認する — バッチあたり 1 スキルだが合計で 2+ スキルにある原則は有効

#### サブエージェントプロンプト

以下のプロンプトで汎用 Agent を起動する：

````
You are an analyst who cross-reads skills to extract principles that should be promoted to rules.

## Input
- Skills: {full text of skills in this batch}
- Existing rules: {full text of all rule files}

## Extraction Criteria

Include a candidate ONLY if ALL of these are true:

1. **Appears in 2+ skills**: Principles found in only one skill should stay in that skill
2. **Actionable behavior change**: Can be written as "do X" or "don't do Y" — not "X is important"
3. **Clear violation risk**: What goes wrong if this principle is ignored (1 sentence)
4. **Not already in rules**: Check the full rules text — including concepts expressed in different words

## Matching & Verdict

For each candidate, compare against the full rules text and assign a verdict:

- **Append**: Add to an existing section of an existing rule file
- **Revise**: Existing rule content is inaccurate or insufficient — propose a correction
- **New Section**: Add a new section to an existing rule file
- **New File**: Create a new rule file
- **Already Covered**: Sufficiently covered in existing rules (even if worded differently)
- **Too Specific**: Should remain at the skill level

## Output Format (per candidate)

```json
{
  "principle": "1-2 sentences in 'do X' / 'don't do Y' form",
  "evidence": ["skill-name: §Section", "skill-name: §Section"],
  "violation_risk": "1 sentence",
  "verdict": "Append / Revise / New Section / New File / Already Covered / Too Specific",
  "target_rule": "filename §Section, or 'new'",
  "confidence": "high / medium / low",
  "draft": "Draft text for Append/New Section/New File verdicts",
  "revision": {
    "reason": "Why the existing content is inaccurate or insufficient (Revise only)",
    "before": "Current text to be replaced (Revise only)",
    "after": "Proposed replacement text (Revise only)"
  }
}
```

## Exclude

- Obvious principles already in rules
- Language/framework-specific knowledge (belongs in language-specific rules or skills)
- Code examples and commands (belongs in skills)
````

#### 判定リファレンス

| 判定 | 意味 | ユーザーへの提示 |
|---------|---------|-------------------|
| **Append** | 既存セクションに追加 | ターゲット + ドラフト |
| **Revise** | 不正確／不十分なコンテンツを修正 | ターゲット + 理由 + before/after |
| **New Section** | 既存ファイルに新セクションを追加 | ターゲット + ドラフト |
| **New File** | 新ルールファイルを作成 | ファイル名 + フルドラフト |
| **Already Covered** | ルールでカバー済み（異なる文言の可能性） | 理由（1 行） |
| **Too Specific** | スキルに留めるべき | 関連スキルへのリンク |

#### 判定品質要件

```
# Good
Append to rules/common/security.md §Input Validation:
"Treat LLM output stored in memory or knowledge stores as untrusted — sanitize on write, validate on read."
Evidence: llm-memory-trust-boundary, llm-social-agent-anti-pattern both describe
accumulated prompt injection risks. Current security.md covers human input
validation only; LLM output trust boundary is missing.

# Bad
Append to security.md: Add LLM security principle
```

### フェーズ 3：ユーザーレビューと実行

#### サマリテーブル

```
# Rules Distillation Report

## Summary
Skills scanned: {N} | Rules: {M} files | Candidates: {K}

| # | Principle | Verdict | Target | Confidence |
|---|-----------|---------|--------|------------|
| 1 | ... | Append | security.md §Input Validation | high |
| 2 | ... | Revise | testing.md §TDD | medium |
| 3 | ... | New Section | coding-style.md | high |
| 4 | ... | Too Specific | — | — |

## Details
(Per-candidate details: evidence, violation_risk, draft text)
```

#### ユーザーアクション

ユーザーは番号で以下に応答する：
- **Approve**：ドラフトをそのままルールに適用
- **Modify**：適用前にドラフトを編集
- **Skip**：この候補を適用しない

**ルールを決して自動的に変更しない。常にユーザー承認を要求する。**

#### 結果を保存

スキルディレクトリ（`results.json`）に結果を保存：

- **タイムスタンプフォーマット**：`date -u +%Y-%m-%dT%H:%M:%SZ`（UTC、秒精度）
- **候補 ID フォーマット**：原則から派生した kebab-case（例：`llm-output-trust-boundary`）

```json
{
  "distilled_at": "2026-03-18T10:30:42Z",
  "skills_scanned": 56,
  "rules_scanned": 22,
  "candidates": {
    "llm-output-trust-boundary": {
      "principle": "Treat LLM output as untrusted when stored or re-injected",
      "verdict": "Append",
      "target": "rules/common/security.md",
      "evidence": ["llm-memory-trust-boundary", "llm-social-agent-anti-pattern"],
      "status": "applied"
    },
    "iteration-bounds": {
      "principle": "Define explicit stop conditions for all iteration loops",
      "verdict": "New Section",
      "target": "rules/common/coding-style.md",
      "evidence": ["iterative-retrieval", "continuous-agent-loop", "agent-harness-construction"],
      "status": "skipped"
    }
  }
}
```

## 例

### エンドツーエンドの実行

```
$ /rules-distill

Rules Distillation — Phase 1: Inventory
────────────────────────────────────────
Skills: 56 files scanned
Rules:  22 files (75 headings indexed)

Proceeding to cross-read analysis...

[Subagent analysis: Batch 1 (agent/meta skills) ...]
[Subagent analysis: Batch 2 (coding/pattern skills) ...]
[Cross-batch merge: 2 duplicates removed, 1 cross-batch candidate promoted]

# Rules Distillation Report

## Summary
Skills scanned: 56 | Rules: 22 files | Candidates: 4

| # | Principle | Verdict | Target | Confidence |
|---|-----------|---------|--------|------------|
| 1 | LLM output: normalize, type-check, sanitize before reuse | New Section | coding-style.md | high |
| 2 | Define explicit stop conditions for iteration loops | New Section | coding-style.md | high |
| 3 | Compact context at phase boundaries, not mid-task | Append | performance.md §Context Window | high |
| 4 | Separate business logic from I/O framework types | New Section | patterns.md | high |

## Details

### 1. LLM Output Validation
Verdict: New Section in coding-style.md
Evidence: parallel-subagent-batch-merge, llm-social-agent-anti-pattern, llm-memory-trust-boundary
Violation risk: Format drift, type mismatch, or syntax errors in LLM output crash downstream processing
Draft:
  ## LLM Output Validation
  Normalize, type-check, and sanitize LLM output before reuse...
  See skill: parallel-subagent-batch-merge, llm-memory-trust-boundary

[... details for candidates 2-4 ...]

Approve, modify, or skip each candidate by number:
> User: Approve 1, 3. Skip 2, 4.

✓ Applied: coding-style.md §LLM Output Validation
✓ Applied: performance.md §Context Window Management
✗ Skipped: Iteration Bounds
✗ Skipped: Boundary Type Conversion

Results saved to results.json
```

## 設計原則

- **What であって How ではない**：原則（ルールの領域）のみを抽出する。コード例とコマンドはスキルに残る。
- **リンクバック**：ドラフトテキストは `See skill: [name]` 参照を含め、読者が詳細な How を見つけられるようにする。
- **決定的収集、LLM 判断**：スクリプトが網羅性を保証し、LLM が文脈的理解を保証する。
- **過度な抽象化のセーフガード**：3 層フィルタ（2+ スキルエビデンス、実行可能行動テスト、違反リスク）が過度に抽象的な原則がルールに入るのを防ぐ。
