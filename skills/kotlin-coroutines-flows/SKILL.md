---
name: kotlin-coroutines-flows
description: Android および KMP 向けの Kotlin Coroutines と Flow パターン — 構造化並行性、Flow オペレーター、StateFlow、エラー処理、テスト (Kotlin Coroutines and Flow patterns for Android and KMP — structured concurrency, Flow operators, StateFlow, error handling, testing)。
origin: ECC
---

# Kotlin Coroutines & Flow

Android および Kotlin Multiplatform プロジェクトにおける構造化並行性、Flow ベースのリアクティブストリーム、コルーチンテストのためのパターンである。

## 起動するタイミング

- Kotlin コルーチンによる非同期コードを記述する場合
- リアクティブデータのために Flow、StateFlow、SharedFlow を使用する場合
- 並行操作 (並列ロード、デバウンス、リトライ) を扱う場合
- コルーチンと Flow をテストする場合
- コルーチンスコープとキャンセルを管理する場合

## 構造化並行性

### スコープ階層

```
Application
  └── viewModelScope (ViewModel)
        └── coroutineScope { } (structured child)
              ├── async { } (concurrent task)
              └── async { } (concurrent task)
```

`GlobalScope` を使わず、必ず構造化並行性を使用する。

```kotlin
// BAD
GlobalScope.launch { fetchData() }

// GOOD — scoped to ViewModel lifecycle
viewModelScope.launch { fetchData() }

// GOOD — scoped to composable lifecycle
LaunchedEffect(key) { fetchData() }
```

### 並列分解

並列作業には `coroutineScope` + `async` を使用する。

```kotlin
suspend fun loadDashboard(): Dashboard = coroutineScope {
    val items = async { itemRepository.getRecent() }
    val stats = async { statsRepository.getToday() }
    val profile = async { userRepository.getCurrent() }
    Dashboard(
        items = items.await(),
        stats = stats.await(),
        profile = profile.await()
    )
}
```

### SupervisorScope

子の失敗が兄弟をキャンセルすべきでない場合は `supervisorScope` を使用する。

```kotlin
suspend fun syncAll() = supervisorScope {
    launch { syncItems() }       // failure here won't cancel syncStats
    launch { syncStats() }
    launch { syncSettings() }
}
```

## Flow パターン

### Cold Flow — ワンショットからストリームへの変換

```kotlin
fun observeItems(): Flow<List<Item>> = flow {
    // Re-emits whenever the database changes
    itemDao.observeAll()
        .map { entities -> entities.map { it.toDomain() } }
        .collect { emit(it) }
}
```

### UI 状態のための StateFlow

```kotlin
class DashboardViewModel(
    observeProgress: ObserveUserProgressUseCase
) : ViewModel() {
    val progress: StateFlow<UserProgress> = observeProgress()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = UserProgress.EMPTY
        )
}
```

`WhileSubscribed(5_000)` は、最後のサブスクライバーが離脱してから 5 秒間アップストリームをアクティブに保つ — 再起動なしで構成変更を生き延びる。

### 複数の Flow の結合

```kotlin
val uiState: StateFlow<HomeState> = combine(
    itemRepository.observeItems(),
    settingsRepository.observeTheme(),
    userRepository.observeProfile()
) { items, theme, profile ->
    HomeState(items = items, theme = theme, profile = profile)
}.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), HomeState())
```

### Flow オペレーター

```kotlin
// Debounce search input
searchQuery
    .debounce(300)
    .distinctUntilChanged()
    .flatMapLatest { query -> repository.search(query) }
    .catch { emit(emptyList()) }
    .collect { results -> _state.update { it.copy(results = results) } }

// Retry with exponential backoff
fun fetchWithRetry(): Flow<Data> = flow { emit(api.fetch()) }
    .retryWhen { cause, attempt ->
        if (cause is IOException && attempt < 3) {
            delay(1000L * (1 shl attempt.toInt()))
            true
        } else {
            false
        }
    }
```

### ワンタイムイベントのための SharedFlow

