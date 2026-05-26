---
name: django-celery
description: Django + Celery 非同期タスクのパターン（async tasks, Celery, Beat）。設定、タスク設計、Beat スケジューリング、retry、canvas ワークフロー、監視、テストを網羅する。Django アプリにバックグラウンドジョブ・スケジュールタスク・非同期処理を追加する場合に用いる。
origin: ECC
---

# Django + Celery 非同期タスクパターン

Redis または RabbitMQ をブローカに用いる Django + Celery によるバックグラウンドタスク処理の本番グレードパターンである。

## 起動タイミング

- Django アプリへバックグラウンドジョブまたは非同期処理を追加する場合
- 定期/スケジュールタスクの実装
- 遅い処理（メール送信・PDF 生成・API 呼び出し）をリクエストサイクルから切り離す場合
- Celery Beat を cron 様スケジューリングに使う場合
- タスク失敗・retry・キュー滞留のデバッグ
- Celery タスクのテスト記述

## プロジェクトセットアップ

### インストール

```bash
pip install celery[redis] django-celery-results django-celery-beat
```

### `celery.py` — アプリエントリポイント

```python
# config/celery.py
import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.development')

app = Celery('myproject')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()  # Discovers tasks.py in each INSTALLED_APP

@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
```

```python
# config/__init__.py
from .celery import app as celery_app

__all__ = ('celery_app',)
```

### Django Settings

```python
# config/settings/base.py

# Broker (Redis recommended for production)
CELERY_BROKER_URL = env('CELERY_BROKER_URL', default='redis://localhost:6379/0')
CELERY_RESULT_BACKEND = env('CELERY_RESULT_BACKEND', default='django-db')

# Serialization
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'

# Task behavior
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 30 * 60        # Hard limit: 30 min
CELERY_TASK_SOFT_TIME_LIMIT = 25 * 60   # Soft limit: sends SoftTimeLimitExceeded
CELERY_WORKER_PREFETCH_MULTIPLIER = 1   # Prevent worker hoarding long tasks
CELERY_TASK_ACKS_LATE = True            # Re-queue on worker crash

# Result persistence
CELERY_RESULT_EXPIRES = 60 * 60 * 24   # Keep results 24 hours

# Beat scheduler (for periodic tasks)
CELERY_BEAT_SCHEDULER = 'django_celery_beat.schedulers:DatabaseScheduler'

# Installed apps
INSTALLED_APPS += [
    'django_celery_results',
    'django_celery_beat',
]
```

### ワーカー起動

```bash
# Start worker (development)
celery -A config worker --loglevel=info

# Start beat scheduler (periodic tasks)
celery -A config beat --loglevel=info --scheduler django_celery_beat.schedulers:DatabaseScheduler

# Combined worker + beat (dev only, never production)
celery -A config worker --beat --loglevel=info

# Production: multiple workers with concurrency
celery -A config worker --loglevel=warning --concurrency=4 -Q default,high_priority
```

## タスク設計パターン

### 基本タスク

```python
# apps/notifications/tasks.py
from celery import shared_task
import logging

logger = logging.getLogger(__name__)

@shared_task(name='notifications.send_welcome_email')
def send_welcome_email(user_id: int) -> None:
    """Send welcome email to newly registered user."""
    from apps.users.models import User
    from apps.notifications.services import EmailService

    try:
        user = User.objects.get(pk=user_id)
    except User.DoesNotExist:
        logger.warning('send_welcome_email: user %s not found', user_id)
        return  # Idempotent — do not raise, task already impossible to complete

    EmailService.send_welcome(user)
    logger.info('Welcome email sent to user %s', user_id)
```

### Retry 可能タスク

```python
@shared_task(
    bind=True,
    name='integrations.sync_to_crm',
    max_retries=5,
    default_retry_delay=60,       # seconds before first retry
    autoretry_for=(ConnectionError, TimeoutError),
    retry_backoff=True,           # exponential backoff
    retry_backoff_max=600,        # cap at 10 minutes
    retry_jitter=True,            # randomise to avoid thundering herd
)
def sync_contact_to_crm(self, contact_id: int) -> dict:
    """Sync contact to external CRM with retry on transient failures."""
    from apps.crm.services import CRMClient

    try:
        result = CRMClient().sync(contact_id)
        return result
    except CRMClient.RateLimitError as exc:
        # Specific retry delay from response header
        raise self.retry(exc=exc, countdown=int(exc.retry_after))
```

