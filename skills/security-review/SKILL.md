---
name: security-review
description: 認証の追加、ユーザー入力の処理、シークレットの取り扱い、API エンドポイントの作成、または決済／機密機能の実装時にこのスキルを使う（comprehensive security checklist and patterns）。包括的なセキュリティチェックリストとパターンを提供する。
origin: ECC
---

# Security Review スキル

このスキルはすべてのコードがセキュリティベストプラクティスに従うことを保証し、潜在的な脆弱性を特定する。

## 起動するタイミング

- 認証または認可の実装
- ユーザー入力またはファイルアップロードの処理
- 新しい API エンドポイントの作成
- シークレットまたはクレデンシャルの取り扱い
- 決済機能の実装
- 機密データの保存または送信
- 第三者 API の統合

## セキュリティチェックリスト

### 1. シークレット管理

#### FAIL：絶対にしないこと
```typescript
const apiKey = "sk-proj-xxxxx"  // Hardcoded secret
const dbPassword = "password123" // In source code
```

#### PASS：常にすべきこと
```typescript
const apiKey = process.env.OPENAI_API_KEY
const dbUrl = process.env.DATABASE_URL

// Verify secrets exist
if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

#### 検証ステップ
- [ ] ハードコードされた API キー、トークン、パスワードなし
- [ ] すべてのシークレットが環境変数に
- [ ] `.env.local` が .gitignore に
- [ ] git 履歴にシークレットなし
- [ ] 本番シークレットがホスティングプラットフォーム（Vercel、Railway）に

### 2. 入力バリデーション

#### 常にユーザー入力を検証
```typescript
import { z } from 'zod'

// Define validation schema
const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150)
})

// Validate before processing
export async function createUser(input: unknown) {
  try {
    const validated = CreateUserSchema.parse(input)
    return await db.users.create(validated)
  } catch (error) {
    if (error instanceof z.ZodError) {
      return { success: false, errors: error.errors }
    }
    throw error
  }
}
```

#### ファイルアップロードバリデーション
```typescript
function validateFileUpload(file: File) {
  // Size check (5MB max)
  const maxSize = 5 * 1024 * 1024
  if (file.size > maxSize) {
    throw new Error('File too large (max 5MB)')
  }

  // Type check
  const allowedTypes = ['image/jpeg', 'image/png', 'image/gif']
  if (!allowedTypes.includes(file.type)) {
    throw new Error('Invalid file type')
  }

  // Extension check
  const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif']
  const extension = file.name.toLowerCase().match(/\.[^.]+$/)?.[0]
  if (!extension || !allowedExtensions.includes(extension)) {
    throw new Error('Invalid file extension')
  }

  return true
}
```

#### 検証ステップ
- [ ] すべてのユーザー入力がスキーマで検証されている
- [ ] ファイルアップロードが制限されている（サイズ、タイプ、拡張子）
- [ ] クエリでユーザー入力を直接使わない
- [ ] ホワイトリスト検証（ブラックリストではない）
- [ ] エラーメッセージが機密情報を漏らさない

### 3. SQL インジェクション防止

#### FAIL：絶対に SQL を連結しない
```typescript
// DANGEROUS - SQL Injection vulnerability
const query = `SELECT * FROM users WHERE email = '${userEmail}'`
await db.query(query)
```

#### PASS：常にパラメータ化クエリを使う
```typescript
// Safe - parameterized query
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('email', userEmail)

// Or with raw SQL
await db.query(
  'SELECT * FROM users WHERE email = $1',
  [userEmail]
)
```

#### 検証ステップ
- [ ] すべてのデータベースクエリがパラメータ化クエリを使用
- [ ] SQL での文字列連結なし
- [ ] ORM／クエリビルダが正しく使用されている
- [ ] Supabase クエリが適切にサニタイズされている

### 4. 認証と認可

#### JWT トークン処理
```typescript
// FAIL: WRONG: localStorage (vulnerable to XSS)
localStorage.setItem('token', token)

// PASS: CORRECT: httpOnly cookies
res.setHeader('Set-Cookie',
  `token=${token}; HttpOnly; Secure; SameSite=Strict; Max-Age=3600`)
