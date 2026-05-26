---
name: tdd-workflow
description: 新機能を書く、バグを修正する、コードをリファクタするときにこのスキルを使う（test-driven development with 80%+ coverage including unit, integration, E2E）。ユニット、統合、E2E テストを含む 80% 以上のカバレッジでテスト駆動開発を強制する。
origin: ECC
---

# テスト駆動開発ワークフロー

このスキルは、すべてのコード開発が包括的テストカバレッジ付きの TDD 原則に従うことを保証する。

## 起動するタイミング

- 新機能または機能性の作成
- バグまたは問題の修正
- 既存コードのリファクタリング
- API エンドポイントの追加
- 新コンポーネントの作成

## コア原則

### 1. コードより前にテスト
常に最初にテストを書き、次にテストを通すコードを実装する。

### 2. カバレッジ要件
- 最低 80% カバレッジ（ユニット + 統合 + E2E）
- すべてのエッジケースをカバー
- エラーシナリオがテストされる
- 境界条件が検証される

### 3. テストタイプ

#### ユニットテスト
- 個別の関数とユーティリティ
- コンポーネントロジック
- 純粋関数
- ヘルパーとユーティリティ

#### 統合テスト
- API エンドポイント
- データベース操作
- サービス相互作用
- 外部 API 呼び出し

#### E2E テスト（Playwright）
- クリティカルなユーザーフロー
- 完全なワークフロー
- ブラウザ自動化
- UI インタラクション

### 4. Git チェックポイント
- リポジトリが Git 配下なら、各 TDD ステージ後にチェックポイントコミットを作成する
- ワークフロー完了まで、これらのチェックポイントコミットを squash や rewrite しない
- 各チェックポイントコミットメッセージはステージとキャプチャされた正確なエビデンスを記述する
- 現在のタスクの現在のアクティブブランチ上に作成されたコミットのみカウントする
- 他のブランチ、以前の無関係な作業、または遠いブランチ履歴からのコミットを有効なチェックポイントエビデンスとして扱わない
- チェックポイントが満たされたとみなす前に、コミットがアクティブブランチの現在の `HEAD` から到達可能で、現在のタスクシーケンスに属することを検証する
- 推奨されるコンパクトなワークフローは：
  - 失敗テスト追加と RED 検証のため 1 コミット
  - 最小修正適用と GREEN 検証のため 1 コミット
  - リファクタ完了のためのオプションコミット 1 つ
- テストコミットが RED に明確に対応し、修正コミットが GREEN に明確に対応するなら、別個のエビデンスのみのコミットは不要

## TDD ワークフローステップ

### ステップ 1：ユーザージャーニーを書く
```
As a [role], I want to [action], so that [benefit]

Example:
As a user, I want to search for markets semantically,
so that I can find relevant markets even without exact keywords.
```

### ステップ 2：テストケースを生成する
各ユーザージャーニーに対して包括的なテストケースを作成：

```typescript
describe('Semantic Search', () => {
  it('returns relevant markets for query', async () => {
    // Test implementation
  })

  it('handles empty query gracefully', async () => {
    // Test edge case
  })

  it('falls back to substring search when Redis unavailable', async () => {
    // Test fallback behavior
  })

  it('sorts results by similarity score', async () => {
    // Test sorting logic
  })
})
```

### ステップ 3：テストを実行（失敗するはず）
```bash
npm test
# Tests should fail - we haven't implemented yet
```

このステップは必須で、すべての本番変更の RED ゲート。

ビジネスロジックや他の本番コードを変更する前に、これらのパスのいずれかで有効な RED 状態を検証する必要がある：
- ランタイム RED：
  - 関連テストターゲットがコンパイル成功
  - 新規または変更されたテストが実際に実行される
  - 結果が RED
- コンパイル時 RED：
  - 新テストがバギーなコードパスを新たにインスタンス化、参照、または実行する
  - コンパイル失敗自体が意図された RED シグナル
- いずれの場合も、失敗は意図されたビジネスロジックバグ、未定義動作、または欠落実装によって引き起こされる
- 失敗は無関係な構文エラー、壊れたテストセットアップ、欠落依存、または無関係なリグレッションによってのみ引き起こされない

書かれたがコンパイルおよび実行されていないテストは RED としてカウントされない。

