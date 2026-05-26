---
name: cpp-coding-standards
description: C++ Core Guidelines (isocpp.github.io) に基づく C++ コーディング標準。モダンで安全で慣用的な実践を強制するために、C++ コードを書く、レビューする、またはリファクタリングするときに使う (C++ coding standards, C++ Core Guidelines, RAII, immutability, type safety, modern C++)。
origin: ECC
---

# C++ コーディング標準 (C++ Core Guidelines)

[C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines) から派生したモダン C++ (C++17/20/23) のための包括的なコーディング標準。型安全性、リソース安全性、不変性、明確性を強制する。

## 利用するタイミング

- 新しい C++ コード (クラス、関数、テンプレート) の作成
- 既存の C++ コードのレビューやリファクタリング
- C++ プロジェクトでアーキテクチャ判断を行う
- C++ コードベース全体で一貫したスタイルを強制
- 言語機能の選択 (例: `enum` vs `enum class`、生ポインタ vs スマートポインタ)

### 利用しないタイミング

- 非 C++ プロジェクト
- モダン C++ 機能を採用できないレガシー C コードベース
- 特定のガイドラインがハードウェア制約と矛盾する組み込み/ベアメタルコンテキスト (選択的に適応)

## 横断的原則

これらのテーマはガイドライン全体で繰り返し現れ、基盤を形成する:

1. **どこでも RAII** (P.8、R.1、E.6、CP.20): リソースライフタイムをオブジェクトライフタイムに束縛
2. **デフォルトで不変** (P.10、Con.1-5、ES.25): `const`/`constexpr` から始める。可変性は例外
3. **型安全性** (P.4、I.4、ES.46-49、Enum.3): コンパイル時にエラーを防ぐために型システムを使う
4. **意図を表現** (P.3、F.1、NL.1-2、T.10): 名前、型、コンセプトは目的を伝えるべき
5. **複雑さを最小化** (F.2-3、ES.5、Per.4-5): シンプルなコードは正しいコード
6. **値セマンティクス対ポインタセマンティクス** (C.10、R.3-5、F.20、CP.31): 値による返却とスコープオブジェクトを優先

## 哲学とインターフェース (P.*, I.*)

### 主要ルール

| ルール | 要約 |
|------|---------|
| **P.1** | アイデアを直接コードで表現 |
| **P.3** | 意図を表現 |
| **P.4** | 理想的にはプログラムは静的に型安全であるべき |
| **P.5** | ランタイムチェックよりコンパイル時チェックを優先 |
| **P.8** | リソースをリークしない |
| **P.10** | 可変データより不変データを優先 |
| **I.1** | インターフェースを明示的にする |
| **I.2** | 非 const グローバル変数を避ける |
| **I.4** | インターフェースを正確に強く型付けする |
| **I.11** | 生ポインタや参照で所有権を転送しない |
| **I.23** | 関数引数の数を低く保つ |

(原文 C++ コード例とすべてのセクションは技術用語のため英語のまま保持)

### DO

```cpp
// P.10 + I.4: Immutable, strongly typed interface
struct Temperature {
    double kelvin;
};

Temperature boil(const Temperature& water);
```

### DON'T

```cpp
// Weak interface: unclear ownership, unclear units
double boil(double* temp);

// Non-const global variable
int g_counter = 0;  // I.2 violation
```

## 関数 (F.*)

### 主要ルール

| ルール | 要約 |
|------|---------|
| **F.1** | 意味ある操作を慎重に命名された関数としてパッケージ化 |
| **F.2** | 関数は単一の論理操作を実行すべき |
| **F.3** | 関数を短くシンプルに保つ |
| **F.4** | コンパイル時評価可能なら `constexpr` を宣言 |
| **F.6** | スローしないなら `noexcept` を宣言 |
| **F.8** | 純粋関数を優先 |
| **F.16** | 「入力」パラメータは安価コピー型は値で、その他は `const&` で渡す |
| **F.20** | 「出力」値は出力パラメータより返値を優先 |
| **F.21** | 複数の「出力」値はストラクトを返す |
| **F.43** | ローカルオブジェクトへのポインタや参照を返さない |

### パラメータ渡し

```cpp
// F.16: Cheap types by value, others by const&
void print(int x);                           // cheap: by value
void analyze(const std::string& data);       // expensive: by const&
void transform(std::string s);               // sink: by value (will move)

// F.20 + F.21: Return values, not output parameters
struct ParseResult {
    std::string token;
    int position;
};

ParseResult parse(std::string_view input);   // GOOD: return struct

// BAD: output parameters
void parse(std::string_view input,
           std::string& token, int& pos);    // avoid this
```

### 純粋関数と constexpr

```cpp
// F.4 + F.8: Pure, constexpr where possible
constexpr int factorial(int n) noexcept {
    return (n <= 1) ? 1 : n * factorial(n - 1);
}

static_assert(factorial(5) == 120);
```

### アンチパターン

- 関数から `T&&` を返す (F.45)
- `va_arg` / C スタイル可変引数を使う (F.55)
- 他スレッドに渡されるラムダで参照キャプチャ (F.53)
- ムーブセマンティクスを阻害する `const T` を返す (F.49)

## クラスとクラス階層 (C.*)

主要ルールとパターン (Rule of Zero、Rule of Five、Virtual destructor 等) は原文を参照。コード例は英語のまま保持。

(残りの長大なセクション C.*・R.*・ES.*・E.*・Con.*・CP.*・T.*・SL.*・Enum.*・SF.*・NL.*・Per.* は原文の英語コードと参照を保持する。各ルールテーブルの要約のみ和訳)

## クイックリファレンスチェックリスト

C++ 作業を完了とマークする前に:

- [ ] 生 `new`/`delete` なし — スマートポインタや RAII を使う (R.11)
- [ ] オブジェクトを宣言時に初期化 (ES.20)
- [ ] 変数はデフォルトで `const`/`constexpr` (Con.1、ES.25)
- [ ] 可能な場所でメンバ関数を `const` に (Con.2)
- [ ] プレーン `enum` ではなく `enum class` (Enum.3)
- [ ] `0`/`NULL` ではなく `nullptr` (ES.47)
- [ ] 縮小変換なし (ES.46)
- [ ] C スタイルキャストなし (ES.48)
- [ ] 単一引数コンストラクタは `explicit` (C.46)
- [ ] Rule of Zero または Rule of Five を適用 (C.20、C.21)
- [ ] 基底クラスデストラクタは public virtual または protected non-virtual (C.35)
- [ ] テンプレートはコンセプトで制約 (T.10)
- [ ] ヘッダのグローバルスコープで `using namespace` なし (SF.7)
- [ ] ヘッダはインクルードガード付きで自己完結 (SF.8、SF.11)
- [ ] ロックは RAII (`scoped_lock`/`lock_guard`) を使う (CP.20)
- [ ] 例外はカスタム型、値でスロー、参照でキャッチ (E.14、E.15)
- [ ] `std::endl` ではなく `'\n'` (SL.io.50)
- [ ] マジックナンバーなし (ES.45)

(本スキルの完全なルール詳細、コード例、すべての C++ Core Guidelines セクションについては原版を参照されたい。)
