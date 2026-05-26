---
name: flutter-dart-code-review
description: ライブラリ非依存の Flutter/Dart コードレビューチェックリスト（Flutter, Dart, code review）。Widget ベストプラクティス、状態管理パターン（BLoC、Riverpod、Provider、GetX、MobX、Signals）、Dart イディオム、パフォーマンス、アクセシビリティ、セキュリティ、クリーンアーキテクチャを網羅する。
origin: ECC
---

# Flutter/Dart コードレビューベストプラクティス

Flutter/Dart アプリケーションをレビューするためのライブラリ非依存の包括的チェックリストである。これらの原則は、用いる状態管理ソリューション・ルーティングライブラリ・DI フレームワークに関係なく適用される。

---

## 1. プロジェクト全般の健全性

- [ ] プロジェクトが一貫したフォルダ構成（feature-first または layer-first）に従っている
- [ ] 関心事の分離: UI・ビジネスロジック・データレイヤ
- [ ] Widget にビジネスロジックがない。Widget は純粋に表示用
- [ ] `pubspec.yaml` がクリーン — 未使用依存なし、バージョン適切固定
- [ ] `analysis_options.yaml` が厳格 lint セットを含み、厳格アナライザ設定が有効
- [ ] 本番コードに `print()` がない — `dart:developer` の `log()` またはロギングパッケージを使う
- [ ] 生成ファイル（`.g.dart`、`.freezed.dart`、`.gr.dart`）が最新、または `.gitignore` 済み
- [ ] プラットフォーム固有コードが抽象の背後に隔離されている

---

## 2. Dart 言語の落とし穴

- [ ] **暗黙的 dynamic**: 型注釈欠落で `dynamic` 化する — `strict-casts`、`strict-inference`、`strict-raw-types` を有効化
- [ ] **null 安全の誤用**: 適切な null チェックや Dart 3 パターンマッチング（`if (value case var v?)`）の代わりに `!` を過剰に使用
- [ ] **型プロモーション失敗**: ローカル変数プロモーションが効くところで `this.field` を使う
- [ ] **過度に広い catch**: `on` 節なしの `catch (e)` を避ける。常に例外型を明示する
- [ ] **`Error` の catch**: `Error` サブタイプはバグを示すため catch しない
- [ ] **未使用 `async`**: `await` しない関数に `async` を付けない（不要オーバーヘッド）
- [ ] **`late` 過剰**: nullable やコンストラクタ初期化のほうが安全な場面での `late` 使用。エラーをランタイムに遅延させる
- [ ] **ループ内文字列連結**: 反復的文字列構築は `+` ではなく `StringBuffer` を使う
- [ ] **`const` コンテキストの可変状態**: `const` コンストラクタクラスのフィールドは可変であってはならない
- [ ] **`Future` 戻り値の無視**: `await` するか、`unawaited()` を明示的に呼ぶ
- [ ] **`final` で足りるところの `var`**: ローカルには `final`、コンパイル時定数には `const` を優先する
- [ ] **相対 import**: 一貫性のため `package:` import を使う
- [ ] **可変コレクションの露出**: 公開 API は生 `List`/`Map` ではなく unmodifiable view を返す
- [ ] **Dart 3 パターンマッチングの欠落**: 冗長な `is` チェックと手動キャストよりも switch 式と `if-case` を優先する
- [ ] **複数戻り値用の使い捨てクラス**: 単一用途 DTO ではなく Dart 3 records `(String, int)` を使う
- [ ] **本番コードの `print()`**: `dart:developer` の `log()` またはプロジェクトのロギングパッケージを使う。`print()` はログレベルがなくフィルタリング不可

---

## 3. Widget ベストプラクティス

### Widget 分解:
- [ ] 単一 Widget の `build()` メソッドが 80〜100 行を超えない
- [ ] Widget はカプセル化基準 AND 変化の仕方（再ビルド境界）で分割する
- [ ] Widget を返すプライベート `_build*()` ヘルパーメソッドは独立 Widget クラスへ抽出する（element 再利用、const 伝播、フレームワーク最適化を可能にする）
- [ ] ローカル可変状態が不要なら Stateful より Stateless を優先する
- [ ] 抽出 Widget は再利用可能なら別ファイルへ

### const 利用:
- [ ] 可能な限り `const` コンストラクタを使う — 不要な再ビルド防止
- [ ] 変化しないコレクションは `const` リテラル（`const []`、`const {}`）
- [ ] フィールドがすべて final ならコンストラクタを `const` 宣言

