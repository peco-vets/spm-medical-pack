# ECC Selective Install 設計

## 目的

本ドキュメントは ECC のユーザー向け selective-install 設計を定義する。

内部ランタイムアーキテクチャとコード境界にフォーカスする `docs/SELECTIVE-INSTALL-ARCHITECTURE.md` を補完する。

本ドキュメントはプロダクトとオペレータの問いに先に答える:

- ユーザーが ECC コンポーネントをどう選ぶか
- CLI がどう感じるべきか
- どの設定ファイルが存在すべきか
- ハーネスターゲット間でインストールがどう振る舞うべきか
- 設計が現 ECC コードベースに、書き直し無しでどうマップするか

## 問題

リポジトリが現在初期版マニフェストとライフサイクルサポートを持っていても、ECC は依然大きなペイロードインストーラのように感じる。

ユーザーはよりシンプルなメンタルモデルが必要:

- ベースラインをインストール
- 実際に使う言語パックを追加
- 実際に欲しいフレームワーク設定を追加
- セキュリティ、研究、オーケストレーションのようなオプショナル能力パックを追加

selective-install システムは ECC を all-or-nothing ではなく合成可能に感じさせるべきである。

現基盤では、ユーザー向けコンポーネントは依然より粗い内部インストールモジュール上のエイリアスレイヤである。つまり include/exclude はモジュール選択レベルで既に有用だが、基底モジュールグラフがより細かく分割されるまで一部のファイルレベル境界は不完全のままである。

## ゴール

1. ユーザーが小さなデフォルト ECC フットプリントをすばやくインストールできる。
2. ユーザーが再利用可能コンポーネントファミリーからインストールを構成できる:
   - core rules
   - language packs
   - framework packs
   - capability packs
   - target/platform configs
3. Claude、Cursor、Antigravity、Codex、OpenCode 全体で 1 つの一貫した UX を保つ。
4. インストールを検査可能、修復可能、アンインストール可能に保つ。
5. ロールアウト中に現行 `ecc-install typescript` スタイルとの後方互換を保持する。

## 非ゴール

- 第一フェーズで ECC を複数の npm パッケージにパッケージング
- リモートマーケットプレース構築
- 同フェーズでフルコントロールプレーン UI
- selective install が出荷する前にすべてのスキル分類問題を解決

## ユーザー体験原則

### 1. 小さく始める

ユーザーは 1 つのコマンドで有用な ECC インストールを得られるべき:

```bash
ecc install --target claude --profile core
```

デフォルト体験は、ユーザーがすべてのスキルファミリーとすべてのフレームワークを望むと仮定すべきでない。

### 2. 意図で積み上げる

ユーザーは以下の観点で考えるべき:

- 「developer ベースラインが欲しい」
- 「TypeScript と Python が必要」
- 「Next.js と Django が欲しい」
- 「security パックが欲しい」

ユーザーは生の内部リポジトリパスを知る必要は無いべき。

### 3. 変更前にプレビュー

すべてのインストールパスは dry-run プランニングをサポートすべき:

```bash
ecc install --target cursor --profile developer --with lang:typescript --with framework:nextjs --dry-run
```

プランは明確に示すべき:

- 選択コンポーネント
- スキップコンポーネント
- ターゲットルート
- 管理パス
- 期待される install-state 場所

### 4. ローカル設定はファーストクラスであるべき

チームはプロジェクトレベルインストール設定をコミットでき、以下を使えるべき:

```bash
ecc install --config ecc-install.json
```

これによりコントリビューターと CI 全体で決定論的インストールが可能になる。

## コンポーネントモデル

現マニフェストは既にインストールモジュールとプロファイルを使う。ユーザー向け設計はその内部構造を保つべきだが、4 つの主要コンポーネントファミリーとして提示する。

近期実装ノート: 一部のユーザー向けコンポーネント ID は依然共有内部モジュールに解決される(特に言語/フレームワークレイヤ)。カタログは即座に UX を改善しつつ、後のフェーズでより細かいモジュール粒度へのクリーンなパスを保持する。

### 1. ベースライン

これらはデフォルト ECC ビルディングブロックである:

- core rules
- baseline agents
- core commands
- runtime hooks
- platform configs
- workflow quality primitives

現内部モジュールの例:

- `rules-core`
- `agents-core`
- `commands-core`
- `hooks-runtime`
- `platform-configs`
- `workflow-quality`

### 2. 言語パック

