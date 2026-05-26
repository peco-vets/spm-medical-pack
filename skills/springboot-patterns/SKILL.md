---
name: springboot-patterns
description: Spring Boot のアーキテクチャパターン、REST API 設計、レイヤード・サービス、データアクセス、キャッシュ、非同期処理、ロギング（Spring Boot architecture, REST API, layered services, data access, caching, async, logging）。Java Spring Boot バックエンド作業に使用する。
origin: ECC
---

# Spring Boot 開発パターン

スケーラブルで本番グレードのサービス向けの Spring Boot アーキテクチャと API パターン。

## 起動するタイミング

- Spring MVC または WebFlux で REST API を構築
- controller → service → repository レイヤを構成
- Spring Data JPA、キャッシュ、非同期処理の設定
- バリデーション、例外処理、ページネーションの追加
- dev/staging/production 環境向けのプロファイル設定
- Spring Events または Kafka でのイベントドリブンパターンの実装

## REST API の構造

```java
@RestController
@RequestMapping("/api/markets")
@Validated
class MarketController {
  private final MarketService marketService;

  MarketController(MarketService marketService) {
    this.marketService = marketService;
  }

  @GetMapping
  ResponseEntity<Page<MarketResponse>> list(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    Page<Market> markets = marketService.list(PageRequest.of(page, size));
    return ResponseEntity.ok(markets.map(MarketResponse::from));
  }

  @PostMapping
  ResponseEntity<MarketResponse> create(@Valid @RequestBody CreateMarketRequest request) {
    Market market = marketService.create(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(MarketResponse.from(market));
  }
}
```

## リポジトリパターン（Spring Data JPA）

```java
public interface MarketRepository extends JpaRepository<MarketEntity, Long> {
  @Query("select m from MarketEntity m where m.status = :status order by m.volume desc")
  List<MarketEntity> findActive(@Param("status") MarketStatus status, Pageable pageable);
}
```

## トランザクション付きサービス層

```java
@Service
public class MarketService {
  private final MarketRepository repo;

  public MarketService(MarketRepository repo) {
    this.repo = repo;
  }

  @Transactional
  public Market create(CreateMarketRequest request) {
    MarketEntity entity = MarketEntity.from(request);
    MarketEntity saved = repo.save(entity);
    return Market.from(saved);
  }
}
```

## DTO とバリデーション

```java
public record CreateMarketRequest(
    @NotBlank @Size(max = 200) String name,
    @NotBlank @Size(max = 2000) String description,
    @NotNull @FutureOrPresent Instant endDate,
    @NotEmpty List<@NotBlank String> categories) {}

public record MarketResponse(Long id, String name, MarketStatus status) {
  static MarketResponse from(Market market) {
    return new MarketResponse(market.id(), market.name(), market.status());
  }
}
```

## 例外処理

```java
@ControllerAdvice
class GlobalExceptionHandler {
  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
    String message = ex.getBindingResult().getFieldErrors().stream()
        .map(e -> e.getField() + ": " + e.getDefaultMessage())
        .collect(Collectors.joining(", "));
    return ResponseEntity.badRequest().body(ApiError.validation(message));
  }

  @ExceptionHandler(AccessDeniedException.class)
  ResponseEntity<ApiError> handleAccessDenied() {
    return ResponseEntity.status(HttpStatus.FORBIDDEN).body(ApiError.of("Forbidden"));
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<ApiError> handleGeneric(Exception ex) {
    // Log unexpected errors with stack traces
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body(ApiError.of("Internal server error"));
  }
}
```

## キャッシュ

設定クラスに `@EnableCaching` が必要。

```java
@Service
public class MarketCacheService {
  private final MarketRepository repo;

  public MarketCacheService(MarketRepository repo) {
    this.repo = repo;
  }

  @Cacheable(value = "market", key = "#id")
  public Market getById(Long id) {
    return repo.findById(id)
        .map(Market::from)
        .orElseThrow(() -> new EntityNotFoundException("Market not found"));
  }

  @CacheEvict(value = "market", key = "#id")
  public void evict(Long id) {}
}
```

## 非同期処理

設定クラスに `@EnableAsync` が必要。

```java
@Service
public class NotificationService {
  @Async
  public CompletableFuture<Void> sendAsync(Notification notification) {
    // send email/SMS
    return CompletableFuture.completedFuture(null);
  }
}
```

## ロギング（SLF4J）

```java
@Service
public class ReportService {
  private static final Logger log = LoggerFactory.getLogger(ReportService.class);

  public Report generate(Long marketId) {
    log.info("generate_report marketId={}", marketId);
    try {
      // logic
    } catch (Exception ex) {
      log.error("generate_report_failed marketId={}", marketId, ex);
      throw ex;
    }
    return new Report();
  }
}
```

## ミドルウェア／フィルタ