### Key 利用:
- [ ] List/Grid で `ValueKey` を使い、並べ替え横断で state を保持する
- [ ] `GlobalKey` は控えめに — ツリー横断で state にアクセスが本当に必要なときのみ
- [ ] `build()` 内の `UniqueKey` は避ける — 毎フレーム再ビルドを強制する
- [ ] アイデンティティが単一値ではなくデータオブジェクトに基づくときは `ObjectKey` を使う

### テーマ & デザインシステム:
- [ ] 色は `Theme.of(context).colorScheme` から取得する — `Colors.red` や hex 値のハードコードはしない
- [ ] テキストスタイルは `Theme.of(context).textTheme` から取得する — raw フォントサイズのインライン `TextStyle` はしない
- [ ] ダークモード互換性を検証する — 明るい背景の前提を置かない
- [ ] 余白・サイズはマジックナンバーではなく一貫したデザイントークンや定数を使う

### build メソッドの複雑さ:
- [ ] `build()` 内でネットワーク呼び出し・ファイル I/O・重い計算をしない
- [ ] `build()` 内で `Future.then()` や `async` 作業をしない
- [ ] `build()` 内で購読生成（`.listen()`）をしない
- [ ] `setState()` を可能な限り狭いサブツリーに局所化する

---

## 4. 状態管理（ライブラリ非依存）

これらの原則は、すべての Flutter 状態管理ソリューション（BLoC、Riverpod、Provider、GetX、MobX、Signals、ValueNotifier 等）に適用される。

### アーキテクチャ:
- [ ] ビジネスロジックは Widget レイヤの外、状態管理コンポーネント（BLoC、Notifier、Controller、Store、ViewModel 等）に置く
- [ ] 状態マネージャは依存を内部で構築せず、注入で受け取る
- [ ] サービスまたはリポジトリレイヤがデータソースを抽象化する — Widget・状態マネージャは API・DB を直接呼ばない
- [ ] 状態マネージャは単一責任 — 無関係事項を扱う "god" マネージャを作らない
- [ ] コンポーネント間依存はソリューションの慣習に従う:
  - **Riverpod**: プロバイダが `ref.watch` で他プロバイダに依存するのは想定通り。循環や過度な絡まりだけをフラグする
  - **BLoC**: bloc は他 bloc に直接依存させず、共有リポジトリやプレゼンテーション層調整を優先する
  - 他: ソキュメント化された inter-component 通信慣習に従う

### 不変性 & 値等価性（不変状態ソリューション: BLoC、Riverpod、Redux）:
- [ ] state オブジェクトは不変。`copyWith()` やコンストラクタで新規生成し、in-place mutation しない
- [ ] state クラスは `==` と `hashCode` を適切に実装する（全フィールドを比較に含める）
- [ ] プロジェクト横断で機構が一貫している — 手動オーバーライド、`Equatable`、`freezed`、Dart records 等
- [ ] state オブジェクト内のコレクションは生の可変 `List`/`Map` として露出させない

### リアクティビティ規律（反応的ミューテーションソリューション: MobX、GetX、Signals）:
- [ ] state はソリューションのリアクティブ API（MobX の `@action`、signals の `.value`、GetX の `.obs`）でのみ変更する — 直接フィールドミューテーションは変更追跡をバイパスする
- [ ] 派生値は冗長保存ではなくソリューションの computed 機構を使う
- [ ] reaction と disposer は適切にクリーンアップする（MobX の `ReactionDisposer`、Signals の effect cleanup）

### state shape 設計:
- [ ] 相互排他状態は sealed type、union variant、またはソリューションのビルトイン async state 型（例: Riverpod の `AsyncValue`）を使う。ブール値フラグ（`isLoading`、`isError`、`hasData`）ではない
- [ ] すべての非同期操作で loading・success・error を distinct state としてモデル化する
- [ ] UI ですべての state バリアントを網羅的に処理する — 暗黙無視ケースを残さない
- [ ] エラー state は表示用エラー情報を持つ。loading state は stale data を持たない
- [ ] nullable data を loading インジケータに使わない — state は明示的にする

