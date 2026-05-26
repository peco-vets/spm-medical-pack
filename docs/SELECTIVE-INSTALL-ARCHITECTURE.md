# ECC 2.0 Selective Install ディスカバリ

## 目的

本ドキュメントは 3 月 11 日メガプランの selective-install 要件を、具体的な ECC 2.0 ディスカバリ設計に変える。

目標は「インストール時にコピーされるファイル数の削減」だけではない。実際のターゲットは、決定論的に以下に答えられるインストールシステムである:

- 何が要求されたか
- 何が解決されたか
- 何がコピーまたは生成されたか
- どのターゲット固有変換が適用されたか
- ECC が所有し、後に安全に削除または修復しうるもの

これが ECC 1.x インストールと ECC 2.0 コントロールプレーンの間の欠けているコントラクトである。

## 現在実装済みの基盤

最初の selective-install 基盤は既にリポジトリ内に存在する:

- `manifests/install-modules.json`
- `manifests/install-profiles.json`
- `schemas/install-modules.schema.json`
- `schemas/install-profiles.schema.json`
- `schemas/install-state.schema.json`
- `scripts/ci/validate-install-manifests.js`
- `scripts/lib/install-manifests.js`
- `scripts/lib/install/request.js`
- `scripts/lib/install/runtime.js`
- `scripts/lib/install/apply.js`
- `scripts/lib/install-targets/`
- `scripts/lib/install-state.js`
- `scripts/lib/install-executor.js`
- `scripts/lib/install-lifecycle.js`
- `scripts/ecc.js`
- `scripts/install-apply.js`
- `scripts/install-plan.js`
- `scripts/list-installed.js`
- `scripts/doctor.js`

現在の能力:

- 機械可読モジュール・プロファイルカタログ
- マニフェストエントリが実リポジトリパスを指すことの CI 検証
- 依存関係展開とターゲットフィルタリング
- アダプタ認識オペレーションプランニング
- レガシーおよびマニフェストインストールモード用の canonical リクエスト正規化
- 正規化リクエストからプラン作成への明示的ランタイムディスパッチ
- レガシーおよびマニフェストインストールの両方が永続的 install-state を書く
- 任意の変更前のインストールプランの read-only 検査
- install、planning、ライフサイクルコマンドをルーティングする統一 `ecc` CLI
- `list-installed`、`doctor`、`repair`、`uninstall` 経由のライフサイクル検査と変更

現在の制限:

- ターゲット固有 merge/remove セマンティクスは一部モジュールで依然 scaffold レベル
- レガシー `ecc-install` 互換は依然 `install.sh` を指す
- `package.json` での publish サーフェスは依然広い

## 現コードレビュー

現行インストーラスタックは元の言語ファーストシェルインストーラより既にはるかに健全だが、いくつかのファイルに責任を集中させすぎている。

### 現ランタイムパス

今日のランタイムフローは:

1. `install.sh`
   実際のパッケージルートを解決する薄いシェルラッパー
2. `scripts/install-apply.js`
   レガシーおよびマニフェストモード用のユーザー向けインストーラ CLI
3. `scripts/lib/install/request.js`
   CLI パースに加えて canonical リクエスト正規化
4. `scripts/lib/install/runtime.js`
   正規化リクエストからインストールプランへのランタイムディスパッチ
5. `scripts/lib/install-executor.js`
   引数翻訳、レガシー互換、オペレーションマテリアライゼーション、ファイルシステム変更、install-state 書き込み
6. `scripts/lib/install-manifests.js`
   モジュール/プロファイルカタログロードに加えて依存関係展開
7. `scripts/lib/install-targets/`
   ターゲットルートと配置先パス足場
8. `scripts/lib/install-state.js`
   スキーマバック install-state 読み書き
9. `scripts/lib/install-lifecycle.js`
   保存されたオペレーションから派生する doctor/repair/uninstall 挙動

これは selective-install 基盤を証明するには十分だが、インストーラアーキテクチャが落ち着いた感じにするには十分ではない。

### 現在の強み

- インストール意図が `--profile` と `--modules` を通じて明示的になった
- リクエストパースとリクエスト正規化が CLI シェルから分割された
- ターゲットルート解決は既にアダプタ化されている
- ライフサイクルコマンドは推測する代わりに永続 install-state を使うようになった
- リポジトリは既に `ecc` と `install-apply.js` を通じて統一 Node エントリポイントを持つ

