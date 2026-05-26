---
name: ai-regression-testing
description: AI 支援開発のための回帰テスト戦略。データベース依存なしのサンドボックスモード API テスト、自動バグチェックワークフロー、同じモデルがコードを書いてレビューする AI のブラインドスポットを捕捉するパターン (AI regression testing, sandbox mode, bug-check workflow, AI blind spot, vitest)。
origin: ECC
---

# AI 回帰テスト

AI 支援開発のために特別に設計されたテストパターン。同じモデルがコードを書いて自身のレビューを行うため、自動テストでしか捕捉できない体系的なブラインドスポットが生まれる。

## 起動するタイミング

- AI エージェント (Claude Code・Cursor・Codex) が API ルートやバックエンドロジックを変更した
- バグが見つかり修正された — 再導入を防ぐ必要がある
- プロジェクトに DB なしのテストに活用できるサンドボックス/モックモードがある
- コード変更後に `/bug-check` や類似レビューコマンドを実行する
- 複数のコードパスが存在する (サンドボックス対本番・フィーチャーフラグ等)

## 中核となる問題

AI がコードを書いてから自身の作業をレビューするとき、両方のステップに同じ前提を持ち込む。これは予測可能な失敗パターンを生む:

```
AI writes fix → AI reviews fix → AI says "looks correct" → Bug still exists
```

**実例** (本番で観測):

```
Fix 1: Added notification_settings to API response
  → Forgot to add it to the SELECT query
  → AI reviewed and missed it (same blind spot)

Fix 2: Added it to SELECT query
  → TypeScript build error (column not in generated types)
  → AI reviewed Fix 1 but didn't catch the SELECT issue

Fix 3: Changed to SELECT *
  → Fixed production path, forgot sandbox path
  → AI reviewed and missed it AGAIN (4th occurrence)

Fix 4: Test caught it instantly on first run PASS:
```

パターン: **サンドボックス/本番パスの不整合** が AI 導入回帰の第 1 位である。

## サンドボックスモード API テスト

AI フレンドリーなアーキテクチャを持つほとんどのプロジェクトにはサンドボックス/モックモードがある。これが高速で DB 不要な API テストの鍵である。

### セットアップ (Vitest + Next.js App Router)

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    environment: "node",
    globals: true,
    include: ["__tests__/**/*.test.ts"],
    setupFiles: ["__tests__/setup.ts"],
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "."),
    },
  },
});
```

```typescript
// __tests__/setup.ts
// Force sandbox mode — no database needed
process.env.SANDBOX_MODE = "true";
process.env.NEXT_PUBLIC_SUPABASE_URL = "";
process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY = "";
```

### Next.js API ルート用テストヘルパー

```typescript
// __tests__/helpers.ts
import { NextRequest } from "next/server";

export function createTestRequest(
  url: string,
  options?: {
    method?: string;
    body?: Record<string, unknown>;
    headers?: Record<string, string>;
    sandboxUserId?: string;
  },
): NextRequest {
  const { method = "GET", body, headers = {}, sandboxUserId } = options || {};
  const fullUrl = url.startsWith("http") ? url : `http://localhost:3000${url}`;
  const reqHeaders: Record<string, string> = { ...headers };

  if (sandboxUserId) {
    reqHeaders["x-sandbox-user-id"] = sandboxUserId;
  }

  const init: { method: string; headers: Record<string, string>; body?: string } = {
    method,
    headers: reqHeaders,
  };

  if (body) {
    init.body = JSON.stringify(body);
    reqHeaders["content-type"] = "application/json";
  }

  return new NextRequest(fullUrl, init);
}

export async function parseResponse(response: Response) {
  const json = await response.json();
  return { status: response.status, json };
}
```

### 回帰テストの書き方

重要原則: **動くコードのためではなく、見つかったバグのためにテストを書く**。

```typescript
// __tests__/api/user/profile.test.ts
import { describe, it, expect } from "vitest";
import { createTestRequest, parseResponse } from "../../helpers";
import { GET, PATCH } from "@/app/api/user/profile/route";