言語パックは言語エコシステム用のルール、ガイダンス、ワークフローをグループ化する。

例:

- `lang:typescript`
- `lang:python`
- `lang:go`
- `lang:java`
- `lang:rust`

各言語パックは 1 つ以上の内部モジュールに加えてターゲット固有アセットに解決すべき。

### 3. フレームワークパック

フレームワークパックは言語パックの上に位置し、フレームワーク固有ルール、スキル、オプショナルセットアップを取り込む。

例:

- `framework:react`
- `framework:nextjs`
- `framework:django`
- `framework:springboot`
- `framework:laravel`

フレームワークパックは適切な場合に正しい言語パックまたはベースラインプリミティブに依存すべき。

### 4. 能力パック

能力パックは横断的 ECC 機能バンドルである。

例:

- `capability:security`
- `capability:research`
- `capability:orchestration`
- `capability:media`
- `capability:content`

これらはマニフェストで既に導入されている現モジュールファミリーにマップすべき。

## プロファイル

プロファイルは依然最速のオンランプである。

推奨ユーザー向けプロファイル:

- `core`
  最小ベースライン、ECC を試す多くのユーザーに安全なデフォルト
- `developer`
  アクティブなソフトウェアエンジニアリング作業のための最良デフォルト
- `security`
  ベースラインに加えてセキュリティ重視ガイダンス
- `research`
  ベースラインに加えて研究/コンテンツ/調査ツール
- `full`
  分類済みで現在サポートされているすべて

プロファイルは追加 `--with` と `--without` フラグで合成可能であるべき。

例:

```bash
ecc install --target claude --profile developer --with lang:typescript --with framework:nextjs --without capability:orchestration
```

## 提案 CLI 設計

### 主要コマンド

```bash
ecc install
ecc plan
ecc list-installed
ecc doctor
ecc repair
ecc uninstall
ecc catalog
```

### Install CLI

推奨形状:

```bash
ecc install [--target <target>] [--profile <name>] [--with <component>]... [--without <component>]... [--config <path>] [--dry-run] [--json]
```

例:

```bash
ecc install --target claude --profile core
ecc install --target cursor --profile developer --with lang:typescript --with framework:nextjs
ecc install --target antigravity --with capability:security --with lang:python
ecc install --config ecc-install.json
```

### Plan CLI

推奨形状:

```bash
ecc plan [same selection flags as install]
```

目的:

- 変更無しでプレビューを生成
- selective install の canonical デバッグサーフェスとして機能

### Catalog CLI

推奨形状:

```bash
ecc catalog profiles
ecc catalog components
ecc catalog components --family language
ecc catalog show framework:nextjs
```

目的:

- ユーザーがドキュメントを読まずに有効なコンポーネント名を発見できる
- 設定オーサリングを親しみやすく保つ

### 互換 CLI

これらレガシーフローはマイグレーション中も動作すべき:

```bash
ecc-install typescript
ecc-install --target cursor typescript
ecc typescript
```

内部的にこれらは新リクエストモデルに正規化し、モダンインストールと同じ方法で install-state を書くべき。

## 提案設定ファイル

### ファイル名

推奨デフォルト:

- `ecc-install.json`

オプショナル将来サポート:

- `.ecc/install.json`

### 設定形状

```json
{
  "$schema": "./schemas/ecc-install-config.schema.json",
  "version": 1,
  "target": "cursor",
  "profile": "developer",
  "include": [
    "lang:typescript",
    "lang:python",
    "framework:nextjs",
    "capability:security"
  ],
  "exclude": [
    "capability:media"
  ],
  "options": {
    "hooksProfile": "standard",
    "mcpCatalog": "baseline",
    "includeExamples": false
  }
}
```

### フィールドセマンティクス

- `target`
  選択ハーネスターゲット (`claude`、`cursor`、`antigravity` など)
- `profile`
  開始ベースラインプロファイル
- `include`
  追加コンポーネント
- `exclude`
  プロファイル結果から減算するコンポーネント
- `options`
  コンポーネントアイデンティティを変えないターゲット/ランタイムチューニングフラグ

### 優先順位ルール

1. CLI 引数が設定ファイル値を上書きする。
2. 設定ファイルがプロファイルデフォルトを上書きする。
3. プロファイルデフォルトが内部モジュールデフォルトを上書きする。

これは挙動を予測可能で説明しやすく保つ。

## モジュラーインストールフロー

ユーザー向けフローは:

