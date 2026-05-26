---
name: windows-desktop-e2e
description: pywinauto と Windows UI Automation を使用した Windows ネイティブデスクトップアプリ（WPF、WinForms、Win32/MFC、Qt）の E2E テスト（E2E testing for Windows native desktop apps）。
origin: ECC
---

# Windows デスクトップ E2E テスト

**pywinauto** を Windows UI Automation（UIA）でバックして Windows ネイティブデスクトップアプリケーションのエンドツーエンドテスト。WPF、WinForms、Win32/MFC、Qt（5.x / 6.x）をカバー — 専用セクションとしての Qt 固有ガイダンス。

## 起動するタイミング

- Windows ネイティブデスクトップアプリケーションの E2E テストの記述または実行
- ゼロからデスクトップ GUI テストスイートをセットアップ
- フレーキーまたは失敗するデスクトップ自動化テストの診断
- 既存アプリに（AutomationId、アクセシブル名）テスト可能性を追加
- デスクトップ E2E を CI/CD パイプラインに統合（GitHub Actions `windows-latest`）

### 使用しないタイミング

- Web アプリケーション → `e2e-testing` スキルを使う（Playwright）
- Electron / CEF / WebView2 アプリ → HTML レイヤは UIA ではなくブラウザ自動化が必要
- モバイルアプリ → プラットフォーム固有ツールを使う（UIAutomator、XCUITest）
- 実行中の GUI を必要としない純粋なユニットまたは統合テスト

## コアコンセプト

すべての Windows デスクトップ自動化は **UI Automation（UIA）** に依存する。Windows 組み込みアクセシビリティ API。すべてのサポートフレームワークが Claude が読み込み、アクションできるプロパティを持つ UIA 要素のツリーを公開する：

```
Your test (Python)
    └── pywinauto (UIA backend)
        └── Windows UI Automation API   ← built into Windows, framework-agnostic
            └── App's UIA provider      ← each framework ships its own
                └── Running .exe
```

**フレームワーク別の UIA 品質：**

| フレームワーク | AutomationId | 信頼性 | 注 |
|-----------|-------------|-------------|-------|
| WPF | ★★★★★ | 優秀 | `x:Name` は AutomationId に直接マッピング |
| WinForms | ★★★★☆ | 良 | `AccessibleName` = AutomationId |
| UWP / WinUI 3 | ★★★★★ | 優秀 | 完全な Microsoft サポート |
| Qt 6.x | ★★★★★ | 優秀 | アクセシビリティはデフォルトで有効、クラス名は `Qt6*` に変更 |
| Qt 5.15+ | ★★★★☆ | 良 | 改善された Accessibility モジュール |
| Qt 5.7–5.14 | ★★★☆☆ | 普通 | `QT_ACCESSIBILITY=1` が必要、objectName は手動 |
| Win32 / MFC | ★★★☆☆ | 普通 | コントロール ID がアクセス可能、テキストマッチング一般的 |

## セットアップと前提条件

```bash
# Python 3.8+, Windows only
pip install pywinauto pytest pytest-html Pillow pytest-timeout
# Optional: screen recording
# Install ffmpeg and add to PATH: https://ffmpeg.org/download.html
```

UIA が到達可能か検証：

```python
from pywinauto import Desktop
Desktop(backend="uia").windows()  # lists all top-level windows
```

**Accessibility Insights for Windows**（無料、Microsoft から）をインストール — テストを書く前に UIA 要素ツリーを検査する DevTools 同等。

## テスト可能性セットアップ（フレームワーク別）

できる最もインパクトのあることは、テストを書く前に**すべての対話的コントロールに安定した AutomationId を与える**こと。

### WPF

```xml
<!-- XAML: x:Name becomes AutomationId automatically -->
<TextBox x:Name="usernameInput" />
<PasswordBox x:Name="passwordInput" />
<Button x:Name="btnLogin" Content="Login" />
<TextBlock x:Name="lblError" />
```

### WinForms

```csharp
// Set in designer or code
usernameInput.AccessibleName = "usernameInput";
passwordInput.AccessibleName = "passwordInput";
btnLogin.AccessibleName = "btnLogin";
lblError.AccessibleName = "lblError";
```

### Win32 / MFC

```cpp
// Control resource IDs in .rc file are exposed as AutomationId strings
// IDC_EDIT_USERNAME -> AutomationId "1001"
// Prefer SetWindowText for Name; add IAccessible for richer support
```

### Qt — 以下の専用セクションを参照

---

## ページオブジェクトモデル

```
tests/
├── conftest.py          # app launch fixture, failure screenshot
├── pytest.ini
├── config.py
├── pages/
│   ├── __init__.py      # required for imports
│   ├── base_page.py     # locators, wait, screenshot helpers
│   ├── login_page.py
│   └── main_page.py
├── tests/
│   ├── __init__.py
│   ├── test_login.py
│   └── test_main_flow.py
└── artifacts/           # screenshots, videos, logs
```

ファイル構造、コードサンプル、Tier 1/2/3 サンドボックス、Qt 固有のクイック、CI 統合、アンチパターンを含む完全なコードサンプルは元の英文を参照（コードブロックはそのまま）。

完全な実装はオリジナルセクションテキストを参照する。重要点：

- AutomationId > Name > ClassName + index > XPath の優先順位ロケータ戦略
- `time.sleep()` ではなく `wait_visible` / `wait_until`
- 状態リークを避けるため `function` スコープのフレッシュアプリプロセス
- アクセシビリティを発動するため Qt 5.x の `QT_ACCESSIBILITY=1`
- DPI スケーリング感受性のあるスクリーンショット マッチング — テンプレートを同じスケールでキャプチャ
- 自動再起動の防止用に Tier 1 サンドボックスフィクスチャ（フィルシステム分離）、Tier 2（ジョブオブジェクト）、Tier 3（Windows Sandbox）

## 関連スキル

- `e2e-testing` — Web アプリケーション用 Playwright E2E
- `cpp-testing` — GoogleTest による C++ ユニット／統合テスト
- `cpp-coding-standards` — C++ コードスタイルとパターン