### 残存する結合

1. `install-executor.js` は以前より小さいが、依然複数のプランニングとマテリアライゼーションレイヤを一度に運んでいる。
   リクエスト境界は抽出されたが、レガシーリクエスト翻訳、マニフェストプラン展開、オペレーションマテリアライゼーションは依然一緒に存在する。
2. ターゲットアダプタは依然薄すぎる。
   現在は主にルートを解決し配置先パスを足場するだけ。実際のインストールセマンティクスは依然 executor ブランチとパスヒューリスティクスに存在する。
3. プランナ/エクゼキュータ境界はまだ十分にクリーンでない。
   `install-manifests.js` がモジュールを解決するが、最終インストールオペレーションセットは依然部分的に executor 固有ロジックで構築される。
4. ライフサイクル挙動が安定モジュールセマンティクスより低レベル記録オペレーションに依存する。
   プレーンファイルコピーには動作するが、merge/generate/remove 挙動には脆くなる。
5. 互換モードがメインインストーラランタイムに直接混入している。
   レガシー言語インストールは並列インストーラアーキテクチャとしてではなく、リクエストアダプタのように振る舞うべき。

## 提案モジュラーアーキテクチャ変更

次のアーキテクチャステップは、インストーラを明示的レイヤに分離し、各レイヤがファイルを即座に変更せず安定データを返すようにすることである。

### ターゲット状態

望ましいインストールパイプラインは:

1. CLI サーフェス
2. リクエスト正規化
3. モジュール解決
4. ターゲットプランニング
5. オペレーションプランニング
6. 実行
7. install-state 永続化
8. 同じオペレーションコントラクト上に構築されたライフサイクルサービス

主要アイデアはシンプル:

- マニフェストがコンテンツを記述する
- アダプタがターゲット固有ランディングセマンティクスを記述する
- プランナが何が起こるべきかを記述する
- エクゼキュータがそれらのプランを適用する
- ライフサイクルコマンドが再発明する代わりに同じプラン/状態モデルを再利用する

### 提案ランタイムレイヤ

#### 1. CLI サーフェス

責任:

- ユーザー意図のパースのみ
- install、plan、doctor、repair、uninstall へのルート
- 人間または JSON 出力のレンダー

所有すべきでないもの:

- レガシー言語翻訳
- ターゲット固有インストールルール
- オペレーション構築

推奨ファイル:

```text
scripts/ecc.js
scripts/install-apply.js
scripts/install-plan.js
scripts/doctor.js
scripts/repair.js
scripts/uninstall.js
```

これらはエントリポイントのまま残るが、ライブラリモジュール周辺の薄いラッパーになる。

#### 2. リクエスト正規化

責任:

- 生 CLI フラグを canonical インストールリクエストに翻訳する
- レガシー言語インストールを互換リクエスト形状に変換する
- 混合または曖昧な入力を早期に拒否する

推奨 canonical リクエスト:

```json
{
  "mode": "manifest",
  "target": "cursor",
  "profile": "developer",
  "modules": [],
  "legacyLanguages": [],
  "dryRun": false
}
```

または互換モードで:

```json
{
  "mode": "legacy-compat",
  "target": "claude",
  "profile": null,
  "modules": [],
  "legacyLanguages": ["typescript", "python"],
  "dryRun": false
}
```

これにより、パイプラインの残りはリクエストが古い CLI 文法から来たか新しいものから来たかを無視できる。

#### 3. モジュールリゾルバ

責任:

- マニフェストカタログをロード
- 依存関係を展開
- コンフリクトを拒否
- ターゲットごとに非サポートモジュールをフィルタ
- canonical 解決オブジェクトを返す

このレイヤは pure かつ read-only に留まるべき。

知るべきでないもの:

- 配置先ファイルシステムパス
- マージセマンティクス
- コピー戦略

現在の最寄りファイル:

- `scripts/lib/install-manifests.js`

推奨分割:

```text
scripts/lib/install/catalog.js
scripts/lib/install/resolve-request.js
scripts/lib/install/resolve-modules.js
```

#### 4. ターゲットプランナ

責任:

