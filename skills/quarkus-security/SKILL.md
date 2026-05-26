---
name: quarkus-security
description: Quarkus Security のベストプラクティス（authentication, authorization, JWT/OIDC, RBAC, input validation, CSRF, secrets management, dependency security）。
origin: ECC
---

# Quarkus セキュリティレビュー

認証、認可、入力バリデーションで Quarkus アプリケーションを保護するベストプラクティスである。

## 起動するタイミング

- 認証を追加する場合（JWT、OIDC、Basic 認証）
- @RolesAllowed または SecurityIdentity による認可の実装
- ユーザー入力のバリデーション（Bean Validation、カスタムバリデータ）
- CORS またはセキュリティヘッダーの設定
- シークレット管理（Vault、環境変数、設定ソース）
- レート制限やブルートフォース対策の追加
- CVE のための依存関係スキャン
- MicroProfile JWT または SmallRye JWT の利用

## 認証

### JWT 認証

```java
// Resource protected with JWT
@Path("/api/protected")
@Authenticated
public class ProtectedResource {
  
  @Inject
  JsonWebToken jwt;

  @Inject
  SecurityIdentity securityIdentity;

  @GET
  public Response getData() {
    String username = jwt.getName();
    Set<String> roles = jwt.getGroups();
    return Response.ok(Map.of(
        "username", username,
        "roles", roles,
        "principal", securityIdentity.getPrincipal().getName()
    )).build();
  }
}
```

設定（application.properties）：
```properties
mp.jwt.verify.publickey.location=publicKey.pem
mp.jwt.verify.issuer=https://auth.example.com

# OIDC
quarkus.oidc.auth-server-url=https://auth.example.com/realms/myrealm
quarkus.oidc.client-id=backend-service
quarkus.oidc.credentials.secret=${OIDC_SECRET}
```

### カスタム認証フィルタ

```java
@Provider
@Priority(Priorities.AUTHENTICATION)
public class CustomAuthFilter implements ContainerRequestFilter {
  
  @Inject
  SecurityIdentity identity;

  @Override
  public void filter(ContainerRequestContext requestContext) {
    String authHeader = requestContext.getHeaderString(HttpHeaders.AUTHORIZATION);
    
    // Reject immediately if header is absent or malformed
    if (authHeader == null || !authHeader.startsWith("Bearer ")) {
      requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED).build());
      return;
    }
    
    String token = authHeader.substring(7);
    if (!validateToken(token)) {
      requestContext.abortWith(Response.status(Response.Status.UNAUTHORIZED).build());
    }
  }

  private boolean validateToken(String token) {
    // Token validation logic
    return true;
  }
}
```

## 認可

### ロールベースアクセス制御

```java
@Path("/api/admin")
@RolesAllowed("ADMIN")
public class AdminResource {
  
  @GET
  @Path("/users")
  public List<UserDto> listUsers() {
    return userService.findAll();
  }

  @DELETE
  @Path("/users/{id}")
  @RolesAllowed({"ADMIN", "SUPER_ADMIN"})
  public Response deleteUser(@PathParam("id") Long id) {
    userService.delete(id);
    return Response.noContent().build();
  }
}

@Path("/api/users")
public class UserResource {
  
  @Inject
  SecurityIdentity securityIdentity;

  @GET
  @Path("/{id}")
  @RolesAllowed("USER")
  public Response getUser(@PathParam("id") Long id) {
    // Check ownership
    if (!securityIdentity.hasRole("ADMIN") && 
        !isOwner(id, securityIdentity.getPrincipal().getName())) {
      return Response.status(Response.Status.FORBIDDEN).build();
    }
    return Response.ok(userService.findById(id)).build();
  }

  private boolean isOwner(Long userId, String username) {
    return userService.isOwner(userId, username);
  }
}
```

### プログラマティックなセキュリティ

```java
@ApplicationScoped
public class SecurityService {
  
  @Inject
  SecurityIdentity securityIdentity;

  public boolean canAccessResource(Long resourceId) {
    if (securityIdentity.isAnonymous()) {
      return false;
    }
    
    if (securityIdentity.hasRole("ADMIN")) {
      return true;
    }

    String userId = securityIdentity.getPrincipal().getName();
    return resourceRepository.isOwner(resourceId, userId);
  }
}
```

