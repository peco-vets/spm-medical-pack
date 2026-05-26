---
name: redis-patterns
description: 本番アプリケーション向けの Redis データ構造パターン、キャッシュ戦略、分散ロック、レート制限、pub/sub、コネクション管理（Redis data structures, caching, distributed locks, rate limiting, pub/sub, connection management）。
origin: ECC
---

# Redis パターン

一般的なバックエンドユースケースにおける Redis ベストプラクティスのクイックリファレンスである。

## 動作の仕組み

Redis はインメモリのデータ構造ストアで、strings、hashes、lists、sets、sorted sets、streams などをサポートする。個々の Redis コマンドは単一インスタンス上でアトミックである。複数ステップのワークフローでは、アトミック性を保つために Lua スクリプト、MULTI/EXEC トランザクション、または明示的同期が必要である。データは任意で RDB スナップショットまたは AOF ログ経由で永続化される。クライアントは RESP プロトコルを使用して TCP 経由で通信する。リクエストごとのハンドシェイクオーバーヘッドを回避するためコネクションプールが不可欠である。

## 起動するタイミング

- アプリケーションにキャッシュを追加する
- レート制限やスロットリングを実装する
- 分散ロックや調整を構築する
- セッションやトークンストレージを設定する
- メッセージング用に Pub/Sub または Redis Streams を使う
- 本番で Redis を設定する（プーリング、エビクション、クラスタリング）

## データ構造チートシート

| ユースケース | 構造 | キー例 |
|----------|-----------|-------------|
| シンプルキャッシュ | String | `product:123` |
| ユーザーセッション | Hash | `session:abc` |
| リーダーボード | Sorted Set | `scores:weekly` |
| ユニークビジター | Set | `visitors:2024-01-01` |
| アクティビティフィード | List | `feed:user:456` |
| イベントストリーム | Stream | `events:orders` |
| カウンタ／レート制限 | String (INCR) | `ratelimit:user:123` |
| ブルームフィルタ／HLL | HyperLogLog | `hll:pageviews` |

## コアパターン

### Cache-Aside（遅延ロード）

```python
import redis
import json

r = redis.Redis(host='localhost', port=6379, decode_responses=True)

def get_product(product_id: int):
    cache_key = f"product:{product_id}"
    cached = r.get(cache_key)

    if cached:
        return json.loads(cached)

    product = db.query("SELECT * FROM products WHERE id = %s", product_id)
    r.setex(cache_key, 3600, json.dumps(product))  # TTL: 1 hour
    return product
```

### Write-Through キャッシュ

```python
def update_product(product_id: int, data: dict):
    # Write to DB first
    db.execute("UPDATE products SET ... WHERE id = %s", product_id)

    # Immediately update cache
    cache_key = f"product:{product_id}"
    r.setex(cache_key, 3600, json.dumps(data))
```

### キャッシュ無効化

```python
# Tag-based invalidation — group related keys under a set
def cache_product(product_id: int, category_id: int, data: dict):
    key = f"product:{product_id}"
    tag = f"tag:category:{category_id}"
    pipe = r.pipeline(transaction=True)
    pipe.setex(key, 3600, json.dumps(data))
    pipe.sadd(tag, key)
    pipe.expire(tag, 3600)
    pipe.execute()

def invalidate_category(category_id: int):
    tag = f"tag:category:{category_id}"
    keys = r.smembers(tag)
    if keys:
        r.delete(*keys)
    r.delete(tag)
```

### セッションストレージ

```python
import time
import uuid

def create_session(user_id: int, ttl: int = 86400) -> str:
    session_id = str(uuid.uuid4())
    key = f"session:{session_id}"
    pipe = r.pipeline(transaction=True)
    pipe.hset(key, mapping={
        "user_id": user_id,
        "created_at": int(time.time()),
    })
    pipe.expire(key, ttl)
    pipe.execute()
    return session_id

def get_session(session_id: str) -> dict | None:
    data = r.hgetall(f"session:{session_id}")
    return data if data else None

def delete_session(session_id: str):
    r.delete(f"session:{session_id}")
```

## レート制限

### 固定ウィンドウ（シンプル）

```python
def is_rate_limited(user_id: int, limit: int = 100, window: int = 60) -> bool:
    key = f"ratelimit:{user_id}:{int(time.time()) // window}"
    pipe = r.pipeline(transaction=True)
    pipe.incr(key)
    pipe.expire(key, window)
    count, _ = pipe.execute()
    return count > limit
```