この RED 状態が確認されるまで本番コードを編集しない。

リポジトリが Git 配下なら、このステージが検証された直後にチェックポイントコミットを作成する。
推奨コミットメッセージフォーマット：
- `test: add reproducer for <feature or bug>`
- このコミットは、再現が意図された理由でコンパイル・実行・失敗した場合、RED 検証チェックポイントとしても機能できる
- 続行前にこのチェックポイントコミットが現在のアクティブブランチ上にあることを検証する

### ステップ 4：コードを実装
テストを通すための最小コードを書く：

```typescript
// Implementation guided by tests
export async function searchMarkets(query: string) {
  // Implementation here
}
```

リポジトリが Git 配下なら、最小修正をステージしておくが、ステップ 5 で GREEN が検証されるまでチェックポイントコミットは延期する。

### ステップ 5：テストを再実行
```bash
npm test
# Tests should now pass
```

修正後に同じ関連テストターゲットを再実行し、以前失敗したテストが GREEN になったことを確認する。

有効な GREEN 結果の後にのみリファクタに進める。

リポジトリが Git 配下なら、GREEN 検証直後にチェックポイントコミットを作成する。
推奨コミットメッセージフォーマット：
- `fix: <feature or bug>`
- 同じ関連テストターゲットが再実行されパスした場合、修正コミットは GREEN 検証チェックポイントとしても機能できる
- 続行前にこのチェックポイントコミットが現在のアクティブブランチ上にあることを検証する

### ステップ 6：リファクタ
テストをグリーンに保ちながらコード品質を改善：
- 重複を削除
- 命名を改善
- パフォーマンスを最適化
- 可読性を向上

リポジトリが Git 配下なら、リファクタリング完了後でテストが緑のままの直後にチェックポイントコミットを作成する。
推奨コミットメッセージフォーマット：
- `refactor: clean up after <feature or bug> implementation`
- TDD サイクル完了とみなす前にこのチェックポイントコミットが現在のアクティブブランチ上にあることを検証する

### ステップ 7：カバレッジを検証
```bash
npm run test:coverage
# Verify 80%+ coverage achieved
```

## テストパターン

### ユニットテストパターン（Jest/Vitest）
```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Button Component', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click</Button>)

    fireEvent.click(screen.getByRole('button'))

    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Click</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})
```

### API 統合テストパターン
```typescript
import { NextRequest } from 'next/server'
import { GET } from './route'

describe('GET /api/markets', () => {
  it('returns markets successfully', async () => {
    const request = new NextRequest('http://localhost/api/markets')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(Array.isArray(data.data)).toBe(true)
  })

  it('validates query parameters', async () => {
    const request = new NextRequest('http://localhost/api/markets?limit=invalid')
    const response = await GET(request)

    expect(response.status).toBe(400)
  })

  it('handles database errors gracefully', async () => {
    // Mock database failure
    const request = new NextRequest('http://localhost/api/markets')
    // Test error handling
  })
})
```

### E2E テストパターン（Playwright）
```typescript
import { test, expect } from '@playwright/test'

test('user can search and filter markets', async ({ page }) => {
  // Navigate to markets page
  await page.goto('/')
  await page.click('a[href="/markets"]')

  // Verify page loaded
  await expect(page.locator('h1')).toContainText('Markets')

  // Search for markets
  await page.fill('input[placeholder="Search markets"]', 'election')

  // Wait for debounce and results
  await page.waitForTimeout(600)

  // Verify search results displayed
  const results = page.locator('[data-testid="market-card"]')
  await expect(results).toHaveCount(5, { timeout: 5000 })

  // Verify results contain search term
  const firstResult = results.first()
  await expect(firstResult).toContainText('election', { ignoreCase: true })

  // Filter by status
  await page.click('button:has-text("Active")')

  // Verify filtered results
  await expect(results).toHaveCount(3)
})

test('user can create a new market', async ({ page }) => {
  // Login first
  await page.goto('/creator-dashboard')

  // Fill market creation form
  await page.fill('input[name="name"]', 'Test Market')
  await page.fill('textarea[name="description"]', 'Test description')
  await page.fill('input[name="endDate"]', '2025-12-31')

  // Submit form
  await page.click('button[type="submit"]')

  // Verify success message
  await expect(page.locator('text=Market created successfully')).toBeVisible()

  // Verify redirect to market page
  await expect(page).toHaveURL(/\/markets\/test-market/)
})
```