// Define the contract — what fields MUST be in the response
const REQUIRED_FIELDS = [
  "id",
  "email",
  "full_name",
  "phone",
  "role",
  "created_at",
  "avatar_url",
  "notification_settings",  // ← Added after bug found it missing
];

describe("GET /api/user/profile", () => {
  it("returns all required fields", async () => {
    const req = createTestRequest("/api/user/profile");
    const res = await GET(req);
    const { status, json } = await parseResponse(res);

    expect(status).toBe(200);
    for (const field of REQUIRED_FIELDS) {
      expect(json.data).toHaveProperty(field);
    }
  });

  // Regression test — this exact bug was introduced by AI 4 times
  it("notification_settings is not undefined (BUG-R1 regression)", async () => {
    const req = createTestRequest("/api/user/profile");
    const res = await GET(req);
    const { json } = await parseResponse(res);

    expect("notification_settings" in json.data).toBe(true);
    const ns = json.data.notification_settings;
    expect(ns === null || typeof ns === "object").toBe(true);
  });
});
```

### サンドボックス/本番パリティのテスト

最も一般的な AI 回帰: 本番パスを修正してサンドボックスパスを忘れる (またはその逆)。

```typescript
// Test that sandbox responses match the expected contract
describe("GET /api/user/messages (conversation list)", () => {
  it("includes partner_name in sandbox mode", async () => {
    const req = createTestRequest("/api/user/messages", {
      sandboxUserId: "user-001",
    });
    const res = await GET(req);
    const { json } = await parseResponse(res);

    // This caught a bug where partner_name was added
    // to production path but not sandbox path
    if (json.data.length > 0) {
      for (const conv of json.data) {
        expect("partner_name" in conv).toBe(true);
      }
    }
  });
});
```

## バグチェックワークフローへのテスト統合

### カスタムコマンド定義

```markdown
<!-- .claude/commands/bug-check.md -->
# Bug Check

## Step 1: Automated Tests (mandatory, cannot skip)

Run these commands FIRST before any code review:

    npm run test       # Vitest test suite
    npm run build      # TypeScript type check + build

- If tests fail → report as highest priority bug
- If build fails → report type errors as highest priority
- Only proceed to Step 2 if both pass

## Step 2: Code Review (AI review)

1. Sandbox / production path consistency
2. API response shape matches frontend expectations
3. SELECT clause completeness
4. Error handling with rollback
5. Optimistic update race conditions

## Step 3: For each bug fixed, propose a regression test
```

### ワークフロー

```
User: "バグチェックして" (or "/bug-check")
  │
  ├─ Step 1: npm run test
  │   ├─ FAIL → Bug found mechanically (no AI judgment needed)
  │   └─ PASS → Continue
  │
  ├─ Step 2: npm run build
  │   ├─ FAIL → Type error found mechanically
  │   └─ PASS → Continue
  │
  ├─ Step 3: AI code review (with known blind spots in mind)
  │   └─ Findings reported
  │
  └─ Step 4: For each fix, write a regression test
      └─ Next bug-check catches if fix breaks
```

## よくある AI 回帰パターン

### Pattern 1: サンドボックス/本番パスの不一致

**頻度**: 最も一般的 (4 回中 3 回の回帰で観測)

```typescript
// FAIL: AI adds field to production path only
if (isSandboxMode()) {
  return { data: { id, email, name } };  // Missing new field
}
// Production path
return { data: { id, email, name, notification_settings } };