```

#### 認可チェック
```typescript
export async function deleteUser(userId: string, requesterId: string) {
  // ALWAYS verify authorization first
  const requester = await db.users.findUnique({
    where: { id: requesterId }
  })

  if (requester.role !== 'admin') {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 403 }
    )
  }

  // Proceed with deletion
  await db.users.delete({ where: { id: userId } })
}
```

#### Row Level Security（Supabase）
```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can only view their own data
CREATE POLICY "Users view own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Users can only update their own data
CREATE POLICY "Users update own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);
```

#### 検証ステップ
- [ ] トークンが httpOnly Cookie に保存（localStorage ではない）
- [ ] 機密操作前に認可チェック
- [ ] Supabase で Row Level Security 有効
- [ ] ロールベースアクセス制御が実装されている
- [ ] セッション管理が安全

### 5. XSS 防止

#### HTML をサニタイズ
```typescript
import DOMPurify from 'isomorphic-dompurify'

// ALWAYS sanitize user-provided HTML
function renderUserContent(html: string) {
  const clean = DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'p'],
    ALLOWED_ATTR: []
  })
  return <div dangerouslySetInnerHTML={{ __html: clean }} />
}
```

#### Content Security Policy

厳格に開始し、文書化された削除計画でのみ緩和する。`'unsafe-inline'` や `'unsafe-eval'` をデフォルトにしない。これらは CSP の保護の多くを無効化し、一時的な互換性負債として扱うべきである。

```typescript
// next.config.js
const securityHeaders = [
  {
    key: 'Content-Security-Policy',
    value: `
      default-src 'self';
      base-uri 'self';
      object-src 'none';
      frame-ancestors 'none';
      script-src 'self';
      style-src 'self';
      img-src 'self' data: https:;
      font-src 'self';
      connect-src 'self' https://api.example.com;
    `.replace(/\s{2,}/g, ' ').trim()
  }
]
```

#### 検証ステップ
- [ ] ユーザー提供 HTML がサニタイズされている
- [ ] CSP ヘッダが設定されている
- [ ] 未検証の動的コンテンツレンダリングなし
- [ ] React のビルトイン XSS 保護が使われている

### 6. CSRF 保護

#### CSRF トークン
```typescript
import { csrf } from '@/lib/csrf'

export async function POST(request: Request) {
  const token = request.headers.get('X-CSRF-Token')

  if (!csrf.verify(token)) {
    return NextResponse.json(
      { error: 'Invalid CSRF token' },
      { status: 403 }
    )
  }

  // Process request
}
```

#### SameSite Cookie
```typescript
res.setHeader('Set-Cookie',
  `session=${sessionId}; HttpOnly; Secure; SameSite=Strict`)
```

#### 検証ステップ
- [ ] 状態変更操作に CSRF トークン
- [ ] すべての Cookie に SameSite=Strict
- [ ] Double-submit cookie パターンが実装されている

### 7. レート制限

#### API レート制限
```typescript
import rateLimit from 'express-rate-limit'

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: 'Too many requests'
})

// Apply to routes
app.use('/api/', limiter)
```

#### 高価な操作
```typescript
// Aggressive rate limiting for searches
const searchLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 requests per minute
  message: 'Too many search requests'
})

app.use('/api/search', searchLimiter)
```

#### 検証ステップ
- [ ] すべての API エンドポイントにレート制限
- [ ] 高価な操作にはより厳しい制限
- [ ] IP ベースのレート制限
- [ ] ユーザーベースのレート制限（認証済み）

### 8. 機密データ漏洩

#### ロギング
```typescript
// FAIL: WRONG: Logging sensitive data
console.log('User login:', { email, password })
console.log('Payment:', { cardNumber, cvv })

// PASS: CORRECT: Redact sensitive data
console.log('User login:', { email, userId })
console.log('Payment:', { last4: card.last4, userId })
```

#### エラーメッセージ
```typescript
// FAIL: WRONG: Exposing internal details
catch (error) {
  return NextResponse.json(
    { error: error.message, stack: error.stack },
    { status: 500 }
  )
}

// PASS: CORRECT: Generic error messages
catch (error) {
  console.error('Internal error:', error)
  return NextResponse.json(
    { error: 'An error occurred. Please try again.' },
    { status: 500 }
  )
}
```

#### 検証ステップ
- [ ] ログにパスワード、トークン、シークレットなし
- [ ] エラーメッセージはユーザー向けに一般的
- [ ] 詳細なエラーはサーバーログのみ
- [ ] ユーザーにスタックトレースを公開しない

### 9. ブロックチェーンセキュリティ（Solana）

#### ウォレット検証
```typescript
import { verify } from '@solana/web3.js'

