---
name: fal-ai-media
description: fal.ai MCP 経由の統合メディア生成（fal.ai, image generation, video generation, audio generation）。画像・動画・音声を扱う。text-to-image（Nano Banana）、text/image-to-video（Seedance、Kling、Veo 3）、text-to-speech（CSM-1B）、video-to-audio（ThinkSound）を網羅する。ユーザーが AI で画像・動画・音声を生成したいときに用いる。
origin: ECC
---

# fal.ai メディア生成

> **ドリフトしやすいスキル。** fal.ai のモデル ID・価格・入力・MCP ツール名は高速に変化する。特定モデル・パラメータ・出力フォーマット・コストを約束する前に、現行のモデルメタデータを検索または取得して確認すること。

MCP 経由で fal.ai モデルを使って画像・動画・音声を生成する。

## 起動タイミング

- テキストプロンプトから画像を生成したい場合
- テキスト・画像から動画を生成する場合
- 音声・音楽・効果音を生成する場合
- 任意のメディア生成タスク
- ユーザーが "generate image"、"create video"、"text to speech"、"make a thumbnail" 等と発言した場合

## MCP 要件

fal.ai MCP サーバの構成が必要である。`~/.claude.json` に追加する。

```json
"fal-ai": {
  "command": "npx",
  "args": ["-y", "fal-ai-mcp-server"],
  "env": { "FAL_KEY": "YOUR_FAL_KEY_HERE" }
}
```

