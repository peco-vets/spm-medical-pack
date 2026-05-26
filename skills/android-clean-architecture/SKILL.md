---
name: android-clean-architecture
description: Android と Kotlin Multiplatform プロジェクトのためのクリーンアーキテクチャパターン — モジュール構造、依存ルール、UseCases、Repositories、データ層パターン (Android clean architecture, Kotlin Multiplatform, KMP, UseCase, Repository, Room, SQLDelight, Ktor)。
origin: ECC
---

# Android クリーンアーキテクチャ

Android と KMP プロジェクト向けのクリーンアーキテクチャパターン。モジュール境界、依存逆転、UseCase/Repository パターン、Room・SQLDelight・Ktor を用いたデータ層設計を扱う。

## 起動するタイミング

- Android または KMP プロジェクトモジュールの構造化
- UseCase・Repository・DataSource の実装
- レイヤー (domain・data・presentation) 間のデータフロー設計
- Koin または Hilt による依存注入のセットアップ
- レイヤードアーキテクチャでの Room・SQLDelight・Ktor の使用

## モジュール構造

### 推奨レイアウト

```
project/
├── app/                  # Android entry point, DI wiring, Application class
├── core/                 # Shared utilities, base classes, error types
├── domain/               # UseCases, domain models, repository interfaces (pure Kotlin)
├── data/                 # Repository implementations, DataSources, DB, network
├── presentation/         # Screens, ViewModels, UI models, navigation
├── design-system/        # Reusable Compose components, theme, typography
└── feature/              # Feature modules (optional, for larger projects)
    ├── auth/
    ├── settings/
    └── profile/
```

### 依存ルール

```
app → presentation, domain, data, core
presentation → domain, design-system, core
data → domain, core
domain → core (or no dependencies)
core → (nothing)
```

**重要**: `domain` は `data`・`presentation`・任意のフレームワークに決して依存してはならない。純粋な Kotlin のみを含む。

## ドメイン層

### UseCase パターン

各 UseCase は 1 つのビジネス操作を表す。クリーンな呼び出しサイトのために `operator fun invoke` を使う:

```kotlin
class GetItemsByCategoryUseCase(
    private val repository: ItemRepository
) {
    suspend operator fun invoke(category: String): Result<List<Item>> {
        return repository.getItemsByCategory(category)
    }
}

// Flow-based UseCase for reactive streams
class ObserveUserProgressUseCase(
    private val repository: UserRepository
) {
    operator fun invoke(userId: String): Flow<UserProgress> {
        return repository.observeProgress(userId)
    }
}
```

### ドメインモデル

ドメインモデルはプレーンな Kotlin データクラス — フレームワークアノテーションなし:

```kotlin
data class Item(
    val id: String,
    val title: String,
    val description: String,
    val tags: List<String>,
    val status: Status,
    val category: String
)

enum class Status { DRAFT, ACTIVE, ARCHIVED }
```

### Repository インターフェース

domain で定義し、data で実装する:

```kotlin
interface ItemRepository {
    suspend fun getItemsByCategory(category: String): Result<List<Item>>
    suspend fun saveItem(item: Item): Result<Unit>
    fun observeItems(): Flow<List<Item>>
}
```

## データ層

### Repository 実装

ローカルとリモートのデータソース間を調整する:

```kotlin
class ItemRepositoryImpl(
    private val localDataSource: ItemLocalDataSource,
    private val remoteDataSource: ItemRemoteDataSource
) : ItemRepository {

    override suspend fun getItemsByCategory(category: String): Result<List<Item>> {
        return runCatching {
            val remote = remoteDataSource.fetchItems(category)
            localDataSource.insertItems(remote.map { it.toEntity() })
            localDataSource.getItemsByCategory(category).map { it.toDomain() }
        }
    }

    override suspend fun saveItem(item: Item): Result<Unit> {
        return runCatching {
            localDataSource.insertItems(listOf(item.toEntity()))
        }
    }

    override fun observeItems(): Flow<List<Item>> {
        return localDataSource.observeAll().map { entities ->
            entities.map { it.toDomain() }
        }
    }
}
```

### Mapper パターン

データモデルの近くにマッパーを拡張関数として保持する:

```kotlin
// In data layer
fun ItemEntity.toDomain() = Item(
    id = id,
    title = title,
    description = description,
    tags = tags.split("|"),
    status = Status.valueOf(status),
    category = category
)

fun ItemDto.toEntity() = ItemEntity(
    id = id,
    title = title,
    description = description,
    tags = tags.joinToString("|"),
    status = status,
    category = category
)
```

### Room データベース (Android)

