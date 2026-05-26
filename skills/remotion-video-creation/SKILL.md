---
name: remotion-video-creation
description: Remotion のベストプラクティス（Video creation in React）。3D、アニメーション、オーディオ、キャプション、チャート、トランジションなどをカバーする 29 のドメイン固有ルール。
metadata:
  tags: remotion, video, react, animation, composition, three.js, lottie
---

## 使用するタイミング

Remotion コードを扱う際にドメイン固有の知識を得るためにこのスキルを使う。

## 使用方法

詳細な説明とコード例については、個別のルールファイルを読む：

- [rules/3d.md](rules/3d.md) - Three.js と React Three Fiber を使った Remotion の 3D コンテンツ
- [rules/animations.md](rules/animations.md) - Remotion の基本的なアニメーションスキル
- [rules/assets.md](rules/assets.md) - Remotion への画像、動画、音声、フォントのインポート
- [rules/audio.md](rules/audio.md) - Remotion での音声利用 — インポート、トリミング、音量、速度、ピッチ
- [rules/calculate-metadata.md](rules/calculate-metadata.md) - コンポジションの再生時間・サイズ・props を動的に設定
- [rules/can-decode.md](rules/can-decode.md) - Mediabunny を使ってブラウザで動画をデコードできるか確認
- [rules/charts.md](rules/charts.md) - Remotion のチャートとデータ可視化パターン
- [rules/compositions.md](rules/compositions.md) - コンポジション、静止画、フォルダ、デフォルト props、動的メタデータの定義
- [rules/display-captions.md](rules/display-captions.md) - TikTok スタイルのページと単語ハイライト付きでキャプションを表示
- [rules/extract-frames.md](rules/extract-frames.md) - Mediabunny を使って動画から特定タイムスタンプのフレームを抽出
- [rules/fonts.md](rules/fonts.md) - Remotion で Google Fonts およびローカルフォントをロード
- [rules/get-audio-duration.md](rules/get-audio-duration.md) - Mediabunny で音声ファイルの長さ（秒）を取得
- [rules/get-video-dimensions.md](rules/get-video-dimensions.md) - Mediabunny で動画ファイルの幅と高さを取得
- [rules/get-video-duration.md](rules/get-video-duration.md) - Mediabunny で動画ファイルの長さ（秒）を取得
- [rules/gifs.md](rules/gifs.md) - Remotion のタイムラインに同期した GIF 表示
- [rules/images.md](rules/images.md) - Img コンポーネントで Remotion に画像を埋め込み
- [rules/import-srt-captions.md](rules/import-srt-captions.md) - @remotion/captions で .srt 字幕ファイルをインポート
- [rules/lottie.md](rules/lottie.md) - Remotion に Lottie アニメーションを埋め込み
- [rules/measuring-dom-nodes.md](rules/measuring-dom-nodes.md) - Remotion で DOM 要素の寸法を測定
- [rules/measuring-text.md](rules/measuring-text.md) - テキストの寸法測定、コンテナへのフィット、オーバーフロー確認
- [rules/sequencing.md](rules/sequencing.md) - Remotion のシーケンシングパターン — 遅延、トリム、アイテムの再生時間制限
- [rules/tailwind.md](rules/tailwind.md) - Remotion で TailwindCSS を使用
- [rules/text-animations.md](rules/text-animations.md) - Remotion のタイポグラフィとテキストアニメーションパターン
- [rules/timing.md](rules/timing.md) - Remotion の補間曲線 — 線形、イージング、スプリングアニメーション
- [rules/transcribe-captions.md](rules/transcribe-captions.md) - 音声を文字起こしして Remotion のキャプションを生成
- [rules/transitions.md](rules/transitions.md) - Remotion のシーントランジションパターン
- [rules/trimming.md](rules/trimming.md) - Remotion のトリミングパターン — アニメーションの最初または最後をカット
- [rules/videos.md](rules/videos.md) - Remotion での動画埋め込み — トリミング、音量、速度、ループ、ピッチ
