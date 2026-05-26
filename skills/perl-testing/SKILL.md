---
name: perl-testing
description: Test2::V0、Test::More、prove ランナー、モッキング、Devel::Cover によるカバレッジ、TDD 手法を使った Perl テストパターン (Perl testing patterns using Test2::V0, Test::More, prove runner, mocking, coverage with Devel::Cover, TDD methodology)。
origin: ECC
---

# Perl テストパターン

Test2::V0、Test::More、prove、TDD 手法を使った Perl アプリケーション向けの包括的テスト戦略。

## 起動するタイミング

- 新しい Perl コードの記述 (TDD に従う: red、green、refactor)
- Perl モジュールやアプリケーションのテストスイート設計
- Perl テストカバレッジのレビュー
- Perl テストインフラストラクチャのセットアップ
- Test::More から Test2::V0 へのテスト移行
- 失敗する Perl テストのデバッグ

## TDD ワークフロー

常に RED-GREEN-REFACTOR サイクルに従う。

```perl
# Step 1: RED — Write a failing test
# t/unit/calculator.t
use v5.36;
use Test2::V0;

use lib 'lib';
use Calculator;

subtest 'addition' => sub {
    my $calc = Calculator->new;
    is($calc->add(2, 3), 5, 'adds two numbers');
    is($calc->add(-1, 1), 0, 'handles negatives');
};

done_testing;

# Step 2: GREEN — Write minimal implementation
# lib/Calculator.pm
package Calculator;
use v5.36;
use Moo;

sub add($self, $a, $b) {
    return $a + $b;
}

1;

# Step 3: REFACTOR — Improve while tests stay green
# Run: prove -lv t/unit/calculator.t
```

## Test::More の基本

標準 Perl テストモジュール — 広く使われ、コアに付属。

### 基本アサーション

```perl
use v5.36;
use Test::More;

# Plan upfront or use done_testing
# plan tests => 5;  # Fixed plan (optional)

# Equality
is($result, 42, 'returns correct value');
isnt($result, 0, 'not zero');

# Boolean
ok($user->is_active, 'user is active');
ok(!$user->is_banned, 'user is not banned');

# Deep comparison
is_deeply(
    $got,
    { name => 'Alice', roles => ['admin'] },
    'returns expected structure'
);

# Pattern matching
like($error, qr/not found/i, 'error mentions not found');
unlike($output, qr/password/, 'output hides password');

# Type check
isa_ok($obj, 'MyApp::User');
can_ok($obj, 'save', 'delete');

done_testing;
```

### SKIP と TODO

```perl
use v5.36;
use Test::More;

# Skip tests conditionally
SKIP: {
    skip 'No database configured', 2 unless $ENV{TEST_DB};

    my $db = connect_db();
    ok($db->ping, 'database is reachable');
    is($db->version, '15', 'correct PostgreSQL version');
}

# Mark expected failures
TODO: {
    local $TODO = 'Caching not yet implemented';
    is($cache->get('key'), 'value', 'cache returns value');
}

done_testing;
```

## Test2::V0 現代的フレームワーク

Test2::V0 は Test::More の現代的置き換えである — より豊富なアサーション、より良い診断、拡張可能。

### Test2 を使う理由

- ハッシュ/配列ビルダーによる優れた深い比較
- 失敗時のより良い診断出力
- よりクリーンなスコープを持つサブテスト
- Test2::Tools::* プラグイン経由で拡張可能
- Test::More テストとの後方互換

### ビルダーによる深い比較

```perl
use v5.36;
use Test2::V0;

# Hash builder — check partial structure
is(
    $user->to_hash,
    hash {
        field name  => 'Alice';
        field email => match(qr/\@example\.com$/);
        field age   => validator(sub { $_ >= 18 });
        # Ignore other fields
        etc();
    },
    'user has expected fields'
);

# Array builder
is(
    $result,
    array {
        item 'first';
        item match(qr/^second/);
        item DNE();  # Does Not Exist — verify no extra items
    },
    'result matches expected list'
);

# Bag — order-independent comparison
is(
    $tags,
    bag {
        item 'perl';
        item 'testing';
        item 'tdd';
    },
    'has all required tags regardless of order'
);
```

### サブテスト

