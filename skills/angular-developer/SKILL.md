---
name: angular-developer
description: Angular コードを生成しアーキテクチャガイダンスを提供する。プロジェクト・コンポーネント・サービスの作成時や、リアクティビティ (signals, linkedSignal, resource)、フォーム、依存注入、ルーティング、SSR、アクセシビリティ (ARIA)、アニメーション、スタイリング (component styles, Tailwind CSS)、テスト、CLI ツーリングのベストプラクティスを扱う際にトリガーする (Angular developer, signals, signal forms, dependency injection, routing, SSR, ARIA, Tailwind, testing, CLI)。
origin: ECC
---

# Angular 開発者ガイドライン

## 起動するタイミング

- 任意の Angular プロジェクトまたはコードベースでの作業
- 新しい Angular プロジェクト・アプリケーション・ライブラリの作成またはスキャフォールド
- コンポーネント・サービス・ディレクティブ・パイプ・ガード・リゾルバの生成
- Angular Signals・`linkedSignal`・`resource` によるリアクティビティの実装
- Angular フォーム (signal forms・reactive forms・template-driven) での作業
- 依存注入・ルーティング・遅延ロード・ルートガードのセットアップ
- アクセシビリティ (ARIA)・アニメーション・コンポーネントスタイリングの追加
- Angular 固有のテスト (ユニット・コンポーネントハーネス・E2E) の作成またはデバッグ
- Angular CLI ツーリングまたは Angular MCP サーバの設定

1. ガイダンスを提供する前に必ずプロジェクトの Angular バージョンを分析する。バージョンによってベストプラクティスや利用可能な機能が大きく異なる場合がある。Angular CLI で新しいプロジェクトを作成する際、ユーザーから指示がない限りバージョンを指定しない。

2. コードを生成する際は、保守性とパフォーマンスのために Angular のスタイルガイドとベストプラクティスに従う。一貫性を確保するためにコンポーネント・サービス・ディレクティブ・パイプ・ルートのスキャフォールドに Angular CLI を使用する。

3. コード生成が終わったら、ビルドエラーがないことを確認するために `ng build` を実行する。エラーがあれば、進める前にエラーメッセージを分析して修正する。このステップは生成コードが正しく機能することを保証するために重要なのでスキップしないこと。

## 新しいプロジェクトの作成

ユーザーからガイドラインが提供されない場合、新しい Angular プロジェクトを作成するときは以下のデフォルトを使用する:

1. ユーザーが別途指定しない限り、Angular の最新安定版を使う。
2. 対象 Angular バージョンが対応しているときのみ、新規プロジェクトでは Signal Forms を優先する。[詳細](references/signal-forms.md)。

**`ng new` の実行ルール:**
新しい Angular プロジェクトの作成を依頼されたとき、以下の厳格なステップに従って正しい実行コマンドを判断しなければならない:

**Step 1: ユーザー指定の明示的バージョンを確認する。**

- ユーザーが特定バージョン (例: Angular 15) を要求した **場合**、ローカルインストールをバイパスして厳密に `npx` を使う。
- **コマンド:** `npx @angular/cli@<requested_version> new <project-name>`

**Step 2: 既存の Angular インストールを確認する。**

- 特定バージョンが要求されていない **場合**、ターミナルで `ng version` を実行して Angular CLI が既にシステムにインストールされているか確認する。
- コマンドが成功してインストール済みバージョンが返れば、ローカル/グローバルインストールを直接使う。
- **コマンド:** `ng new <project-name>`

**Step 3: 最新版へのフォールバック。**

- 特定バージョンが要求されておらず **かつ** `ng version` が失敗する (Angular がインストールされていない) **場合**、最新版を取得するために `npx` を使わなければならない。
- **コマンド:** `npx @angular/cli@latest new <project-name>`

## コンポーネント

Angular コンポーネントを扱う際、タスクに応じて以下の参考資料を参照する:

