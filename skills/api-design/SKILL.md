---
name: api-design
description: 本番 API のためのリソース命名、ステータスコード、ページネーション、フィルタリング、エラーレスポンス、バージョニング、レート制限を含む REST API 設計パターン (API design, REST, pagination, status code, versioning, rate limit)。
origin: ECC
---

# API 設計パターン

一貫性があり開発者にやさしい REST API を設計するための規約とベストプラクティス。

## 起動するタイミング

- 新しい API エンドポイントの設計
- 既存 API 契約のレビュー
- ページネーション・フィルタリング・ソートの追加
- API のためのエラー処理の実装
- API バージョニング戦略の計画
- パブリックまたはパートナー向け API の構築

## リソース設計

### URL 構造

```
# Resources are nouns, plural, lowercase, kebab-case
GET    /api/v1/users
GET    /api/v1/users/:id
POST   /api/v1/users
PUT    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id

# Sub-resources for relationships
GET    /api/v1/users/:id/orders
POST   /api/v1/users/:id/orders

# Actions that don't map to CRUD (use verbs sparingly)
POST   /api/v1/orders/:id/cancel
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
```

### 命名ルール

```
# GOOD
/api/v1/team-members          # kebab-case for multi-word resources
/api/v1/orders?status=active  # query params for filtering
/api/v1/users/123/orders      # nested resources for ownership

# BAD
/api/v1/getUsers              # verb in URL
/api/v1/user                  # singular (use plural)
/api/v1/team_members          # snake_case in URLs
/api/v1/users/123/getOrders   # verb in nested resource
```

## HTTP メソッドとステータスコード

### メソッドのセマンティクス

| メソッド | 冪等 | セーフ | 用途 |
|--------|-----------|------|---------|
| GET | Yes | Yes | リソース取得 |
| POST | No | No | リソース作成、アクション起動 |
| PUT | Yes | No | リソースの完全置換 |
| PATCH | No* | No | リソースの部分更新 |
| DELETE | Yes | No | リソース削除 |

*PATCH は適切な実装で冪等にできる

### ステータスコードリファレンス

```
# Success
200 OK                    — GET, PUT, PATCH (with response body)
201 Created               — POST (include Location header)
204 No Content            — DELETE, PUT (no response body)

# Client Errors
400 Bad Request           — Validation failure, malformed JSON
401 Unauthorized          — Missing or invalid authentication
403 Forbidden             — Authenticated but not authorized
404 Not Found             — Resource doesn't exist
409 Conflict              — Duplicate entry, state conflict
422 Unprocessable Entity  — Semantically invalid (valid JSON, bad data)
429 Too Many Requests     — Rate limit exceeded

# Server Errors
500 Internal Server Error — Unexpected failure (never expose details)
502 Bad Gateway           — Upstream service failed
503 Service Unavailable   — Temporary overload, include Retry-After
```

### よくある誤り

```
# BAD: 200 for everything
{ "status": 200, "success": false, "error": "Not found" }

# GOOD: Use HTTP status codes semantically
HTTP/1.1 404 Not Found
{ "error": { "code": "not_found", "message": "User not found" } }

# BAD: 500 for validation errors
# GOOD: 400 or 422 with field-level details

# BAD: 200 for created resources
# GOOD: 201 with Location header
HTTP/1.1 201 Created
Location: /api/v1/users/abc-123
```

## レスポンスフォーマット

### 成功レスポンス

```json
{
  "data": {
    "id": "abc-123",
    "email": "alice@example.com",
    "name": "Alice",
    "created_at": "2025-01-15T10:30:00Z"
  }
}
```

### コレクションレスポンス (ページネーション付き)

```json
{
  "data": [
    { "id": "abc-123", "name": "Alice" },
    { "id": "def-456", "name": "Bob" }
  ],
  "meta": {
    "total": 142,
    "page": 1,
    "per_page": 20,
    "total_pages": 8
  },
  "links": {
    "self": "/api/v1/users?page=1&per_page=20",
    "next": "/api/v1/users?page=2&per_page=20",
    "last": "/api/v1/users?page=8&per_page=20"
  }
}
```

### エラーレスポンス

```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address",
        "code": "invalid_format"
      },
      {
        "field": "age",
        "message": "Must be between 0 and 150",
        "code": "out_of_range"
      }
    ]
  }
}
```