- インストールターゲットアダプタを選択
- ターゲットルートを解決
- install-state パスを解決
- module-to-target マッピングルールを展開
- ターゲット認識オペレーション意図を発出

ここがターゲット固有意味が存在すべき場所である。

例:

- Claude は `~/.claude` 配下のネイティブ階層を保持しうる
- Cursor はルールとは異なる方法で同梱 `.cursor` ルート子を同期しうる
- 生成設定はターゲットによってマージまたは置換セマンティクスを要しうる

現在の最寄りファイル:

- `scripts/lib/install-targets/helpers.js`
- `scripts/lib/install-targets/registry.js`

推奨進化:

```text
scripts/lib/install/targets/registry.js
scripts/lib/install/targets/claude-home.js
scripts/lib/install/targets/cursor-project.js
scripts/lib/install/targets/antigravity-project.js
```

各アダプタは最終的に `resolveRoot` 以上を公開すべきである。
ターゲットファミリのパスと戦略マッピングを所有すべきである。

#### 5. オペレーションプランナ

責任:

- モジュール解決とアダプタルールを型付きオペレーショングラフに変える
- 以下のようなファーストクラスオペレーションを発出する:
  - `copy-file`
  - `copy-tree`
  - `merge-json`
  - `render-template`
  - `remove`
- 所有権と検証メタデータをアタッチする

これが現行インストーラに欠けているアーキテクチャシームである。

今日、オペレーションは部分的に scaffold レベルで部分的に executor 固有である。ECC 2.0 はオペレーションプランニングをスタンドアロンフェーズにして、以下を可能にすべき:

- `plan` が真の実行プレビューになる
- `doctor` が現ファイルだけでなく意図された挙動を検証できる
- `repair` が欠けている作業を安全に正確に再構築できる
- `uninstall` が管理オペレーションのみを反転できる

#### 6. 実行エンジン

責任:

- 型付きオペレーショングラフを適用する
- 上書きと所有権ルールを強制する
- 書き込みを安全にステージングする
- 最終適用オペレーション結果を収集する

このレイヤは *何* をするかを決定すべきでない。
提供されたオペレーション種別を *どう* 安全に適用するかのみを決定すべきである。

現在の最寄りファイル:

- `scripts/lib/install-executor.js`

推奨リファクタ:

```text
scripts/lib/install/executor/apply-plan.js
scripts/lib/install/executor/apply-copy.js
scripts/lib/install/executor/apply-merge-json.js
scripts/lib/install/executor/apply-remove.js
```

これは executor ロジックを 1 つの大きな分岐ランタイムから小さなオペレーションハンドラのセットに変える。

#### 7. Install-State ストア

責任:

- install-state を検証・永続化する
- canonical リクエスト、解決、適用オペレーションを記録する
- インストールをリバースエンジニアリングすることを強制せずにライフサイクルコマンドをサポートする

現在の最寄りファイル:

- `scripts/lib/install-state.js`

このレイヤは既に正しい形状に近い。主な残りの変更は、merge/generate セマンティクスが実際になった時点でより豊富なオペレーションメタデータを保存することである。

#### 8. ライフサイクルサービス

責任:

- `list-installed`: 状態のみを検査
- `doctor`: desired/install-state ビューを現ファイルシステムと比較
- `repair`: 状態からプランを再生成し安全なオペレーションを再適用
- `uninstall`: ECC 所有出力のみを削除

現在の最寄りファイル:

- `scripts/lib/install-lifecycle.js`

このレイヤは最終的に生 `copy-file` レコードだけでなく、オペレーション種別と所有権ポリシー上で動作すべきである。

## 提案ファイルレイアウト

クリーンなモジュラー終状態は概ね以下のようになるべき:

```text
scripts/lib/install/
  catalog.js
  request.js
  resolve-modules.js
  plan-operations.js
  state-store.js
  targets/
    registry.js
    claude-home.js
    cursor-project.js
    antigravity-project.js
    codex-home.js
    opencode-home.js
  executor/
    apply-plan.js
    apply-copy.js
    apply-merge-json.js
    apply-render-template.js
    apply-remove.js
  lifecycle/
    discover.js
    doctor.js
    repair.js
    uninstall.js
```

これはパッケージング分割ではない。
現リポジトリ内のコード所有権分割であり、各レイヤが 1 つの仕事を持つようにする。