1. 提供された、または自動検出された設定ファイルをロード
2. 設定意図の上に CLI 意図をマージ
3. リクエストを canonical 選択に正規化
4. プロファイルをベースラインコンポーネントに展開
5. `include` コンポーネントを追加
6. `exclude` コンポーネントを減算
7. 依存関係とターゲット互換を解決
8. プランをレンダー
9. dry-run モードでなければオペレーションを適用
10. install-state を書く

重要な UX 特性は、正確に同じフローが以下を駆動することである:

- `install`
- `plan`
- `repair`
- `uninstall`

コマンドはアクションで異なり、ECC が選択インストールを理解する方法では異ならない。

## ターゲット挙動

selective install は全ターゲット間で同じ概念的コンポーネントグラフを保持しつつ、ターゲットアダプタにコンテンツがどう着地するかを決めさせるべきである。

### Claude

最適な用途:

- home-scoped ECC ベースライン
- コマンド、エージェント、ルール、フック、プラットフォーム設定、オーケストレーション

### Cursor

最適な用途:

- project-scoped インストール
- ルールに加えてプロジェクトローカル自動化と設定

### Antigravity

最適な用途:

- project-scoped エージェント/ルール/ワークフローインストール

### Codex / OpenCode

インストーラの特殊フォークではなく加算的ターゲットのまま残るべき。

selective-install 設計は、これらを新インストーラアーキテクチャではなく、単に新アダプタに加えて新ターゲット固有マッピングルールにすべきである。

## 技術的実現可能性

この設計はリポジトリが既に以下を持つため実現可能である:

- インストールモジュールとプロファイルマニフェスト
- install-state パスを持つターゲットアダプタ
- プラン検査
- install-state 記録
- ライフサイクルコマンド
- 統一 `ecc` CLI サーフェス

欠落作業は概念的発明ではない。欠落作業は現基盤をよりクリーンなユーザー向けコンポーネントモデルにプロダクト化することである。

### Phase 1 で実現可能

- profile + include/exclude 選択
- `ecc-install.json` 設定ファイルパース
- catalog/discovery コマンド
- ユーザー向けコンポーネント ID から内部モジュールセットへのエイリアスマッピング
- dry-run と JSON プランニング

### Phase 2 で実現可能

- より豊富なターゲットアダプタセマンティクス
- 設定様アセット用のマージ認識オペレーション
- 非コピーオペレーション用のより強い repair/uninstall 挙動

### 後で

- 削減された publish サーフェス
- 生成スリムバンドル
- リモートコンポーネントフェッチ

## 現 ECC マニフェストへのマッピング

現マニフェストは真のユーザー向け `lang:*` / `framework:*` / `capability:*` 分類体系をまだ公開していない。それは既存モジュール上のプレゼンテーションレイヤとして導入されるべきで、2 つ目のインストーラエンジンとしてではない。

推奨アプローチ:

- `install-modules.json` を内部解決カタログとして保つ
- フレンドリーなコンポーネント ID を 1 つ以上の内部モジュールにマップするユーザー向けコンポーネントカタログを追加
- マイグレーション窓中はプロファイルが内部モジュールまたはユーザー向けコンポーネント ID のいずれかを参照できるようにする

これは UX を改善しつつ現 selective-install 基盤を壊さない。

## 推奨ロールアウト

### Phase 1: 設計とディスカバリ

- ユーザー向けコンポーネント分類体系を最終化
- 設定スキーマを追加
- CLI 設計と優先順位ルールを追加

### Phase 2: ユーザー向け解決レイヤ

- コンポーネントエイリアスを実装
- 設定ファイルパースを実装
- `include` / `exclude` を実装
- `catalog` を実装

### Phase 3: より強いターゲットセマンティクス

- より多くのロジックをターゲット所有プランニングに移す
- merge/generate オペレーションをクリーンにサポート
- repair/uninstall 忠実度を改善

### Phase 4: パッケージング最適化

- publish サーフェスを狭める
- 生成バンドルを評価

## 推奨

次の実装移動は「インストーラを書き直す」ではないべきである。

それは:

1. 現マニフェスト/ランタイム基盤を保つ
2. ユーザー向けコンポーネントカタログと設定ファイルを追加
3. `include` / `exclude` 選択とカタログディスカバリを追加
4. 既存プランナとライフサイクルスタックにそのモデルを消費させる

これは現 ECC コードベースから、大きなレガシーインストーラではなく ECC 2.0 のように感じる実際の selective install 体験への最短パスである。