API キーは [fal.ai](https://fal.ai) で取得する。

## MCP ツール

fal.ai MCP は以下を提供する。
- `search` — キーワードで利用可能モデルを検索
- `find` — モデル詳細とパラメータを取得
- `generate` — モデルをパラメータ付きで実行
- `result` — 非同期生成のステータス確認
- `status` — ジョブステータス確認
- `cancel` — 実行中ジョブのキャンセル
- `estimate_cost` — 生成コスト見積
- `models` — 人気モデル一覧
- `upload` — 入力として使うファイルのアップロード

---

## 画像生成

### Nano Banana 2（高速）

用途: 高速イテレーション、ドラフト、text-to-image、画像編集。

```
generate(
  app_id: "fal-ai/nano-banana-2",
  input_data: {
    "prompt": "a futuristic cityscape at sunset, cyberpunk style",
    "image_size": "landscape_16_9",
    "num_images": 1,
    "seed": 42
  }
)
```

### Nano Banana Pro（高品質）

用途: 本番画像、リアリズム、タイポグラフィ、詳細プロンプト。

```
generate(
  app_id: "fal-ai/nano-banana-pro",
  input_data: {
    "prompt": "professional product photo of wireless headphones on marble surface, studio lighting",
    "image_size": "square",
    "num_images": 1,
    "guidance_scale": 7.5
  }
)
```

### 共通画像パラメータ

| Param | Type | Options | Notes |
|-------|------|---------|-------|
| `prompt` | string | required | Describe what you want |
| `image_size` | string | `square`, `portrait_4_3`, `landscape_16_9`, `portrait_16_9`, `landscape_4_3` | Aspect ratio |
| `num_images` | number | 1-4 | How many to generate |
| `seed` | number | any integer | Reproducibility |
| `guidance_scale` | number | 1-20 | How closely to follow the prompt (higher = more literal) |

### 画像編集

Nano Banana 2 に入力画像を与え、inpainting・outpainting・スタイル転写を行う。

```
# First upload the source image
upload(file_path: "/path/to/image.png")

# Then generate with image input
generate(
  app_id: "fal-ai/nano-banana-2",
  input_data: {
    "prompt": "same scene but in watercolor style",
    "image_url": "<uploaded_url>",
    "image_size": "landscape_16_9"
  }
)
```

---

## 動画生成

### Seedance 1.0 Pro（ByteDance）

用途: text-to-video、高モーション品質の image-to-video。

```
generate(
  app_id: "fal-ai/seedance-1-0-pro",
  input_data: {
    "prompt": "a drone flyover of a mountain lake at golden hour, cinematic",
    "duration": "5s",
    "aspect_ratio": "16:9",
    "seed": 42
  }
)
```

### Kling Video v3 Pro

用途: 音声ネイティブ生成を伴う text/image-to-video。

```
generate(
  app_id: "fal-ai/kling-video/v3/pro",
  input_data: {
    "prompt": "ocean waves crashing on a rocky coast, dramatic clouds",
    "duration": "5s",
    "aspect_ratio": "16:9"
  }
)
```

### Veo 3（Google DeepMind）

用途: 生成サウンド付き動画、高ビジュアル品質。

```
generate(
  app_id: "fal-ai/veo-3",
  input_data: {
    "prompt": "a bustling Tokyo street market at night, neon signs, crowd noise",
    "aspect_ratio": "16:9"
  }
)
```

### Image-to-Video

既存画像から開始する。

```
generate(
  app_id: "fal-ai/seedance-1-0-pro",
  input_data: {
    "prompt": "camera slowly zooms out, gentle wind moves the trees",
    "image_url": "<uploaded_image_url>",
    "duration": "5s"
  }
)
```

### 動画パラメータ

| Param | Type | Options | Notes |
|-------|------|---------|-------|
| `prompt` | string | required | Describe the video |
| `duration` | string | `"5s"`, `"10s"` | Video length |
| `aspect_ratio` | string | `"16:9"`, `"9:16"`, `"1:1"` | Frame ratio |
| `seed` | number | any integer | Reproducibility |
| `image_url` | string | URL | Source image for image-to-video |

---

## 音声生成

### CSM-1B（会話音声）

自然な会話品質の text-to-speech。

```
generate(
  app_id: "fal-ai/csm-1b",
  input_data: {
    "text": "Hello, welcome to the demo. Let me show you how this works.",
    "speaker_id": 0
  }
)
```

### ThinkSound（Video-to-Audio）

動画コンテンツに合う音声を生成する。

```
generate(
  app_id: "fal-ai/thinksound",
  input_data: {
    "video_url": "<video_url>",
    "prompt": "ambient forest sounds with birds chirping"
  }
)
```

### ElevenLabs（API 直接、MCP なし）

プロ品質音声合成には ElevenLabs を直接使う。

```python
import os
import requests

resp = requests.post(
    "https://api.elevenlabs.io/v1/text-to-speech/<voice_id>",
    headers={
        "xi-api-key": os.environ["ELEVENLABS_API_KEY"],
        "Content-Type": "application/json"
    },
    json={
        "text": "Your text here",
        "model_id": "eleven_turbo_v2_5",
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
    }
)
with open("output.mp3", "wb") as f:
    f.write(resp.content)
```

### VideoDB Generative Audio

VideoDB が構成済みなら、その生成音声を使う。

```python
# Voice generation
audio = coll.generate_voice(text="Your narration here", voice="alloy")

# Music generation
music = coll.generate_music(prompt="upbeat electronic background music", duration=30)

# Sound effects
sfx = coll.generate_sound_effect(prompt="thunder crack followed by rain")
```

---

## コスト見積

生成前に推定コストを確認する。

```
estimate_cost(
  estimate_type: "unit_price",
  endpoints: {
    "fal-ai/nano-banana-pro": {
      "unit_quantity": 1
    }
  }
)
```

## モデル探索

特定タスク用モデルを検索する。

```
search(query: "text to video")
find(endpoint_ids: ["fal-ai/seedance-1-0-pro"])
models()
```

## ヒント

- プロンプトのイテレーション時は再現性のため `seed` を使う
- プロンプト探索は低コストモデル（Nano Banana 2）で行い、最終出力で Pro に切り替える
- 動画はプロンプトを記述的だが簡潔に保ち、モーションとシーンに焦点を置く
- Image-to-video は純粋な text-to-video より制御しやすい結果が得られる
- 高コスト動画生成前に `estimate_cost` を確認する

## 関連スキル

- `videodb` — 動画処理・編集・ストリーミング
- `video-editing` — AI ドリブンな動画編集ワークフロー
- `content-engine` — ソーシャルプラットフォーム向けコンテンツ作成