## 現ファイルからのマイグレーションマップ

最も低リスクなマイグレーションパスは進化的であり、書き直しではない。

### 保持

- 公開互換シムとしての `install.sh`
- 統一 CLI としての `scripts/ecc.js`
- 状態ストアの開始点としての `scripts/lib/install-state.js`
- 現ターゲットアダプタ ID と状態場所

### 抽出

- `scripts/lib/install-executor.js` からリクエストパースと互換翻訳
- executor ブランチからターゲットアダプタとプランナモジュールへターゲット認識オペレーションプランニング
- 共有ライフサイクルモノリスから小さなサービスへライフサイクル固有分析

### 段階的に置換

- 広いパスコピーヒューリスティクスを型付きオペレーションで
- scaffold のみのアダプタプランニングをアダプタ所有セマンティクスで
- レガシー言語インストールブランチを同じプランナ/エクゼキュータパイプラインへのレガシーリクエスト翻訳で

## 次に行うべき即時アーキテクチャ変更

目標が ECC 2.0 で「動作するだけ」でないなら、次のモジュラー化ステップは:

1. `install-executor.js` をリクエスト正規化、オペレーションプランニング、実行モジュールに分割する
2. ターゲット固有戦略決定をアダプタ所有プランニングメソッドに移す
3. `repair` と `uninstall` を単にプレーン `copy-file` レコードではなく型付きオペレーションハンドラ上で動作させる
4. マニフェストにインストール戦略と所有権を教え、プランナがパスヒューリスティクスに依存しないようにする
5. 内部モジュール境界が安定した後にのみ npm publish サーフェスを狭める

## なぜ現モデルが不十分か

今日 ECC は依然広いペイロードコピー機として振る舞う:

- `install.sh` は言語ファーストでターゲットブランチが重い
- ターゲットはディレクトリレイアウトに部分的に暗黙的
- uninstall、repair、doctor は現在存在するが依然初期ライフサイクルコマンドである
- リポジトリは以前のインストールが実際に何を書いたかを証明できない
- `package.json` での publish サーフェスは依然広い

これはメガプランで既に指摘された問題を作る:

- ユーザーはハーネスやワークフローが必要とする以上のコンテンツを pull する
- インストールが記録されないため、サポートとアップグレードがより難しい
- インストールロジックがシェルブランチで重複するため、ターゲット挙動がドリフトする
- Codex や OpenCode のような将来のターゲットは、安定インストールコントラクトを再利用する代わりにより多くの特殊ケースロジックを要する

## ECC 2.0 設計テーゼ

selective install は以下としてモデル化すべき:

1. 要求された意図を canonical モジュールグラフに解決する
2. そのグラフをターゲットアダプタを通じて翻訳する
3. 決定論的インストールオペレーションセットを実行する
4. 永続的真実源として install-state を書く

つまり ECC 2.0 は 1 つではなく 2 つのコントラクトを必要とする:

- コンテンツコントラクト
  どのモジュールが存在し、互いにどう依存するか
- ターゲットコントラクト
  それらモジュールが Claude、Cursor、Antigravity、Codex、OpenCode 内にどう着地するか

現リポジトリは初期形でしか前半を持っていなかった。
現リポジトリは現在最初のフル垂直スライスを持つが、フルターゲット固有セマンティクスはない。

## 設計制約

1. `everything-claude-code` を canonical ソースリポジトリとして保つ。
2. マイグレーション中に既存 `install.sh` フローを保持する。
3. 同じプランナから home-scoped と project-scoped ターゲットをサポートする。
4. 推測なしで uninstall/repair/doctor を可能にする。
5. ターゲットごとのコピーロジックがモジュール定義に逆流入することを避ける。
6. 将来の Codex と OpenCode サポートを書き直しではなく加算的に保つ。

## Canonical アーティファクト

### 1. モジュールカタログ

モジュールカタログは canonical コンテンツグラフである。

既に実装されている現在のフィールド:

- `id`
- `kind`
- `description`
- `paths`
- `targets`
- `dependencies`
- `defaultInstall`
- `cost`
- `stability`

ECC 2.0 にまだ必要なフィールド:

- `installStrategy`
  例えば `copy`、`flatten-rules`、`generate`、`merge-config`
