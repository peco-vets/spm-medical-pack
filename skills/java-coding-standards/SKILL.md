---
name: java-coding-standards
description: "Spring Boot と Quarkus サービス向け Java コーディング標準。命名、不変性、Optional 使用、ストリーム、例外、ジェネリクス、CDI、リアクティブパターン、プロジェクト構成 (Java coding standards for Spring Boot and Quarkus services: naming, immutability, Optional usage, streams, exceptions, generics, CDI, reactive patterns, project layout)。フレームワーク固有の規約を自動適用する。"
origin: ECC
---

# Java コーディング標準

Spring Boot および Quarkus サービスにおける、可読性と保守性の高い Java(17+) コードのための標準である。

## 使用するタイミング

- Spring Boot または Quarkus プロジェクトで Java コードを記述・レビューする場合
- 命名、不変性、例外処理の規約を強制する場合
- レコード、シールドクラス、パターンマッチング (Java 17+) を扱う場合
- Optional、ストリーム、ジェネリクスの使用をレビューする場合
- パッケージとプロジェクト構成を整理する場合
- **[QUARKUS]**: CDI スコープ、Panache エンティティ、リアクティブパイプラインを扱う場合

## 動作の仕組み

### フレームワーク検出

標準を適用する前に、ビルドファイルからフレームワークを判定する。

- ビルドファイルに `quarkus` が含まれる → **[QUARKUS]** 規約を適用
- ビルドファイルに `spring-boot` が含まれる → **[SPRING]** 規約を適用
- どちらも検出されない → 共通規約のみを適用

## 基本原則

- 巧妙さよりも明瞭さを優先する
- デフォルトで不変であり、共有可変状態を最小化する
- 意味のある例外でフェイルファストする
- 一貫した命名とパッケージ構成
- **[QUARKUS]**: 実行時処理よりもビルド時処理を優先し、可能な限り実行時リフレクションを避ける

## 例

以下のセクションでは、命名、不変性、依存性注入、リアクティブコード、例外、プロジェクト構成、ロギング、設定、テストについて、Spring Boot、Quarkus、共通の具体例を示す。

## 命名

```java
// PASS: Classes/Records: PascalCase
public class MarketService {}
public record Money(BigDecimal amount, Currency currency) {}

// PASS: Methods/fields: camelCase
private final MarketRepository marketRepository;
public Market findBySlug(String slug) {}

// PASS: Constants: UPPER_SNAKE_CASE
private static final int MAX_PAGE_SIZE = 100;

// PASS: [QUARKUS] JAX-RS resources named as *Resource, not *Controller
public class MarketResource {}

// PASS: [SPRING] REST controllers named as *Controller
public class MarketController {}
```

## 不変性

```java
// PASS: Favor records and final fields
public record MarketDto(Long id, String name, MarketStatus status) {}

public class Market {
  private final Long id;
  private final String name;
  // getters only, no setters
}

// PASS: [QUARKUS] Panache active-record entities use public fields (Quarkus convention)
@Entity
public class Market extends PanacheEntity {
  public String name;
  public MarketStatus status;
  // Panache generates accessors at build time; public fields are idiomatic here
}

// PASS: [QUARKUS] Panache MongoDB entities
@MongoEntity(collection = "markets")
public class Market extends PanacheMongoEntity {
  public String name;
  public MarketStatus status;
}
```

## Optional の使用

```java
// PASS: Return Optional from find* methods
// [SPRING]
Optional<Market> market = marketRepository.findBySlug(slug);

// [QUARKUS] Panache
Optional<Market> market = Market.find("slug", slug).firstResultOptional();

// PASS: Map/flatMap instead of get()
return market
    .map(MarketResponse::from)
    .orElseThrow(() -> new EntityNotFoundException("Market not found"));
```

## ストリームのベストプラクティス

```java
// PASS: Use streams for transformations, keep pipelines short
List<String> names = markets.stream()
    .map(Market::name)
    .filter(Objects::nonNull)
    .toList();

// FAIL: Avoid complex nested streams; prefer loops for clarity
```

## 依存性注入