- **基本**: 解剖学・メタデータ・中核概念・テンプレートの制御フロー (@if・@for・@switch)。[components.md](references/components.md) を読む
- **入力**: シグナルベースの入力・トランスフォーム・モデル入力。[inputs.md](references/inputs.md) を読む
- **出力**: シグナルベースの出力とカスタムイベントのベストプラクティス。[outputs.md](references/outputs.md) を読む
- **ホスト要素**: ホストバインディングと属性注入。[host-elements.md](references/host-elements.md) を読む

上記の参考資料に見当たらない深いドキュメントが必要なら、`https://angular.dev/guide/components` のドキュメントを読む。

## リアクティビティとデータ管理

状態とデータのリアクティビティを管理する際、Angular Signals を使い以下の参考資料を参照する:

- **Signals 概要**: コアシグナル概念 (`signal`・`computed`)・リアクティブコンテキスト・`untracked`。[signals-overview.md](references/signals-overview.md) を読む
- **依存状態 (`linkedSignal`)**: ソースシグナルにリンクされた書き込み可能状態の作成。[linked-signal.md](references/linked-signal.md) を読む
- **非同期リアクティビティ (`resource`)**: 非同期データを直接シグナル状態にフェッチする。[resource.md](references/resource.md) を読む
- **副作用 (`effect`)**: ロギング、サードパーティ DOM 操作 (`afterRenderEffect`)、エフェクトを使うべきでない場合。[effects.md](references/effects.md) を読む

## フォーム

新規アプリのほとんどの場合、**signal forms を優先する**。フォームの決定を行う際、プロジェクトを分析し以下のガイドラインを考慮する:

- アプリのバージョンが Signal Forms をサポートしており、これが新規フォームなら、**signal forms を優先する**。
- 古いアプリや既存フォームでは、アプリの現在のフォーム戦略に合わせる。

- **Signal Forms**: フォーム状態管理にシグナルを使う。[signal-forms.md](references/signal-forms.md) を読む
- **Template-driven forms**: シンプルなフォームに使う。[template-driven-forms.md](references/template-driven-forms.md) を読む
- **Reactive forms**: 複雑なフォームに使う。[reactive-forms.md](references/reactive-forms.md) を読む

## 依存注入

Angular で依存注入を実装する際、以下のガイドラインに従う:

- **基本**: 依存注入、サービス、`inject()` 関数の概要。[di-fundamentals.md](references/di-fundamentals.md) を読む
- **サービスの作成と使用**: サービスの作成、`providedIn: 'root'` オプション、コンポーネントや他サービスへの注入。[creating-services.md](references/creating-services.md) を読む
- **依存プロバイダの定義**: 自動 vs 手動プロビジョン、`InjectionToken`・`useClass`・`useValue`・`useFactory`・スコープ。[defining-providers.md](references/defining-providers.md) を読む
- **注入コンテキスト**: `inject()` が許可される場所、`runInInjectionContext`、`assertInInjectionContext`。[injection-context.md](references/injection-context.md) を読む
- **階層インジェクタ**: `EnvironmentInjector` vs `ElementInjector`、解決ルール、修飾子 (`optional`・`skipSelf`)、`providers` vs `viewProviders`。[hierarchical-injectors.md](references/hierarchical-injectors.md) を読む

## Angular Aria

Accordion・Listbox・Combobox・Menu・Tabs・Toolbar・Tree・Grid の各パターンにおいてアクセシブルなカスタムコンポーネントを構築する際、以下の参考資料を参照する:

- **Angular Aria コンポーネント**: ヘッドレスでアクセシブルなコンポーネント (Accordion・Listbox・Combobox・Menu・Tabs・Toolbar・Tree・Grid) の構築と ARIA 属性のスタイリング。[angular-aria.md](references/angular-aria.md) を読む

## ルーティング

Angular でナビゲーションを実装する際、以下の参考資料を参照する:

