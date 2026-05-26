---
name: ui-to-vue
description: ユーザーが UI スクリーンショットや設計エクスポートを Vue 3 コンポーネントに一括変換する必要があるとき、特に Vant、Element Plus、Ant Design Vue で使用する（batch-convert UI screenshots into Vue 3 components）。
origin: community
---

# UI To Vue

UI 設計スクリーンショットを Vue 3 Composition API コンポーネントコードに一括変換する。

## 使用するタイミング

- ユーザーが設計スクリーンショットまたは設計エクスポート画像のディレクトリを提供
- ターゲットアプリケーションが Vue 3
- ユーザーがページコンポーネント、共有コンポーネント、ルータ配線の初回パスを望む
- ユーザーが Vant、Element Plus、または Ant Design Vue をコンポーネントライブラリとして指定

## 使用しないタイミング

- ユーザーがスクリーンショット 1 つだけを持ち、カスタムコンポーネントを望む
- ターゲットプロジェクトが Vue ではない
- 設計が詳細なインタラクションロジック、データフロー、またはアクセシビリティレビューを必要とする
- スクリーンショットに外部モデル API に送信できないプライベート顧客データが含まれる

## 入力

モジュールとページ状態でスクリーンショットをグループ化した入力ディレクトリを使う：

```text
screenshots/
|-- HomePage/
|   |-- List/
|   |   |-- HomePage-List-Default@3x.png
|   |   `-- cut-images/
|   |-- cut-images/
|   `-- HomePage-Default@3x.png
`-- cut-images/
```

サポートされる cut-image ディレクトリ名には `assets`、`icons`、`sprites`、`cut`、`images`、`cut-images` を含む。

## 変換モデル

- ページグループ化：リスト、詳細、フォーム、ローディング、または空状態を表すとき、関連スクリーンショットを 1 つのページコンポーネントに結合
- UI ライブラリマッピング：実用的な場合、ネイティブな視覚要素を Vant、Element Plus、または Ant Design Vue コンポーネントにマップ
- Cut-image 優先度：ページレベルアセット、次にモジュールレベルアセット、次にグローバル共有アセットを優先
- コンポーネント抽出：複数回現れる繰り返し UI 領域を共有コンポーネントに抽出

## CLI 使用法

`npx` でコンバータを実行し、ドキュメント化されたコマンドがグローバルバイナリに依存せずに動作するようにする：

```bash
export DASHSCOPE_API_KEY=your_key
npx ui-to-vue-converter@1.0.2 --input ./screenshots --ui vant --output ./src
```

デスクトップ UI ライブラリには：

```bash
npx ui-to-vue-converter@1.0.2 --input ./designs --ui element-plus --output ./src
npx ui-to-vue-converter@1.0.2 --input ./designs --ui antd-vue --output ./src
```

パッケージがグローバルにインストールされている場合、`ui-to-vue` バイナリを直接使える：

```bash
npm install -g ui-to-vue-converter@1.0.2
ui-to-vue --input ./screenshots --ui vant --output ./src
```

## オプション

| オプション | 説明 | デフォルト |
| --- | --- | --- |
| `--input` | 設計画像ディレクトリ | `./screenshots` |
| `--ui` | UI ライブラリ：`vant`、`element-plus`、`antd-vue` | `vant` |
| `--output` | 出力ディレクトリ | `./src` |
| `--config` | 設定ファイルパス | `./.ui-to-vue.config.json` |

## API キー処理

コンバータは設定ファイルまたは環境から DashScope クレデンシャルを読める。リポジトリでは環境変数を推奨：

```bash
export DASHSCOPE_API_KEY=your_key
```

ローカル設定ファイルが必要な場合、バージョン管理から除外する：

```json
{
  "apiKey": "your_dashscope_key",
  "input": "./designs",
  "ui": "vant",
  "output": "./src"
}
```

```gitignore
.ui-to-vue.config.json
```

## セキュリティとプライバシー

- 設計スクリーンショットは外部モデル API に送信される可能性のあるソース資料として扱う。
- 許可なくプライベート顧客設計でこのフローを実行しない。
- 再現可能なワークフローでは `@latest` ではなくコンバータバージョンをピン留めする。
- コミット前に生成された Vue コードをレビューする。
- `.ui-to-vue.config.json`、API キー、生成されたシークレット、または顧客スクリーンショットをコミットしない。

## 出力レビューチェックリスト

- [ ] ページコンポーネントが `views/` または選択された出力ディレクトリ下に生成された
- [ ] 繰り返し UI 領域は再利用が明確なときのみ `components/` に抽出された
- [ ] ルータ出力がターゲットプロジェクトのルータスタイルと互換性がある
- [ ] 生成コンポーネントが要求された UI ライブラリを一貫して使う
- [ ] 生成 CSS 単位が設計ベースラインにマッチ
- [ ] コードがプロジェクトのフォーマッタ、リンタ、型チェッカ、ビルドを通過
- [ ] コミット前にプレースホルダコピー、モックデータ、生成アセットがレビューされた

## トラブルシューティング

| 問題 | チェック |
| --- | --- |
| `401` または認証エラー | コマンドを実行するシェルで `DASHSCOPE_API_KEY` が設定されているか確認 |
| `command not found: ui-to-vue` | `npx ui-to-vue-converter@1.0.2` 形式を使うか、パッケージをグローバルにインストール |
| Cut 画像が無視される | アセットディレクトリ名がサポートされており、マッチするページまたはモジュール下にネストされているか確認 |
| コンポーネントが要求された UI ライブラリを無視 | 明示的な `--ui` 値で再実行し、生成されたインポートを検査 |
| 生成レイアウト寸法が間違って見える | スクリーンショットエクスポート幅がターゲットライブラリベースラインにマッチするか確認 |

## 参照

- npm パッケージ：`ui-to-vue-converter`
