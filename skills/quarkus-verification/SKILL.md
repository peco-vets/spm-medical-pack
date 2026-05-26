---
name: quarkus-verification
description: "Quarkus プロジェクトの検証ループ（verification loop: build, static analysis, tests with coverage, security scans, native compilation, diff review）。リリースまたは PR の前に実行する。"
origin: ECC
---

# Quarkus 検証ループ

PR 前、主要変更後、デプロイ前に実行する。

## 起動するタイミング

- Quarkus サービスの PR を開く前
- 主要なリファクタリングや依存関係アップグレード後
- ステージングまたは本番のデプロイ前検証
- フルビルド → リント → テスト → セキュリティスキャン → ネイティブコンパイルパイプラインの実行
- テストカバレッジが閾値（80%+）を満たすことの検証
- ネイティブイメージ互換性のテスト

## フェーズ 1：ビルド

```bash
# Maven
mvn clean verify -DskipTests

# Gradle
./gradlew clean assemble -x test
```

ビルドに失敗したら停止してコンパイルエラーを修正する。

## フェーズ 2：静的解析

### Checkstyle・PMD・SpotBugs（Maven）

```bash
mvn checkstyle:check pmd:check spotbugs:check
```

### SonarQube（設定済みの場合）

```bash
mvn sonar:sonar \
  -Dsonar.projectKey=my-quarkus-project \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=${SONAR_TOKEN}
```

### よくある対処すべき問題

- 未使用のインポートや変数
- 複雑なメソッド（高い循環的複雑度）
- 潜在的な null ポインター参照
- SpotBugs がフラグするセキュリティ問題

## フェーズ 3：テスト + カバレッジ

```bash
# Run all tests
mvn clean test

# Generate coverage report
mvn jacoco:report

# Enforce coverage threshold (80%)
mvn jacoco:check

# Or with Gradle
./gradlew test jacocoTestReport jacocoTestCoverageVerification
```

### テストカテゴリ

#### ユニットテスト
モック依存でサービスロジックをテストする：

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
  @Mock UserRepository userRepository;
  @InjectMocks UserService userService;

  @Test
  void createUser_validInput_returnsUser() {
    var dto = new CreateUserDto("Alice", "alice@example.com");

    // Panache persist() is void — use doNothing + verify
    doNothing().when(userRepository).persist(any(User.class));

    User result = userService.create(dto);

    assertThat(result.name).isEqualTo("Alice");
    verify(userRepository).persist(any(User.class));
  }
}
```

#### 統合テスト
実 DB（Testcontainers）でテストする：

```java
@QuarkusTest
@QuarkusTestResource(PostgresTestResource.class)
class UserRepositoryIntegrationTest {

  @Inject
  UserRepository userRepository;

  @Test
  @Transactional
  void findByEmail_existingUser_returnsUser() {
    User user = new User();
    user.name = "Alice";
    user.email = "alice@example.com";
    userRepository.persist(user);

    Optional<User> found = userRepository.findByEmail("alice@example.com");

    assertThat(found).isPresent();
    assertThat(found.get().name).isEqualTo("Alice");
  }
}
```

#### API テスト
REST Assured で REST エンドポイントをテストする：

```java
@QuarkusTest
class UserResourceTest {

  @Test
  void createUser_validInput_returns201() {
    given()
        .contentType(ContentType.JSON)
        .body("""
            {"name": "Alice", "email": "alice@example.com"}
            """)
        .when().post("/api/users")
        .then()
        .statusCode(201)
        .body("name", equalTo("Alice"));
  }

  @Test
  void createUser_invalidEmail_returns400() {
    given()
        .contentType(ContentType.JSON)
        .body("""
            {"name": "Alice", "email": "invalid"}
            """)
        .when().post("/api/users")
        .then()
        .statusCode(400);
  }
}
```

### カバレッジレポート

詳細なカバレッジは `target/site/jacoco/index.html` を確認する：
- 全体の行カバレッジ（目標：80%+）
- 分岐カバレッジ（目標：70%+）
- カバーされていないクリティカルパスを特定する

## フェーズ 4：セキュリティスキャン

### 依存関係の脆弱性（Maven）

```bash
mvn org.owasp:dependency-check-maven:check
```

CVE は `target/dependency-check-report.html` でレビューする。

### Quarkus セキュリティ監査

```bash
# Check vulnerable extensions
mvn quarkus:audit

# List all extensions
mvn quarkus:list-extensions
```

### OWASP ZAP（API セキュリティテスト）

```bash
docker run -t owasp/zap2docker-stable zap-api-scan.py \
  -t http://localhost:8080/q/openapi \
  -f openapi
```

### 共通セキュリティチェック

- [ ] すべてのシークレットが環境変数にある（コード内ではない）
- [ ] すべてのエンドポイントで入力バリデーション
- [ ] 認証／認可が設定されている
- [ ] CORS が適切に設定されている
- [ ] セキュリティヘッダーが設定されている
- [ ] パスワードが BCrypt でハッシュ化されている
- [ ] SQL インジェクション保護（パラメータ化クエリ）
- [ ] 公開エンドポイントにレート制限

## フェーズ 5：ネイティブコンパイル

GraalVM ネイティブイメージ互換性をテストする：

```bash
# Build native executable
mvn package -Dnative

# Or with container
mvn package -Dnative -Dquarkus.native.container-build=true