### レスポンスエンベロープのバリアント

```typescript
// Option A: Envelope with data wrapper (recommended for public APIs)
interface ApiResponse<T> {
  data: T;
  meta?: PaginationMeta;
  links?: PaginationLinks;
}

interface ApiError {
  error: {
    code: string;
    message: string;
    details?: FieldError[];
  };
}

// Option B: Flat response (simpler, common for internal APIs)
// Success: just return the resource directly
// Error: return error object
// Distinguish by HTTP status code
```

## ページネーション

### オフセットベース (シンプル)

```
GET /api/v1/users?page=2&per_page=20

# Implementation
SELECT * FROM users
ORDER BY created_at DESC
LIMIT 20 OFFSET 20;
```

**長所:** 実装が簡単、「N ページへジャンプ」をサポート
**短所:** 大きなオフセット (OFFSET 100000) で遅い、並行挿入で一貫性なし

### カーソルベース (スケーラブル)

```
GET /api/v1/users?cursor=eyJpZCI6MTIzfQ&limit=20

# Implementation
SELECT * FROM users
WHERE id > :cursor_id
ORDER BY id ASC
LIMIT 21;  -- fetch one extra to determine has_next
```

```json
{
  "data": [...],
  "meta": {
    "has_next": true,
    "next_cursor": "eyJpZCI6MTQzfQ"
  }
}
```

**長所:** 位置に関係なく一貫したパフォーマンス、並行挿入でも安定
**短所:** 任意のページへジャンプできない、カーソルは不透明

### どちらを使うか

| ユースケース | ページネーションタイプ |
|----------|----------------|
| 管理ダッシュボード、小規模データセット (<10K) | オフセット |
| 無限スクロール、フィード、大規模データセット | カーソル |
| パブリック API | カーソル (デフォルト) とオフセット (オプション) |
| 検索結果 | オフセット (ユーザはページ番号を期待する) |

## フィルタリング・ソート・検索

### フィルタリング

```
# Simple equality
GET /api/v1/orders?status=active&customer_id=abc-123

# Comparison operators (use bracket notation)
GET /api/v1/products?price[gte]=10&price[lte]=100
GET /api/v1/orders?created_at[after]=2025-01-01

# Multiple values (comma-separated)
GET /api/v1/products?category=electronics,clothing

# Nested fields (dot notation)
GET /api/v1/orders?customer.country=US
```

### ソート

```
# Single field (prefix - for descending)
GET /api/v1/products?sort=-created_at

# Multiple fields (comma-separated)
GET /api/v1/products?sort=-featured,price,-created_at
```

### 全文検索

```
# Search query parameter
GET /api/v1/products?q=wireless+headphones

# Field-specific search
GET /api/v1/users?email=alice
```

### スパースフィールドセット

```
# Return only specified fields (reduces payload)
GET /api/v1/users?fields=id,name,email
GET /api/v1/orders?fields=id,total,status&include=customer.name
```

## 認証と認可

### トークンベース認証

```
# Bearer token in Authorization header
GET /api/v1/users
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

# API key (for server-to-server)
GET /api/v1/data
X-API-Key: sk_live_abc123
```

### 認可パターン

```typescript
// Resource-level: check ownership
app.get("/api/v1/orders/:id", async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: { code: "not_found" } });
  if (order.userId !== req.user.id) return res.status(403).json({ error: { code: "forbidden" } });
  return res.json({ data: order });
});

// Role-based: check permissions
app.delete("/api/v1/users/:id", requireRole("admin"), async (req, res) => {
  await User.delete(req.params.id);
  return res.status(204).send();
});
```

## レート制限

### ヘッダ

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640000000

