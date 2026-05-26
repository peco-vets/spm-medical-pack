---
name: agent-sort
description: 並列の repo 認識レビューパスを使い、スキル・コマンド・ルール・フック・追加要素を DAILY バケットと LIBRARY バケットに分類し、特定リポジトリのための証拠に基づく ECC インストール計画を構築する。フルバンドルを読み込むのではなく、プロジェクトが実際に必要とするものに ECC を絞り込む場合に使用する (agent sort, ECC install plan, daily vs library, repo-aware classification, skill triage)。
origin: ECC
---

# Agent Sort

リポジトリがデフォルトのフルインストールではなくプロジェクト固有の ECC サーフェスを必要とするときにこのスキルを使う。

目標は「役に立ちそうな気がする」と推測することではない。実際のコードベースからの証拠で ECC コンポーネントを分類することである。

## 利用するタイミング

- プロジェクトが ECC の一部のみを必要としており、フルインストールがノイズだらけになる場合
- リポジトリのスタックは明確だが、誰もスキルを一つひとつ手作業でキュレートしたくない場合
- 主観ではなく grep の証拠に裏付けされた繰り返し可能なインストール判断をチームが望む場合
- 常にロードされるデイリーワークフローサーフェスと、検索可能なライブラリ/参照サーフェスを分離する必要がある場合
- リポジトリが誤った言語・ルール・フックセットに漂流しており、クリーンアップが必要な場合

## 譲れないルール

- 一般的な好みではなく、現在のリポジトリを真実のソースとして使う
- すべての DAILY 判断は具体的なリポジトリ証拠を引用しなければならない
- LIBRARY は「削除」を意味しない。「デフォルトでロードせずアクセス可能に保つ」を意味する
- 現在のリポジトリが使えないフック・ルール・スクリプトをインストールしない
- ECC ネイティブのサーフェスを優先し、二つ目のインストールシステムを導入しない

## 成果物

以下のアーティファクトを順に生成する:

1. DAILY インベントリ
2. LIBRARY インベントリ
3. インストール計画
4. 検証レポート
5. プロジェクトが望むなら任意の `skill-library` ルーター

## 分類モデル

2 つのバケットのみを使う:

- `DAILY`
  - このリポジトリの全セッションでロードすべき
  - リポジトリの言語・フレームワーク・ワークフロー・オペレーターサーフェスに強く一致する
- `LIBRARY`
  - 保持する価値はあるが、デフォルトでロードする価値はない
  - 検索・ルータースキル・選択的な手動使用を介してアクセス可能なままにすべき

## 証拠ソース

分類を行う前にリポジトリローカルの証拠を使う:

- ファイル拡張子
- パッケージマネージャーとロックファイル
- フレームワーク設定
- CI とフック設定
- ビルド/テストスクリプト
- インポートと依存マニフェスト
- スタックを明示的に記述するリポジトリドキュメント

役立つコマンド:

```bash
rg --files
rg -n "typescript|react|next|supabase|django|spring|flutter|swift"
cat package.json
cat pyproject.toml
cat Cargo.toml
cat pubspec.yaml
cat go.mod
```

## 並列レビューパス

並列サブエージェントが利用可能な場合、レビューを以下のパスに分割する:

1. Agents
   - `agents/*` を分類する
2. Skills
   - `skills/*` を分類する
3. Commands
   - `commands/*` を分類する
4. Rules
   - `rules/*` を分類する
5. Hooks とスクリプト
   - フックサーフェス・MCP ヘルスチェック・ヘルパースクリプト・OS 互換性を分類する
6. Extras
   - コンテキスト・例・MCP 設定・テンプレート・ガイダンスドキュメントを分類する

サブエージェントが利用できない場合は同じパスを順次実行する。

## 主要ワークフロー

### 1. リポジトリを読む

何かを分類する前に、実際のスタックを確立する:

- 使用言語
- 使用フレームワーク
- 主要パッケージマネージャー
- テストスタック
- lint/format スタック
- デプロイ/ランタイムサーフェス
- 既存のオペレーター統合

### 2. 証拠テーブルを構築する

候補サーフェスごとに以下を記録する:

- コンポーネントパス
- コンポーネント種類
- 提案バケット
- リポジトリ証拠
- 短い正当化

以下のフォーマットを使う:

```text
skills/frontend-patterns | skill | DAILY | 84 .tsx files, next.config.ts present | core frontend stack
skills/django-patterns   | skill | LIBRARY | no .py files, no pyproject.toml       | not active in this repo
rules/typescript/*       | rules | DAILY | package.json + tsconfig.json            | active TS repo
rules/python/*           | rules | LIBRARY | zero Python source files             | keep accessible only
```

### 3. DAILY 対 LIBRARY を判断する

以下の場合 `DAILY` に昇格する:

- リポジトリが対応するスタックを明らかに使用している
- コンポーネントが汎用的で、すべてのセッションで役立つ
- リポジトリが対応するランタイムまたはワークフローに既に依存している

以下の場合 `LIBRARY` に降格する:

- コンポーネントがスタック外
- リポジトリが将来必要とするかもしれないが、毎日ではない
- 即時の関連性なしに文脈のオーバーヘッドを追加する

### 4. インストール計画を構築する

分類をアクションに翻訳する:

- DAILY スキル -> `.claude/skills/` にインストールまたは保持
- DAILY コマンド -> まだ有用な場合のみ明示的なシムとして保持
- DAILY ルール -> 一致する言語セットのみインストール
- DAILY フック/スクリプト -> 互換性のあるもののみ保持
- LIBRARY サーフェス -> 検索または `skill-library` を介してアクセス可能に保つ

リポジトリが既に選択的インストールを使用しているなら、新しいシステムを作るのではなく既存のプランを更新する。

### 5. 任意のライブラリルーターを作成する

プロジェクトが検索可能なライブラリサーフェスを望むなら以下を作成する:

- `.claude/skills/skill-library/SKILL.md`

そのルーターには以下を含めるべきである:

- DAILY 対 LIBRARY の短い説明
- グループ化されたトリガーキーワード
- ライブラリ参照の所在

ルーター内に各スキルの本体を重複させない。

### 6. 結果を検証する

プランが適用された後、以下を検証する:

- すべての DAILY ファイルが期待される場所に存在する
- 古い言語ルールが有効なまま残されていない
- 互換性のないフックがインストールされていない
- 結果のインストールが実際にリポジトリのスタックと一致する

以下を含むコンパクトなレポートを返す:

- DAILY 数
- LIBRARY 数
- 削除された古いサーフェス
- 未解決の質問

## ハンドオフ

次のステップが対話型インストールや修復なら、以下にハンドオフする:

- `configure-ecc`

次のステップが重複のクリーンアップやカタログレビューなら、以下にハンドオフする:

- `skill-stocktake`

次のステップがより広範な文脈削減なら、以下にハンドオフする:

- `strategic-compact`

## 出力フォーマット

以下の順序で結果を返す:

```text
STACK
- language/framework/runtime summary

DAILY
- always-loaded items with evidence

LIBRARY
- searchable/reference items with evidence

INSTALL PLAN
- what should be installed, removed, or routed

VERIFICATION
- checks run and remaining gaps
```