```perl
use v5.36;
use Test2::V0;

subtest 'User creation' => sub {
    my $user = User->new(name => 'Alice', email => 'alice@example.com');
    ok($user, 'user object created');
    is($user->name, 'Alice', 'name is set');
    is($user->email, 'alice@example.com', 'email is set');
};

subtest 'User validation' => sub {
    my $warnings = warns {
        User->new(name => '', email => 'bad');
    };
    ok($warnings, 'warns on invalid data');
};

done_testing;
```

### Test2 による例外テスト

```perl
use v5.36;
use Test2::V0;

# Test that code dies
like(
    dies { divide(10, 0) },
    qr/Division by zero/,
    'dies on division by zero'
);

# Test that code lives
ok(lives { divide(10, 2) }, 'division succeeds') or note($@);

# Combined pattern
subtest 'error handling' => sub {
    ok(lives { parse_config('valid.json') }, 'valid config parses');
    like(
        dies { parse_config('missing.json') },
        qr/Cannot open/,
        'missing file dies with message'
    );
};

done_testing;
```

## テスト組織と prove

### ディレクトリ構造

```text
t/
├── 00-load.t              # Verify modules compile
├── 01-basic.t             # Core functionality
├── unit/
│   ├── config.t           # Unit tests by module
│   ├── user.t
│   └── util.t
├── integration/
│   ├── database.t
│   └── api.t
├── lib/
│   └── TestHelper.pm      # Shared test utilities
└── fixtures/
    ├── config.json        # Test data files
    └── users.csv
```

### prove コマンド

```bash
# Run all tests
prove -l t/

# Verbose output
prove -lv t/

# Run specific test
prove -lv t/unit/user.t

# Recursive search
prove -lr t/

# Parallel execution (8 jobs)
prove -lr -j8 t/

# Run only failing tests from last run
prove -l --state=failed t/

# Colored output with timer
prove -l --color --timer t/

# TAP output for CI
prove -l --formatter TAP::Formatter::JUnit t/ > results.xml
```

### .proverc 設定

```text
-l
--color
--timer
-r
-j4
--state=save
```

## フィクスチャとセットアップ/ティアダウン

### サブテスト分離

```perl
use v5.36;
use Test2::V0;
use File::Temp qw(tempdir);
use Path::Tiny;

subtest 'file processing' => sub {
    # Setup
    my $dir = tempdir(CLEANUP => 1);
    my $file = path($dir, 'input.txt');
    $file->spew_utf8("line1\nline2\nline3\n");

    # Test
    my $result = process_file("$file");
    is($result->{line_count}, 3, 'counts lines');

    # Teardown happens automatically (CLEANUP => 1)
};
```

### 共有テストヘルパー

`t/lib/TestHelper.pm` に再利用可能ヘルパーを配置し、`use lib 't/lib'` でロード。`Exporter` 経由で `create_test_db()`、`create_temp_dir()`、`fixture_path()` などのファクトリ関数をエクスポートする。

## モッキング

### Test::MockModule

```perl
use v5.36;
use Test2::V0;
use Test::MockModule;

subtest 'mock external API' => sub {
    my $mock = Test::MockModule->new('MyApp::API');

    # Good: Mock returns controlled data
    $mock->mock(fetch_user => sub ($self, $id) {
        return { id => $id, name => 'Mock User', email => 'mock@test.com' };
    });

    my $api = MyApp::API->new;
    my $user = $api->fetch_user(42);
    is($user->{name}, 'Mock User', 'returns mocked user');

    # Verify call count
    my $call_count = 0;
    $mock->mock(fetch_user => sub { $call_count++; return {} });
    $api->fetch_user(1);
    $api->fetch_user(2);
    is($call_count, 2, 'fetch_user called twice');

    # Mock is automatically restored when $mock goes out of scope
};

# Bad: Monkey-patching without restoration
# *MyApp::API::fetch_user = sub { ... };  # NEVER — leaks across tests
```

軽量モックオブジェクトには、`Test::MockObject` を使い `->mock()` で注入可能なテストダブルを作成し、`->called_ok()` で呼び出しを検証する。

## Devel::Cover によるカバレッジ

### カバレッジの実行