```dart
// BAD — boolean flag soup allows impossible states
class UserState {
  bool isLoading = false;
  bool hasError = false; // isLoading && hasError is representable!
  User? user;
}

// GOOD (immutable approach) — sealed types make impossible states unrepresentable
sealed class UserState {}
class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final User user;
  const UserLoaded(this.user);
}
class UserError extends UserState {
  final String message;
  const UserError(this.message);
}

// GOOD (reactive approach) — observable enum + data, mutations via reactivity API
// enum UserStatus { initial, loading, loaded, error }
// Use your solution's observable/signal to wrap status and data separately
```

### 再ビルド最適化:
- [ ] state consumer Widget（Builder、Consumer、Observer、Obx、Watch 等）を可能な限り狭くスコープする
- [ ] selector で特定フィールド変更時のみ再ビルドする — 全 state emit で再ビルドしない
- [ ] `const` Widget でツリーを通る再ビルド伝播を止める
- [ ] computed/派生 state はリアクティブに計算し、冗長保存しない

### 購読とディスポーザル:
- [ ] すべての手動購読（`.listen()`）を `dispose()` / `close()` でキャンセルする
- [ ] 不要になった Stream controller を close する
- [ ] Timer を disposal ライフサイクルでキャンセルする
- [ ] 手動購読より宣言的ビルダ（`.listen()` よりフレームワーク管理ライフサイクル）を優先する
- [ ] async コールバックでの `setState` 前に `mounted` チェックする
- [ ] `await` 後に `BuildContext` を使う際は `context.mounted` を確認する（Flutter 3.7+） — 古い context はクラッシュを引き起こす
- [ ] 非同期ギャップ後の navigation・dialog・scaffold message は Widget が依然 mounted であることを確認する
- [ ] `BuildContext` をシングルトン・状態マネージャ・静的フィールドに保存しない

### ローカル vs グローバル state:
- [ ] 一過性 UI state（checkbox、slider、animation）はローカル state（`setState`、`ValueNotifier`）を使う
- [ ] 共有 state は必要な高さだけリフトする — 過度にグローバル化しない
- [ ] 機能スコープ state は機能非アクティブ時に適切にディスポーズする

---

## 5. パフォーマンス

### 不要な再ビルド:
- [ ] root Widget レベルで `setState()` を呼ばない — state 変更を局所化する
- [ ] `const` Widget で再ビルド伝播を止める
- [ ] 独立に repaint する複雑サブツリーには `RepaintBoundary` を使う
- [ ] アニメーション非依存サブツリーには `AnimatedBuilder` の child パラメータを使う

### build() 内の高コスト操作:
- [ ] `build()` 内で大規模コレクションをソート・フィルタ・mapping しない — 状態管理レイヤで計算する
- [ ] `build()` 内で regex コンパイルしない
- [ ] `MediaQuery.of(context)` は具体的に（例: `MediaQuery.sizeOf(context)`）

### 画像最適化:
- [ ] ネットワーク画像はキャッシュを使う（プロジェクトに適した任意のキャッシュソリューション）
- [ ] ターゲットデバイスに適した解像度（サムネに 4K 画像を読み込まない）
- [ ] `Image.asset` には `cacheWidth`/`cacheHeight` で表示サイズにデコード
- [ ] ネットワーク画像に placeholder と error widget を提供する

### 遅延読み込み:
- [ ] 大規模または動的リストには `ListView(children: [...])` ではなく `ListView.builder` / `GridView.builder` を使う（小規模・静的リストには具象コンストラクタで OK）
- [ ] 大規模データセットにはページネーションを実装する
- [ ] Web ビルドでは重ライブラリに deferred loading（`deferred as`）を使う

### その他:
- [ ] アニメーションで `Opacity` Widget を避ける — `AnimatedOpacity` または `FadeTransition` を使う
- [ ] アニメーションでクリッピングを避ける — 画像を事前クリップする
- [ ] Widget で `operator ==` をオーバーライドしない — 代わりに `const` コンストラクタを使う
- [ ] 内在寸法 Widget（`IntrinsicHeight`、`IntrinsicWidth`）は控えめに（追加レイアウトパス）

---

## 6. テスト

### テストタイプと期待:
- [ ] **ユニットテスト**: 全ビジネスロジック（状態マネージャ・リポジトリ・ユーティリティ関数）をカバー
- [ ] **Widget テスト**: 個別 Widget の挙動・相互作用・視覚出力をカバー
- [ ] **統合テスト**: クリティカルなユーザーフローを E2E カバー
- [ ] **ゴールデンテスト**: デザインクリティカル UI コンポーネントのピクセル完全比較