### 冪等タスクパターン

同じ入力で複数回実行されても安全になるように設計する。

```python
@shared_task(name='orders.mark_shipped')
def mark_order_shipped(order_id: int, tracking_number: str) -> None:
    """Mark order as shipped — safe to run multiple times."""
    from apps.orders.models import Order

    updated = Order.objects.filter(
        pk=order_id,
        status=Order.Status.PROCESSING,    # Guard: only update if not already shipped
    ).update(
        status=Order.Status.SHIPPED,
        tracking_number=tracking_number,
    )

    if not updated:
        logger.info('mark_order_shipped: order %s already shipped or not found', order_id)
```

### Soft Time Limit 付きタスク

```python
from celery.exceptions import SoftTimeLimitExceeded

@shared_task(
    bind=True,
    name='reports.generate_pdf',
    soft_time_limit=120,
    time_limit=150,
)
def generate_pdf_report(self, report_id: int) -> str:
    """Generate PDF report with graceful timeout handling."""
    from apps.reports.services import PDFGenerator

    try:
        path = PDFGenerator.build(report_id)
        return path
    except SoftTimeLimitExceeded:
        # Clean up partial files before hard kill
        PDFGenerator.cleanup(report_id)
        raise
```

## タスクの呼び出し

```python
from datetime import timedelta
from django.utils import timezone

# Fire and forget (async)
send_welcome_email.delay(user.pk)

# Schedule in the future
send_reminder.apply_async(args=[user.pk], countdown=3600)  # 1 hour from now
send_reminder.apply_async(args=[user.pk], eta=timezone.now() + timedelta(days=1))

# Apply with queue routing
sync_contact_to_crm.apply_async(args=[contact.pk], queue='high_priority')

# Run synchronously (tests / debugging only)
result = generate_pdf_report.apply(args=[report.pk])
```

## Beat スケジューリング（定期タスク）

### コードで定義するスケジュール

```python
# config/settings/base.py
from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    'cleanup-expired-sessions': {
        'task': 'users.cleanup_expired_sessions',
        'schedule': crontab(hour=2, minute=0),   # 2am daily
    },
    'sync-inventory': {
        'task': 'products.sync_inventory',
        'schedule': 60.0,                         # every 60 seconds
    },
    'weekly-digest': {
        'task': 'notifications.send_weekly_digest',
        'schedule': crontab(day_of_week='monday', hour=8, minute=0),
    },
}
```

### DB で定義するスケジュール（django-celery-beat 経由）

```python
# Manage periodic tasks from Django admin or code
from django_celery_beat.models import PeriodicTask, CrontabSchedule
import json

schedule, _ = CrontabSchedule.objects.get_or_create(
    hour='*/6', minute='0',
    timezone='UTC',
)

PeriodicTask.objects.update_or_create(
    name='Sync inventory every 6 hours',
    defaults={
        'crontab': schedule,
        'task': 'products.sync_inventory',
        'args': json.dumps([]),
        'enabled': True,
    }
)
```

## Canvas: タスクの連結とグルーピング

```python
from celery import chain, group, chord

# Chain: run tasks sequentially, passing results
pipeline = chain(
    fetch_data.s(source_id),
    transform_data.s(),          # receives fetch_data result as first arg
    load_to_warehouse.s(),
)
pipeline.delay()

# Group: run tasks in parallel
parallel = group(
    send_welcome_email.s(user_id)
    for user_id in new_user_ids
)
parallel.delay()

# Chord: parallel tasks + callback when all complete
result = chord(
    group(process_chunk.s(chunk) for chunk in data_chunks),
    aggregate_results.s(),       # called with list of chunk results
)
result.delay()
```

## エラーハンドリングと Dead Letter Queue

```python
# apps/core/tasks.py
from celery.signals import task_failure

@task_failure.connect
def on_task_failure(sender, task_id, exception, args, kwargs, traceback, einfo, **kw):
    """Log all task failures to Sentry / alerting."""
    import sentry_sdk
    with sentry_sdk.new_scope() as scope:
        scope.set_context('celery', {
            'task': sender.name,
            'task_id': task_id,
            'args': args,
            'kwargs': kwargs,
        })
        sentry_sdk.capture_exception(exception)
```