- `ownership`
  ECC がターゲットパスを完全所有するか、その下の生成ファイルのみか
- `pathMode`
  例えば `preserve`、`flatten`、`target-template`
- `conflicts`
  1 つのターゲット上で共存できないモジュールまたはパスファミリ
- `publish`
  モジュールがデフォルトでパッケージ化されるか、オプショナルか、インストール後生成か

推奨将来形状:

```json
{
  "id": "hooks-runtime",
  "kind": "hooks",
  "paths": ["hooks", "scripts/hooks"],
  "targets": ["claude", "cursor", "opencode"],
  "dependencies": [],
  "installStrategy": "copy",
  "pathMode": "preserve",
  "ownership": "managed",
  "defaultInstall": true,
  "cost": "medium",
  "stability": "stable"
}
```

### 2. プロファイルカタログ

プロファイルは薄く留まる。

ターゲットロジックを重複させるのではなく、ユーザー意図を表現すべき。

既に実装されている現在の例:

- `core`
- `developer`
- `security`
- `research`
- `full`

まだ必要なフィールド:

- `defaultTargets`
- `recommendedFor`
- `excludes`
- `requiresConfirmation`

これにより ECC 2.0 は以下のようなことを言える:

- `developer` は Claude と Cursor の推奨デフォルト
- `research` は狭いローカルインストールには重い可能性
- `full` は許可されるがデフォルトではない

### 3. ターゲットアダプタ

これが主な欠落レイヤである。

モジュールグラフは以下を知るべきでない:

- Claude ホームがどこに住むか
- Cursor がコンテンツをどうフラット化または再マップするか
- どの設定ファイルが盲目的コピーの代わりにマージセマンティクスを必要とするか

それはターゲットアダプタに属する。

推奨インターフェース:

```ts
type InstallTargetAdapter = {
  id: string;
  kind: "home" | "project";
  supports(target: string): boolean;
  resolveRoot(input?: string): Promise<string>;
  planOperations(input: InstallOperationInput): Promise<InstallOperation[]>;
  validate?(input: InstallOperationInput): Promise<ValidationIssue[]>;
};
```

推奨初期アダプタ:

1. `claude-home`
   `~/.claude/...` に書く
2. `cursor-project`
   `./.cursor/...` に書く
3. `antigravity-project`
   `./.agent/...` に書く
4. `codex-home`
   後で
5. `opencode-home`
   後で

これは session-adapter ディスカバリドキュメントで既に提案された同じパターンに合致する: canonical コントラクトファースト、ハーネス固有アダプタセカンド。

## インストールプランニングモデル

現行 `scripts/install-plan.js` CLI は、リポジトリが要求されたモジュールをフィルタ済みモジュールセットに解決できることを証明する。

ECC 2.0 は次のレイヤを必要とする: オペレーションプランニング。

推奨フェーズ:

1. 入力正規化
   - `--target` をパース
   - `--profile` をパース
   - `--modules` をパース
   - オプションでレガシー言語引数を翻訳
2. モジュール解決
   - 依存関係を展開
   - コンフリクトを拒否
   - サポートターゲットでフィルタ
3. アダプタプランニング
   - ターゲットルートを解決
   - 正確なコピーまたは生成オペレーションを派生
   - 設定マージとターゲット再マップを識別
4. ドライラン出力
   - 選択モジュールを表示
   - スキップモジュールを表示
   - 正確なファイルオペレーションを表示
5. 変更
   - オペレーションプランを実行
6. 状態書き込み
   - 成功完了後にのみ install-state を永続化

推奨オペレーション形状:

```json
{
  "kind": "copy",
  "moduleId": "rules-core",
  "source": "rules/common/coding-style.md",
  "destination": "/Users/example/.claude/rules/ecc/common/coding-style.md",
  "ownership": "managed",
  "overwritePolicy": "replace"
}
```

他のオペレーション種別:

- `copy`
- `copy-tree`
- `flatten-copy`
- `render-template`
- `merge-json`
- `merge-jsonc`
- `mkdir`
- `remove`

## Install-State コントラクト

install-state は ECC 1.x に欠けている永続的コントラクトである。

推奨パス規約:

- Claude ターゲット:
  `~/.claude/ecc/install-state.json`
- Cursor ターゲット:
  `./.cursor/ecc-install-state.json`