### カバレッジ目標:
- [ ] ビジネスロジックで 80%+ ライン カバレッジを目指す
- [ ] すべての state 遷移に対応テスト（loading → success、loading → error、retry 等）
- [ ] エッジケーステスト: empty・error・loading・境界値

### テスト隔離:
- [ ] 外部依存（API クライアント・DB・サービス）はモックまたはフェイク
- [ ] 各テストファイルは1クラス/ユニットのみテスト
- [ ] テストは振る舞いを検証する。実装詳細をテストしない
- [ ] stub はテストごとに必要な挙動のみ定義する（最小限スタブ）
- [ ] テストケース間で共有可変 state を持たない

### Widget テスト品質:
- [ ] 非同期操作には `pumpWidget` と `pump` を正しく使う
- [ ] `find.byType`・`find.text`・`find.byKey` を適切に使う
- [ ] タイミング依存のフレーキーテストを作らない — `pumpAndSettle` または明示的 `pump(Duration)` を使う
- [ ] テストは CI で実行され、失敗時はマージブロックされる

---

## 7. アクセシビリティ

### セマンティック Widget:
- [ ] 自動ラベルでは不十分な箇所に `Semantics` Widget でスクリーンリーダーラベルを提供する
- [ ] 純粋装飾要素には `ExcludeSemantics` を使う
- [ ] 関連 Widget を単一のアクセス可能要素にまとめるには `MergeSemantics` を使う
- [ ] 画像に `semanticLabel` プロパティを設定する

### スクリーンリーダーサポート:
- [ ] すべての対話要素がフォーカス可能で意味あるディスクリプションを持つ
- [ ] フォーカス順序が論理的である（視覚的読み順に従う）

### 視覚的アクセシビリティ:
- [ ] テキストの背景に対するコントラスト比 ≥ 4.5:1
- [ ] タップターゲットが 48x48 ピクセル以上
- [ ] 色のみで状態を示さない（アイコン・テキスト併用）
- [ ] テキストがシステムフォントサイズ設定にスケールする

### 対話アクセシビリティ:
- [ ] no-op の `onPressed` コールバックがない — すべてのボタンは何か行うか disabled になっている
- [ ] エラーフィールドが修正提案を行う
- [ ] ユーザーが入力中に context が予期せず変化しない

---

## 8. プラットフォーム固有の考慮

### iOS/Android 差異:
- [ ] 適切な場面でプラットフォーム適応 Widget を使う
- [ ] 戻るナビゲーションを正しく扱う（Android 戻るボタン、iOS スワイプ戻る）
- [ ] ステータスバーとセーフエリアを `SafeArea` Widget で扱う
- [ ] プラットフォーム固有 permission を `AndroidManifest.xml` と `Info.plist` で宣言する

### レスポンシブデザイン:
- [ ] レスポンシブレイアウトに `LayoutBuilder` または `MediaQuery` を使う
- [ ] ブレークポイントを一貫して定義する（phone・tablet・desktop）
- [ ] 小画面でテキストがオーバーフローしない — `Flexible`・`Expanded`・`FittedBox` を使う
- [ ] 横向きをテストするか明示的にロックする
- [ ] Web 固有: マウス/キーボード操作対応、hover 状態あり

---

## 9. セキュリティ

### セキュアストレージ:
- [ ] 機密データ（トークン・クレデンシャル）はプラットフォームセキュアストレージ（iOS Keychain、Android EncryptedSharedPreferences）で保存する
- [ ] シークレットを平文保存しない
- [ ] 機密操作に生体認証ゲーティングを検討する

### API キーの扱い:
- [ ] API キーを Dart ソースにハードコードしない — `--dart-define`、VCS 除外の `.env`、コンパイル時設定を使う
- [ ] シークレットを git にコミットしない — `.gitignore` を確認する
- [ ] 真に秘密のキーにはバックエンドプロキシを使う（クライアントはサーバーシークレットを持つべきでない）

### 入力検証:
- [ ] すべてのユーザー入力を API 送信前に検証する
- [ ] フォーム検証に適切な検証パターンを使う
- [ ] ユーザー入力の生 SQL や文字列補間をしない
- [ ] ディープリンク URL を navigation 前に検証・サニタイズする

### ネットワークセキュリティ:
- [ ] 全 API 呼び出しに HTTPS を強制する
- [ ] 高セキュリティアプリでは証明書ピンニングを検討する
- [ ] 認証トークンが適切にリフレッシュ・失効する
- [ ] 機密データをログ・print しない

