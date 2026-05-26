---
name: springboot-security
description: Java Spring Boot サービスでの認証／認可、バリデーション、CSRF、シークレット、ヘッダ、レート制限、依存関係セキュリティのための Spring Security ベストプラクティス（Spring Security: authn/authz, validation, CSRF, secrets, headers, rate limiting）。
origin: ECC
---

# Spring Boot セキュリティレビュー

認証の追加、入力処理、エンドポイント作成、シークレット処理時に使う。

## 起動するタイミング

- 認証の追加（JWT、OAuth2、セッションベース）
- 認可の実装（@PreAuthorize、ロールベースアクセス）
- ユーザー入力のバリデーション（Bean Validation、カスタムバリデータ）
- CORS、CSRF、セキュリティヘッダの設定
- シークレット管理（Vault、環境変数）
- レート制限またはブルートフォース対策の追加
- CVE のための依存関係スキャン

## 認証

- ステートレス JWT または失効リスト付き opaque トークンを推奨
- セッションには `httpOnly`、`Secure`、`SameSite=Strict` Cookie を使う
- `OncePerRequestFilter` またはリソースサーバでトークンを検証する

```java
@Component
public class JwtAuthFilter extends OncePerRequestFilter {
  private final JwtService jwtService;

  public JwtAuthFilter(JwtService jwtService) {
    this.jwtService = jwtService;
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain chain) throws ServletException, IOException {
    String header = request.getHeader(HttpHeaders.AUTHORIZATION);
    if (header != null && header.startsWith("Bearer ")) {
      String token = header.substring(7);
      Authentication auth = jwtService.authenticate(token);
      SecurityContextHolder.getContext().setAuthentication(auth);
    }
    chain.doFilter(request, response);
  }
}
```

## 認可

- メソッドセキュリティを有効化：`@EnableMethodSecurity`
- `@PreAuthorize("hasRole('ADMIN')")` または `@PreAuthorize("@authz.canEdit(#id)")` を使う
- デフォルトで拒否、必要なスコープのみ公開

```java
@RestController
@RequestMapping("/api/admin")
public class AdminController {

  @PreAuthorize("hasRole('ADMIN')")
  @GetMapping("/users")
  public List<UserDto> listUsers() {
    return userService.findAll();
  }

  @PreAuthorize("@authz.isOwner(#id, authentication)")
  @DeleteMapping("/users/{id}")
  public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
    userService.delete(id);
    return ResponseEntity.noContent().build();
  }
}
```

## 入力バリデーション

- コントローラで Bean Validation を `@Valid` で使う
- DTO に制約を適用：`@NotBlank`、`@Email`、`@Size`、カスタムバリデータ
- レンダリング前にホワイトリストで HTML をサニタイズする

```java
// BAD: No validation
@PostMapping("/users")
public User createUser(@RequestBody UserDto dto) {
  return userService.create(dto);
}

// GOOD: Validated DTO
public record CreateUserDto(
    @NotBlank @Size(max = 100) String name,
    @NotBlank @Email String email,
    @NotNull @Min(0) @Max(150) Integer age
) {}

@PostMapping("/users")
public ResponseEntity<UserDto> createUser(@Valid @RequestBody CreateUserDto dto) {
  return ResponseEntity.status(HttpStatus.CREATED)
      .body(userService.create(dto));
}
```

## SQL インジェクション防止

- Spring Data リポジトリまたはパラメータ化クエリを使う
- ネイティブクエリには `:param` バインディングを使い、決して文字列連結しない

```java
// BAD: String concatenation in native query
@Query(value = "SELECT * FROM users WHERE name = '" + name + "'", nativeQuery = true)

// GOOD: Parameterized native query
@Query(value = "SELECT * FROM users WHERE name = :name", nativeQuery = true)
List<User> findByName(@Param("name") String name);

// GOOD: Spring Data derived query (auto-parameterized)
List<User> findByEmailAndActiveTrue(String email);
```

## パスワードエンコーディング

- パスワードは常に BCrypt または Argon2 でハッシュ化 — 平文で保存しない
- 手動ハッシュではなく `PasswordEncoder` Bean を使う

