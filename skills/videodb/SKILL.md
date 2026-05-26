---
name: videodb
description: ビデオと音声を見る、理解する、アクションする（See, Understand, Act on video and audio）。See — ローカルファイル、URL、RTSP／ライブフィード、またはライブデスクトップ録画から取り込み、リアルタイムコンテキストと再生可能ストリームリンクを返す。Understand — フレームを抽出し、ビジュアル／セマンティック／時間インデックスを構築し、タイムスタンプと自動クリップで瞬間を検索。Act — トランスコードと正規化（コーデック、fps、解像度、アスペクト比）、タイムライン編集（字幕、テキスト／画像オーバーレイ、ブランディング、音声オーバーレイ、吹き替え、翻訳）、メディアアセット生成（画像、音声、ビデオ）、ライブストリームまたはデスクトップキャプチャからのイベント用リアルタイムアラート作成。
origin: ECC
allowed-tools: Read Grep Glob Bash(python:*)
argument-hint: "[task description]"
---

# VideoDB スキル

**ビデオ、ライブストリーム、デスクトップセッションの知覚 + メモリ + アクション。**

## 使用するタイミング

### デスクトップ知覚
- **画面、マイク、システム音声**をキャプチャする**デスクトップセッション**を開始／停止
- **ライブコンテキスト**をストリームし、**エピソードセッションメモリ**を保存
- 話されているものと画面で起きていることに対する**リアルタイムアラート／トリガ**を実行
- **セッションサマリ**、検索可能なタイムライン、**再生可能なエビデンスリンク**を生成

### ビデオ取り込み + ストリーム
- **ファイルまたは URL** を取り込み、**再生可能な Web ストリームリンク**を返す
- トランスコード／正規化：**コーデック、ビットレート、fps、解像度、アスペクト比**

### インデックス + 検索（タイムスタンプ + エビデンス）
- **ビジュアル**、**話された**、**キーワード**インデックスを構築
- 検索し、**タイムスタンプ**と**再生可能エビデンス**で正確な瞬間を返す
- 検索結果から**クリップ**を自動作成

### タイムライン編集 + 生成
- 字幕：**生成**、**翻訳**、**焼き付け**
- オーバーレイ：**テキスト／画像／ブランディング**、モーションキャプション
- 音声：**背景音楽**、**ナレーション**、**吹き替え**
- **タイムライン操作**経由のプログラマブルコンポジションとエクスポート

### ライブストリーム（RTSP）+ モニタリング
- **RTSP／ライブフィード**を接続
- **リアルタイムビジュアルと話された理解**を実行し、モニタリングワークフロー用に**イベント／アラート**を発出

## 動作の仕組み

### 共通入力
- ローカル**ファイルパス**、パブリック **URL**、または **RTSP URL**
- デスクトップキャプチャリクエスト：**開始／停止／セッション要約**
- 望ましい操作：理解用コンテキスト取得、トランスコード仕様、インデックス仕様、検索クエリ、クリップ範囲、タイムライン編集、アラートルール

### 共通出力
- **ストリーム URL**
- **タイムスタンプ**と**エビデンスリンク**付き検索結果
- 生成アセット：字幕、音声、画像、クリップ
- ライブストリーム用 **イベント／アラートペイロード**
- デスクトップ **セッションサマリ**とメモリエントリ

### Python コードの実行

VideoDB コードを実行する前に、プロジェクトディレクトリに変更し環境変数をロードする：

```python
from dotenv import load_dotenv
load_dotenv(".env")

import videodb
conn = videodb.connect()
```

これは以下から `VIDEO_DB_API_KEY` を読む：
1. 環境（すでにエクスポートされている場合）
2. 現在ディレクトリのプロジェクト `.env` ファイル

キーが欠落していると、`videodb.connect()` は自動的に `AuthenticationError` を発生させる。

短いインラインコマンドで機能するときにスクリプトファイルを書かない。

インライン Python（`python -c "..."`）を書くときは、常に適切にフォーマットされたコードを使う — ステートメントを分離するためにセミコロンを使い、読みやすく保つ。約 3 ステートメントより長いものには、代わりに heredoc を使う：