```kotlin
class ItemListViewModel : ViewModel() {
    private val _effects = MutableSharedFlow<Effect>()
    val effects: SharedFlow<Effect> = _effects.asSharedFlow()

    sealed interface Effect {
        data class ShowSnackbar(val message: String) : Effect
        data class NavigateTo(val route: String) : Effect
    }

    private fun deleteItem(id: String) {
        viewModelScope.launch {
            repository.delete(id)
            _effects.emit(Effect.ShowSnackbar("Item deleted"))
        }
    }
}

// Collect in Composable
LaunchedEffect(Unit) {
    viewModel.effects.collect { effect ->
        when (effect) {
            is Effect.ShowSnackbar -> snackbarHostState.showSnackbar(effect.message)
            is Effect.NavigateTo -> navController.navigate(effect.route)
        }
    }
}
```

## ディスパッチャー

```kotlin
// CPU-intensive work
withContext(Dispatchers.Default) { parseJson(largePayload) }

// IO-bound work
withContext(Dispatchers.IO) { database.query() }

// Main thread (UI) — default in viewModelScope
withContext(Dispatchers.Main) { updateUi() }
```

KMP では `Dispatchers.Default` と `Dispatchers.Main` を使用する (全プラットフォームで利用可能)。`Dispatchers.IO` は JVM/Android のみ — 他プラットフォームでは `Dispatchers.Default` を使うか DI 経由で提供する。

## キャンセル

### 協調キャンセル

長時間実行ループはキャンセルをチェックする必要がある。

```kotlin
suspend fun processItems(items: List<Item>) = coroutineScope {
    for (item in items) {
        ensureActive()  // throws CancellationException if cancelled
        process(item)
    }
}
```

### try/finally によるクリーンアップ

```kotlin
viewModelScope.launch {
    try {
        _state.update { it.copy(isLoading = true) }
        val data = repository.fetch()
        _state.update { it.copy(data = data) }
    } finally {
        _state.update { it.copy(isLoading = false) }  // always runs, even on cancellation
    }
}
```

## テスト

### Turbine による StateFlow のテスト

```kotlin
@Test
fun `search updates item list`() = runTest {
    val fakeRepository = FakeItemRepository().apply { emit(testItems) }
    val viewModel = ItemListViewModel(GetItemsUseCase(fakeRepository))

    viewModel.state.test {
        assertEquals(ItemListState(), awaitItem())  // initial

        viewModel.onSearch("query")
        val loading = awaitItem()
        assertTrue(loading.isLoading)

        val loaded = awaitItem()
        assertFalse(loaded.isLoading)
        assertEquals(1, loaded.items.size)
    }
}
```

### TestDispatcher によるテスト

```kotlin
@Test
fun `parallel load completes correctly`() = runTest {
    val viewModel = DashboardViewModel(
        itemRepo = FakeItemRepo(),
        statsRepo = FakeStatsRepo()
    )

    viewModel.load()
    advanceUntilIdle()

    val state = viewModel.state.value
    assertNotNull(state.items)
    assertNotNull(state.stats)
}
```

### Flow のフェイク化

```kotlin
class FakeItemRepository : ItemRepository {
    private val _items = MutableStateFlow<List<Item>>(emptyList())

    override fun observeItems(): Flow<List<Item>> = _items

    fun emit(items: List<Item>) { _items.value = items }

    override suspend fun getItemsByCategory(category: String): Result<List<Item>> {
        return Result.success(_items.value.filter { it.category == category })
    }
}
```

## 避けるべきアンチパターン

- `GlobalScope` の使用 — コルーチンがリークし、構造化キャンセルがない
- スコープなしで `init {}` 内で Flow を収集 — `viewModelScope.launch` を使う
- `MutableStateFlow` を可変コレクションと併用 — 必ず不変コピーを使う: `_state.update { it.copy(list = it.list + newItem) }`
- `CancellationException` をキャッチ — 適切なキャンセルのために伝播させる
- 収集に `flowOn(Dispatchers.Main)` を使用 — 収集ディスパッチャーは呼び出し側のディスパッチャーである
- `remember` なしで `@Composable` 内に `Flow` を作成 — リコンポーズのたびに Flow を再作成する

## 参照

スキル `compose-multiplatform-patterns` を参照 (Flow の UI 消費)。
スキル `android-clean-architecture` を参照 (コルーチンが各層のどこに収まるか)。