```java
// PASS: [SPRING] Constructor injection (preferred over @Autowired on fields)
@Service
public class MarketService {
  private final MarketRepository marketRepository;

  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// PASS: [QUARKUS] Constructor injection
@ApplicationScoped
public class MarketService {
  private final MarketRepository marketRepository;

  @Inject
  public MarketService(MarketRepository marketRepository) {
    this.marketRepository = marketRepository;
  }
}

// PASS: [QUARKUS] Package-private field injection (acceptable in Quarkus — avoids proxy issues)
@ApplicationScoped
public class MarketService {
  @Inject
  MarketRepository marketRepository;
}

// FAIL: [SPRING] Field injection with @Autowired
@Autowired
private MarketRepository marketRepository; // use constructor injection

// FAIL: [QUARKUS] @Singleton when interception or lazy init is needed
@Singleton // non-proxyable — use @ApplicationScoped instead
public class MarketService {}
```

## リアクティブパターン [QUARKUS]

```java
// PASS: Return Uni/Multi from reactive endpoints
@GET
@Path("/{slug}")
public Uni<Market> findBySlug(@PathParam("slug") String slug) {
  return Market.find("slug", slug)
      .<Market>firstResult()
      .onItem().ifNull().failWith(() -> new MarketNotFoundException(slug));
}

// PASS: Non-blocking pipeline composition
public Uni<OrderConfirmation> placeOrder(OrderRequest req) {
  return validateOrder(req)
      .chain(valid -> persistOrder(valid))
      .chain(order -> notifyFulfillment(order));
}

// FAIL: Blocking call inside a Uni/Multi pipeline
public Uni<Market> find(String slug) {
  Market m = Market.find("slug", slug).firstResult(); // BLOCKING — breaks event loop
  return Uni.createFrom().item(m);
}

// FAIL: Subscribing more than once to a shared Uni
Uni<Market> shared = fetchMarket(slug);
shared.subscribe().with(m -> log(m));
shared.subscribe().with(m -> cache(m)); // double subscribe — use Uni.memoize()
```

## 例外

- ドメインエラーには非チェック例外を使用し、技術例外はコンテキストとともにラップする
- ドメイン固有の例外を作成する(例: `MarketNotFoundException`)
- 中央で再スロー・ロギングしない限り、広範な `catch (Exception ex)` を避ける

```java
throw new MarketNotFoundException(slug);
```

### 集約された例外処理

```java
// [SPRING]
@RestControllerAdvice
public class GlobalExceptionHandler {
  @ExceptionHandler(MarketNotFoundException.class)
  public ResponseEntity<ErrorResponse> handle(MarketNotFoundException ex) {
    return ResponseEntity.status(404).body(ErrorResponse.from(ex));
  }
}

// [QUARKUS] Option A: ExceptionMapper
@Provider
public class MarketNotFoundMapper implements ExceptionMapper<MarketNotFoundException> {
  @Override
  public Response toResponse(MarketNotFoundException ex) {
    return Response.status(404).entity(ErrorResponse.from(ex)).build();
  }
}

// [QUARKUS] Option B: @ServerExceptionMapper (RESTEasy Reactive)
@ServerExceptionMapper
public RestResponse<ErrorResponse> handle(MarketNotFoundException ex) {
  return RestResponse.status(Status.NOT_FOUND, ErrorResponse.from(ex));
}
```

## ジェネリクスと型安全性

- raw 型を避け、ジェネリクスパラメータを宣言する
- 再利用可能なユーティリティには有界ジェネリクスを優先する

```java
public <T extends Identifiable> Map<Long, T> indexById(Collection<T> items) { ... }
```

## プロジェクト構成

### [SPRING] Maven/Gradle

```
src/main/java/com/example/app/
  config/
  controller/
  service/
  repository/
  domain/
  dto/
  util/
src/main/resources/
  application.yml
src/test/java/... (mirrors main)
```

### [QUARKUS] Maven/Gradle

```
src/main/java/com/example/app/
  config/              # @ConfigMapping, @ConfigProperty beans, Producers
  resource/            # JAX-RS resources (not "controller")
  service/
  repository/          # PanacheRepository implementations (if not using active record)
  domain/              # JPA/Panache entities, MongoDB entities
  dto/
  util/
  mapper/              # MapStruct mappers (if used)
src/main/resources/
  application.properties   # Quarkus convention (YAML supported with quarkus-config-yaml)
  import.sql               # Hibernate auto-import for dev/test
src/test/java/... (mirrors main)
```

## フォーマットとスタイル