## 入力バリデーション

### Bean Validation

```java
// BAD: No validation
@POST
public Response createUser(UserDto dto) {
  return Response.ok(userService.create(dto)).build();
}

// GOOD: Validated DTO
public record CreateUserDto(
    @NotBlank @Size(max = 100) String name,
    @NotBlank @Email String email,
    @NotNull @Min(18) @Max(150) Integer age,
    @Pattern(regexp = "^\\+?[1-9]\\d{1,14}$") String phone
) {}

@POST
@Path("/users")
public Response createUser(@Valid CreateUserDto dto) {
  User user = userService.create(dto);
  return Response.status(Response.Status.CREATED).entity(user).build();
}
```

### カスタムバリデータ

```java
@Target({ElementType.FIELD, ElementType.PARAMETER})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = UsernameValidator.class)
public @interface ValidUsername {
  String message() default "Invalid username format";
  Class<?>[] groups() default {};
  Class<? extends Payload>[] payload() default {};
}

public class UsernameValidator implements ConstraintValidator<ValidUsername, String> {
  @Override
  public boolean isValid(String value, ConstraintValidatorContext context) {
    if (value == null) return false;
    return value.matches("^[a-zA-Z0-9_-]{3,20}$");
  }
}

// Usage
public record CreateUserDto(
    @ValidUsername String username,
    @NotBlank @Email String email
) {}
```

## SQL インジェクション防止

### Panache Active Record（既定で安全）

```java
// GOOD: Parameterized queries with Panache
List<User> users = User.list("email = ?1 and active = ?2", email, true);

Optional<User> user = User.find("username", username).firstResultOptional();

// GOOD: Named parameters
List<User> users = User.list("email = :email and age > :minAge", 
    Parameters.with("email", email).and("minAge", 18));
```

### ネイティブクエリ（パラメータを使用）

```java
// BAD: String concatenation
@Query(value = "SELECT * FROM users WHERE name = '" + name + "'", nativeQuery = true)

// GOOD: Parameterized native query
@Entity
public class User extends PanacheEntity {
  public static List<User> findByEmailNative(String email) {
    return getEntityManager()
        .createNativeQuery("SELECT * FROM users WHERE email = :email", User.class)
        .setParameter("email", email)
        .getResultList();
  }
}
```

## パスワードハッシュ化

```java
@ApplicationScoped
public class PasswordService {
  
  public String hash(String plainPassword) {
    return BcryptUtil.bcryptHash(plainPassword);
  }

  public boolean verify(String plainPassword, String hashedPassword) {
    return BcryptUtil.matches(plainPassword, hashedPassword);
  }
}

// In service
@ApplicationScoped
public class UserService {
  @Inject
  PasswordService passwordService;

  @Transactional
  public User register(CreateUserDto dto) {
    String hashedPassword = passwordService.hash(dto.password());
    User user = new User();
    user.email = dto.email();
    user.password = hashedPassword;
    user.persist();
    return user;
  }

  public boolean authenticate(String email, String password) {
    return User.find("email", email)
        .firstResultOptional()
        .map(u -> passwordService.verify(password, u.password))
        .orElse(false);
  }
}
```

## CORS 設定

```properties
# application.properties
quarkus.http.cors=true
quarkus.http.cors.origins=https://app.example.com,https://admin.example.com
quarkus.http.cors.methods=GET,POST,PUT,DELETE
quarkus.http.cors.headers=accept,authorization,content-type,x-requested-with
quarkus.http.cors.exposed-headers=Content-Disposition
quarkus.http.cors.access-control-max-age=24H
quarkus.http.cors.access-control-allow-credentials=true
```

## シークレット管理

```properties
# application.properties - NO SECRETS HERE

# Use environment variables
quarkus.datasource.username=${DB_USER}
quarkus.datasource.password=${DB_PASSWORD}
quarkus.oidc.credentials.secret=${OIDC_CLIENT_SECRET}

# Or use Vault
quarkus.vault.url=https://vault.example.com
quarkus.vault.authentication.kubernetes.role=my-role
```

### HashiCorp Vault 統合

