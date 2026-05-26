---
name: django-verification
description: "Django プロジェクトの検証ループ（verification loop）: マイグレーション、lint、カバレッジ付きテスト、セキュリティスキャン、リリースや PR 前のデプロイ準備チェック。"
origin: ECC
---

# Django 検証ループ

PR 前・大規模変更後・デプロイ前に実行し、Django アプリの品質とセキュリティを担保する。

## 起動タイミング

- Django プロジェクトの PR オープン前
- モデル変更・マイグレーション更新・依存パッケージ更新の後
- ステージング・本番のデプロイ前検証
- 環境 → lint → test → security → デプロイ準備のパイプライン全体の実行
- マイグレーション安全性とテストカバレッジの検証

## Phase 1: 環境チェック

```bash
# Verify Python version
python --version  # Should match project requirements

# Check virtual environment
which python
pip list --outdated

# Verify environment variables
python -c "import os; import environ; print('DJANGO_SECRET_KEY set' if os.environ.get('DJANGO_SECRET_KEY') else 'MISSING: DJANGO_SECRET_KEY')"
```

環境が誤構成なら停止して修正する。

## Phase 2: コード品質・フォーマット

```bash
# Type checking
mypy . --config-file pyproject.toml

# Linting with ruff
ruff check . --fix

# Formatting with black
black . --check
black .  # Auto-fix

# Import sorting
isort . --check-only
isort .  # Auto-fix

# Django-specific checks
python manage.py check --deploy
```

ありがちな問題:
- 公開関数の型ヒント不足
- PEP 8 フォーマット違反
- ソートされていない import
- デバッグ設定が本番に残置

## Phase 3: マイグレーション

```bash
# Check for unapplied migrations
python manage.py showmigrations

# Create missing migrations
python manage.py makemigrations --check

# Dry-run migration application
python manage.py migrate --plan

# Apply migrations (test environment)
python manage.py migrate

# Check for migration conflicts
python manage.py makemigrations --merge  # Only if conflicts exist
```

レポート:
- 未適用マイグレーション件数
- マイグレーション競合
- マイグレーションなしのモデル変更

## Phase 4: テスト + カバレッジ

```bash
# Run all tests with pytest
pytest --cov=apps --cov-report=html --cov-report=term-missing --reuse-db

# Run specific app tests
pytest apps/users/tests/

# Run with markers
pytest -m "not slow"  # Skip slow tests
pytest -m integration  # Only integration tests

# Coverage report
open htmlcov/index.html
```

レポート:
- 合計テスト: X 件 pass、Y 件 fail、Z 件 skip
- 全体カバレッジ: XX%
- アプリ別カバレッジ内訳

カバレッジ目標:

| コンポーネント | 目標 |
|-----------|--------|
| Models | 90%+ |
| Serializers | 85%+ |
| Views | 80%+ |
| Services | 90%+ |
| Overall | 80%+ |

## Phase 5: セキュリティスキャン

```bash
# Dependency vulnerabilities
pip-audit
safety check --full-report

# Django security checks
python manage.py check --deploy

# Bandit security linter
bandit -r . -f json -o bandit-report.json

# Secret scanning (if gitleaks is installed)
gitleaks detect --source . --verbose

# Environment variable check
python -c "from django.core.exceptions import ImproperlyConfigured; from django.conf import settings; settings.DEBUG"
```

レポート:
- 脆弱な依存パッケージ
- セキュリティ設定の問題
- ハードコードされたシークレット
- DEBUG モードの状態（本番では False）

## Phase 6: Django 管理コマンド

```bash
# Check for model issues
python manage.py check

# Collect static files
python manage.py collectstatic --noinput --clear

# Create superuser (if needed for tests)
echo "from apps.users.models import User; User.objects.create_superuser('admin@example.com', 'admin')" | python manage.py shell

# Database integrity
python manage.py check --database default

# Cache verification (if using Redis)
python -c "from django.core.cache import cache; cache.set('test', 'value', 10); print(cache.get('test'))"
```

