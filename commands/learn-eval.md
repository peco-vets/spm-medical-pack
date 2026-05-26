---
description: "セッションから再利用可能なパターンを抽出し、保存前に品質を自己評価し、適切な保存場所（Global vs Project）を決定する / Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project)."
---

# /learn-eval - Extract, Evaluate, then Save

`/learn` を拡張し、品質ゲート、保存場所の決定、ナレッジ配置の認識を含めてから、任意のスキルファイルを書き込む。

## 抽出するもの

以下を探す：

1. **エラー解決パターン** — 根本原因 + 修正 + 再利用可能性
2. **デバッグ技法** — 自明でないステップ、ツールの組み合わせ
3. **ワークアラウンド** — ライブラリの癖、API の制限、バージョン固有の修正
4. **プロジェクト固有パターン** — 規約、アーキテクチャ決定、統合パターン

## プロセス

1. 抽出可能なパターンについてセッションをレビューする
2. 最も価値があり再利用可能な洞察を特定する

3. **保存場所を決定する：**
   - 質問する：「このパターンは別のプロジェクトでも有用か？」
   - **Global** (`~/.claude/skills/learned/`)：2つ以上のプロジェクトで使えるジェネリックなパターン（bash 互換性、LLM API 動作、デバッグ技法など）
   - **Project** (現在のプロジェクトの `.claude/skills/learned/`)：プロジェクト固有の知識（特定の設定ファイルの癖、プロジェクト固有のアーキテクチャ決定など）
   - 迷ったら Global を選ぶ（Global → Project への移動は逆より簡単）

4. このフォーマットを使ってスキルファイルをドラフトする：

```markdown
---
name: pattern-name
description: "Under 130 characters"
user-invocable: false
origin: auto-extracted
---

# [Descriptive Pattern Name]

**Extracted:** [Date]
**Context:** [Brief description of when this applies]

## Problem
[What problem this solves - be specific]

## Solution
[The pattern/technique/workaround - with code examples]

## When to Use
[Trigger conditions]
```

5. **品質ゲート — チェックリスト + 総合的判定**

   ### 5a. 必須チェックリスト（実際にファイルを読んで検証）

   ドラフトを評価する前に、以下の**すべて**を実行する：

   - [ ] `~/.claude/skills/` および関連するプロジェクトの `.claude/skills/` ファイルを keyword で grep して内容の重複を確認する
   - [ ] MEMORY.md（プロジェクトおよびグローバル両方）の重複を確認する
   - [ ] 既存のスキルへの追記で十分か検討する
   - [ ] これが一度限りの修正ではなく、再利用可能なパターンであることを確認する

   ### 5b. 総合的判定

   チェックリストの結果とドラフトの品質を統合し、以下から**1つ**を選択する：

   | 判定 | 意味 | 次のアクション |
   |---------|---------|-------------|
   | **Save** | ユニークで、具体的で、スコープが適切 | Step 6 へ進む |
   | **Improve then Save** | 価値はあるが洗練が必要 | 改善点をリスト → 改訂 → 再評価（1回） |
   | **Absorb into [X]** | 既存スキルに追記すべき | 対象スキルと追記内容を表示 → Step 6 |
   | **Drop** | 些末、冗長、または抽象的すぎる | 理由を説明して停止 |

**ガイドライン次元**（判定を伝えるが、スコアリングしない）：

- **Specificity & Actionability**：すぐに使えるコード例やコマンドを含む
- **Scope Fit**：名前、トリガー条件、内容が単一のパターンに焦点が合っている
- **Uniqueness**：既存スキルでカバーされない価値を提供する（チェックリスト結果に基づく）
- **Reusability**：将来のセッションに現実的なトリガーシナリオが存在する

6. **判定固有の確認フロー**

- **Improve then Save**：必要な改善点 + 改訂ドラフト + 1回の再評価後の更新チェックリスト/判定を提示；改訂判定が **Save** ならユーザー確認後に保存、それ以外なら新しい判定に従う
- **Save**：保存パス + チェックリスト結果 + 1行の判定理由 + 完全なドラフトを提示 → ユーザー確認後に保存
- **Absorb into [X]**：対象パス + 追記内容（diff 形式）+ チェックリスト結果 + 判定理由を提示 → ユーザー確認後に追記
- **Drop**：チェックリスト結果と理由のみ表示（確認は不要）

7. 決定された場所に保存／取り込む

## Step 5 の出力フォーマット

```
### Checklist
- [x] skills/ grep: no overlap (or: overlap found → details)
- [x] MEMORY.md: no overlap (or: overlap found → details)
- [x] Existing skill append: new file appropriate (or: should append to [X])
- [x] Reusability: confirmed (or: one-off → Drop)

### Verdict: Save / Improve then Save / Absorb into [X] / Drop

**Rationale:** (1-2 sentences explaining the verdict)
```

## 設計の根拠

このバージョンは、以前の5次元の数値スコアリングルーブリック（Specificity、Actionability、Scope Fit、Non-redundancy、Coverage を 1-5 でスコアリング）を、チェックリストベースの総合的判定システムに置き換える。最新のフロンティアモデル（Opus 4.6+）は強いコンテキスト判断力を持っており、豊かな質的シグナルを数値スコアに押し込めるとニュアンスが失われ、誤解を招く合計を生む可能性がある。総合的アプローチは、モデルがすべての要因を自然に重み付けすることを許し、明示的なチェックリストがクリティカルなチェックがスキップされないことを保証しながら、より正確な save/drop 決定を生成する。

## 注意事項

- 些末な修正（タイプミス、単純な構文エラー）を抽出しない
- 一度限りの問題（特定の API ダウンなど）を抽出しない
- 将来のセッションで時間を節約するパターンに焦点を当てる
- スキルを焦点を絞ったものに保つ — 1スキルにつき1パターン
- 判定が Absorb の場合、新しいファイルを作るのではなく既存スキルに追記する
