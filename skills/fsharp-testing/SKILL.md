---
name: fsharp-testing
description: F# テストパターン（F# testing, xUnit, FsUnit, Unquote, FsCheck, property-based testing）。xUnit、FsUnit、Unquote、FsCheck によるプロパティベーステスト、統合テスト、テスト構成のベストプラクティスを網羅する。
origin: ECC
---

# F# テストパターン

xUnit、FsUnit、Unquote、FsCheck、モダン .NET テスト慣行を用いた F# アプリケーションの包括的テストパターンである。

## 起動タイミング

- F# コードの新規テスト記述
- テスト品質とカバレッジのレビュー
- F# プロジェクトのテスト基盤セットアップ
- フレーキー・低速テストのデバッグ

## テストフレームワークスタック

| ツール | 用途 |
|---|---|
| **xUnit** | テストフレームワーク（標準 .NET エコシステム選択） |
| **FsUnit.xUnit** | xUnit 向けの F# フレンドリ assertion 構文 |
| **Unquote** | F# クォーテーションを用いた明瞭な失敗メッセージを生成する assertion ライブラリ |
| **FsCheck.xUnit** | xUnit 統合のプロパティベーステスト |
| **NSubstitute** | .NET 依存のモック |
| **Testcontainers** | 統合テストでの実インフラ |
| **WebApplicationFactory** | ASP.NET Core 統合テスト |

## xUnit + FsUnit のユニットテスト

### 基本テスト構造

```fsharp
module OrderServiceTests

open Xunit
open FsUnit.Xunit

[<Fact>]
let ``create sets status to Pending`` () =
    let order = Order.create "cust-1" [ validItem ]
    order.Status |> should equal Pending

[<Fact>]
let ``confirm changes status to Confirmed`` () =
    let order = Order.create "cust-1" [ validItem ]
    let confirmed = Order.confirm order
    confirmed.Status |> should be (ofCase <@ Confirmed @>)
```

### Unquote による Assertion

Unquote は F# クォーテーションを使うため、失敗メッセージは "expected X got Y" だけでなく失敗した式全体を表示する。

```fsharp
module OrderValidationTests

open Xunit
open Swensen.Unquote

[<Fact>]
let ``PlaceOrder returns success when request is valid`` () =
    let request = { CustomerId = "cust-123"; Items = [ validItem ] }
    let result = OrderService.placeOrder request
    test <@ Result.isOk result @>

[<Fact>]
let ``order total sums item prices`` () =
    let items = [ { Sku = "A"; Quantity = 2; Price = 10m }
                  { Sku = "B"; Quantity = 1; Price = 5m } ]
    let total = Order.calculateTotal items
    test <@ total = 25m @>

[<Fact>]
let ``validated email rejects empty input`` () =
    let result = ValidatedEmail.create ""
    test <@ Result.isError result @>
```

### 非同期テスト

```fsharp
[<Fact>]
let ``PlaceOrder returns success when request is valid`` () = task {
    let deps = createTestDeps ()
    let request = { CustomerId = "cust-123"; Items = [ validItem ] }

    let! result = OrderService.placeOrder deps request

    test <@ Result.isOk result @>
}

[<Fact>]
let ``PlaceOrder returns error when items are empty`` () = task {
    let deps = createTestDeps ()
    let request = { CustomerId = "cust-123"; Items = [] }

    let! result = OrderService.placeOrder deps request

    test <@ Result.isError result @>
}
```

### Theory によるパラメータ化テスト

```fsharp
[<Theory>]
[<InlineData("")>]
[<InlineData("   ")>]
let ``PlaceOrder rejects empty customer ID`` (customerId: string) =
    let request = { CustomerId = customerId; Items = [ validItem ] }
    let result = OrderService.placeOrder request
    result |> should be (ofCase <@ Error @>)

[<Theory>]
[<InlineData("", false)>]
[<InlineData("a", false)>]
[<InlineData("user@example.com", true)>]
[<InlineData("user+tag@example.co.uk", true)>]
let ``IsValidEmail returns expected result`` (email: string, expected: bool) =
    test <@ EmailValidator.isValid email = expected @>
```

## FsCheck によるプロパティベーステスト

### FsCheck.xUnit の利用

