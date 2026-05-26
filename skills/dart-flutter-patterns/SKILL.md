---
name: dart-flutter-patterns
description: null safety、不変状態、非同期コンポジション、ウィジェットアーキテクチャ、人気の状態管理フレームワーク (BLoC、Riverpod、Provider)、GoRouter ナビゲーション、Dio ネットワーキング、Freezed コード生成、クリーンアーキテクチャをカバーする本番品質の Dart と Flutter パターン (Dart, Flutter, BLoC, Riverpod, Provider, GoRouter, Dio, Freezed, null safety, immutable state)。
origin: ECC
---

# Dart/Flutter パターン

## 利用するタイミング

このスキルを使う場面:
- 新しい Flutter 機能を開始し、状態管理、ナビゲーション、データアクセスの慣用的パターンが必要
- Dart コードをレビューまたは作成し、null 安全性、sealed 型、非同期コンポジションのガイダンスが必要
- 新しい Flutter プロジェクトをセットアップし、BLoC、Riverpod、Provider の間で選択
- 安全な HTTP クライアント、WebView 統合、ローカルストレージを実装
- Flutter ウィジェット、Cubit、Riverpod プロバイダのテストを書く
- 認証ガード付きで GoRouter を配線

## 仕組み

このスキルは関心ごとに整理された貼り付けて使える Dart/Flutter コードパターンを提供する:
1. **Null 安全性** — `!` を避け、`?.`/`??`/パターンマッチを優先
2. **不変状態** — sealed クラス、`freezed`、`copyWith`
3. **非同期コンポジション** — 並行 `Future.wait`、`await` 後の安全な `BuildContext`
4. **ウィジェットアーキテクチャ** — メソッドではなくクラスに抽出、`const` 伝播、スコープリビルド
5. **状態管理** — BLoC/Cubit イベント、Riverpod ノーティファイアと派生プロバイダ
6. **ナビゲーション** — `refreshListenable` を介したリアクティブ認証ガード付き GoRouter
7. **ネットワーキング** — インターセプタ付き Dio、ワンタイムリトライガード付きトークンリフレッシュ
8. **エラー処理** — グローバルキャプチャ、`ErrorWidget.builder`、crashlytics 配線
9. **テスト** — ユニット (BLoC test)、ウィジェット (ProviderScope オーバーライド)、モックよりフェイク

(本スキルのコード例 — sealed 状態、GoRouter、Riverpod 派生プロバイダ、null 安全性、不変状態、非同期コンポジション、ウィジェットアーキテクチャ、BLoC、Riverpod、ナビゲーション、Dio、エラー処理、テスト — はすべて Dart コードのため英語のまま保持される。)

## 主要パターン要約

### 1. Null 安全性の基礎

- `!` の代わりにパターンを優先する
- `late` の過剰使用を避ける

### 2. 不変状態

- 状態階層に sealed クラスを使う (`UserInitial`, `UserLoading`, `UserLoaded`, `UserError`)
- Freezed でボイラープレートのない不変性

### 3. 非同期コンポジション

- `Future.wait` での構造化された並行性
- 全 `await` 後に `mounted` をチェックする (`BuildContext` 安全性)

### 4. ウィジェットアーキテクチャ

- メソッドではなくクラスに抽出する (`const` を有効にしエレメント再利用を可能にする)
- `const` を可能な限り使う (再ビルド伝播を停止)
- スコープリビルドで影響を限定する

### 5. 状態管理: BLoC/Cubit

```dart
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authService) : super(const AuthState.initial());
  final AuthService _authService;

  Future<void> login(String email, String password) async {
    emit(const AuthState.loading());
    try {
      final user = await _authService.login(email, password);
      emit(AuthState.authenticated(user));
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    }
  }
}
```

### 6. 状態管理: Riverpod

```dart
@riverpod
Future<List<Product>> products(Ref ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getAll();
}

@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  List<CartItem> build() => [];

  void add(Product product) { /* ... */ }
}
```

### 7. GoRouter ナビゲーション

```dart
final router = GoRouter(
  refreshListenable: GoRouterRefreshStream(authCubit.stream),
  redirect: (context, state) {
    final isLoggedIn = context.read<AuthCubit>().state is AuthAuthenticated;
    if (!isLoggedIn && !state.matchedLocation.startsWith('/login')) return '/login';
    return null;
  },
  routes: [/* ... */],
);
```

### 8. Dio による HTTP

インターセプタで認証トークン、リトライガード付きのトークンリフレッシュを処理する。

### 9. エラー処理

`FlutterError.onError` と `PlatformDispatcher.instance.onError` をグローバル捕捉のために設定する。

### 10. テスト

`bloc_test`、`flutter_test`、`ProviderScope` オーバーライドを使ったクイックリファレンス。モックよりフェイクを優先。

## 参考資料

- [Effective Dart: Design](https://dart.dev/effective-dart/design)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Riverpod Documentation](https://riverpod.dev/)
- [BLoC Library](https://bloclibrary.dev/)
- [GoRouter](https://pub.dev/packages/go_router)
- [Freezed](https://pub.dev/packages/freezed)
- スキル: `flutter-dart-code-review` — 包括的レビューチェックリスト
- ルール: `rules/dart/` — コーディングスタイル、パターン、セキュリティ、テスト、フック

(完全なコード例とすべてのセクションについては原版を参照されたい。)