```python
# Route failed tasks to dead-letter queue after max retries
@shared_task(
    bind=True,
    max_retries=3,
    name='payments.charge_card',
)
def charge_card(self, order_id: int) -> None:
    from apps.payments.models import Order, FailedCharge

    try:
        _do_charge(order_id)
    except Exception as exc:
        if self.request.retries >= self.max_retries:
            # Persist to dead-letter table for manual review
            FailedCharge.objects.create(
                order_id=order_id,
                error=str(exc),
                task_id=self.request.id,
            )
            return  # Don't raise — task is permanently failed
        raise self.retry(exc=exc)
```

## Celery タスクのテスト

### ユニットテスト（ブローカなし）

```python
# tests/test_tasks.py
import pytest
from unittest.mock import patch, MagicMock
from apps.notifications.tasks import send_welcome_email

class TestSendWelcomeEmail:

    @pytest.mark.django_db
    def test_sends_email_to_existing_user(self, user):
        with patch('apps.notifications.services.EmailService') as mock_email:
            send_welcome_email(user.pk)
            mock_email.send_welcome.assert_called_once_with(user)

    @pytest.mark.django_db
    def test_skips_missing_user_gracefully(self):
        """Should not raise when user is deleted between enqueue and execute."""
        send_welcome_email(99999)  # Non-existent user — must not raise
```

### CELERY_TASK_ALWAYS_EAGER による統合テスト

```python
# config/settings/test.py
CELERY_TASK_ALWAYS_EAGER = True      # Run tasks synchronously in tests
CELERY_TASK_EAGER_PROPAGATES = True  # Re-raise exceptions from tasks

# tests/test_integration.py
@pytest.mark.django_db
def test_registration_triggers_welcome_email(client):
    with patch('apps.notifications.services.EmailService') as mock_email:
        response = client.post('/api/users/', {
            'email': 'new@example.com',
            'password': 'strongpass123',
        })

    assert response.status_code == 201
    mock_email.send_welcome.assert_called_once()
```

### Retry のテスト

```python
@pytest.mark.django_db
def test_task_retries_on_connection_error():
    with patch('apps.crm.services.CRMClient.sync') as mock_sync:
        mock_sync.side_effect = ConnectionError('timeout')

        with pytest.raises(ConnectionError):
            sync_contact_to_crm.apply(args=[1], throw=True)

        assert mock_sync.call_count == 1  # First attempt only when eager
```

## モニタリング

```bash
# Inspect active workers and queues
celery -A config inspect active
celery -A config inspect stats
celery -A config inspect reserved

# Check queue lengths (Redis)
redis-cli llen celery

# Flower: web-based real-time monitor
pip install flower
celery -A config flower --port=5555
```

## アンチパターン

```python
# BAD: Passing model instances — they may be stale by execution time
send_welcome_email.delay(user)        # Never pass ORM objects
send_welcome_email.delay(user.pk)     # Always pass PKs

# BAD: Calling tasks synchronously in production views
result = generate_report.apply()      # Blocks the request thread

# BAD: Non-idempotent task without guards
@shared_task
def charge_and_fulfill(order_id):
    order.charge()     # May charge twice if task retries!
    order.fulfill()

# GOOD: Idempotent with status guard
@shared_task
def charge_and_fulfill(order_id):
    order = Order.objects.select_for_update().get(pk=order_id)
    if order.status != Order.Status.PENDING:
        return  # Already processed
    order.charge()
    order.fulfill()
```

## 本番チェックリスト

| 確認項目 | 設定 |
|-------|---------|
| クラッシュ時にワーカーが再起動する | `supervisord` または `systemd` unit |
| `CELERY_TASK_ACKS_LATE = True` | ワーカークラッシュ時に再キューする |
| `CELERY_WORKER_PREFETCH_MULTIPLIER = 1` | 長尺タスクのフェア分配 |
| 優先度別キュー分離 | `-Q default,high_priority,low_priority` |
| `CELERY_TASK_SOFT_TIME_LIMIT` 設定済み | ハードキル前のグレースフルタイムアウト |
| Sentry 連携 | すべての `task_failure` シグナルを捕捉 |
| Flower などの監視 | キュー深さの可視化 |
| Beat は単一ノードでのみ稼働 | 重複スケジュール実行の防止 |

## 関連スキル

- `django-patterns` — ORM、サービスレイヤー、プロジェクト構成
- `django-tdd` — Django のモデル・ビュー・サービスのテスト
- `python-testing` — pytest 設定とフィクスチャ
