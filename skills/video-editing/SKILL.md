---
name: video-editing
description: 実映像を切る、構造化する、補強するための AI 支援ビデオ編集ワークフロー（AI-assisted video editing for cutting, structuring, augmenting real footage）。生キャプチャから FFmpeg、Remotion、ElevenLabs、fal.ai、Descript または CapCut での最終仕上げまでのフルパイプラインをカバー。ユーザーがビデオを編集、映像を切る、vlog を作成、またはビデオコンテンツを構築したいときに使用する。
origin: ECC
---

# Video Editing

実映像のための AI 支援編集。プロンプトからの生成ではない。既存ビデオを高速に編集。

## 起動するタイミング

- ユーザーがビデオ映像を編集、切る、構造化したい
- 長い録画を短形式コンテンツに変える
- 生キャプチャから vlog、チュートリアル、デモビデオを構築
- 既存ビデオにオーバーレイ、字幕、音楽、ナレーションを追加
- 異なるプラットフォーム向けにビデオをリフレーム（YouTube、TikTok、Instagram）
- ユーザーが「edit video」「cut this footage」「make a vlog」「video workflow」と言う

## コアテーゼ

AI ビデオ編集は、ビデオ全体を作成することを依頼するのをやめ、実映像を圧縮、構造化、補強するために使い始めたときに有用。価値は生成ではない。価値は圧縮。

## パイプライン

```
Screen Studio / raw footage
  → Claude / Codex
  → FFmpeg
  → Remotion
  → ElevenLabs / fal.ai
  → Descript or CapCut
```

各層には特定の仕事がある。層をスキップしない。1 つのツールにすべてをさせようとしない。

## 層 1：キャプチャ（Screen Studio / 生映像）

ソース資料を収集：
- **Screen Studio**：アプリデモ、コーディングセッション、ブラウザワークフロー用の磨かれた画面録画
- **生カメラ映像**：vlog 映像、インタビュー、イベント録画
- **VideoDB によるデスクトップキャプチャ**：リアルタイムコンテキスト付きセッション録画（`videodb` スキル参照）

出力：整理準備が整った生ファイル。

## 層 2：整理（Claude / Codex）

Claude Code または Codex を使う：
- **転写とラベル付け**：トランスクリプトを生成、トピックとテーマを特定
- **構造計画**：何を残し、何をカットし、どの順序が機能するかを決定
- **デッドセクションを特定**：ポーズ、脱線、繰り返しテイクを見つける
- **編集決定リストを生成**：カットのタイムスタンプ、保持するセグメント
- **FFmpeg と Remotion コードを足場化**：コマンドとコンポジションを生成

```
プロンプト例：
「これは 4 時間録画のトランスクリプト。24 分の vlog 用に最も強い 8 セグメントを特定して。
各セグメントに FFmpeg カットコマンドをください」
```

この層は構造についてで、最終的な創造的味覚ではない。

## 層 3：決定的カット（FFmpeg）

FFmpeg は退屈だが重要な作業を扱う：分割、トリミング、連結、前処理。

### タイムスタンプでセグメントを抽出

```bash
ffmpeg -i raw.mp4 -ss 00:12:30 -to 00:15:45 -c copy segment_01.mp4
```

### 編集決定リストからバッチカット

```bash
#!/bin/bash
# cuts.txt: start,end,label
while IFS=, read -r start end label; do
  ffmpeg -i raw.mp4 -ss "$start" -to "$end" -c copy "segments/${label}.mp4"
done < cuts.txt
```

### セグメントを連結

```bash
# Create file list
for f in segments/*.mp4; do echo "file '$f'"; done > concat.txt
ffmpeg -f concat -safe 0 -i concat.txt -c copy assembled.mp4
```

### 高速編集用にプロキシを作成

```bash
ffmpeg -i raw.mp4 -vf "scale=960:-2" -c:v libx264 -preset ultrafast -crf 28 proxy.mp4
```

### 転写用に音声を抽出

```bash
ffmpeg -i raw.mp4 -vn -acodec pcm_s16le -ar 16000 audio.wav
```

### 音声レベルを正規化

```bash
ffmpeg -i segment.mp4 -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:v copy normalized.mp4
```

## 層 4：プログラマブルコンポジション（Remotion）

Remotion は編集問題をコンポーザブルコードに変える。伝統的エディタが苦しめることに使う：

### Remotion を使うとき

- オーバーレイ：テキスト、画像、ブランディング、ローワーサード
- データ可視化：チャート、統計、アニメーション数字
- モーショングラフィックス：トランジション、解説アニメーション
- コンポーザブルシーン：ビデオ全体での再利用可能テンプレート
- 製品デモ：注釈付きスクリーンショット、UI ハイライト

### 基本 Remotion コンポジション

```tsx
import { AbsoluteFill, Sequence, Video, useCurrentFrame } from "remotion";

export const VlogComposition: React.FC = () => {
  const frame = useCurrentFrame();

  return (
    <AbsoluteFill>
      {/* Main footage */}
      <Sequence from={0} durationInFrames={300}>
        <Video src="/segments/intro.mp4" />
      </Sequence>

      {/* Title overlay */}
      <Sequence from={30} durationInFrames={90}>
        <AbsoluteFill style={{
          justifyContent: "center",
          alignItems: "center",
        }}>
          <h1 style={{
            fontSize: 72,
            color: "white",
            textShadow: "2px 2px 8px rgba(0,0,0,0.8)",
          }}>
            The AI Editing Stack
          </h1>
        </AbsoluteFill>
      </Sequence>

      {/* Next segment */}
      <Sequence from={300} durationInFrames={450}>
        <Video src="/segments/demo.mp4" />
      </Sequence>
    </AbsoluteFill>
  );
};
```