## テストファイル構成

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx          # Unit tests
│   │   └── Button.stories.tsx       # Storybook
│   └── MarketCard/
│       ├── MarketCard.tsx
│       └── MarketCard.test.tsx
├── app/
│   └── api/
│       └── markets/
│           ├── route.ts
│           └── route.test.ts         # Integration tests
└── e2e/
    ├── markets.spec.ts               # E2E tests
    ├── trading.spec.ts
    └── auth.spec.ts
```

## 外部サービスのモック

### Supabase モック
```typescript
jest.mock('@/lib/supabase', () => ({
  supabase: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => Promise.resolve({
          data: [{ id: 1, name: 'Test Market' }],
          error: null
        }))
      }))
    }))
  }
}))
```

### Redis モック
```typescript
jest.mock('@/lib/redis', () => ({
  searchMarketsByVector: jest.fn(() => Promise.resolve([
    { slug: 'test-market', similarity_score: 0.95 }
  ])),
  checkRedisHealth: jest.fn(() => Promise.resolve({ connected: true }))
}))
```

### OpenAI モック
```typescript
jest.mock('@/lib/openai', () => ({
  generateEmbedding: jest.fn(() => Promise.resolve(
    new Array(1536).fill(0.1) // Mock 1536-dim embedding
  ))
}))
```

## テストカバレッジ検証

### カバレッジレポート実行
```bash
npm run test:coverage
```

### カバレッジ閾値
```json
{
  "jest": {
    "coverageThresholds": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

## 避けるべき一般的なテストミス

### FAIL：WRONG：実装詳細をテスト
```typescript
// Don't test internal state
expect(component.state.count).toBe(5)
```

### PASS：CORRECT：ユーザーから見える振る舞いをテスト
```typescript
// Test what users see
expect(screen.getByText('Count: 5')).toBeInTheDocument()
```

### FAIL：WRONG：脆いセレクタ
```typescript
// Breaks easily
await page.click('.css-class-xyz')
```

### PASS：CORRECT：セマンティックセレクタ
```typescript
// Resilient to changes
await page.click('button:has-text("Submit")')
await page.click('[data-testid="submit-button"]')
```

### FAIL：WRONG：テスト分離なし
```typescript
// Tests depend on each other
test('creates user', () => { /* ... */ })
test('updates same user', () => { /* depends on previous test */ })
```

### PASS：CORRECT：独立したテスト
```typescript
// Each test sets up its own data
test('creates user', () => {
  const user = createTestUser()
  // Test logic
})

test('updates user', () => {
  const user = createTestUser()
  // Update logic
})
```

## 継続テスト

### 開発中のウォッチモード
```bash
npm test -- --watch
# Tests run automatically on file changes
```

### Pre-Commit フック
```bash
# Runs before every commit
npm test && npm run lint
```

### CI/CD 統合
```yaml
# GitHub Actions
- name: Run Tests
  run: npm test -- --coverage
- name: Upload Coverage
  uses: codecov/codecov-action@v3
```

## ベストプラクティス

1. **テストを先に書く** - 常に TDD
2. **テストごとに 1 つのアサート** - 単一の振る舞いに焦点
3. **記述的なテスト名** - 何がテストされているかを説明
4. **Arrange-Act-Assert** - 明確なテスト構造
5. **外部依存をモック** - ユニットテストを分離
6. **エッジケースをテスト** - null、undefined、空、大きい
7. **エラーパスをテスト** - ハッピーパスだけではない
8. **テストを高速に保つ** - ユニットテストは各 < 50ms
9. **テスト後にクリーンアップ** - 副作用なし
10. **カバレッジレポートをレビュー** - ギャップを特定

## 成功メトリック

- 80%+ コードカバレッジ達成
- すべてのテストが合格（緑）
- スキップまたは無効化されたテストなし
- 高速なテスト実行（ユニットテストは < 30 秒）
- E2E テストがクリティカルなユーザーフローをカバー
- テストが本番前にバグを捕捉

---

**覚えておくこと**：テストはオプションではない。それらは自信のあるリファクタリング、迅速な開発、本番信頼性を可能にするセーフティネットである。