# Test native executable
./target/*-runner

# Run basic smoke tests
curl http://localhost:8080/q/health/live
curl http://localhost:8080/q/health/ready
```

### ネイティブイメージのトラブルシューティング

よくある問題：
- **リフレクション**：動的クラスにリフレクション設定を追加する
- **リソース**：`quarkus.native.resources.includes` でリソースを含める
- **JNI**：ネイティブライブラリ使用時に JNI クラスを登録する

リフレクション設定の例：
```java
@RegisterForReflection(targets = {MyDynamicClass.class})
public class ReflectionConfiguration {}
```

## フェーズ 6：パフォーマンステスト

### K6 による負荷テスト

```javascript
// load-test.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '1m', target: 100 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  const res = http.get('http://localhost:8080/api/markets');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
  });
}
```

実行：
```bash
k6 run load-test.js
```

### モニタリング対象メトリック

- レスポンスタイム（p50、p95、p99）
- スループット（リクエスト/秒）
- エラー率
- メモリ使用量
- CPU 使用率

## フェーズ 7：ヘルスチェック

```bash
# Liveness
curl http://localhost:8080/q/health/live

# Readiness
curl http://localhost:8080/q/health/ready

# All health checks
curl http://localhost:8080/q/health

# Metrics (if enabled)
curl http://localhost:8080/q/metrics
```

期待されるレスポンス：
```json
{
  "status": "UP",
  "checks": [
    {
      "name": "Database connection",
      "status": "UP"
    }
  ]
}
```

## フェーズ 8：コンテナイメージビルド

```bash
# Build container image
mvn package -Dquarkus.container-image.build=true

# Or with specific registry
mvn package \
  -Dquarkus.container-image.build=true \
  -Dquarkus.container-image.registry=docker.io \
  -Dquarkus.container-image.group=myorg \
  -Dquarkus.container-image.tag=1.0.0

# Test container
docker run -p 8080:8080 myorg/my-quarkus-app:1.0.0
```

### コンテナセキュリティスキャン

```bash
# Trivy
trivy image myorg/my-quarkus-app:1.0.0

# Grype
grype myorg/my-quarkus-app:1.0.0
```

## フェーズ 9：設定バリデーション

```bash
# Check all configuration properties
mvn quarkus:info

# List all config sources
curl http://localhost:8080/q/dev/io.quarkus.quarkus-vertx-http/config
```

### 環境固有のチェック

- [ ] データベース URL が環境ごとに設定されている
- [ ] シークレットが外出しされている（Vault、環境変数）
- [ ] ロギングレベルが適切
- [ ] CORS オリジンが正しく設定されている
- [ ] レート制限が設定されている
- [ ] モニタリング／トレースが有効

## フェーズ 10：ドキュメントレビュー

- [ ] OpenAPI/Swagger ドキュメントが最新（`/q/swagger-ui`）
- [ ] README にセットアップ手順がある
- [ ] API 変更が文書化されている
- [ ] 破壊的変更の移行ガイド
- [ ] 設定プロパティが文書化されている

OpenAPI スペックの生成：
```bash
curl http://localhost:8080/q/openapi -o openapi.json
```

## 検証チェックリスト

### コード品質
- [ ] 警告なしでビルドが通る
- [ ] 静的解析がクリーン（高／中レベルの問題なし）
- [ ] コードがチーム規約に従う
- [ ] PR にコメントアウトされたコードや TODO がない

### テスト
- [ ] すべてのテストが通る
- [ ] コードカバレッジ ≥ 80%
- [ ] 実 DB での統合テスト
- [ ] セキュリティテストが通る
- [ ] パフォーマンスが許容範囲内

### セキュリティ
- [ ] 依存関係の脆弱性なし
- [ ] 認証／認可がテスト済み
- [ ] 入力バリデーションが完全
- [ ] シークレットがソースコード内にない
- [ ] セキュリティヘッダーが設定されている

### デプロイ
- [ ] ネイティブコンパイルが成功
- [ ] コンテナイメージがビルドされる
- [ ] ヘルスチェックが正しく応答する
- [ ] 対象環境向けの設定が有効

### ネイティブイメージ
- [ ] ネイティブ実行ファイルがビルドされる
- [ ] ネイティブテストが通る
- [ ] 起動時間 < 100ms
- [ ] メモリフットプリントが許容範囲

## 検証自動化スクリプト

```bash
#!/bin/bash
set -e

echo "=== Phase 1: Build ==="
mvn clean verify -DskipTests

echo "=== Phase 2: Static Analysis ==="
mvn checkstyle:check pmd:check spotbugs:check

echo "=== Phase 3: Tests + Coverage ==="
mvn test jacoco:report jacoco:check

echo "=== Phase 4: Security Scan ==="
mvn org.owasp:dependency-check-maven:check

echo "=== Phase 5: Native Compilation ==="
mvn package -Dnative -Dquarkus.native.container-build=true

echo "=== All Phases Complete ==="
echo "Review reports:"
echo "  - Coverage: target/site/jacoco/index.html"
echo "  - Security: target/dependency-check-report.html"
echo "  - Native: target/*-runner"
```

## CI/CD 統合

### GitHub Actions の例

```yaml
name: Verification

on: [push, pull_request]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK 21
        uses: actions/setup-java@v3
        with:
          java-version: '21'
          distribution: 'temurin'
      
      - name: Cache Maven packages
        uses: actions/cache@v3
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
      
      - name: Build
        run: mvn clean verify -DskipTests
      
      - name: Test with Coverage
        run: mvn test jacoco:report jacoco:check
      
      - name: Security Scan
        run: mvn org.owasp:dependency-check-maven:check
      
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          files: target/site/jacoco/jacoco.xml
```

## ベストプラクティス

- すべての PR の前に検証ループを実行する
- CI/CD パイプラインで自動化する
- 問題は直ちに修正する。負債を蓄積しない
- カバレッジを 80% 以上に維持する
- 依存関係を定期的に更新する
- ネイティブコンパイルを定期的にテストする
- パフォーマンストレンドを監視する
- 破壊的変更を文書化する
- セキュリティスキャン結果をレビューする
- 各環境の設定を検証する