---

## 10. パッケージ/依存レビュー

### pub.dev パッケージ評価:
- [ ] **pub points score** を確認する（130+/160 を目標）
- [ ] コミュニティシグナルとして **likes** と **popularity** を確認する
- [ ] パブリッシャが pub.dev で **verified** か確認する
- [ ] 最終公開日を確認する — 1年以上前は陳腐化リスク
- [ ] open issue とメンテナの返信時間を確認する
- [ ] ライセンス互換性を確認する
- [ ] プラットフォームサポートが対象を含むか確認する

### バージョン制約:
- [ ] 依存にキャレット記法（`^1.2.3`）を使う — 互換更新を許可
- [ ] 厳密バージョン固定は本当に必要なときのみ
- [ ] `flutter pub outdated` を定期実行し陳腐化依存を追跡する
- [ ] 本番 `pubspec.yaml` に依存オーバーライドを置かない — 一時修正のみ、コメントと issue リンク付き
- [ ] 推移依存数を最小化する — 各依存はアタック表面である

### モノレポ固有（melos/workspace）:
- [ ] 内部パッケージは公開 API からのみ import する — `package:other/src/internal.dart` は禁止（Dart パッケージカプセル化を破壊）
- [ ] 内部パッケージ依存はワークスペース解決を使う。ハードコード `path: ../../` 相対文字列は避ける
- [ ] すべてのサブパッケージが root `analysis_options.yaml` を共有または継承する

---

## 11. ナビゲーション・ルーティング

### 一般原則（任意のルーティングソリューションに適用）:
- [ ] 1つのルーティングアプローチを一貫して使う — 命令的 `Navigator.push` と宣言的 router を混在させない
- [ ] ルート引数は型付き — `Map<String, dynamic>` や `Object?` キャストをしない
- [ ] ルートパスは定数・enum・生成 — 散在するマジック文字列を避ける
- [ ] 認証ガード/リダイレクトを集中化する — 個別画面に重複させない
- [ ] Android と iOS の両方でディープリンクを構成する
- [ ] ディープリンク URL を navigation 前に検証・サニタイズする
- [ ] navigation state がテスト可能 — ルート変更をテストで検証できる
- [ ] 戻る挙動が全プラットフォームで正しい

---

## 12. エラーハンドリング

### フレームワークエラーハンドリング:
- [ ] `FlutterError.onError` をオーバーライドしてフレームワークエラー（build・layout・paint）を捕捉する
- [ ] Flutter が捕捉しない async エラーに `PlatformDispatcher.instance.onError` を設定する
- [ ] リリースモードに `ErrorWidget.builder` をカスタマイズする（red screen ではなくユーザーフレンドリー表示）
- [ ] `runApp` 周りにグローバルエラー捕捉ラッパ（例: `runZonedGuarded`、Sentry/Crashlytics ラッパ）を置く

### エラー報告:
- [ ] エラー報告サービス統合（Firebase Crashlytics、Sentry または同等）
- [ ] 非致命エラーをスタックトレース付きで報告する
- [ ] 状態管理エラーオブザーバをエラー報告に接続する（例: BlocObserver、ProviderObserver、ソリューション同等品）
- [ ] デバッグ用にユーザー識別情報（user ID）をエラー報告に付与する

### グレースフル劣化:
- [ ] API エラーがクラッシュではなくユーザーフレンドリーなエラー UI に至る
- [ ] 一過性ネットワーク障害にリトライ機構
- [ ] オフライン状態をグレースフルに処理する
- [ ] 状態管理のエラー state が表示用エラー情報を持つ
- [ ] raw 例外（ネットワーク・パース）は UI 到達前にユーザーフレンドリー・ローカライズメッセージへマッピング — raw 例外文字列をユーザーに見せない

---

## 13. 国際化（l10n）

### セットアップ:
- [ ] ローカライゼーションソリューション構成（Flutter ビルトイン ARB/l10n、easy_localization、または同等）
- [ ] サポートロケールをアプリ構成で宣言する

### コンテンツ:
- [ ] すべてのユーザー可視文字列をローカライゼーションシステム経由にする — Widget でハードコード文字列を持たない
- [ ] テンプレートファイルに翻訳者向け説明/文脈を含める
- [ ] 複数形・性別・選択に ICU メッセージ構文を使う
- [ ] プレースホルダを型付きで定義する
- [ ] ロケール間でキー欠落がない