## Phase 7: パフォーマンスチェック

```bash
# Django Debug Toolbar output (check for N+1 queries)
# Run in dev mode with DEBUG=True and access a page
# Look for duplicate queries in SQL panel

# Query count analysis
django-admin debugsqlshell  # If django-debug-sqlshell installed

# Check for missing indexes
python manage.py shell << EOF
from django.db import connection
with connection.cursor() as cursor:
    cursor.execute("SELECT table_name, index_name FROM information_schema.statistics WHERE table_schema = 'public'")
    print(cursor.fetchall())
EOF
```

レポート:
- ページあたりクエリ数（一般ページで50未満が目安）
- DB インデックスの欠落
- 重複クエリの検出

## Phase 8: 静的アセット

```bash
# Check for npm dependencies (if using npm)
npm audit
npm audit fix

# Build static files (if using webpack/vite)
npm run build

# Verify static files
ls -la staticfiles/
python manage.py findstatic css/style.css
```

## Phase 9: 設定レビュー

```python
# Run in Python shell to verify settings
python manage.py shell << EOF
from django.conf import settings
import os

# Critical checks
checks = {
    'DEBUG is False': not settings.DEBUG,
    'SECRET_KEY set': bool(settings.SECRET_KEY and len(settings.SECRET_KEY) > 30),
    'ALLOWED_HOSTS set': len(settings.ALLOWED_HOSTS) > 0,
    'HTTPS enabled': getattr(settings, 'SECURE_SSL_REDIRECT', False),
    'HSTS enabled': getattr(settings, 'SECURE_HSTS_SECONDS', 0) > 0,
    'Database configured': settings.DATABASES['default']['ENGINE'] != 'django.db.backends.sqlite3',
}

for check, result in checks.items():
    status = '✓' if result else '✗'
    print(f"{status} {check}")
EOF
```

## Phase 10: ロギング設定

```bash
# Test logging output
python manage.py shell << EOF
import logging
logger = logging.getLogger('django')
logger.warning('Test warning message')
logger.error('Test error message')
EOF

# Check log files (if configured)
tail -f /var/log/django/django.log
```

## Phase 11: API ドキュメント（DRF の場合）

```bash
# Generate schema
python manage.py generateschema --format openapi-json > schema.json

# Validate schema
# Check if schema.json is valid JSON
python -c "import json; json.load(open('schema.json'))"

# Access Swagger UI (if using drf-yasg)
# Visit http://localhost:8000/swagger/ in browser
```

## Phase 12: Diff レビュー

```bash
# Show diff statistics
git diff --stat

# Show actual changes
git diff

# Show changed files
git diff --name-only

# Check for common issues
git diff | grep -i "todo\|fixme\|hack\|xxx"
git diff | grep "print("  # Debug statements
git diff | grep "DEBUG = True"  # Debug mode
git diff | grep "import pdb"  # Debugger
```

チェックリスト:
- デバッグ文（print、pdb、breakpoint()）なし
- クリティカルコードに TODO/FIXME コメントなし
- ハードコードされたシークレット・クレデンシャルなし
- モデル変更に伴うマイグレーション含む
- 設定変更がドキュメント化されている
- 外部呼び出しにエラーハンドリングがある
- 必要箇所にトランザクション管理がある

## 出力テンプレート