// PASS: Both paths must return the same shape
if (isSandboxMode()) {
  return { data: { id, email, name, notification_settings: null } };
}
return { data: { id, email, name, notification_settings } };
```

**捕捉するテスト**:

```typescript
it("sandbox and production return same fields", async () => {
  // In test env, sandbox mode is forced ON
  const res = await GET(createTestRequest("/api/user/profile"));
  const { json } = await parseResponse(res);

  for (const field of REQUIRED_FIELDS) {
    expect(json.data).toHaveProperty(field);
  }
});
```

### Pattern 2: SELECT 句の省略

**頻度**: 新しいカラムを追加する際に Supabase/Prisma でよく発生

```typescript
// FAIL: New column added to response but not to SELECT
const { data } = await supabase
  .from("users")
  .select("id, email, name")  // notification_settings not here
  .single();

return { data: { ...data, notification_settings: data.notification_settings } };
// → notification_settings is always undefined

// PASS: Use SELECT * or explicitly include new columns
const { data } = await supabase
  .from("users")
  .select("*")
  .single();
```

### Pattern 3: エラー状態のリーク

**頻度**: 中程度 — 既存コンポーネントへのエラーハンドリング追加時

```typescript
// FAIL: Error state set but old data not cleared
catch (err) {
  setError("Failed to load");
  // reservations still shows data from previous tab!
}

// PASS: Clear related state on error
catch (err) {
  setReservations([]);  // Clear stale data
  setError("Failed to load");
}
```

### Pattern 4: 適切なロールバックのない楽観的更新

```typescript
// FAIL: No rollback on failure
const handleRemove = async (id: string) => {
  setItems(prev => prev.filter(i => i.id !== id));
  await fetch(`/api/items/${id}`, { method: "DELETE" });
  // If API fails, item is gone from UI but still in DB
};

// PASS: Capture previous state and rollback on failure
const handleRemove = async (id: string) => {
  const prevItems = [...items];
  setItems(prev => prev.filter(i => i.id !== id));
  try {
    const res = await fetch(`/api/items/${id}`, { method: "DELETE" });
    if (!res.ok) throw new Error("API error");
  } catch {
    setItems(prevItems);  // Rollback
    alert("削除に失敗しました");
  }
};
```

## 戦略: バグが見つかった場所をテストする

100% カバレッジを目指さない。代わりに:

```
Bug found in /api/user/profile     → Write test for profile API
Bug found in /api/user/messages    → Write test for messages API
Bug found in /api/user/favorites   → Write test for favorites API
No bug in /api/user/notifications  → Don't write test (yet)
```

**AI 開発でこれが機能する理由:**

1. AI は **同じカテゴリのミス** を繰り返す傾向がある
2. バグは複雑な領域 (認証・マルチパスロジック・状態管理) に集中する
3. 一度テストすれば、その正確な回帰は **再発不可能** になる
4. テスト数はバグ修正とともに有機的に増える — 無駄な労力なし

## クイックリファレンス

| AI 回帰パターン | テスト戦略 | 優先度 |
|---|---|---|
| サンドボックス/本番不一致 | サンドボックスモードで同じ応答形状をアサート | High |
| SELECT 句省略 | 応答内のすべての必須フィールドをアサート | High |
| エラー状態リーク | エラー時の状態クリーンアップをアサート | Medium |
| ロールバック欠落 | API 失敗時の状態復元をアサート | Medium |
| null をマスクする型キャスト | フィールドが undefined でないことをアサート | Medium |

## DO / DON'T

**DO:**
- バグを見つけた直後にテストを書く (可能なら修正前に)
- 実装ではなく API 応答形状をテストする
- すべてのバグチェックの最初のステップとしてテストを実行する
- テストを高速に保つ (サンドボックスモードで合計 < 1 秒)
- 防ぐバグの名前をテストにつける (例: "BUG-R1 regression")

**DON'T:**
- 一度もバグが出ていないコードにテストを書く
- 自動テストの代わりとして AI のセルフレビューを信頼する
- 「ただのモックデータだから」とサンドボックスパスのテストをスキップする
- ユニットテストで十分な場合に統合テストを書く
- カバレッジ率を目指す — 回帰防止を目指す