### コードレビュー:
- [ ] プロジェクト全体でローカライゼーションアクセサを一貫して使う
- [ ] 日付・時刻・数値・通貨フォーマットがロケール対応
- [ ] アラビア語・ヘブライ語等を対象とするならテキスト方向（RTL）をサポートする
- [ ] ローカライズテキストの文字列連結をしない — パラメータ化メッセージを使う

---

## 14. 依存性注入

### 原則（任意の DI アプローチに適用）:
- [ ] クラスはレイヤ境界で具象実装ではなく抽象（インターフェース）に依存する
- [ ] 依存はコンストラクタ、DI フレームワーク、provider グラフ経由で外部から提供される — 内部で生成しない
- [ ] 登録でライフタイムを区別する: singleton vs factory vs lazy singleton
- [ ] 環境固有バインディング（dev/staging/prod）はランタイム `if` ではなく構成で扱う
- [ ] DI グラフに循環依存がない
- [ ] サービスロケータ呼び出し（使用時）がビジネスロジック全体に散らばらない

---

## 15. 静的解析

### 構成:
- [ ] `analysis_options.yaml` が存在し、厳格設定が有効
- [ ] 厳格アナライザ設定: `strict-casts: true`、`strict-inference: true`、`strict-raw-types: true`
- [ ] 包括的な lint ルールセットを含む（very_good_analysis、flutter_lints、またはカスタム厳格ルール）
- [ ] モノレポの全サブパッケージが root analysis options を継承または共有する

### 強制:
- [ ] コミットコードに未解決アナライザ警告がない
- [ ] lint 抑制（`// ignore:`）は理由のコメントで正当化されている
- [ ] `flutter analyze` が CI で実行され、失敗はマージブロック

### lint パッケージに依らず確認すべき主要ルール:
- [ ] `prefer_const_constructors` — Widget ツリーのパフォーマンス
- [ ] `avoid_print` — 適切なロギングを使う
- [ ] `unawaited_futures` — fire-and-forget async バグ防止
- [ ] `prefer_final_locals` — 変数レベルの不変性
- [ ] `always_declare_return_types` — 明示的契約
- [ ] `avoid_catches_without_on_clauses` — 具体的エラーハンドリング
- [ ] `always_use_package_imports` — 一貫した import スタイル

---

## 状態管理クイックリファレンス

下表は普遍原則を人気ソリューションでの実装にマッピングする。レビュー規則を当該プロジェクトのソリューションに適応させるのに用いる。

| 原則 | BLoC/Cubit | Riverpod | Provider | GetX | MobX | Signals | Built-in |
|-----------|-----------|----------|----------|------|------|---------|----------|
| State コンテナ | `Bloc`/`Cubit` | `Notifier`/`AsyncNotifier` | `ChangeNotifier` | `GetxController` | `Store` | `signal()` | `StatefulWidget` |
| UI consumer | `BlocBuilder` | `ConsumerWidget` | `Consumer` | `Obx`/`GetBuilder` | `Observer` | `Watch` | `setState` |
| Selector | `BlocSelector`/`buildWhen` | `ref.watch(p.select(...))` | `Selector` | N/A | computed | `computed()` | N/A |
| 副作用 | `BlocListener` | `ref.listen` | `Consumer` callback | `ever()`/`once()` | `reaction` | `effect()` | callbacks |
| ディスポーザル | `BlocProvider` で自動 | `.autoDispose` | `Provider` で自動 | `onClose()` | `ReactionDisposer` | manual | `dispose()` |
| テスト | `blocTest()` | `ProviderContainer` | `ChangeNotifier` 直接 | テストで `Get.put` | store 直接 | signal 直接 | widget test |

---

## 参照元

- [Effective Dart: Style](https://dart.dev/effective-dart/style)
- [Effective Dart: Usage](https://dart.dev/effective-dart/usage)
- [Effective Dart: Design](https://dart.dev/effective-dart/design)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter Testing Overview](https://docs.flutter.dev/testing/overview)
- [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [Flutter Internationalization](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [Flutter Navigation and Routing](https://docs.flutter.dev/ui/navigation)
- [Flutter Error Handling](https://docs.flutter.dev/testing/errors)
- [Flutter State Management Options](https://docs.flutter.dev/data-and-backend/state-mgmt/options)