```kotlin
@Entity(tableName = "items")
data class ItemEntity(
    @PrimaryKey val id: String,
    val title: String,
    val description: String,
    val tags: String,
    val status: String,
    val category: String
)

@Dao
interface ItemDao {
    @Query("SELECT * FROM items WHERE category = :category")
    suspend fun getByCategory(category: String): List<ItemEntity>

    @Upsert
    suspend fun upsert(items: List<ItemEntity>)

    @Query("SELECT * FROM items")
    fun observeAll(): Flow<List<ItemEntity>>
}
```

### SQLDelight (KMP)

```sql
-- Item.sq
CREATE TABLE ItemEntity (
    id TEXT NOT NULL PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    tags TEXT NOT NULL,
    status TEXT NOT NULL,
    category TEXT NOT NULL
);

getByCategory:
SELECT * FROM ItemEntity WHERE category = ?;

upsert:
INSERT OR REPLACE INTO ItemEntity (id, title, description, tags, status, category)
VALUES (?, ?, ?, ?, ?, ?);

observeAll:
SELECT * FROM ItemEntity;
```

### Ktor ネットワーククライアント (KMP)

```kotlin
class ItemRemoteDataSource(private val client: HttpClient) {

    suspend fun fetchItems(category: String): List<ItemDto> {
        return client.get("api/items") {
            parameter("category", category)
        }.body()
    }
}

// HttpClient setup with content negotiation
val httpClient = HttpClient {
    install(ContentNegotiation) { json(Json { ignoreUnknownKeys = true }) }
    install(Logging) { level = LogLevel.HEADERS }
    defaultRequest { url("https://api.example.com/") }
}
```

## 依存注入

### Koin (KMP フレンドリー)

```kotlin
// Domain module
val domainModule = module {
    factory { GetItemsByCategoryUseCase(get()) }
    factory { ObserveUserProgressUseCase(get()) }
}

// Data module
val dataModule = module {
    single<ItemRepository> { ItemRepositoryImpl(get(), get()) }
    single { ItemLocalDataSource(get()) }
    single { ItemRemoteDataSource(get()) }
}

// Presentation module
val presentationModule = module {
    viewModelOf(::ItemListViewModel)
    viewModelOf(::DashboardViewModel)
}
```

### Hilt (Android 専用)

```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    abstract fun bindItemRepository(impl: ItemRepositoryImpl): ItemRepository
}

@HiltViewModel
class ItemListViewModel @Inject constructor(
    private val getItems: GetItemsByCategoryUseCase
) : ViewModel()
```

## エラー処理

### Result/Try パターン

エラー伝播に `Result<T>` またはカスタム sealed 型を使う:

```kotlin
sealed interface Try<out T> {
    data class Success<T>(val value: T) : Try<T>
    data class Failure(val error: AppError) : Try<Nothing>
}

sealed interface AppError {
    data class Network(val message: String) : AppError
    data class Database(val message: String) : AppError
    data object Unauthorized : AppError
}

// In ViewModel — map to UI state
viewModelScope.launch {
    when (val result = getItems(category)) {
        is Try.Success -> _state.update { it.copy(items = result.value, isLoading = false) }
        is Try.Failure -> _state.update { it.copy(error = result.error.toMessage(), isLoading = false) }
    }
}
```

## Convention プラグイン (Gradle)

KMP プロジェクトでは convention プラグインを使ってビルドファイルの重複を減らす:

```kotlin
// build-logic/src/main/kotlin/kmp-library.gradle.kts
plugins {
    id("org.jetbrains.kotlin.multiplatform")
}

kotlin {
    androidTarget()
    iosX64(); iosArm64(); iosSimulatorArm64()
    sourceSets {
        commonMain.dependencies { /* shared deps */ }
        commonTest.dependencies { implementation(kotlin("test")) }
    }
}
```

モジュールに適用する:

```kotlin
// domain/build.gradle.kts
plugins { id("kmp-library") }
```

## 避けるべきアンチパターン

- `domain` で Android フレームワーククラスをインポート — 純粋な Kotlin に保つ
- データベースエンティティや DTO を UI 層に公開 — 常にドメインモデルにマップする
- ViewModel にビジネスロジックを置く — UseCase に抽出する
- `GlobalScope` や構造化されていないコルーチンを使う — `viewModelScope` または構造化並行性を使う
- 肥大した Repository 実装 — 集中した DataSource に分割する
- 循環モジュール依存 — A が B に依存するなら、B は A に依存してはならない

## 参考

UI パターンについてはスキル `compose-multiplatform-patterns` を参照。
非同期パターンについてはスキル `kotlin-coroutines-flows` を参照。