### スライディングウィンドウ（Lua — アトミック）

```lua
-- sliding_window.lua
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])

redis.call('ZREMRANGEBYSCORE', key, 0, now - window)
local count = redis.call('ZCARD', key)

if count < limit then
    -- Use unique member (now + sequence) to avoid collisions within the same millisecond
    local seq_key = key .. ':seq'
    local seq = redis.call('INCR', seq_key)
    redis.call('EXPIRE', seq_key, math.ceil(window / 1000))
    redis.call('ZADD', key, now, now .. '-' .. seq)
    redis.call('EXPIRE', key, math.ceil(window / 1000))
    return 1
end
return 0
```

```python
sliding_window = r.register_script(open('sliding_window.lua').read())

def allow_request(user_id: int) -> bool:
    key = f"ratelimit:sliding:{user_id}"
    now = int(time.time() * 1000)
    return bool(sliding_window(keys=[key], args=[now, 60000, 100]))
```

## 分散ロック

### 分散ロック（単一ノード — SET NX PX）

```python
import uuid

def acquire_lock(resource: str, ttl_ms: int = 5000) -> str | None:
    lock_key = f"lock:{resource}"
    token = str(uuid.uuid4())
    acquired = r.set(lock_key, token, px=ttl_ms, nx=True)
    return token if acquired else None

def release_lock(resource: str, token: str) -> bool:
    release_script = """
    if redis.call('get', KEYS[1]) == ARGV[1] then
        return redis.call('del', KEYS[1])
    else
        return 0
    end
    """
    result = r.eval(release_script, 1, f"lock:{resource}", token)
    return bool(result)

# Usage
token = acquire_lock("order:payment:123")
if token:
    try:
        process_payment()
    finally:
        release_lock("order:payment:123", token)
```

> マルチノード構成では完全な Redlock アルゴリズムを実装する `redlock-py` ライブラリを使う。

## Pub/Sub と Streams

### Pub/Sub（Fire-and-Forget）

```python
# Publisher
def publish_event(channel: str, payload: dict):
    r.publish(channel, json.dumps(payload))

# Subscriber (blocking — run in separate thread/process)
def subscribe_events(channel: str):
    pubsub = r.pubsub()
    pubsub.subscribe(channel)
    for message in pubsub.listen():
        if message['type'] == 'message':
            handle(json.loads(message['data']))
```

### Redis Streams（耐久キュー）

```python
# Producer
def emit(stream: str, event: dict):
    r.xadd(stream, event, maxlen=10000)  # Cap stream length

# Consumer group — guarantees at-least-once delivery
try:
    r.xgroup_create('events:orders', 'processor', id='0', mkstream=True)
except Exception:
    pass  # Group already exists

def consume(stream: str, group: str, consumer: str):
    while True:
        messages = r.xreadgroup(group, consumer, {stream: '>'}, count=10, block=2000)
        for _, entries in (messages or []):
            for msg_id, data in entries:
                process(data)
                r.xack(stream, group, msg_id)
```

> 配信保証、コンシューマグループ、リプレイが必要な場合は Pub/Sub より **Streams** を推奨する。

## キー設計

### 命名規則

```
# Pattern: resource:id:field
user:123:profile
order:456:status
cache:product:789

# Pattern: namespace:resource:id
myapp:session:abc123
myapp:ratelimit:user:123

# Pattern: resource:date (time-bound keys)
stats:pageviews:2024-01-01
```

### TTL 戦略

| データ型 | 推奨 TTL |
|-----------|--------------|
| ユーザーセッション | 24 時間（`86400`） |
| API レスポンスキャッシュ | 5–15 分 |
| レート制限ウィンドウ | ウィンドウサイズに一致 |
| 短命トークン | 5–10 分 |
| リーダーボード | 1 時間–24 時間 |
| 静的／参照データ | 1 時間–1 週間 |

常に TTL を設定する。TTL なしのキーは無制限に蓄積されメモリ圧迫を引き起こす。

## コネクション管理

### コネクションプーリング

```python
from redis import ConnectionPool, Redis

pool = ConnectionPool(
    host='localhost',
    port=6379,
    db=0,
    max_connections=20,
    decode_responses=True,
    socket_connect_timeout=2,
    socket_timeout=2,
)

r = Redis(connection_pool=pool)
```

### クラスタモード

```python
from redis.cluster import RedisCluster

r = RedisCluster(
    startup_nodes=[{"host": "redis-1", "port": 6379}],
    decode_responses=True,
    skip_full_coverage_check=True,
)
```