async function verifyWalletOwnership(
  publicKey: string,
  signature: string,
  message: string
) {
  try {
    const isValid = verify(
      Buffer.from(message),
      Buffer.from(signature, 'base64'),
      Buffer.from(publicKey, 'base64')
    )
    return isValid
  } catch (error) {
    return false
  }
}
```

#### トランザクション検証
```typescript
async function verifyTransaction(transaction: Transaction) {
  // Verify recipient
  if (transaction.to !== expectedRecipient) {
    throw new Error('Invalid recipient')
  }

  // Verify amount
  if (transaction.amount > maxAmount) {
    throw new Error('Amount exceeds limit')
  }

  // Verify user has sufficient balance
  const balance = await getBalance(transaction.from)
  if (balance < transaction.amount) {
    throw new Error('Insufficient balance')
  }

  return true
}
```

#### 検証ステップ
- [ ] ウォレット署名が検証されている
- [ ] トランザクション詳細が検証されている
- [ ] トランザクション前の残高チェック
- [ ] ブラインドトランザクション署名なし

### 10. 依存関係セキュリティ

#### 定期的な更新
```bash
# Check for vulnerabilities
npm audit

# Fix automatically fixable issues
npm audit fix

# Update dependencies
npm update

# Check for outdated packages
npm outdated
```

#### ロックファイル
```bash
# ALWAYS commit lock files
git add package-lock.json

# Use in CI/CD for reproducible builds
npm ci  # Instead of npm install
```

#### 検証ステップ
- [ ] 依存関係が最新
- [ ] 既知の脆弱性なし（npm audit がクリーン）
- [ ] ロックファイルがコミットされている
- [ ] GitHub で Dependabot が有効
- [ ] 定期的なセキュリティ更新

## セキュリティテスト

### 自動セキュリティテスト
```typescript
// Test authentication
test('requires authentication', async () => {
  const response = await fetch('/api/protected')
  expect(response.status).toBe(401)
})

// Test authorization
test('requires admin role', async () => {
  const response = await fetch('/api/admin', {
    headers: { Authorization: `Bearer ${userToken}` }
  })
  expect(response.status).toBe(403)
})

// Test input validation
test('rejects invalid input', async () => {
  const response = await fetch('/api/users', {
    method: 'POST',
    body: JSON.stringify({ email: 'not-an-email' })
  })
  expect(response.status).toBe(400)
})

// Test rate limiting
test('enforces rate limits', async () => {
  const requests = Array(101).fill(null).map(() =>
    fetch('/api/endpoint')
  )

  const responses = await Promise.all(requests)
  const tooManyRequests = responses.filter(r => r.status === 429)

  expect(tooManyRequests.length).toBeGreaterThan(0)
})
```

## デプロイ前セキュリティチェックリスト

任意の本番デプロイ前に：

- [ ] **シークレット**：ハードコードシークレットなし、すべて環境変数
- [ ] **入力バリデーション**：すべてのユーザー入力が検証されている
- [ ] **SQL インジェクション**：すべてのクエリがパラメータ化
- [ ] **XSS**：ユーザーコンテンツがサニタイズ
- [ ] **CSRF**：保護有効
- [ ] **認証**：適切なトークン処理
- [ ] **認可**：ロールチェック実装
- [ ] **レート制限**：すべてのエンドポイントで有効
- [ ] **HTTPS**：本番で強制
- [ ] **セキュリティヘッダ**：CSP、X-Frame-Options 設定
- [ ] **エラー処理**：エラーに機密データなし
- [ ] **ロギング**：機密データを記録しない
- [ ] **依存関係**：最新、脆弱性なし
- [ ] **Row Level Security**：Supabase で有効
- [ ] **CORS**：適切に設定
- [ ] **ファイルアップロード**：検証済み（サイズ、タイプ）
- [ ] **ウォレット署名**：検証済み（ブロックチェーンの場合）

## リソース

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Next.js Security](https://nextjs.org/docs/security)
- [Supabase Security](https://supabase.com/docs/guides/auth)
- [Web Security Academy](https://portswigger.net/web-security)

---

**覚えておくこと**：セキュリティはオプションではない。1 つの脆弱性がプラットフォーム全体を侵害する可能性がある。疑わしいときは慎重を期す。