```fsharp
open FsCheck
open FsCheck.Xunit

[<Property>]
let ``order total is always non-negative`` (items: NonEmptyList<PositiveInt * decimal>) =
    let orderItems =
        items.Get
        |> List.map (fun (qty, price) ->
            { Sku = "SKU"; Quantity = qty.Get; Price = abs price })
    let total = Order.calculateTotal orderItems
    total >= 0m

[<Property>]
let ``serialization roundtrips`` (order: Order) =
    let json = JsonSerializer.Serialize order
    let deserialized = JsonSerializer.Deserialize<Order> json
    deserialized = order
```

### カスタムジェネレータ

```fsharp
type OrderGenerators =
    static member ValidEmail () =
        gen {
            let! user = Gen.elements [ "alice"; "bob"; "carol" ]
            let! domain = Gen.elements [ "example.com"; "test.org" ]
            return $"{user}@{domain}"
        }
        |> Arb.fromGen

[<Property(Arbitrary = [| typeof<OrderGenerators> |])>]
let ``valid emails pass validation`` (email: string) =
    EmailValidator.isValid email
```

## 依存のモック

### 関数 stub（推奨）

```fsharp
let createTestDeps () =
    let mutable savedOrders = []
    { FindOrder = fun id -> task { return Map.tryFind id testData }
      SaveOrder = fun order -> task { savedOrders <- order :: savedOrders }
      SendNotification = fun _ -> Task.CompletedTask }

[<Fact>]
let ``PlaceOrder saves the confirmed order`` () = task {
    let mutable saved = []
    let deps =
        { createTestDeps () with
            SaveOrder = fun order -> task { saved <- order :: saved } }

    let! _ = OrderService.placeOrder deps validRequest

    test <@ saved.Length = 1 @>
}
```

### .NET インターフェース向け NSubstitute

```fsharp
open NSubstitute

[<Fact>]
let ``calls repository with correct ID`` () = task {
    let repo = Substitute.For<IOrderRepository>()
    repo.FindByIdAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>())
        .Returns(Task.FromResult(Some testOrder))

    let service = OrderService(repo)
    let! _ = service.GetOrder(testOrder.Id, CancellationToken.None)

    do! repo.Received(1).FindByIdAsync(testOrder.Id, Arg.Any<CancellationToken>())
}
```

## ASP.NET Core 統合テスト

```fsharp
type OrderApiTests (factory: WebApplicationFactory<Program>) =
    interface IClassFixture<WebApplicationFactory<Program>>

    let client =
        factory.WithWebHostBuilder(fun builder ->
            builder.ConfigureServices(fun services ->
                services.RemoveAll<DbContextOptions<AppDbContext>>() |> ignore
                services.AddDbContext<AppDbContext>(fun options ->
                    options.UseInMemoryDatabase("TestDb") |> ignore) |> ignore))
            .CreateClient()

    [<Fact>]
    member _.``GET order returns 404 when not found`` () = task {
        let! response = client.GetAsync($"/api/orders/{Guid.NewGuid()}")
        test <@ response.StatusCode = HttpStatusCode.NotFound @>
    }
```

## テスト構成

```
tests/
  MyApp.Tests/
    Unit/
      OrderServiceTests.fs
      PaymentServiceTests.fs
    Integration/
      OrderApiTests.fs
      OrderRepositoryTests.fs
    Properties/
      OrderPropertyTests.fs
    Helpers/
      TestData.fs
      TestDeps.fs
```

## 一般的なアンチパターン

| アンチパターン | 修正 |
|---|---|
| 実装詳細のテスト | 振る舞いと結果をテストする |
| 可変共有テスト state | テストごとに新規 state |
| 非同期テストでの `Thread.Sleep` | タイムアウト付き `Task.Delay` またはポーリングヘルパー |
| `sprintf` 出力への assertion | 型付き値とパターンマッチに assertion |
| `CancellationToken` 無視 | 必ず渡しキャンセルを検証 |
| プロパティベーステストのスキップ | 明確な不変量を持つ関数には FsCheck を使う |

## 関連スキル

- `dotnet-patterns` — 慣用的 .NET パターン・DI・アーキテクチャ
- `csharp-testing` — C# テストパターン（WebApplicationFactory・Testcontainers 等の共通基盤は F# にも適用）

## テスト実行

```bash
# Run all tests
dotnet test

# Run with coverage
dotnet test --collect:"XPlat Code Coverage"

# Run specific project
dotnet test tests/MyApp.Tests/

# Filter by test name
dotnet test --filter "FullyQualifiedName~OrderService"

# Watch mode during development
dotnet watch test --project tests/MyApp.Tests/
```
