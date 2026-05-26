---
name: jpa-patterns
description: Spring Boot におけるエンティティ設計、リレーション、クエリ最適化、トランザクション、監査、インデックス、ページネーション、プーリングのための JPA/Hibernate パターン (JPA/Hibernate patterns for entity design, relationships, query optimization, transactions, auditing, indexing, pagination, pooling in Spring Boot)。
origin: ECC
---

# JPA/Hibernate パターン

Spring Boot におけるデータモデリング、リポジトリ、パフォーマンスチューニングのために使用する。

## 起動するタイミング

- JPA エンティティとテーブルマッピングを設計する場合
- リレーション(@OneToMany、@ManyToOne、@ManyToMany)を定義する場合
- クエリを最適化する場合(N+1 防止、フェッチ戦略、プロジェクション)
- トランザクション、監査、論理削除を設定する場合
- ページネーション、ソート、カスタムリポジトリメソッドをセットアップする場合
- コネクションプール(HikariCP)や 2 次キャッシュをチューニングする場合

## エンティティ設計

```java
@Entity
@Table(name = "markets", indexes = {
  @Index(name = "idx_markets_slug", columnList = "slug", unique = true)
})
@EntityListeners(AuditingEntityListener.class)
public class MarketEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, length = 200)
  private String name;

  @Column(nullable = false, unique = true, length = 120)
  private String slug;

  @Enumerated(EnumType.STRING)
  private MarketStatus status = MarketStatus.ACTIVE;

  @CreatedDate private Instant createdAt;
  @LastModifiedDate private Instant updatedAt;
}
```

監査を有効化する。
```java
@Configuration
@EnableJpaAuditing
class JpaConfig {}
```

## リレーションと N+1 防止

```java
@OneToMany(mappedBy = "market", cascade = CascadeType.ALL, orphanRemoval = true)
private List<PositionEntity> positions = new ArrayList<>();
```

- デフォルトで遅延ロードとし、必要に応じてクエリ内で `JOIN FETCH` を使用する
- コレクションに対する `EAGER` は避ける。読み取りパスには DTO プロジェクションを使用する

```java
@Query("select m from MarketEntity m left join fetch m.positions where m.id = :id")
Optional<MarketEntity> findWithPositions(@Param("id") Long id);
```

## リポジトリパターン

```java
public interface MarketRepository extends JpaRepository<MarketEntity, Long> {
  Optional<MarketEntity> findBySlug(String slug);

  @Query("select m from MarketEntity m where m.status = :status")
  Page<MarketEntity> findByStatus(@Param("status") MarketStatus status, Pageable pageable);
}
```

- 軽量クエリにはプロジェクションを使用する。
```java
public interface MarketSummary {
  Long getId();
  String getName();
  MarketStatus getStatus();
}
Page<MarketSummary> findAllBy(Pageable pageable);
```

## トランザクション

- サービスメソッドに `@Transactional` を付与する
- 読み取りパスでは最適化のために `@Transactional(readOnly = true)` を使用する
- 伝播は慎重に選択し、長時間実行するトランザクションを避ける

```java
@Transactional
public Market updateStatus(Long id, MarketStatus status) {
  MarketEntity entity = repo.findById(id)
      .orElseThrow(() -> new EntityNotFoundException("Market"));
  entity.setStatus(status);
  return Market.from(entity);
}
```

## ページネーション

```java
PageRequest page = PageRequest.of(pageNumber, pageSize, Sort.by("createdAt").descending());
Page<MarketEntity> markets = repo.findByStatus(MarketStatus.ACTIVE, page);
```

カーソル風のページネーションには、JPQL に並び順とともに `id > :lastId` を含める。

## インデックスとパフォーマンス

- よく使うフィルタ(`status`、`slug`、外部キー)にインデックスを追加する
- クエリパターンに合う複合インデックスを使用する(`status, created_at`)
- `select *` を避け、必要なカラムのみを射影する
- 書き込みは `saveAll` と `hibernate.jdbc.batch_size` でバッチ化する

## コネクションプール (HikariCP)

推奨プロパティ:
```
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=30000
spring.datasource.hikari.validation-timeout=5000
```

PostgreSQL の LOB 処理には以下を追加する。
```
spring.jpa.properties.hibernate.jdbc.lob.non_contextual_creation=true
```

## キャッシュ

- 1 次キャッシュは EntityManager ごと。トランザクション間でエンティティを保持しない
- 読み取り集中型エンティティには 2 次キャッシュを慎重に検討し、エビクション戦略を検証する

## マイグレーション

- Flyway または Liquibase を使用する。本番では Hibernate 自動 DDL に依存しない
- マイグレーションは冪等かつ追加的に保ち、計画なしのカラム削除を避ける

## データアクセスのテスト

- 本番を模倣するために `@DataJpaTest` と Testcontainers を優先する
- SQL の効率をログでアサートする。`logging.level.org.hibernate.SQL=DEBUG` を設定し、パラメータ値には `logging.level.org.hibernate.orm.jdbc.bind=TRACE` を設定する

**注意**: エンティティは無駄なく、クエリは意図的に、トランザクションは短く保つこと。フェッチ戦略とプロジェクションで N+1 を防ぎ、読み書きパスに合わせてインデックスを張ること。