- Antigravity ターゲット:
  `./.agent/ecc-install-state.json`
- 将来の Codex ターゲット:
  `~/.codex/ecc-install-state.json`

推奨ペイロード:

```json
{
  "schemaVersion": "ecc.install.v1",
  "installedAt": "2026-03-13T00:00:00Z",
  "lastValidatedAt": "2026-03-13T00:00:00Z",
  "target": {
    "id": "claude-home",
    "root": "/Users/example/.claude"
  },
  "request": {
    "profile": "developer",
    "modules": ["orchestration"],
    "legacyLanguages": ["typescript", "python"]
  },
  "resolution": {
    "selectedModules": [
      "rules-core",
      "agents-core",
      "commands-core",
      "hooks-runtime",
      "platform-configs",
      "workflow-quality",
      "framework-language",
      "database",
      "orchestration"
    ],
    "skippedModules": []
  },
  "source": {
    "repoVersion": "2.0.0-rc.1",
    "repoCommit": "git-sha",
    "manifestVersion": 1
  },
  "operations": [
    {
      "kind": "copy",
      "moduleId": "rules-core",
      "destination": "/Users/example/.claude/rules/ecc/common/coding-style.md",
      "digest": "sha256:..."
    }
  ]
}
```

状態要件:

- uninstall が ECC 管理出力のみを削除するための十分な詳細
- repair が desired vs 実際にインストールされたファイルを比較するための十分な詳細
- doctor が推測する代わりにドリフトを説明するための十分な詳細

## ライフサイクルコマンド

以下のコマンドが install-state のライフサイクルサーフェスである:

1. `ecc list-installed`
2. `ecc uninstall`
3. `ecc doctor`
4. `ecc repair`

現実装状況:

- `ecc list-installed` は `node scripts/list-installed.js` にルートする
- `ecc uninstall` は `node scripts/uninstall.js` にルートする
- `ecc doctor` は `node scripts/doctor.js` にルートする
- `ecc repair` は `node scripts/repair.js` にルートする
- レガシースクリプトエントリポイントはマイグレーション中も利用可能なまま

### `list-installed`

責任:

- ターゲット ID とルートを表示
- 要求プロファイル/モジュールを表示
- 解決モジュールを表示
- ソースバージョンとインストール時刻を表示

### `uninstall`

責任:

- install-state をロード
- 状態に記録された ECC 管理配置先のみを削除
- ユーザー作成の無関係ファイルに触れない
- 成功クリーンアップ後にのみ install-state を削除

### `doctor`

責任:

- 欠落管理ファイルを検出
- 予期せぬ設定ドリフトを検出
- もはや存在しないターゲットルートを検出
- マニフェスト/バージョン不一致を検出

### `repair`

責任:

- install-state から望ましいオペレーションプランを再構築
- 欠落またはドリフト管理ファイルを再コピー
- 互換マップが存在しない限り、要求モジュールが現マニフェストに存在しない場合は repair を拒否

## レガシー互換レイヤ

現行 `install.sh` は受理する:

- `--target <claude|cursor|antigravity>`
- 言語名のリスト

ユーザーが既に依存しているため、その挙動は 1 回のカットで消えることはできない。

ECC 2.0 はレガシー言語引数を互換リクエストに翻訳すべきである。

推奨アプローチ:

1. レガシーモード用に既存 CLI 形状を保つ
2. 言語名を以下のようなモジュールリクエストにマップ:
   - `rules-core`
   - ターゲット互換ルールサブセット
3. レガシーインストールでも install-state を書く
4. リクエストを `legacyMode: true` でラベルする

例:

```json
{
  "request": {
    "legacyMode": true,
    "legacyLanguages": ["typescript", "python"]
  }
}
```

これは古い挙動を利用可能に保ちつつ、すべてのインストールを同じ状態コントラクトに移す。

## Publish 境界

現行 npm パッケージは依然 `package.json` を通じて広いペイロードを publish する。

ECC 2.0 はこれを慎重に改善すべきである。

推奨シーケンス:

1. 最初に 1 つの canonical npm パッケージを保つ
2. publish 形状を変更する前にインストール時選択を駆動するためにマニフェストを使う
3. 後にのみ安全な場所でパッケージサーフェスを縮小することを検討する

