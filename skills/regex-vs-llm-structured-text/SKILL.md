---
name: regex-vs-llm-structured-text
description: 構造化テキストをパースする際に正規表現と LLM のどちらを選ぶかの意思決定フレームワーク（regex vs LLM）。正規表現から始め、低信頼のエッジケースにのみ LLM を追加する。
origin: ECC
---

# 構造化テキストのパースにおける Regex vs LLM

構造化テキスト（クイズ、フォーム、請求書、ドキュメント）をパースするための実用的な意思決定フレームワークである。鍵となる洞察：正規表現はケースの 95-98% を安価かつ決定的に処理する。高価な LLM 呼び出しは残りのエッジケースのために予約する。

## 起動するタイミング

- 繰り返しパターンを持つ構造化テキスト（質問、フォーム、テーブル）のパース
- テキスト抽出に正規表現と LLM のどちらを使うかの決定
- 両アプローチを組み合わせたハイブリッドパイプラインの構築
- テキスト処理におけるコスト／精度トレードオフの最適化

## 意思決定フレームワーク

```
テキストフォーマットは一貫し繰り返しているか？
├── はい（>90% がパターンに従う）→ 正規表現から開始
│   ├── 正規表現が 95%+ 処理 → 完了。LLM 不要
│   └── 正規表現が <95% 処理 → エッジケースのみ LLM を追加
└── いいえ（自由形式、可変性高）→ LLM を直接使う
```

## アーキテクチャパターン

```
ソーステキスト
    │
    ▼
[Regex Parser] ─── 構造を抽出（95-98% 精度）
    │
    ▼
[Text Cleaner] ─── ノイズを除去（マーカー、ページ番号、アーティファクト）
    │
    ▼
[Confidence Scorer] ─── 低信頼の抽出をフラグ付け
    │
    ├── 高信頼（≥0.95）→ 直接出力
    │
    └── 低信頼（<0.95）→ [LLM Validator] → 出力
```

## 実装

### 1. Regex Parser（大多数を処理）

```python
import re
from dataclasses import dataclass

@dataclass(frozen=True)
class ParsedItem:
    id: str
    text: str
    choices: tuple[str, ...]
    answer: str
    confidence: float = 1.0

def parse_structured_text(content: str) -> list[ParsedItem]:
    """Parse structured text using regex patterns."""
    pattern = re.compile(
        r"(?P<id>\d+)\.\s*(?P<text>.+?)\n"
        r"(?P<choices>(?:[A-D]\..+?\n)+)"
        r"Answer:\s*(?P<answer>[A-D])",
        re.MULTILINE | re.DOTALL,
    )
    items = []
    for match in pattern.finditer(content):
        choices = tuple(
            c.strip() for c in re.findall(r"[A-D]\.\s*(.+)", match.group("choices"))
        )
        items.append(ParsedItem(
            id=match.group("id"),
            text=match.group("text").strip(),
            choices=choices,
            answer=match.group("answer"),
        ))
    return items
```

### 2. 信頼度スコアリング

LLM レビューが必要かもしれない項目をフラグ付けする：

```python
@dataclass(frozen=True)
class ConfidenceFlag:
    item_id: str
    score: float
    reasons: tuple[str, ...]

def score_confidence(item: ParsedItem) -> ConfidenceFlag:
    """Score extraction confidence and flag issues."""
    reasons = []
    score = 1.0

    if len(item.choices) < 3:
        reasons.append("few_choices")
        score -= 0.3

    if not item.answer:
        reasons.append("missing_answer")
        score -= 0.5

    if len(item.text) < 10:
        reasons.append("short_text")
        score -= 0.2

    return ConfidenceFlag(
        item_id=item.id,
        score=max(0.0, score),
        reasons=tuple(reasons),
    )

def identify_low_confidence(
    items: list[ParsedItem],
    threshold: float = 0.95,
) -> list[ConfidenceFlag]:
    """Return items below confidence threshold."""
    flags = [score_confidence(item) for item in items]
    return [f for f in flags if f.score < threshold]
```

### 3. LLM Validator（エッジケースのみ）

```python
def validate_with_llm(
    item: ParsedItem,
    original_text: str,
    client,
) -> ParsedItem:
    """Use LLM to fix low-confidence extractions."""
    response = client.messages.create(
        model="claude-haiku-4-5-20251001",  # Cheapest model for validation
        max_tokens=500,
        messages=[{
            "role": "user",
            "content": (
                f"Extract the question, choices, and answer from this text.\n\n"
                f"Text: {original_text}\n\n"
                f"Current extraction: {item}\n\n"
                f"Return corrected JSON if needed, or 'CORRECT' if accurate."
            ),
        }],
    )
    # Parse LLM response and return corrected item...
    return corrected_item
```

### 4. ハイブリッドパイプライン

```python
def process_document(
    content: str,
    *,
    llm_client=None,
    confidence_threshold: float = 0.95,
) -> list[ParsedItem]:
    """Full pipeline: regex -> confidence check -> LLM for edge cases."""
    # Step 1: Regex extraction (handles 95-98%)
    items = parse_structured_text(content)

    # Step 2: Confidence scoring
    low_confidence = identify_low_confidence(items, confidence_threshold)

    if not low_confidence or llm_client is None:
        return items

    # Step 3: LLM validation (only for flagged items)
    low_conf_ids = {f.item_id for f in low_confidence}
    result = []
    for item in items:
        if item.id in low_conf_ids:
            result.append(validate_with_llm(item, content, llm_client))
        else:
            result.append(item)

    return result
```

## 実世界のメトリック

本番のクイズパースパイプライン（410 件）から：

| メトリック | 値 |
|--------|-------|
| 正規表現成功率 | 98.0% |
| 低信頼項目 | 8（2.0%） |
| 必要な LLM 呼び出し | 約 5 |
| すべて LLM の場合に対するコスト削減 | 約 95% |
| テストカバレッジ | 93% |

## ベストプラクティス

- **正規表現から始める** — 不完全な正規表現でも改善のベースラインになる
- **信頼度スコアリングを使う**ことで、LLM の助けが必要なものをプログラムで特定する
- 検証には**最も安い LLM** を使う（Haiku クラスのモデルで十分）
- パース済み項目を**決して変異させない** — クリーニング／検証ステップから新しいインスタンスを返す
- パーサには **TDD がうまく機能する** — 既知パターンのテストを先に書き、次にエッジケース
- パイプラインの健全性を追跡するため**メトリックを記録**する（正規表現成功率、LLM 呼び出し数）

## 避けるべきアンチパターン

- 正規表現が 95%+ のケースを処理するのにすべてのテキストを LLM に送る（高価で遅い）
- 自由形式で可変性の高いテキストに正規表現を使う（ここでは LLM が良い）
- 信頼度スコアリングをスキップして正規表現が「そのまま動く」ことを期待する
- クリーニング／検証ステップ中にパース済みオブジェクトを変異させる
- エッジケース（不正な入力、欠落フィールド、エンコーディング問題）をテストしない

## 使用するタイミング

- クイズ／試験問題のパース
- フォームデータ抽出
- 請求書／領収書処理
- ドキュメント構造パース（ヘッダ、セクション、テーブル）
- コストが重要な、繰り返しパターンを持つあらゆる構造化テキスト
