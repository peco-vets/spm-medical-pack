---
name: compose-multiplatform-patterns
description: KMP プロジェクト向け Compose Multiplatform と Jetpack Compose パターン — 状態管理、ナビゲーション、テーマ、パフォーマンス、プラットフォーム固有 UI (Compose Multiplatform, Jetpack Compose, KMP, state management, navigation, theming, performance)。
origin: ECC
---

# Compose Multiplatform パターン

Compose Multiplatform と Jetpack Compose を使って Android・iOS・Desktop・Web 全体で共有 UI を構築するパターン。状態管理・ナビゲーション・テーマ・パフォーマンスをカバーする。

## 起動するタイミング

- Compose UI の構築 (Jetpack Compose または Compose Multiplatform)
- ViewModel と Compose 状態による UI 状態の管理
- KMP または Android プロジェクトでのナビゲーション実装
- 再利用可能な composable とデザインシステムの設計
- 再コンポジションとレンダリングパフォーマンスの最適化

## 状態管理

### ViewModel + 単一状態オブジェクト

画面状態に単一のデータクラスを使う。`StateFlow` として公開し Compose で収集する:

```kotlin
data class ItemListState(
    val items: List<Item> = emptyList(),
    val isLoading: Boolean = false,
    val error: String? = null,
    val searchQuery: String = ""
)

class ItemListViewModel(
    private val getItems: GetItemsUseCase
) : ViewModel() {
    private val _state = MutableStateFlow(ItemListState())
    val state: StateFlow<ItemListState> = _state.asStateFlow()

    fun onSearch(query: String) {
        _state.update { it.copy(searchQuery = query) }
        loadItems(query)
    }

    private fun loadItems(query: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            getItems(query).fold(
                onSuccess = { items -> _state.update { it.copy(items = items, isLoading = false) } },
                onFailure = { e -> _state.update { it.copy(error = e.message, isLoading = false) } }
            )
        }
    }
}
```

### Compose での状態収集

```kotlin
@Composable
fun ItemListScreen(viewModel: ItemListViewModel = koinViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    ItemListContent(
        state = state,
        onSearch = viewModel::onSearch
    )
}

@Composable
private fun ItemListContent(
    state: ItemListState,
    onSearch: (String) -> Unit
) {
    // Stateless composable — easy to preview and test
}
```

### イベントシンクパターン

複雑な画面では、複数のコールバックラムダではなく sealed interface のイベントを使う:

```kotlin
sealed interface ItemListEvent {
    data class Search(val query: String) : ItemListEvent
    data class Delete(val itemId: String) : ItemListEvent
    data object Refresh : ItemListEvent
}

// In ViewModel
fun onEvent(event: ItemListEvent) {
    when (event) {
        is ItemListEvent.Search -> onSearch(event.query)
        is ItemListEvent.Delete -> deleteItem(event.itemId)
        is ItemListEvent.Refresh -> loadItems(_state.value.searchQuery)
    }
}

// In Composable — single lambda instead of many
ItemListContent(
    state = state,
    onEvent = viewModel::onEvent
)
```

## ナビゲーション

### 型安全ナビゲーション (Compose Navigation 2.8+)

ルートを `@Serializable` オブジェクトとして定義する:

```kotlin
@Serializable data object HomeRoute
@Serializable data class DetailRoute(val id: String)
@Serializable data object SettingsRoute

@Composable
fun AppNavHost(navController: NavHostController = rememberNavController()) {
    NavHost(navController, startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(onNavigateToDetail = { id -> navController.navigate(DetailRoute(id)) })
        }
        composable<DetailRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<DetailRoute>()
            DetailScreen(id = route.id)
        }
        composable<SettingsRoute> { SettingsScreen() }
    }
}
```

### ダイアログとボトムシートナビゲーション

命令型 show/hide ではなく `dialog()` とオーバーレイパターンを使う:

```kotlin
NavHost(navController, startDestination = HomeRoute) {
    composable<HomeRoute> { /* ... */ }
    dialog<ConfirmDeleteRoute> { backStackEntry ->
        val route = backStackEntry.toRoute<ConfirmDeleteRoute>()
        ConfirmDeleteDialog(
            itemId = route.itemId,
            onConfirm = { navController.popBackStack() },
            onDismiss = { navController.popBackStack() }
        )
    }
}
```