### 出力をレンダリング

```bash
npx remotion render src/index.ts VlogComposition output.mp4
```

詳細なパターンと API リファレンスは [Remotion ドキュメント](https://www.remotion.dev/docs) を参照。

## 層 5：生成アセット（ElevenLabs / fal.ai）

必要なものだけ生成する。ビデオ全体を生成しない。

### ElevenLabs でのナレーション

```python
import os
import requests

resp = requests.post(
    f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}",
    headers={
        "xi-api-key": os.environ["ELEVENLABS_API_KEY"],
        "Content-Type": "application/json"
    },
    json={
        "text": "Your narration text here",
        "model_id": "eleven_turbo_v2_5",
        "voice_settings": {"stability": 0.5, "similarity_boost": 0.75}
    }
)
with open("voiceover.mp3", "wb") as f:
    f.write(resp.content)
```

### fal.ai での音楽と SFX

以下のために `fal-ai-media` スキルを使う：
- 背景音楽生成
- 効果音（ビデオから音声への ThinkSound モデル）
- トランジションサウンド

### fal.ai での生成ビジュアル

存在しないインサートショット、サムネイル、または b-roll に使う：
```
generate(app_id: "fal-ai/nano-banana-pro", input_data: {
  "prompt": "professional thumbnail for tech vlog, dark background, code on screen",
  "image_size": "landscape_16_9"
})
```

### VideoDB 生成音声

VideoDB が設定されている場合：
```python
voiceover = coll.generate_voice(text="Narration here", voice="alloy")
music = coll.generate_music(prompt="lo-fi background for coding vlog", duration=120)
sfx = coll.generate_sound_effect(prompt="subtle whoosh transition")
```

## 層 6：最終仕上げ（Descript / CapCut）

最終層は人間。伝統的エディタを以下に使う：
- **ペーシング**：速すぎたり遅すぎたりするカットを調整
- **キャプション**：自動生成、次に手動クリーンアップ
- **カラーグレーディング**：基本補正とムード
- **最終オーディオミックス**：音声、音楽、SFX レベルのバランス
- **エクスポート**：プラットフォーム固有のフォーマットと品質設定

ここに味覚が住む。AI は繰り返し作業をクリアする。あなたが最終決定を下す。

## ソーシャルメディアリフレーミング

異なるプラットフォームには異なるアスペクト比が必要：

| プラットフォーム | アスペクト比 | 解像度 |
|----------|-------------|------------|
| YouTube | 16:9 | 1920x1080 |
| TikTok / Reels | 9:16 | 1080x1920 |
| Instagram フィード | 1:1 | 1080x1080 |
| X / Twitter | 16:9 または 1:1 | 1280x720 または 720x720 |

### FFmpeg でリフレーム

```bash
# 16:9 to 9:16 (center crop)
ffmpeg -i input.mp4 -vf "crop=ih*9/16:ih,scale=1080:1920" vertical.mp4

# 16:9 to 1:1 (center crop)
ffmpeg -i input.mp4 -vf "crop=ih:ih,scale=1080:1080" square.mp4
```

### VideoDB でリフレーム

```python
from videodb import ReframeMode

# Smart reframe (AI-guided subject tracking)
reframed = video.reframe(start=0, end=60, target="vertical", mode=ReframeMode.smart)
```

## シーン検出と自動カット

### FFmpeg シーン検出

```bash
# Detect scene changes (threshold 0.3 = moderate sensitivity)
ffmpeg -i input.mp4 -vf "select='gt(scene,0.3)',showinfo" -vsync vfr -f null - 2>&1 | grep showinfo
```

### 自動カット用無音検出

```bash
# Find silent segments (useful for cutting dead air)
ffmpeg -i input.mp4 -af silencedetect=noise=-30dB:d=2 -f null - 2>&1 | grep silence
```

### ハイライト抽出

Claude を使ってトランスクリプト + シーンタイムスタンプを解析：
```
「タイムスタンプ付きこのトランスクリプトとこれらのシーン変更点を考えて、
ソーシャルメディア向けに最もエンゲージメントの高い 30 秒クリップを 5 つ特定して」
```

## 各ツールが最も得意なこと

| ツール | 強み | 弱み |
|------|----------|----------|
| Claude / Codex | 整理、計画、コード生成 | 創造的味覚層ではない |
| FFmpeg | 決定的カット、バッチ処理、フォーマット変換 | ビジュアル編集 UI なし |
| Remotion | プログラマブルオーバーレイ、コンポーザブルシーン、再利用可能テンプレート | 非開発者向け学習曲線 |
| Screen Studio | 即座に磨かれた画面録画 | 画面キャプチャのみ |
| ElevenLabs | 音声、ナレーション、音楽、SFX | ワークフローの中心ではない |
| Descript / CapCut | 最終ペーシング、キャプション、仕上げ | 手動、自動化不可 |

## キー原則

1. **編集して、生成しない。** このワークフローは実映像を切るためで、プロンプトから作成するためではない。
2. **スタイルの前に構造。** ビジュアルを触る前に層 2 でストーリーを正しくする。
3. **FFmpeg がバックボーン。** 退屈だが重要。長い映像が管理可能になる場所。
4. **再利用性のための Remotion。** 1 度以上行うなら、Remotion コンポーネントにする。
5. **選択的に生成。** AI 生成を、存在しないアセットにのみ使い、すべてではない。
6. **味覚は最後の層。** AI は繰り返し作業をクリアする。あなたが最終創造的決定を下す。

## 関連スキル

- `fal-ai-media` — AI 画像、ビデオ、音声生成
- `videodb` — サーバーサイドビデオ処理、インデックス化、ストリーミング
- `content-engine` — プラットフォームネイティブコンテンツ配信
