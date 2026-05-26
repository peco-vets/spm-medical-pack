---
name: content-hash-cache-pattern
description: SHA-256 コンテンツハッシュを使った高コストなファイル処理結果のキャッシング — パス非依存、自動無効化、サービス層分離付き (content hash cache, SHA-256, file processing, path-independent, auto-invalidate, service layer)。
origin: ECC
---

# コンテンツハッシュファイルキャッシュパターン

SHA-256 コンテンツハッシュをキャッシュキーとして、高コストなファイル処理結果 (PDF 解析、テキスト抽出、画像分析) をキャッシュする。パスベースキャッシングと異なり、このアプローチはファイル移動/リネームを生き残り、コンテンツ変更時に自動無効化される。

## 起動するタイミング

- ファイル処理パイプライン (PDF・画像・テキスト抽出) の構築
- 処理コストが高く、同じファイルが繰り返し処理される
- `--cache/--no-cache` CLI オプションが必要
- 既存の純粋関数を修正せずにキャッシングを追加したい

## コアパターン

### 1. コンテンツハッシュベースのキャッシュキー

ファイルコンテンツ (パスではない) をキャッシュキーとして使う:

```python
import hashlib
from pathlib import Path

_HASH_CHUNK_SIZE = 65536  # 64KB chunks for large files

def compute_file_hash(path: Path) -> str:
    """SHA-256 of file contents (chunked for large files)."""
    if not path.is_file():
        raise FileNotFoundError(f"File not found: {path}")
    sha256 = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(_HASH_CHUNK_SIZE)
            if not chunk:
                break
            sha256.update(chunk)
    return sha256.hexdigest()
```

**なぜコンテンツハッシュか?** ファイルリネーム/移動 = キャッシュヒット。コンテンツ変更 = 自動無効化。インデックスファイル不要。

### 2. キャッシュエントリのための frozen dataclass

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class CacheEntry:
    file_hash: str
    source_path: str
    document: ExtractedDocument  # The cached result
```

### 3. ファイルベースキャッシュストレージ

各キャッシュエントリは `{hash}.json` として保存される — ハッシュによる O(1) ルックアップ、インデックスファイル不要。

```python
import json
from typing import Any

def write_cache(cache_dir: Path, entry: CacheEntry) -> None:
    cache_dir.mkdir(parents=True, exist_ok=True)
    cache_file = cache_dir / f"{entry.file_hash}.json"
    data = serialize_entry(entry)
    cache_file.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")

def read_cache(cache_dir: Path, file_hash: str) -> CacheEntry | None:
    cache_file = cache_dir / f"{file_hash}.json"
    if not cache_file.is_file():
        return None
    try:
        raw = cache_file.read_text(encoding="utf-8")
        data = json.loads(raw)
        return deserialize_entry(data)
    except (json.JSONDecodeError, ValueError, KeyError):
        return None  # Treat corruption as cache miss
```

### 4. サービス層ラッパー (SRP)

処理関数を純粋に保つ。キャッシングを別のサービス層として追加する。

```python
def extract_with_cache(
    file_path: Path,
    *,
    cache_enabled: bool = True,
    cache_dir: Path = Path(".cache"),
) -> ExtractedDocument:
    """Service layer: cache check -> extraction -> cache write."""
    if not cache_enabled:
        return extract_text(file_path)  # Pure function, no cache knowledge

    file_hash = compute_file_hash(file_path)

    # Check cache
    cached = read_cache(cache_dir, file_hash)
    if cached is not None:
        logger.info("Cache hit: %s (hash=%s)", file_path.name, file_hash[:12])
        return cached.document

    # Cache miss -> extract -> store
    logger.info("Cache miss: %s (hash=%s)", file_path.name, file_hash[:12])
    doc = extract_text(file_path)
    entry = CacheEntry(file_hash=file_hash, source_path=str(file_path), document=doc)
    write_cache(cache_dir, entry)
    return doc
```

## 主要設計判断

| 判断 | 根拠 |
|----------|-----------|
| SHA-256 コンテンツハッシュ | パス非依存、コンテンツ変更時に自動無効化 |
| `{hash}.json` ファイル命名 | O(1) ルックアップ、インデックスファイル不要 |
| サービス層ラッパー | SRP: 抽出は純粋に、キャッシュは別の懸念 |
| 手動 JSON シリアライゼーション | frozen dataclass シリアライゼーションのフル制御 |
| 破損は `None` を返す | 優雅な劣化、次回実行時に再処理 |
| `cache_dir.mkdir(parents=True)` | 初回書き込み時の遅延ディレクトリ作成 |

## ベストプラクティス

- **コンテンツをハッシュし、パスではない** — パスは変わるがコンテンツアイデンティティは変わらない
- ハッシュ時に **大きなファイルをチャンク** — メモリにファイル全体をロードしない
- **処理関数を純粋に保つ** — キャッシングについて何も知るべきでない
- デバッグのために切り詰めたハッシュで **キャッシュヒット/ミスをログ**
- **破損を優雅に処理** — 無効なキャッシュエントリはミスとして扱い、決してクラッシュしない

## 避けるべきアンチパターン

```python
# BAD: Path-based caching (breaks on file move/rename)
cache = {"/path/to/file.pdf": result}

# BAD: Adding cache logic inside the processing function (SRP violation)
def extract_text(path, *, cache_enabled=False, cache_dir=None):
    if cache_enabled:  # Now this function has two responsibilities
        ...

# BAD: Using dataclasses.asdict() with nested frozen dataclasses
# (can cause issues with complex nested types)
data = dataclasses.asdict(entry)  # Use manual serialization instead
```

## 利用するタイミング

- ファイル処理パイプライン (PDF 解析・OCR・テキスト抽出・画像分析)
- `--cache/--no-cache` オプションから利益を得る CLI ツール
- 実行間で同じファイルが現れるバッチ処理
- 既存の純粋関数を修正せずにキャッシングを追加

## 利用しないタイミング

- 常に新鮮でなければならないデータ (リアルタイムフィード)
- 極めて大きくなるキャッシュエントリ (代わりにストリーミングを検討)
- ファイルコンテンツを超えるパラメータに依存する結果 (例: 異なる抽出設定)