## Composable 設計

### スロットベース API

柔軟性のためにスロットパラメータ付きで composable を設計する:

```kotlin
@Composable
fun AppCard(
    modifier: Modifier = Modifier,
    header: @Composable () -> Unit = {},
    content: @Composable ColumnScope.() -> Unit,
    actions: @Composable RowScope.() -> Unit = {}
) {
    Card(modifier = modifier) {
        Column {
            header()
            Column(content = content)
            Row(horizontalArrangement = Arrangement.End, content = actions)
        }
    }
}
```

### Modifier の順序

Modifier の順序が重要 — このシーケンスで適用する:

```kotlin
Text(
    text = "Hello",
    modifier = Modifier
        .padding(16.dp)          // 1. Layout (padding, size)
        .clip(RoundedCornerShape(8.dp))  // 2. Shape
        .background(Color.White) // 3. Drawing (background, border)
        .clickable { }           // 4. Interaction
)
```

## KMP プラットフォーム固有 UI

### プラットフォーム composable のための expect/actual

```kotlin
// commonMain
@Composable
expect fun PlatformStatusBar(darkIcons: Boolean)

// androidMain
@Composable
actual fun PlatformStatusBar(darkIcons: Boolean) {
    val systemUiController = rememberSystemUiController()
    SideEffect { systemUiController.setStatusBarColor(Color.Transparent, darkIcons) }
}

// iosMain
@Composable
actual fun PlatformStatusBar(darkIcons: Boolean) {
    // iOS handles this via UIKit interop or Info.plist
}
```

## パフォーマンス

### スキップ可能な再コンポジションのための Stable 型

すべてのプロパティが stable のとき、クラスを `@Stable` または `@Immutable` でマークする:

```kotlin
@Immutable
data class ItemUiModel(
    val id: String,
    val title: String,
    val description: String,
    val progress: Float
)
```

### `key()` と Lazy リストを正しく使う

```kotlin
LazyColumn {
    items(
        items = items,
        key = { it.id }  // Stable keys enable item reuse and animations
    ) { item ->
        ItemRow(item = item)
    }
}
```

### `derivedStateOf` で読み込みを遅延する

```kotlin
val listState = rememberLazyListState()
val showScrollToTop by remember {
    derivedStateOf { listState.firstVisibleItemIndex > 5 }
}
```

### 再コンポジションでの割り当てを避ける

```kotlin
// BAD — new lambda and list every recomposition
items.filter { it.isActive }.forEach { ActiveItem(it, onClick = { handle(it) }) }

// GOOD — key each item so callbacks stay attached to the right row
val activeItems = remember(items) { items.filter { it.isActive } }
activeItems.forEach { item ->
    key(item.id) {
        ActiveItem(item, onClick = { handle(item) })
    }
}
```

## テーマ

### Material 3 ダイナミックテーマ

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            if (darkTheme) dynamicDarkColorScheme(LocalContext.current)
            else dynamicLightColorScheme(LocalContext.current)
        }
        darkTheme -> darkColorScheme()
        else -> lightColorScheme()
    }

    MaterialTheme(colorScheme = colorScheme, content = content)
}
```

## 避けるべきアンチパターン

- ViewModel での `mutableStateOf` 使用 — ライフサイクル安全のために `collectAsStateWithLifecycle` 付きの `MutableStateFlow` を使う
- composable 深く `NavController` を渡す — 代わりにラムダコールバックを渡す
- `@Composable` 関数内の重い計算 — ViewModel または `remember {}` に移動する
- ViewModel init の代用としての `LaunchedEffect(Unit)` — 一部のセットアップで設定変更時に再実行される
- composable パラメータでの新オブジェクトインスタンス作成 — 不要な再コンポジションを引き起こす

## 参考

モジュール構造と階層化についてはスキル `android-clean-architecture` を参照。
コルーチンと Flow パターンについてはスキル `kotlin-coroutines-flows` を参照。