- 一貫して 2 または 4 スペースを使用する(プロジェクト標準)
- ファイルごとに 1 つのパブリックトップレベル型のみ
- メソッドは短く焦点を絞り、ヘルパーを抽出する
- メンバーの順序: 定数、フィールド、コンストラクタ、public メソッド、protected、private

## 避けるべきコードスメル

- 長いパラメータリスト → DTO/ビルダーを使用
- 深いネスト → 早期リターン
- マジックナンバー → 名前付き定数
- 静的可変状態 → 依存性注入を優先
- 沈黙する catch ブロック → ログを出し、対処するか再スロー
- **[QUARKUS]**: `@ApplicationScoped` を意図する箇所での `@Singleton` — プロキシ化とインターセプションを壊す
- **[QUARKUS]**: `quarkus-resteasy-reactive` と `quarkus-resteasy` (クラシック) の混在 — どちらか 1 つを選ぶ
- **[QUARKUS]**: 同じ境界づけられたコンテキスト内での Panache アクティブレコード + リポジトリパターン — どちらか 1 つを選ぶ

## ロギング

```java
// [SPRING] SLF4J
private static final Logger log = LoggerFactory.getLogger(MarketService.class);
log.info("fetch_market slug={}", slug);
log.error("failed_fetch_market slug={}", slug, ex);

// [QUARKUS] JBoss Logging (default, zero-cost at build time)
private static final Logger log = Logger.getLogger(MarketService.class);
log.infof("fetch_market slug=%s", slug);
log.errorf(ex, "failed_fetch_market slug=%s", slug);

// [QUARKUS] Alternative: simplified logging with @Inject
@Inject
Logger log; // CDI-injected, scoped to declaring class
```

## null 処理

- 避けられない場合にのみ `@Nullable` を受け入れ、それ以外は `@NonNull` を使用する
- 入力には Bean Validation (`@NotNull`、`@NotBlank`) を使用する
- **[QUARKUS]**: `@BeanParam`、`@RestForm`、リクエストボディパラメータに `@Valid` を適用する

## 設定

```java
// [SPRING] @ConfigurationProperties
@ConfigurationProperties(prefix = "market")
public record MarketProperties(int maxPageSize, Duration cacheTtl) {}

// [QUARKUS] @ConfigMapping (type-safe, build-time validated)
@ConfigMapping(prefix = "market")
public interface MarketConfig {
  int maxPageSize();
  Duration cacheTtl();
}

// [QUARKUS] Simple values with @ConfigProperty
@ConfigProperty(name = "market.max-page-size", defaultValue = "100")
int maxPageSize;
```

## テストの期待事項

### 共通
- JUnit 5 + 流暢なアサーションのための AssertJ
- モック作成には Mockito、可能な限り部分モックを避ける
- 決定論的なテストを優先し、隠れた sleep を入れない

### [SPRING]
- コントローラスライスには `@WebMvcTest`、リポジトリスライスには `@DataJpaTest`
- `@SpringBootTest` は完全な統合テスト用に予約する
- Spring コンテキスト内のビーンを置き換えるには `@MockBean`

### [QUARKUS]
- ユニットテストには素の JUnit 5 + Mockito (`@QuarkusTest` 不要)
- `@QuarkusTest` は CDI 統合テスト用に予約する
- 統合テストで CDI ビーンを置き換えるには `@InjectMock`
- データベース/Kafka/Redis には Dev Services を使用 — Dev Services で十分な場合は手動の Testcontainers セットアップを避ける
- カスタム外部サービスのライフサイクルには `@QuarkusTestResource`

```java
// [SPRING] Controller test
@WebMvcTest(MarketController.class)
class MarketControllerTest {
  @Autowired MockMvc mockMvc;
  @MockBean MarketService marketService;
}

// [QUARKUS] Integration test
@QuarkusTest
class MarketResourceTest {
  @InjectMock
  MarketService marketService;

  @Test
  void should_return_404_when_market_not_found() {
    given().when().get("/markets/unknown").then().statusCode(404);
  }
}

// [QUARKUS] Unit test (no CDI, no @QuarkusTest)
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository marketRepository;
  @InjectMocks MarketService marketService;
}
```

**注意**: コードは意図的、型付き、観測可能に保つこと。必要性が証明されない限り、マイクロ最適化よりも保守性を優先せよ。