- **ルートを定義する**: URL パス、静的 vs 動的セグメント、ワイルドカード、リダイレクト。[define-routes.md](references/define-routes.md) を読む
- **ルートロード戦略**: 即時 vs 遅延ロード、コンテキスト対応ロード。[loading-strategies.md](references/loading-strategies.md) を読む
- **アウトレットでルートを表示する**: `<router-outlet>` の使用、ネストアウトレット、名前付きアウトレット。[show-routes-with-outlets.md](references/show-routes-with-outlets.md) を読む
- **ルートへナビゲートする**: `RouterLink` による宣言的ナビゲーションと `Router` によるプログラム的ナビゲーション。[navigate-to-routes.md](references/navigate-to-routes.md) を読む
- **ガードでルートアクセスを制御する**: セキュリティのための `CanActivate`・`CanMatch` 等の実装。[route-guards.md](references/route-guards.md) を読む
- **データリゾルバ**: `ResolveFn` でルート起動前にデータを事前フェッチ。[data-resolvers.md](references/data-resolvers.md) を読む
- **ルーターライフサイクルとイベント**: ナビゲーションイベントの時系列順序とデバッグ。[router-lifecycle.md](references/router-lifecycle.md) を読む
- **レンダリング戦略**: CSR、SSG (Prerendering)、ハイドレーション付き SSR。[rendering-strategies.md](references/rendering-strategies.md) を読む
- **ルート遷移アニメーション**: View Transitions API の有効化とカスタマイズ。[route-animations.md](references/route-animations.md) を読む

より深いドキュメントや文脈が必要なら、[公式 Angular Routing ガイド](https://angular.dev/guide/routing) を参照。

## スタイリングとアニメーション

Angular でスタイリングとアニメーションを実装する際、以下の参考資料を参照する:

- **Angular で Tailwind CSS を使う**: Tailwind CSS を Angular プロジェクトに統合する。[tailwind-css.md](references/tailwind-css.md) を読む
- **Angular アニメーション**: ダイナミックエフェクトにネイティブ CSS (推奨) またはレガシー DSL を使う。[angular-animations.md](references/angular-animations.md) を読む
- **コンポーネントのスタイリング**: コンポーネントスタイルとカプセル化のベストプラクティス。[component-styling.md](references/component-styling.md) を読む

## テスト

テストを書く・更新する際、タスクに応じて以下の参考資料を参照する:

- **基本**: ユニットテスト、非同期パターン、`TestBed` のベストプラクティス。[testing-fundamentals.md](references/testing-fundamentals.md) を読む
- **コンポーネントハーネス**: 堅牢なコンポーネントインタラクションの標準パターン。[component-harnesses.md](references/component-harnesses.md) を読む
- **ルーターテスト**: 信頼性の高いナビゲーションテストのための `RouterTestingHarness` 使用。[router-testing.md](references/router-testing.md) を読む
- **End-to-End (E2E) テスト**: Cypress または Playwright での E2E テストのベストプラクティス。[e2e-testing.md](references/e2e-testing.md) を読む

## ツーリング

Angular ツーリングを扱う際、以下の参考資料を参照する:

- **Angular CLI**: アプリケーションの作成、コード (コンポーネント・ルート・サービス) の生成、サーブ、ビルド。[cli.md](references/cli.md) を読む
- **Angular MCP サーバ**: 利用可能なツール、設定、実験的機能。[mcp.md](references/mcp.md) を読む

## アンチパターン

- 初期シグナルフォームフィールド値に `null` や `undefined` を使う — 代わりに `''`・`0`・`[]` を使う
- フィールドを呼び出さずにフォームフィールド状態フラグにアクセス: `form.field.valid()` — `form.field().valid()` を使う
- 対象 Angular バージョンが Signal Forms をサポートしているのに古いフォーム API で新規フォームを始める
- `[formField]` 入力に `min`・`max`・`value`・`disabled`・`readonly` HTML 属性を設定 — 代わりにスキーマルールとして定義する
- 注入コンテキスト外で `inject()` を呼ぶ — 必要なら `runInInjectionContext` を使う
- `computed()` を使うべき派生状態に `effect()` を使う
- ネストされた `@for` ループ内で `$parent.$index` を参照 — Angular は `$parent` をサポートしない。代わりに `let outerIdx = $index` を使う

## 関連スキル

- `tdd-workflow` — Angular コンポーネントとサービスに適用可能なテスト駆動開発ワークフロー
- `security-review` — Angular 固有の懸念を含む Web アプリケーションのセキュリティチェックリスト
- `frontend-patterns` — React/Next.js アプローチのコンテキストとしての一般的なフロントエンドパターン