```java
@ApplicationScoped
public class SecretService {
  
  @ConfigProperty(name = "api-key")
  String apiKey; // Fetched from Vault

  public String getSecret(String key) {
    return ConfigProvider.getConfig().getValue(key, String.class);
  }
}
```

## レート制限

**セキュリティ注意**：`X-Forwarded-For` を直接使ってはならない。クライアントが偽装できる。
サーブレットリクエストからの実際のリモートアドレス、または利用可能な場合は
認証済みアイデンティティ（API キー、JWT subject）を使用する。

```java
@ApplicationScoped
public class RateLimitFilter implements ContainerRequestFilter {
  private final Map<String, RateLimiter> limiters = new ConcurrentHashMap<>();

  @Inject
  HttpServletRequest servletRequest;

  @Override
  public void filter(ContainerRequestContext requestContext) {
    String clientId = getClientIdentifier();
    RateLimiter limiter = limiters.computeIfAbsent(clientId, 
        k -> RateLimiter.create(100.0)); // 100 requests per second

    if (!limiter.tryAcquire()) {
      requestContext.abortWith(
          Response.status(429)
              .entity(Map.of("error", "Too many requests"))
              .build()
      );
    }
  }

  private String getClientIdentifier() {
    // Use the container-provided remote address (not X-Forwarded-For).
    // If behind a trusted proxy, configure quarkus.http.proxy.proxy-address-forwarding=true
    // so getRemoteAddr() returns the real client IP.
    return servletRequest.getRemoteAddr();
  }
}
```

## セキュリティヘッダー

```java
@Provider
public class SecurityHeadersFilter implements ContainerResponseFilter {
  
  @Override
  public void filter(ContainerRequestContext request, ContainerResponseContext response) {
    MultivaluedMap<String, Object> headers = response.getHeaders();
    
    // Prevent clickjacking
    headers.putSingle("X-Frame-Options", "DENY");
    
    // XSS protection
    headers.putSingle("X-Content-Type-Options", "nosniff");
    headers.putSingle("X-XSS-Protection", "1; mode=block");
    
    // HSTS
    headers.putSingle("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
    
    // CSP — avoid 'unsafe-inline' for script-src as it negates XSS protection;
    // use nonces or hashes instead. 'unsafe-inline' for style-src is acceptable
    // when CSS frameworks require it, but prefer nonces where possible.
    headers.putSingle("Content-Security-Policy", 
        "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'");
  }
}
```

## 監査ログ

```java
@ApplicationScoped
public class AuditService {
  private static final Logger LOG = Logger.getLogger(AuditService.class);

  @Inject
  SecurityIdentity securityIdentity;

  public void logAccess(String resource, String action) {
    String user = securityIdentity.isAnonymous() 
        ? "anonymous" 
        : securityIdentity.getPrincipal().getName();
    
    LOG.infof("AUDIT: user=%s action=%s resource=%s timestamp=%s", 
        user, action, resource, Instant.now());
  }
}

// Usage in resource
@Path("/api/sensitive")
public class SensitiveResource {
  @Inject
  AuditService auditService;

  @GET
  @RolesAllowed("ADMIN")
  public Response getData() {
    auditService.logAccess("sensitive-data", "READ");
    return Response.ok(data).build();
  }
}
```

## 依存関係のセキュリティスキャン

```bash
# Maven
mvn org.owasp:dependency-check-maven:check

# Gradle
./gradlew dependencyCheckAnalyze

# Check Quarkus extensions
quarkus extension list --installable
```

## ベストプラクティス

- 本番では常に HTTPS を使用する
- ステートレス認証には JWT または OIDC を有効化する
- 宣言的認可には `@RolesAllowed` を使用する
- すべての入力を Bean Validation でバリデーションする
- パスワードは BCrypt でハッシュ化する（平文は不可）
- シークレットは Vault または環境変数に保存する
- SQL インジェクション防止のためパラメータ化クエリを使用する
- すべてのレスポンスにセキュリティヘッダーを追加する
- 公開エンドポイントにレート制限を実装する
- 機密操作を監査する
- 依存関係を最新に保ち CVE をスキャンする
- プログラマティックチェックには SecurityIdentity を使用する
- 適切な CORS ポリシーを設定する
- 認証および認可パスをテストする