### Sentinel（高可用性）

```python
from redis.sentinel import Sentinel

sentinel = Sentinel(
    [('sentinel-1', 26379), ('sentinel-2', 26379)],
    socket_timeout=0.5,
)
master = sentinel.master_for('mymaster', decode_responses=True)
replica = sentinel.slave_for('mymaster', decode_responses=True)
```

## エビクションポリシー

| ポリシー | 動作 | 最適 |
|--------|----------|----------|
| `noeviction` | フル時に書き込みエラー | キュー／クリティカルデータ |
| `allkeys-lru` | 最も最近使われていないものを排除 | 汎用キャッシュ |
| `volatile-lru` | TTL のあるキーのみで LRU | 混在データストア |
| `allkeys-lfu` | 最も使用頻度の低いものを排除 | 偏ったアクセスパターン |
| `volatile-ttl` | 最も早く期限切れのものを排除 | 長寿命データを優先 |

`redis.conf` 経由で設定：`maxmemory-policy allkeys-lru`

## アンチパターン

| アンチパターン | 問題 | 修正 |
|---|---|---|
| TTL なしのキー | メモリが無制限に増大 | 常に TTL を設定 |
| 本番での `KEYS *` | サーバーをブロックする（O(N)） | `SCAN` カーソルを使う |
| 大きな blob（>100KB）の保存 | 遅いシリアライゼーション、メモリ圧迫 | リファレンスを保存しオブジェクトストアから取得 |
| 全部に単一 Redis | キャッシュとキューの分離なし | 別個の DB またはインスタンスを使う |
| コネクションプール上限を無視 | 負荷時のコネクション枯渇 | ワークロードに合わせてプールサイズを決める |
| キャッシュミススタンピードを処理しない | コールドスタートで thundering herd | ロックまたは確率的早期期限切れを使う |
| 思慮なしの `FLUSHALL` | インスタンス全体を消去 | キーパターンで削除をスコープする |

### キャッシュミススタンピード防止

```python
import threading

_locks: dict[str, threading.Lock] = {}
_locks_mutex = threading.Lock()

def get_with_lock(key: str, fetch_fn, ttl: int = 300):
    cached = r.get(key)
    if cached:
        return json.loads(cached)

    with _locks_mutex:
        if key not in _locks:
            _locks[key] = threading.Lock()
        lock = _locks[key]
    with lock:
        cached = r.get(key)  # Re-check after acquiring lock
        if cached:
            return json.loads(cached)
        value = fetch_fn()
        r.setex(key, ttl, json.dumps(value))
        return value
```

> 注：マルチプロセスデプロイでは、プロセス内ロックを上記分散ロックセクションの `acquire_lock`/`release_lock` で置き換える。

## 例

**Django/Flask API エンドポイントにキャッシュを追加：**
`setex` と 5 分 TTL でレスポンスに cache-aside を使う。リクエストパラメータでキーを作る。

**ユーザー単位で API のレート制限：**
低トラフィックエンドポイントには `pipeline(transaction=True)` での固定ウィンドウを使う。正確なユーザー単位スロットリングにはスライディングウィンドウ Lua を使う。

**ワーカー間でバックグラウンドジョブを調整：**
期待されるジョブ持続時間を超える TTL で `acquire_lock` を使う。常に `finally` ブロックで解放する。

**複数サブスクライバへの通知ファンアウト：**
fire-and-forget には Pub/Sub を使う。遅いコンシューマ向けに保証された配信またはリプレイが必要なら Streams に切り替える。

## クイックリファレンス

| パターン | 使用するタイミング |
|---------|-------------|
| Cache-aside | 読み込み重視、わずかな陳腐化を許容 |
| Write-through | 強整合性が必要 |
| 分散ロック | リソースへの並行アクセスを防ぐ |
| スライディングウィンドウレート制限 | 正確なユーザー単位スロットリング |
| Redis Streams | コンシューマグループ付き耐久イベントキュー |
| Pub/Sub | 配信保証が不要なブロードキャスト |
| Sorted Set リーダーボード | ランク付きスコアリング、ページネーション |
| HyperLogLog | 低メモリでの近似ユニークカウント |

## 関連

- スキル：`postgres-patterns` — リレーショナルデータパターン
- スキル：`backend-patterns` — API およびサービス層パターン
- スキル：`database-migrations` — スキーマバージョニング
- スキル：`django-patterns` — Django キャッシュフレームワーク統合
- エージェント：`database-reviewer` — 完全なデータベースレビューワークフロー
