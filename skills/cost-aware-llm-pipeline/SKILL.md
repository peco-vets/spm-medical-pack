---
name: cost-aware-llm-pipeline
description: LLM API 利用のためのコスト最適化パターン — タスク複雑度によるモデルルーティング、予算追跡、リトライロジック、プロンプトキャッシング (cost-aware LLM pipeline, model routing, budget, retry, prompt caching, Anthropic, Claude)。
origin: ECC
---

# コスト認識 LLM パイプライン

品質を維持しながら LLM API コストを制御するパターン。モデルルーティング、予算追跡、リトライロジック、プロンプトキャッシングを構成可能なパイプラインに組み合わせる。

## 起動するタイミング

- LLM API (Claude・GPT 等) を呼ぶアプリケーションの構築
- 様々な複雑度のアイテムバッチの処理
- API 支出の予算内に留まる必要がある
- 複雑なタスクの品質を犠牲にせずコストを最適化する

## コアコンセプト

### 1. タスク複雑度によるモデルルーティング

シンプルなタスクには自動的に安いモデルを選択し、複雑なものに高価なモデルを予約する。

```python
MODEL_SONNET = "claude-sonnet-4-6"
MODEL_HAIKU = "claude-haiku-4-5-20251001"

_SONNET_TEXT_THRESHOLD = 10_000  # chars
_SONNET_ITEM_THRESHOLD = 30     # items

def select_model(
    text_length: int,
    item_count: int,
    force_model: str | None = None,
) -> str:
    """Select model based on task complexity."""
    if force_model is not None:
        return force_model
    if text_length >= _SONNET_TEXT_THRESHOLD or item_count >= _SONNET_ITEM_THRESHOLD:
        return MODEL_SONNET  # Complex task
    return MODEL_HAIKU  # Simple task (3-4x cheaper)
```

### 2. 不変コスト追跡

frozen dataclass で累積支出を追跡する。各 API 呼び出しは新しいトラッカーを返す — 決して状態を変更しない。

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class CostRecord:
    model: str
    input_tokens: int
    output_tokens: int
    cost_usd: float

@dataclass(frozen=True, slots=True)
class CostTracker:
    budget_limit: float = 1.00
    records: tuple[CostRecord, ...] = ()

    def add(self, record: CostRecord) -> "CostTracker":
        """Return new tracker with added record (never mutates self)."""
        return CostTracker(
            budget_limit=self.budget_limit,
            records=(*self.records, record),
        )

    @property
    def total_cost(self) -> float:
        return sum(r.cost_usd for r in self.records)

    @property
    def over_budget(self) -> bool:
        return self.total_cost > self.budget_limit
```

### 3. 狭いリトライロジック

一過性エラーのみリトライする。認証や bad request エラーには素早く失敗する。

```python
from anthropic import (
    APIConnectionError,
    InternalServerError,
    RateLimitError,
)

_RETRYABLE_ERRORS = (APIConnectionError, RateLimitError, InternalServerError)
_MAX_RETRIES = 3

def call_with_retry(func, *, max_retries: int = _MAX_RETRIES):
    """Retry only on transient errors, fail fast on others."""
    for attempt in range(max_retries):
        try:
            return func()
        except _RETRYABLE_ERRORS:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)  # Exponential backoff
    # AuthenticationError, BadRequestError etc. → raise immediately
```

### 4. プロンプトキャッシング

長いシステムプロンプトをキャッシュしてすべてのリクエストで再送信しないようにする。

```python
messages = [
    {
        "role": "user",
        "content": [
            {
                "type": "text",
                "text": system_prompt,
                "cache_control": {"type": "ephemeral"},  # Cache this
            },
            {
                "type": "text",
                "text": user_input,  # Variable part
            },
        ],
    }
]
```

## 構成

4 つすべての技術を単一のパイプライン関数に組み合わせる:

```python
def process(text: str, config: Config, tracker: CostTracker) -> tuple[Result, CostTracker]:
    # 1. Route model
    model = select_model(len(text), estimated_items, config.force_model)

    # 2. Check budget
    if tracker.over_budget:
        raise BudgetExceededError(tracker.total_cost, tracker.budget_limit)

    # 3. Call with retry + caching
    response = call_with_retry(lambda: client.messages.create(
        model=model,
        messages=build_cached_messages(system_prompt, text),
    ))

    # 4. Track cost (immutable)
    record = CostRecord(model=model, input_tokens=..., output_tokens=..., cost_usd=...)
    tracker = tracker.add(record)

    return parse_result(response), tracker
```

## 価格参照 (2025-2026)

| モデル | Input ($/1M tokens) | Output ($/1M tokens) | 相対コスト |
|-------|---------------------|----------------------|---------------|
| Haiku 4.5 | $0.80 | $4.00 | 1x |
| Sonnet 4.6 | $3.00 | $15.00 | ~4x |
| Opus 4.5 | $15.00 | $75.00 | ~19x |

## ベストプラクティス

- **最も安いモデルから始める**、複雑度しきい値が満たされたときのみ高価なモデルにルーティング
- バッチ処理前に **明示的な予算制限を設定する** — 使い過ぎより早く失敗
- **モデル選択判断をログ** し、実データに基づいてしきい値をチューニングできるように
- 1024 トークンを超えるシステムプロンプトには **プロンプトキャッシングを使う** — コストとレイテンシ両方を節約
- **認証やバリデーションエラーで決してリトライしない** — 一過性失敗 (ネットワーク・レート制限・サーバエラー) のみ

## 避けるべきアンチパターン

- 複雑度に関係なくすべてのリクエストに最も高価なモデルを使う
- すべてのエラーでリトライ (永続的失敗で予算を浪費)
- コスト追跡状態を変更 (デバッグと監査を難しくする)
- コードベース全体でモデル名をハードコード (定数や設定を使う)
- 繰り返しのシステムプロンプトでプロンプトキャッシングを無視

## 利用するタイミング

- Claude・OpenAI・類似 LLM API を呼ぶすべてのアプリケーション
- コストが急速に積み上がるバッチ処理パイプライン
- インテリジェントルーティングを必要とするマルチモデルアーキテクチャ
- 予算ガードレールが必要な本番システム