```java
@Bean
public PasswordEncoder passwordEncoder() {
  return new BCryptPasswordEncoder(12); // cost factor 12
}

// In service
public User register(CreateUserDto dto) {
  String hashedPassword = passwordEncoder.encode(dto.password());
  return userRepository.save(new User(dto.email(), hashedPassword));
}
```

## CSRF 保護

- ブラウザセッションアプリは CSRF を有効に保ち、フォーム／ヘッダにトークンを含める
- Bearer トークンを使う純 API は CSRF を無効化し、ステートレス認証に依存する

```java
http
  .csrf(csrf -> csrf.disable())
  .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS));
```

## シークレット管理

- ソースにシークレットなし、環境または Vault から読み込む
- `application.yml` をクレデンシャルから解放、プレースホルダを使う
- トークンと DB クレデンシャルを定期的にローテーション

```yaml
# BAD: Hardcoded in application.yml
spring:
  datasource:
    password: mySecretPassword123

# GOOD: Environment variable placeholder
spring:
  datasource:
    password: ${DB_PASSWORD}

# GOOD: Spring Cloud Vault integration
spring:
  cloud:
    vault:
      uri: https://vault.example.com
      token: ${VAULT_TOKEN}
```

## セキュリティヘッダ

```java
http
  .headers(headers -> headers
    .contentSecurityPolicy(csp -> csp
      .policyDirectives("default-src 'self'"))
    .frameOptions(HeadersConfigurer.FrameOptionsConfig::sameOrigin)
    .xssProtection(Customizer.withDefaults())
    .referrerPolicy(rp -> rp.policy(ReferrerPolicyHeaderWriter.ReferrerPolicy.NO_REFERRER)));
```

## CORS 設定

- セキュリティフィルタレベルで CORS を設定し、コントローラごとには設定しない
- 許可された origin を制限 — 本番で `*` を使わない

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
  CorsConfiguration config = new CorsConfiguration();
  config.setAllowedOrigins(List.of("https://app.example.com"));
  config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE"));
  config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
  config.setAllowCredentials(true);
  config.setMaxAge(3600L);

  UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
  source.registerCorsConfiguration("/api/**", config);
  return source;
}

// In SecurityFilterChain:
http.cors(cors -> cors.configurationSource(corsConfigurationSource()));
```

## レート制限

- 高価なエンドポイントに Bucket4j またはゲートウェイレベルの制限を適用する
- バーストでログとアラート、リトライヒント付きで 429 を返す

```java
// Using Bucket4j for per-endpoint rate limiting
@Component
public class RateLimitFilter extends OncePerRequestFilter {
  private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

  private Bucket createBucket() {
    return Bucket.builder()
        .addLimit(Bandwidth.classic(100, Refill.intervally(100, Duration.ofMinutes(1))))
        .build();
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
      FilterChain chain) throws ServletException, IOException {
    String clientIp = request.getRemoteAddr();
    Bucket bucket = buckets.computeIfAbsent(clientIp, k -> createBucket());

    if (bucket.tryConsume(1)) {
      chain.doFilter(request, response);
    } else {
      response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
      response.getWriter().write("{\"error\": \"Rate limit exceeded\"}");
    }
  }
}
```

## 依存関係セキュリティ

- CI で OWASP Dependency Check / Snyk を実行
- Spring Boot と Spring Security をサポートされているバージョンに保つ
- 既知の CVE でビルドを失敗させる

## ロギングと PII

- シークレット、トークン、パスワード、完全な PAN データを決してログしない
- センシティブフィールドを編集、構造化 JSON ロギングを使う

## ファイルアップロード

- サイズ、コンテンツタイプ、拡張子を検証する
- Web ルート外に保存、必要に応じてスキャン

## リリース前チェックリスト

- [ ] 認証トークンが正しく検証され期限切れになる
- [ ] すべての機密パスに認可ガード
- [ ] すべての入力が検証・サニタイズされている
- [ ] 文字列連結 SQL なし
- [ ] アプリタイプに正しい CSRF 姿勢
- [ ] シークレットが外出しされている、コミットなし
- [ ] セキュリティヘッダが設定されている
- [ ] API にレート制限
- [ ] 依存関係がスキャン済み、最新
- [ ] ログにセンシティブデータなし

**覚えておくこと**：デフォルトで拒否、入力を検証、最小権限、設定によるセキュリティを優先。