理由:

- selective install は積極的なパッケージ手術の前に出荷できる
- uninstall と repair は publish 変更より install-state に依存する
- Codex/OpenCode サポートはパッケージソースが統一されたままであれば容易

可能な後の方向:

- プロファイルごとの生成スリムバンドル
- 生成ターゲット固有 tarball
- 重いモジュールのオプショナルリモートフェッチ

それらは Phase 3 以降であり、プロファイル認識インストールの前提条件ではない。

## ファイルレイアウト推奨

推奨次ファイル:

```text
scripts/lib/install-targets/
  claude-home.js
  cursor-project.js
  antigravity-project.js
  registry.js
scripts/lib/install-state.js
scripts/ecc.js
scripts/install-apply.js
scripts/list-installed.js
scripts/uninstall.js
scripts/doctor.js
scripts/repair.js
tests/lib/install-targets.test.js
tests/lib/install-state.test.js
tests/lib/install-lifecycle.test.js
```

`install.sh` はマイグレーション中もユーザー向けエントリポイントのまま残れるが、ターゲットごとのシェルブランチを成長させ続ける代わりに Node ベースのプランナとエクゼキュータ周辺の薄いシェルになるべきである。

## 実装シーケンス

### Phase 1: プランナからコントラクトへ

1. 現マニフェストスキーマとリゾルバを保つ
2. 解決モジュール上にオペレーションプランニングを追加
3. `ecc.install.v1` 状態スキーマを定義
4. 成功インストールで install-state を書く

### Phase 2: ターゲットアダプタ

1. Claude インストール挙動を `claude-home` アダプタに抽出
2. Cursor インストール挙動を `cursor-project` アダプタに抽出
3. Antigravity インストール挙動を `antigravity-project` アダプタに抽出
4. `install.sh` を引数パースとアダプタ起動に減らす

### Phase 3: ライフサイクル

1. ターゲット固有のより強い merge/remove セマンティクスを追加
2. 非コピーオペレーション用に repair/uninstall カバレッジを拡張
3. パッケージ出荷サーフェスを広いフォルダの代わりにモジュールグラフに減らす
4. `ecc-install` が `ecc install` の薄いエイリアスになるべき時を決定

### Phase 4: Publish と将来のターゲット

1. `package.json` publish サーフェスの安全な縮小を評価
2. `codex-home` を追加
3. `opencode-home` を追加
4. パッケージング圧力が高いままなら生成プロファイルバンドルを検討

## 即時リポジトリローカル次ステップ

このリポジトリでの最高シグナル次実装移動は:

1. 設定様モジュール用にターゲット固有 merge/remove セマンティクスを追加
2. 単純な copy-file オペレーション以上に repair と uninstall を拡張
3. パッケージ出荷サーフェスを広いフォルダの代わりにモジュールグラフに減らす
4. `ecc-install` が別個のままか `ecc install` になるかを決定
5. 以下をロックダウンするテストを追加:
   - ターゲット固有 merge/remove 挙動
   - 非コピーオペレーション用の repair と uninstall 安全性
   - 統一 `ecc` CLI ルーティングと互換性保証

## オープン質問

1. レガシーモードのルールは永遠に言語アドレス可能のままか、マイグレーション窓のみか?
2. `platform-configs` は常に `core` とインストールするか、より小さなターゲット固有モジュールに分割するか?
3. 設定マージセマンティクスをオペレーションレベルで記録するか、アダプタロジックのみで記録するか?
4. 重いスキルファミリは最終的にパッケージ時包含ではなくフェッチオンデマンドに移すか?
5. Codex と OpenCode ターゲットアダプタは Claude/Cursor ライフサイクルコマンドが安定した後にのみ出荷するか?

## 推奨

現マニフェストリゾルバをインストール用アダプタ `0` として扱う:

1. 現インストールサーフェスを保持する
2. 実コピー挙動をターゲットアダプタの背後に移す
3. すべての成功インストールに対して install-state を書く
4. uninstall、doctor、repair が install-state のみに依存するようにする
5. その後にのみパッケージングを縮小するかより多くのターゲットを追加する

これは ECC 1.x インストーラ拡散から、決定論的、サポート可能、拡張可能な ECC 2.0 インストール/コントロールコントラクトへの最短パスである。