# When exceeded
HTTP/1.1 429 Too Many Requests
Retry-After: 60
{
  "error": {
    "code": "rate_limit_exceeded",
    "message": "Rate limit exceeded. Try again in 60 seconds."
  }
}
```

### レート制限ティア

| ティア | 上限 | 期間 | ユースケース |
|------|-------|--------|----------|
| Anonymous | 30/min | IP ごと | パブリックエンドポイント |
| Authenticated | 100/min | ユーザごと | 標準 API アクセス |
| Premium | 1000/min | API キーごと | 有料 API プラン |
| Internal | 10000/min | サービスごと | サービス間 |

## バージョニング

### URL パスバージョニング (推奨)

```
/api/v1/users
/api/v2/users
```

**長所:** 明示的、ルーティング容易、キャッシュ可能
**短所:** バージョン間で URL が変わる

### ヘッダバージョニング

```
GET /api/users
Accept: application/vnd.myapp.v2+json
```

**長所:** クリーンな URL
**短所:** テストが難しい、忘れやすい

### バージョニング戦略

```
1. /api/v1/ から始める — 必要になるまでバージョン化しない
2. 同時にアクティブなのは最大 2 バージョン (現行 + 前)
3. 廃止タイムライン:
   - 廃止を発表 (パブリック API は 6 ヶ月前通知)
   - Sunset ヘッダを追加: Sunset: Sat, 01 Jan 2026 00:00:00 GMT
   - sunset 日以降は 410 Gone を返す
4. 非破壊変更は新バージョン不要:
   - レスポンスへの新フィールド追加
   - 新しいオプションのクエリパラメータ追加
   - 新エンドポイント追加
5. 破壊変更は新バージョンが必要:
   - フィールドの削除や改名
   - フィールド型の変更
   - URL 構造の変更
   - 認証方式の変更
```

## 実装パターン

### TypeScript (Next.js API Route)

```typescript
import { z } from "zod";
import { NextRequest, NextResponse } from "next/server";

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

export async function POST(req: NextRequest) {
  const body = await req.json();
  const parsed = createUserSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json({
      error: {
        code: "validation_error",
        message: "Request validation failed",
        details: parsed.error.issues.map(i => ({
          field: i.path.join("."),
          message: i.message,
          code: i.code,
        })),
      },
    }, { status: 422 });
  }

  const user = await createUser(parsed.data);

  return NextResponse.json(
    { data: user },
    {
      status: 201,
      headers: { Location: `/api/v1/users/${user.id}` },
    },
  );
}
```

### Python (Django REST Framework)

```python
from rest_framework import serializers, viewsets, status
from rest_framework.response import Response

class CreateUserSerializer(serializers.Serializer):
    email = serializers.EmailField()
    name = serializers.CharField(max_length=100)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "email", "name", "created_at"]

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return CreateUserSerializer
        return UserSerializer

    def create(self, request):
        serializer = CreateUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = UserService.create(**serializer.validated_data)
        return Response(
            {"data": UserSerializer(user).data},
            status=status.HTTP_201_CREATED,
            headers={"Location": f"/api/v1/users/{user.id}"},
        )
```

### Go (net/http)

```go
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "invalid_json", "Invalid request body")
        return
    }

    if err := req.Validate(); err != nil {
        writeError(w, http.StatusUnprocessableEntity, "validation_error", err.Error())
        return
    }

    user, err := h.service.Create(r.Context(), req)
    if err != nil {
        switch {
        case errors.Is(err, domain.ErrEmailTaken):
            writeError(w, http.StatusConflict, "email_taken", "Email already registered")
        default:
            writeError(w, http.StatusInternalServerError, "internal_error", "Internal error")
        }
        return
    }

    w.Header().Set("Location", fmt.Sprintf("/api/v1/users/%s", user.ID))
    writeJSON(w, http.StatusCreated, map[string]any{"data": user})
}
```

## API 設計チェックリスト

新しいエンドポイントをリリースする前に:

- [ ] リソース URL が命名規則に従う (複数形・kebab-case・動詞なし)
- [ ] 正しい HTTP メソッドが使われている (読み取りは GET、作成は POST 等)
- [ ] 適切なステータスコードが返される (全部 200 ではない)
- [ ] 入力がスキーマ (Zod・Pydantic・Bean Validation) で検証されている
- [ ] エラーレスポンスがコードとメッセージ付きの標準フォーマットに従う
- [ ] リストエンドポイントにページネーションが実装されている (カーソルかオフセット)
- [ ] 認証が必要である (または明示的にパブリックとマークされている)
- [ ] 認可がチェックされている (ユーザは自身のリソースのみアクセス可能)
- [ ] レート制限が設定されている
- [ ] レスポンスが内部詳細 (スタックトレース・SQL エラー) を漏らさない
- [ ] 既存エンドポイントと一貫した命名 (camelCase vs snake_case)
- [ ] ドキュメント化されている (OpenAPI/Swagger 仕様が更新されている)
