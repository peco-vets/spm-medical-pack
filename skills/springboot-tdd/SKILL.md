---
name: springboot-tdd
description: JUnit 5、Mockito、MockMvc、Testcontainers、JaCoCo を使用した Spring Boot のテスト駆動開発（test-driven development for Spring Boot using JUnit 5, Mockito, MockMvc, Testcontainers, JaCoCo）。機能追加、バグ修正、リファクタリング時に使用する。
origin: ECC
---

# Spring Boot TDD ワークフロー

80% 以上のカバレッジ（ユニット + 統合）の Spring Boot サービス向け TDD ガイダンス。

## 使用するタイミング

- 新機能またはエンドポイント
- バグ修正またはリファクタ
- データアクセスロジックまたはセキュリティルールの追加

## ワークフロー

1) テストを先に書く（失敗するはず）
2) 通過させる最小限のコードを実装する
3) テストがグリーンのままリファクタする
4) カバレッジを強制（JaCoCo）

## ユニットテスト（JUnit 5 + Mockito）

```java
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository repo;
  @InjectMocks MarketService service;

  @Test
  void createsMarket() {
    CreateMarketRequest req = new CreateMarketRequest("name", "desc", Instant.now(), List.of("cat"));
    when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Market result = service.create(req);

    assertThat(result.name()).isEqualTo("name");
    verify(repo).save(any());
  }
}
```

パターン：
- Arrange-Act-Assert
- 部分モックを避ける、明示的スタブを推奨
- バリアントには `@ParameterizedTest` を使う

## Web レイヤテスト（MockMvc）

```java
@WebMvcTest(MarketController.class)
class MarketControllerTest {
  @Autowired MockMvc mockMvc;
  @MockBean MarketService marketService;

  @Test
  void returnsMarkets() throws Exception {
    when(marketService.list(any())).thenReturn(Page.empty());

    mockMvc.perform(get("/api/markets"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.content").isArray());
  }
}
```

## 統合テスト（SpringBootTest）

```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MarketIntegrationTest {
  @Autowired MockMvc mockMvc;

  @Test
  void createsMarket() throws Exception {
    mockMvc.perform(post("/api/markets")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {"name":"Test","description":"Desc","endDate":"2030-01-01T00:00:00Z","categories":["general"]}
        """))
      .andExpect(status().isCreated());
  }
}
```

## 永続化テスト（DataJpaTest）

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestContainersConfig.class)
class MarketRepositoryTest {
  @Autowired MarketRepository repo;

  @Test
  void savesAndFinds() {
    MarketEntity entity = new MarketEntity();
    entity.setName("Test");
    repo.save(entity);

    Optional<MarketEntity> found = repo.findByName("Test");
    assertThat(found).isPresent();
  }
}
```

## Testcontainers

- 本番をミラーするために Postgres/Redis に再利用可能なコンテナを使用
- Spring コンテキストに JDBC URL を注入するため `@DynamicPropertySource` でワイヤリング

## カバレッジ（JaCoCo）

Maven スニペット：
```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.14</version>
  <executions>
    <execution>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>report</id>
      <phase>verify</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

## アサーション

- 読みやすさのため AssertJ（`assertThat`）を推奨
- JSON レスポンスには `jsonPath` を使う
- 例外には `assertThatThrownBy(...)` を使う

## テストデータビルダー

```java
class MarketBuilder {
  private String name = "Test";
  MarketBuilder withName(String name) { this.name = name; return this; }
  Market build() { return new Market(null, name, MarketStatus.ACTIVE); }
}
```

## CI コマンド

- Maven：`mvn -T 4 test` または `mvn verify`
- Gradle：`./gradlew test jacocoTestReport`

**覚えておくこと**：テストを高速、独立、決定的に保つ。実装詳細ではなく振る舞いをテストする。