```bash
# Basic coverage report
cover -test

# Or step by step
perl -MDevel::Cover -Ilib t/unit/user.t
cover

# HTML report
cover -report html
open cover_db/coverage.html

# Specific thresholds
cover -test -report text | grep 'Total'

# CI-friendly: fail under threshold
cover -test && cover -report text -select '^lib/' \
  | perl -ne 'if (/Total.*?(\d+\.\d+)/) { exit 1 if $1 < 80 }'
```

### 統合テスト

データベーステストにはインメモリ SQLite を使い、API テストには HTTP::Tiny をモックする。

```perl
use v5.36;
use Test2::V0;
use DBI;

subtest 'database integration' => sub {
    my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
        RaiseError => 1,
    });
    $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');

    $dbh->prepare('INSERT INTO users (name) VALUES (?)')->execute('Alice');
    my $row = $dbh->selectrow_hashref('SELECT * FROM users WHERE name = ?', undef, 'Alice');
    is($row->{name}, 'Alice', 'inserted and retrieved user');
};

done_testing;
```

## ベストプラクティス

### DO

- **TDD に従う**: 実装前にテストを書く (red-green-refactor)
- **Test2::V0 を使う**: 現代的アサーション、より良い診断
- **サブテストを使う**: 関連アサーションをグループ化、状態を分離
- **外部依存関係をモック**: ネットワーク、データベース、ファイルシステム
- **`prove -l` を使う**: 常に lib/ を `@INC` に含める
- **テストに明確に名前を付ける**: `'user login with invalid password fails'`
- **エッジケースをテスト**: 空文字列、undef、ゼロ、境界値
- **80% 以上のカバレッジを目指す**: ビジネスロジックパスに焦点
- **テストを高速に保つ**: I/O をモック、インメモリデータベースを使う

### DON'T

- **実装をテストしない**: 内部ではなく振る舞いと出力をテスト
- **サブテスト間で状態を共有しない**: 各サブテストは独立すべき
- **`done_testing` をスキップしない**: すべての計画されたテストが実行されたことを保証
- **過度にモックしない**: 境界のみをモックし、テスト対象コードはモックしない
- **新規プロジェクトで `Test::More` を使わない**: Test2::V0 を優先
- **テスト失敗を無視しない**: マージ前にすべてのテストが通る必要がある
- **CPAN モジュールをテストしない**: ライブラリが正しく動作することを信頼
- **脆いテストを書かない**: 過度に具体的な文字列マッチングを避ける

## クイックリファレンス

| タスク | コマンド / パターン |
|---|---|
| すべてのテストを実行 | `prove -lr t/` |
| 1 つのテストを詳細に実行 | `prove -lv t/unit/user.t` |
| 並列テスト実行 | `prove -lr -j8 t/` |
| カバレッジレポート | `cover -test && cover -report html` |
| 等価性テスト | `is($got, $expected, 'label')` |
| 深い比較 | `is($got, hash { field k => 'v'; etc() }, 'label')` |
| 例外テスト | `like(dies { ... }, qr/msg/, 'label')` |
| 例外なしテスト | `ok(lives { ... }, 'label')` |
| メソッドモック | `Test::MockModule->new('Pkg')->mock(m => sub { ... })` |
| テストスキップ | `SKIP: { skip 'reason', $count unless $cond; ... }` |
| TODO テスト | `TODO: { local $TODO = 'reason'; ... }` |

## 一般的な落とし穴

### `done_testing` を忘れる

```perl
# Bad: Test file runs but doesn't verify all tests executed
use Test2::V0;
is(1, 1, 'works');
# Missing done_testing — silent bugs if test code is skipped

# Good: Always end with done_testing
use Test2::V0;
is(1, 1, 'works');
done_testing;
```

### `-l` フラグの欠落

```bash
# Bad: Modules in lib/ not found
prove t/unit/user.t
# Can't locate MyApp/User.pm in @INC

# Good: Include lib/ in @INC
prove -l t/unit/user.t
```

### 過剰モック

*依存関係*をモックし、テスト対象コードをモックしない。テストがモックが返すよう指示したものを返すことのみを検証する場合、それは何もテストしていない。

### テスト汚染

サブテスト内では `my` 変数を使う — `our` ではない — テスト間で状態が漏れることを防ぐ。

**注意**: テストは安全網である。高速、フォーカス、独立に保つ。新規プロジェクトには Test2::V0、実行には prove、説明責任には Devel::Cover を使う。