```bash
python << 'EOF'
from dotenv import load_dotenv
load_dotenv(".env")

import videodb
conn = videodb.connect()
coll = conn.get_collection()
print(f"Videos: {len(coll.get_videos())}")
EOF
```

### セットアップ

ユーザーが「setup videodb」または類似のことを尋ねたとき：

### 1. SDK をインストール

```bash
pip install "videodb[capture]" python-dotenv
```

`videodb[capture]` が Linux で失敗したら、capture extra なしでインストール：

```bash
pip install videodb python-dotenv
```

### 2. API キーを設定

ユーザーは**いずれか**の方法で `VIDEO_DB_API_KEY` を設定する必要がある：

- **ターミナルでエクスポート**（Claude 起動前）：`export VIDEO_DB_API_KEY=your-key`
- **プロジェクト `.env` ファイル**：プロジェクトの `.env` ファイルに `VIDEO_DB_API_KEY=your-key` を保存

[console.videodb.io](https://console.videodb.io) で無料 API キーを取得（50 無料アップロード、クレジットカード不要）。

**自分で**API キーを読み取り、書き込み、または処理**しない**。常にユーザーに設定させる。

### クイックリファレンス

### メディアアップロード

```python
# URL
video = coll.upload(url="https://example.com/video.mp4")

# YouTube
video = coll.upload(url="https://www.youtube.com/watch?v=VIDEO_ID")

# Local file
video = coll.upload(file_path="/path/to/video.mp4")
```

### トランスクリプト + 字幕

```python
# force=True skips the error if the video is already indexed
video.index_spoken_words(force=True)
text = video.get_transcript_text()
stream_url = video.add_subtitle()
```

### ビデオ内検索

```python
from videodb.exceptions import InvalidRequestError

video.index_spoken_words(force=True)

# search() raises InvalidRequestError when no results are found.
# Always wrap in try/except and treat "No results found" as empty.
try:
    results = video.search("product demo")
    shots = results.get_shots()
    stream_url = results.compile()
except InvalidRequestError as e:
    if "No results found" in str(e):
        shots = []
    else:
        raise
```

### シーン検索

```python
import re
from videodb import SearchType, IndexType, SceneExtractionType
from videodb.exceptions import InvalidRequestError

# index_scenes() has no force parameter — it raises an error if a scene
# index already exists. Extract the existing index ID from the error.
try:
    scene_index_id = video.index_scenes(
        extraction_type=SceneExtractionType.shot_based,
        prompt="Describe the visual content in this scene.",
    )
except Exception as e:
    match = re.search(r"id\s+([a-f0-9]+)", str(e))
    if match:
        scene_index_id = match.group(1)
    else:
        raise

# Use score_threshold to filter low-relevance noise (recommended: 0.3+)
try:
    results = video.search(
        query="person writing on a whiteboard",
        search_type=SearchType.semantic,
        index_type=IndexType.scene,
        scene_index_id=scene_index_id,
        score_threshold=0.3,
    )
    shots = results.get_shots()
    stream_url = results.compile()
except InvalidRequestError as e:
    if "No results found" in str(e):
        shots = []
    else:
        raise
```

### タイムライン編集

**重要：** タイムライン構築前に常にタイムスタンプを検証する：
- `start` は >= 0 でなければならない（負の値はサイレントに受け入れられるが壊れた出力を生む）
- `start` は `end` 未満でなければならない
- `end` は `video.length` 以下でなければならない

```python
from videodb.timeline import Timeline
from videodb.asset import VideoAsset, TextAsset, TextStyle

timeline = Timeline(conn)
timeline.add_inline(VideoAsset(asset_id=video.id, start=10, end=30))
timeline.add_overlay(0, TextAsset(text="The End", duration=3, style=TextStyle(fontsize=36)))
stream_url = timeline.generate_stream()
```

### ビデオのトランスコード（解像度／品質変更）

```python
from videodb import TranscodeMode, VideoConfig, AudioConfig

# Change resolution, quality, or aspect ratio server-side
job_id = conn.transcode(
    source="https://example.com/video.mp4",
    callback_url="https://example.com/webhook",
    mode=TranscodeMode.economy,
    video_config=VideoConfig(resolution=720, quality=23, aspect_ratio="16:9"),
    audio_config=AudioConfig(mute=False),
)
```

### アスペクト比のリフレーム（ソーシャルプラットフォーム向け）

**警告：** `reframe()` は遅いサーバーサイド操作。長いビデオでは数分かかり、タイムアウトする可能性がある。ベストプラクティス：
- 可能なら常に `start`/`end` を使って短いセグメントに制限
- 全長ビデオには非同期処理のため `callback_url` を使う
- 最初に `Timeline` でビデオをトリミングし、次により短い結果をリフレーム

```python
from videodb import ReframeMode

# Always prefer reframing a short segment:
reframed = video.reframe(start=0, end=60, target="vertical", mode=ReframeMode.smart)

# Async reframe for full-length videos (returns None, result via webhook):
video.reframe(target="vertical", callback_url="https://example.com/webhook")

# Presets: "vertical" (9:16), "square" (1:1), "landscape" (16:9)
reframed = video.reframe(start=0, end=60, target="square")

# Custom dimensions
reframed = video.reframe(start=0, end=60, target={"width": 1280, "height": 720})
```

### 生成メディア

```python
image = coll.generate_image(
    prompt="a sunset over mountains",
    aspect_ratio="16:9",
)
```

## エラー処理

```python
from videodb.exceptions import AuthenticationError, InvalidRequestError

try:
    conn = videodb.connect()
except AuthenticationError:
    print("Check your VIDEO_DB_API_KEY")

try:
    video = coll.upload(url="https://example.com/video.mp4")
except InvalidRequestError as e:
    print(f"Upload failed: {e}")
```

### よくある落とし穴

| シナリオ | エラーメッセージ | 解決策 |
|----------|--------------|----------|
| すでにインデックス化されたビデオのインデックス化 | `Spoken word index for video already exists` | すでにインデックス化されている場合スキップするため `video.index_spoken_words(force=True)` を使う |
| シーンインデックスがすでに存在 | `Scene index with id XXXX already exists` | エラーから既存の `scene_index_id` を `re.search(r"id\s+([a-f0-9]+)", str(e))` で抽出 |
| 検索がマッチを見つけない | `InvalidRequestError: No results found` | 例外をキャッチし空の結果として扱う（`shots = []`） |
| リフレームがタイムアウト | 長いビデオで無期限にブロック | セグメントを制限するため `start`/`end` を使うか、非同期に `callback_url` を渡す |
| Timeline の負タイムスタンプ | サイレントに壊れたストリームを生成 | `VideoAsset` 作成前に常に `start >= 0` を検証 |
| `generate_video()` / `create_collection()` 失敗 | `Operation not allowed` または `maximum limit` | プランゲート機能 — ユーザーにプラン制限を通知 |

## 例

### 正規プロンプト
- 「デスクトップキャプチャを開始し、パスワードフィールドが現れたらアラートして」
- 「セッションを録画し、終了時に実行可能なサマリを生成して」
- 「このファイルを取り込み、再生可能なストリームリンクを返して」
- 「このフォルダをインデックス化し、人がいるすべてのシーンを見つけて、タイムスタンプを返して」
- 「字幕を生成し、焼き付け、軽い背景音楽を追加して」
- 「この RTSP URL を接続し、人がゾーンに入ったらアラートして」

### 画面録画（デスクトップキャプチャ）

録画セッション中の WebSocket イベントをキャプチャするために `ws_listener.py` を使う。デスクトップキャプチャは **macOS** のみサポート。

#### クイックスタート

1. **状態ディレクトリを選択**：`STATE_DIR="${VIDEODB_EVENTS_DIR:-$HOME/.local/state/videodb}"`
2. **リスナーを開始**：`VIDEODB_EVENTS_DIR="$STATE_DIR" python scripts/ws_listener.py --clear "$STATE_DIR" &`
3. **WebSocket ID を取得**：`cat "$STATE_DIR/videodb_ws_id"`
4. **キャプチャコードを実行**（完全なワークフローには reference/capture.md を参照）
5. **イベントは以下に書かれる**：`$STATE_DIR/videodb_events.jsonl`

新しいキャプチャ実行を開始するたびに `--clear` を使って、古いトランスクリプトとビジュアルイベントが新しいセッションに漏れないようにする。

#### イベントクエリ

```python
import json
import os
import time
from pathlib import Path

events_dir = Path(os.environ.get("VIDEODB_EVENTS_DIR", Path.home() / ".local" / "state" / "videodb"))
events_file = events_dir / "videodb_events.jsonl"
events = []

if events_file.exists():
    with events_file.open(encoding="utf-8") as handle:
        for line in handle:
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue

transcripts = [e["data"]["text"] for e in events if e.get("channel") == "transcript"]
cutoff = time.time() - 300
recent_visual = [
    e for e in events
    if e.get("channel") == "visual_index" and e["unix_ts"] > cutoff
]
```

## 追加ドキュメント

リファレンスドキュメントはこの SKILL.md ファイルに隣接する `reference/` ディレクトリにある。必要なら Glob ツールでその場所を探す。

- [reference/api-reference.md](reference/api-reference.md) - VideoDB Python SDK API リファレンス完全版
- [reference/search.md](reference/search.md) - ビデオ検索の深掘りガイド（話された単語とシーンベース）
- [reference/editor.md](reference/editor.md) - タイムライン編集、アセット、コンポジション
- [reference/streaming.md](reference/streaming.md) - HLS ストリーミングと即時再生
- [reference/generative.md](reference/generative.md) - AI 駆動メディア生成（画像、ビデオ、音声）
- [reference/rtstream.md](reference/rtstream.md) - ライブストリーム取り込みワークフロー（RTSP/RTMP）
- [reference/rtstream-reference.md](reference/rtstream-reference.md) - RTStream SDK メソッドと AI パイプライン
- [reference/capture.md](reference/capture.md) - デスクトップキャプチャワークフロー
- [reference/capture-reference.md](reference/capture-reference.md) - Capture SDK と WebSocket イベント
- [reference/use-cases.md](reference/use-cases.md) - 一般的なビデオ処理パターンと例

**VideoDB が操作をサポートするときは ffmpeg、moviepy、またはローカルエンコーディングツールを使わない**。以下はすべて VideoDB によってサーバーサイドで処理される — トリミング、クリップ結合、音声や音楽のオーバーレイ、字幕追加、テキスト／画像オーバーレイ、トランスコード、解像度変更、アスペクト比変換、プラットフォーム要件向けリサイズ、転写、メディア生成。reference/editor.md の Limitations 下にリストされた操作（トランジション、速度変更、クロップ／ズーム、カラーグレーディング、ボリュームミキシング）にのみローカルツールにフォールバック。

### 何をいつ使うか

| 問題 | VideoDB ソリューション |
|---------|-----------------|
| プラットフォームがビデオアスペクト比または解像度を拒否 | `video.reframe()` または `VideoConfig` 付きの `conn.transcode()` |
| Twitter/Instagram/TikTok 向けにビデオをリサイズする必要 | `video.reframe(target="vertical")` または `target="square"` |
| 解像度を変更する必要（例：1080p → 720p） | `VideoConfig(resolution=720)` 付きの `conn.transcode()` |
| ビデオに音声／音楽をオーバーレイする必要 | `Timeline` 上の `AudioAsset` |
| 字幕を追加する必要 | `video.add_subtitle()` または `CaptionAsset` |
| クリップを結合／トリムする必要 | `Timeline` 上の `VideoAsset` |
| ナレーション、音楽、または SFX を生成する必要 | `coll.generate_voice()`、`generate_music()`、`generate_sound_effect()` |

## 出所

このスキルのリファレンス資料は `skills/videodb/reference/` 下にローカルにベンダリングされている。
ランタイムで外部リポジトリリンクに従う代わりに上記のローカルコピーを使う。
