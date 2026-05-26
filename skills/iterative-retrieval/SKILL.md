---
name: iterative-retrieval
description: サブエージェントコンテキスト問題を解決するため、コンテキスト取得を段階的に精緻化するパターン（iterative retrieval, context refinement, multi-agent context problem）。
origin: ECC
---

# 反復取得パターン

サブエージェントが作業開始まで何のコンテキストが必要かを知らない、マルチエージェントワークフローでの「コンテキスト問題」を解決する。

## 起動タイミング

- 事前予測できないコードベースコンテキストが必要なサブエージェントの生成
- コンテキストが段階的に精緻化されるマルチエージェントワークフロー構築
- エージェントタスクで「context too large」または「missing context」失敗に遭遇
- コード探索向け RAG ライクな取得パイプラインの設計
- エージェントオーケストレーションでのトークン使用最適化

## 問題

サブエージェントは限られたコンテキストで生成される。以下を知らない:
- どのファイルに関連コードが含まれるか
- コードベースにどんなパターンが存在するか
- プロジェクトがどんな用語を使うか

標準アプローチは失敗する:
- **すべて送る**: コンテキスト上限超過
- **何も送らない**: エージェントがクリティカル情報を欠く
- **必要なものを推測する**: しばしば誤り

## 解決策: 反復取得

コンテキストを段階的に精緻化する 4 フェーズループ:

```
┌─────────────────────────────────────────────┐
│                                             │
│   ┌──────────┐      ┌──────────┐            │
│   │ DISPATCH │─────│ EVALUATE │            │
│   └──────────┘      └──────────┘            │
│        ▲                  │                 │
│        │                  ▼                 │
│   ┌──────────┐      ┌──────────┐            │
│   │   LOOP   │─────│  REFINE  │            │
│   └──────────┘      └──────────┘            │
│                                             │
│        Max 3 cycles, then proceed           │
└─────────────────────────────────────────────┘
```

### Phase 1: DISPATCH

候補ファイル収集のための初期広範クエリ:

```javascript
// Start with high-level intent
const initialQuery = {
  patterns: ['src/**/*.ts', 'lib/**/*.ts'],
  keywords: ['authentication', 'user', 'session'],
  excludes: ['*.test.ts', '*.spec.ts']
};

// Dispatch to retrieval agent
const candidates = await retrieveFiles(initialQuery);
```

### Phase 2: EVALUATE

取得コンテンツの関連性を評価:

```javascript
function evaluateRelevance(files, task) {
  return files.map(file => ({
    path: file.path,
    relevance: scoreRelevance(file.content, task),
    reason: explainRelevance(file.content, task),
    missingContext: identifyGaps(file.content, task)
  }));
}
```

スコア基準:
- **High (0.8-1.0)**: 対象機能を直接実装
- **Medium (0.5-0.7)**: 関連パターンや型を含む
- **Low (0.2-0.4)**: 接線的に関連
- **None (0-0.2)**: 無関係、除外

### Phase 3: REFINE

評価に基づき検索条件を更新:

```javascript
function refineQuery(evaluation, previousQuery) {
  return {
    // Add new patterns discovered in high-relevance files
    patterns: [...previousQuery.patterns, ...extractPatterns(evaluation)],

    // Add terminology found in codebase
    keywords: [...previousQuery.keywords, ...extractKeywords(evaluation)],

    // Exclude confirmed irrelevant paths
    excludes: [...previousQuery.excludes, ...evaluation
      .filter(e => e.relevance < 0.2)
      .map(e => e.path)
    ],

    // Target specific gaps
    focusAreas: evaluation
      .flatMap(e => e.missingContext)
      .filter(unique)
  };
}
```

### Phase 4: LOOP

精緻化条件で繰り返す（最大 3 サイクル）:

```javascript
async function iterativeRetrieve(task, maxCycles = 3) {
  let query = createInitialQuery(task);
  let bestContext = [];

  for (let cycle = 0; cycle < maxCycles; cycle++) {
    const candidates = await retrieveFiles(query);
    const evaluation = evaluateRelevance(candidates, task);

    // Check if we have sufficient context
    const highRelevance = evaluation.filter(e => e.relevance >= 0.7);
    if (highRelevance.length >= 3 && !hasCriticalGaps(evaluation)) {
      return highRelevance;
    }

    // Refine and continue
    query = refineQuery(evaluation, query);
    bestContext = mergeContext(bestContext, highRelevance);
  }

  return bestContext;
}
```

## 実用例

### 例 1: バグ修正コンテキスト

```
Task: "Fix the authentication token expiry bug"

Cycle 1:
  DISPATCH: Search for "token", "auth", "expiry" in src/**
  EVALUATE: Found auth.ts (0.9), tokens.ts (0.8), user.ts (0.3)
  REFINE: Add "refresh", "jwt" keywords; exclude user.ts

Cycle 2:
  DISPATCH: Search refined terms
  EVALUATE: Found session-manager.ts (0.95), jwt-utils.ts (0.85)
  REFINE: Sufficient context (2 high-relevance files)

Result: auth.ts, tokens.ts, session-manager.ts, jwt-utils.ts
```

### 例 2: 機能実装

```
Task: "Add rate limiting to API endpoints"

Cycle 1:
  DISPATCH: Search "rate", "limit", "api" in routes/**
  EVALUATE: No matches - codebase uses "throttle" terminology
  REFINE: Add "throttle", "middleware" keywords

Cycle 2:
  DISPATCH: Search refined terms
  EVALUATE: Found throttle.ts (0.9), middleware/index.ts (0.7)
  REFINE: Need router patterns

Cycle 3:
  DISPATCH: Search "router", "express" patterns
  EVALUATE: Found router-setup.ts (0.8)
  REFINE: Sufficient context

Result: throttle.ts, middleware/index.ts, router-setup.ts
```

## エージェントとの統合

エージェントプロンプトで使う:

```markdown
When retrieving context for this task:
1. Start with broad keyword search
2. Evaluate each file's relevance (0-1 scale)
3. Identify what context is still missing
4. Refine search criteria and repeat (max 3 cycles)
5. Return files with relevance >= 0.7
```

## ベストプラクティス

1. **広範から始め、段階的に絞る** — 初期クエリを過剰特定しない
2. **コードベース用語を学ぶ** — 最初のサイクルが命名規則を明らかにすることが多い
3. **欠落を追跡する** — 明示的なギャップ特定が精緻化を駆動する
4. **「十分良い」で止める** — 高関連 3 ファイル > 中庸 10 ファイル
5. **自信を持って除外する** — 低関連ファイルは関連にならない

## 関連

- [The Longform Guide](https://x.com/affaanmustafa/status/2014040193557471352) — サブエージェントオーケストレーションセクション
- `continuous-learning` スキル — 時系列で改善するパターン向け
- ECC に同梱されるエージェント定義（手動インストールパス: `agents/`）