```
DJANGO VERIFICATION REPORT
==========================

Phase 1: Environment Check
  ✓ Python 3.11.5
  ✓ Virtual environment active
  ✓ All environment variables set

Phase 2: Code Quality
  ✓ mypy: No type errors
  ✗ ruff: 3 issues found (auto-fixed)
  ✓ black: No formatting issues
  ✓ isort: Imports properly sorted
  ✓ manage.py check: No issues

Phase 3: Migrations
  ✓ No unapplied migrations
  ✓ No migration conflicts
  ✓ All models have migrations

Phase 4: Tests + Coverage
  Tests: 247 passed, 0 failed, 5 skipped
  Coverage:
    Overall: 87%
    users: 92%
    products: 89%
    orders: 85%
    payments: 91%

Phase 5: Security Scan
  ✗ pip-audit: 2 vulnerabilities found (fix required)
  ✓ safety check: No issues
  ✓ bandit: No security issues
  ✓ No secrets detected
  ✓ DEBUG = False

Phase 6: Django Commands
  ✓ collectstatic completed
  ✓ Database integrity OK
  ✓ Cache backend reachable

Phase 7: Performance
  ✓ No N+1 queries detected
  ✓ Database indexes configured
  ✓ Query count acceptable

Phase 8: Static Assets
  ✓ npm audit: No vulnerabilities
  ✓ Assets built successfully
  ✓ Static files collected

Phase 9: Configuration
  ✓ DEBUG = False
  ✓ SECRET_KEY configured
  ✓ ALLOWED_HOSTS set
  ✓ HTTPS enabled
  ✓ HSTS enabled
  ✓ Database configured

Phase 10: Logging
  ✓ Logging configured
  ✓ Log files writable

Phase 11: API Documentation
  ✓ Schema generated
  ✓ Swagger UI accessible

Phase 12: Diff Review
  Files changed: 12
  +450, -120 lines
  ✓ No debug statements
  ✓ No hardcoded secrets
  ✓ Migrations included

RECOMMENDATION: WARNING: Fix pip-audit vulnerabilities before deploying

NEXT STEPS:
1. Update vulnerable dependencies
2. Re-run security scan
3. Deploy to staging for final testing
```

## デプロイ前チェックリスト

- [ ] 全テスト合格
- [ ] カバレッジ ≥ 80%
- [ ] セキュリティ脆弱性なし
- [ ] 未適用マイグレーションなし
- [ ] 本番設定で DEBUG = False
- [ ] SECRET_KEY が適切に構成済み
- [ ] ALLOWED_HOSTS が正しく設定済み
- [ ] DB バックアップ有効
- [ ] 静的ファイル収集・配信済み
- [ ] ロギング構成・動作確認済み
- [ ] エラー監視（Sentry など）構成済み
- [ ] CDN 構成済み（該当時）
- [ ] Redis/キャッシュバックエンド構成済み
- [ ] Celery ワーカー稼働中（該当時）
- [ ] HTTPS/SSL 構成済み
- [ ] 環境変数のドキュメント化

## CI

### GitHub Actions 例

```yaml
# .github/workflows/django-verification.yml
name: Django Verification

on: [push, pull_request]

jobs:
  verify:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Cache pip
        uses: actions/cache@v3
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install ruff black mypy pytest pytest-django pytest-cov bandit safety pip-audit

      - name: Code quality checks
        run: |
          ruff check .
          black . --check
          isort . --check-only
          mypy .

      - name: Security scan
        run: |
          bandit -r . -f json -o bandit-report.json
          safety check --full-report
          pip-audit

      - name: Run tests
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          DJANGO_SECRET_KEY: test-secret-key
        run: |
          pytest --cov=apps --cov-report=xml --cov-report=term-missing

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## クイックリファレンス

| チェック | コマンド |
|-------|---------|
| 環境 | `python --version` |
| 型チェック | `mypy .` |
| Lint | `ruff check .` |
| フォーマット | `black . --check` |
| マイグレーション | `python manage.py makemigrations --check` |
| テスト | `pytest --cov=apps` |
| セキュリティ | `pip-audit && bandit -r .` |
| Django チェック | `python manage.py check --deploy` |
| Collectstatic | `python manage.py collectstatic --noinput` |
| Diff 統計 | `git diff --stat` |

備考: 自動検証は一般的な問題を捕捉するが、手動コードレビューおよびステージング環境でのテストの代替にはならない。