```java
@Component
public class RequestLoggingFilter extends OncePerRequestFilter {
  private static final Logger log = LoggerFactory.getLogger(RequestLoggingFilter.class);

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain filterChain) throws ServletException, IOException {
    long start = System.currentTimeMillis();
    try {
      filterChain.doFilter(request, response);
    } finally {
      long duration = System.currentTimeMillis() - start;
      log.info("req method={} uri={} status={} durationMs={}",
          request.getMethod(), request.getRequestURI(), response.getStatus(), duration);
    }
  }
}
```

## ページネーションとソート

```java
PageRequest page = PageRequest.of(pageNumber, pageSize, Sort.by("createdAt").descending());
Page<Market> results = marketService.list(page);
```

## エラー耐性のある外部呼び出し

```java
public <T> T withRetry(Supplier<T> supplier, int maxRetries) {
  int attempts = 0;
  while (true) {
    try {
      return supplier.get();
    } catch (Exception ex) {
      attempts++;
      if (attempts >= maxRetries) {
        throw ex;
      }
      try {
        Thread.sleep((long) Math.pow(2, attempts) * 100L);
      } catch (InterruptedException ie) {
        Thread.currentThread().interrupt();
        throw ex;
      }
    }
  }
}
```

## レート制限（Filter + Bucket4j）

**セキュリティ注意**：`X-Forwarded-For` ヘッダはクライアントが偽装可能なためデフォルトで信頼できない。
転送ヘッダを使うのは以下のときのみ：
1. アプリが信頼できるリバースプロキシ（nginx、AWS ALB など）の背後にある
2. `ForwardedHeaderFilter` を Bean として登録している
3. application プロパティで `server.forward-headers-strategy=NATIVE` または `FRAMEWORK` を設定している
4. プロキシが `X-Forwarded-For` ヘッダを上書きする（追加ではなく）ように設定されている

`ForwardedHeaderFilter` が適切に設定されると、`request.getRemoteAddr()` は転送ヘッダから正しいクライアント IP を自動的に返す。この設定がない場合、`request.getRemoteAddr()` を直接使う — それは直接接続 IP を返し、これが唯一信頼できる値である。

```java
@Component
public class RateLimitFilter extends OncePerRequestFilter {
  private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

  /*
   * SECURITY: This filter uses request.getRemoteAddr() to identify clients for rate limiting.
   *
   * If your application is behind a reverse proxy (nginx, AWS ALB, etc.), you MUST configure
   * Spring to handle forwarded headers properly for accurate client IP detection:
   *
   * 1. Set server.forward-headers-strategy=NATIVE (for cloud platforms) or FRAMEWORK in
   *    application.properties/yaml
   * 2. If using FRAMEWORK strategy, register ForwardedHeaderFilter:
   *
   *    @Bean
   *    ForwardedHeaderFilter forwardedHeaderFilter() {
   *        return new ForwardedHeaderFilter();
   *    }
   *
   * 3. Ensure your proxy overwrites (not appends) the X-Forwarded-For header to prevent spoofing
   * 4. Configure server.tomcat.remoteip.trusted-proxies or equivalent for your container
   *
   * Without this configuration, request.getRemoteAddr() returns the proxy IP, not the client IP.
   * Do NOT read X-Forwarded-For directly—it is trivially spoofable without trusted proxy handling.
   */
  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain filterChain) throws ServletException, IOException {
    // Use getRemoteAddr() which returns the correct client IP when ForwardedHeaderFilter
    // is configured, or the direct connection IP otherwise. Never trust X-Forwarded-For
    // headers directly without proper proxy configuration.
    String clientIp = request.getRemoteAddr();

    Bucket bucket = buckets.computeIfAbsent(clientIp,
        k -> Bucket.builder()
            .addLimit(Bandwidth.classic(100, Refill.greedy(100, Duration.ofMinutes(1))))
            .build());

    if (bucket.tryConsume(1)) {
      filterChain.doFilter(request, response);
    } else {
      response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
    }
  }
}
```

## バックグラウンドジョブ

Spring の `@Scheduled` を使うか、キュー（Kafka、SQS、RabbitMQ など）と統合する。ハンドラは冪等で観察可能にする。

## オブザーバビリティ

- Logback エンコーダによる構造化ロギング（JSON）
- メトリック：Micrometer + Prometheus/OTel
- トレース：OpenTelemetry または Brave バックエンドの Micrometer Tracing

## 本番デフォルト

- コンストラクタインジェクションを推奨、フィールドインジェクションを避ける
- RFC 7807 エラーには `spring.mvc.problemdetails.enabled=true` を有効化（Spring Boot 3+）
- ワークロード用に HikariCP プールサイズを設定、タイムアウトを設定
- クエリには `@Transactional(readOnly = true)` を使う
- 適切な場所で `@NonNull` と `Optional` で null セーフティを強制

**覚えておくこと**：コントローラを薄く、サービスを焦点を絞り、リポジトリをシンプルに、エラーは中央で処理する。保守性とテスト性のために最適化する。
