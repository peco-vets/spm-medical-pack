---
name: flox-environments
description: "Nix の上に構築された宣言的環境マネージャ Flox で、再現可能・クロスプラットフォームな開発環境を作成する（Flox, reproducible environments, cross-platform, dev environments）。次のような場合に必ずこのスキルを使う: システムレベル依存（コンパイラ、DB、openssl・libvips・BLAS・LAPACK 等のネイティブライブラリ）が必要なプロジェクトのセットアップ、Python・Node.js・Rust・Go・C/C++・Java・Ruby・Elixir・PHP 等のツールチェーン構成、macOS と Linux で同一動作する環境の管理、チーム向け正確なパッケージバージョン固定、開発ツールと並走するローカルサービス（PostgreSQL・Redis・Kafka）起動、ワンコマンドでの新規開発者オンボーディング、'works on my machine' 問題解決。AI 支援・vibe coding に特に有用 — Flox は sudo・システム汚染・サンドボックス制約なしにプロジェクトスコープ環境へエージェントがツールを導入できる、その結果環境はリポジトリにコミットされ即座に再現可能になる。ユーザーが Flox に言及しない場合でも、宣言的・再現可能・クロスプラットフォームでシステムパッケージを伴う開発環境が必要だと述べていれば本スキルが正解である。.flox/、manifest.toml、flox activate、FloxHub 等への言及があった場合も使う。"
origin: Flox
---

# Flox 環境

Flox は単一の TOML マニフェストで定義される再現可能な開発環境を作成する。チーム全員が macOS・Linux 横断で同一パッケージ・ツール・構成を取得でき、コンテナや VM を必要としない。Nix の上に構築されており、15万以上のパッケージにアクセス可能である。

## 起動タイミング

ユーザーが Flox に言及していなくても、環境管理問題を抱えているときに用いる。Flox が適切なのは以下の場合である。

- 言語固有依存とともに**システムレベルパッケージ**（コンパイラ・DB・CLI ツール）が必要
- **再現性が重要** — チームメンバーのマシン・CI・新規ラップトップで同一に動くべき
- **複数ツールの共存**が必要 — 例: Python 3.11 + PostgreSQL 16 + Redis + Node.js を1環境に
- **クロスプラットフォームサポート**が必要（同一設定で macOS と Linux）
- **AI エージェントによるツール導入** — Flox は sudo・システム汚染・サンドボックス制約なしにエージェントがプロジェクトスコープ環境へパッケージを追加できる

ユーザーが単一言語ランタイムをシステム依存なしに必要とするだけなら、標準ツール（nvm、pyenv、rustup 単体）で足りる場合がある。完全な OS レベル隔離が必要ならコンテナが適切な場合がある。Flox はその中間に位置する: コンテナのオーバーヘッドなしに宣言的・再現可能な環境を提供する。

**前提:** Flox を先にインストールする必要がある — macOS・Linux・Docker は [flox.dev/docs](https://flox.dev/docs/install-flox/install/) を参照。

## 中核コンセプト

Flox 環境は `.flox/env/manifest.toml` に定義され、`flox activate` で起動される。マニフェストはパッケージ・環境変数・セットアップフック・シェル設定を宣言する。これだけで環境はどこでも再現可能である。

**主要パス:**
- `.flox/env/manifest.toml` — 環境定義（commit する）
- `$FLOX_ENV` — インストール済みパッケージのランタイムパス（`/usr` 相当、`bin/`・`lib/`・`include/` を含む）
- `$FLOX_ENV_CACHE` — キャッシュ・venv・データ用の永続ローカルストレージ（再ビルドで残存）
- `$FLOX_ENV_PROJECT` — プロジェクトルート（`.flox/` を含むディレクトリ）

## 必須コマンド

```bash
flox init                       # Create new environment
flox search <package> [--all]   # Search for packages
flox show <package>             # Show available versions
flox install <package>          # Add a package
flox list                       # List installed packages
flox activate                   # Enter environment
flox activate -- <cmd>          # Run a command in the environment without a subshell
flox edit                       # Edit manifest interactively
```

## マニフェスト構造

```toml
# .flox/env/manifest.toml

[install]
# Packages to install — the core of the environment
ripgrep.pkg-path = "ripgrep"
jq.pkg-path = "jq"

[vars]
# Static environment variables
DATABASE_URL = "postgres://localhost:5432/myapp"

[hook]
# Non-interactive setup scripts (run every activation)
on-activate = """
  echo "Environment ready"
"""

[profile]
# Shell functions and aliases (available in interactive shell)
common = """
  alias dev="npm run dev"
"""

[options]
# Supported platforms
systems = ["x86_64-linux", "aarch64-linux", "x86_64-darwin", "aarch64-darwin"]
```

## パッケージインストールパターン

### 基本インストール

```toml
[install]
nodejs.pkg-path = "nodejs"
python.pkg-path = "python311"
rustup.pkg-path = "rustup"
```

### バージョン固定

```toml
[install]
nodejs.pkg-path = "nodejs"
nodejs.version = "^20.0"          # Semver range: latest 20.x

postgres.pkg-path = "postgresql"
postgres.version = "16.2"         # Exact version
```

### プラットフォーム固有パッケージ

```toml
[install]
# Linux-only tools
valgrind.pkg-path = "valgrind"
valgrind.systems = ["x86_64-linux", "aarch64-linux"]

# macOS frameworks
Security.pkg-path = "darwin.apple_sdk.frameworks.Security"
Security.systems = ["x86_64-darwin", "aarch64-darwin"]

# GNU tools on macOS (where BSD defaults differ)
coreutils.pkg-path = "coreutils"
coreutils.systems = ["x86_64-darwin", "aarch64-darwin"]
```

### パッケージ衝突の解決

2つのパッケージが同じバイナリをインストールするときは `priority`（低いほうが勝つ）を使う。

```toml
[install]
gcc.pkg-path = "gcc12"
gcc.priority = 3

clang.pkg-path = "clang_18"
clang.priority = 5               # gcc wins file conflicts
```

バージョンを一緒に解決すべきパッケージは `pkg-group` でグループ化する。

```toml
[install]
python.pkg-path = "python311"
python.pkg-group = "python-stack"

pip.pkg-path = "python311Packages.pip"
pip.pkg-group = "python-stack"    # Resolves together with python
```

## 言語別レシピ

### Python with uv

```toml
[install]
python.pkg-path = "python311"
uv.pkg-path = "uv"

[vars]
UV_CACHE_DIR = "$FLOX_ENV_CACHE/uv-cache"
PIP_CACHE_DIR = "$FLOX_ENV_CACHE/pip-cache"

[hook]
on-activate = """
  venv="$FLOX_ENV_CACHE/venv"
  if [ ! -d "$venv" ]; then
    uv venv "$venv" --python python3
  fi
  if [ -f "$venv/bin/activate" ]; then
    source "$venv/bin/activate"
  fi

  if [ -f requirements.txt ] && [ ! -f "$FLOX_ENV_CACHE/.deps_installed" ]; then
    uv pip install --python "$venv/bin/python" -r requirements.txt --quiet
    touch "$FLOX_ENV_CACHE/.deps_installed"
  fi
"""
```

### Node.js

```toml
[install]
nodejs.pkg-path = "nodejs"
nodejs.version = "^20.0"

[hook]
on-activate = """
  if [ -f package.json ] && [ ! -d node_modules ]; then
    npm install --silent
  fi
"""
```

### Rust

```toml
[install]
rustup.pkg-path = "rustup"
pkg-config.pkg-path = "pkg-config"
openssl.pkg-path = "openssl"

[vars]
RUSTUP_HOME = "$FLOX_ENV_CACHE/rustup"
CARGO_HOME = "$FLOX_ENV_CACHE/cargo"

[profile]
common = """
  export PATH="$CARGO_HOME/bin:$PATH"
"""
```

### Go

```toml
[install]
go.pkg-path = "go"
gopls.pkg-path = "gopls"
delve.pkg-path = "delve"

[vars]
GOPATH = "$FLOX_ENV_CACHE/go"
GOBIN = "$FLOX_ENV_CACHE/go/bin"

[profile]
common = """
  export PATH="$GOBIN:$PATH"
"""
```

### C/C++

```toml
[install]
gcc.pkg-path = "gcc13"
gcc.pkg-group = "compilers"

# IMPORTANT: gcc alone doesn't expose libstdc++ headers — you need gcc-unwrapped
gcc-unwrapped.pkg-path = "gcc-unwrapped"
gcc-unwrapped.pkg-group = "libraries"

cmake.pkg-path = "cmake"
cmake.pkg-group = "build"

gnumake.pkg-path = "gnumake"
gnumake.pkg-group = "build"

gdb.pkg-path = "gdb"
gdb.systems = ["x86_64-linux", "aarch64-linux"]
```

## フックとプロファイル

### フック — 非対話型セットアップ

フックは activate のたびに実行される。高速かつ冪等に保つこと。原則: **自動で起こすべきは `[hook]`、ユーザーが入力できるべきは `[profile]`**。

```toml
[hook]
on-activate = """
  setup_database() {
    if [ ! -d "$FLOX_ENV_CACHE/pgdata" ]; then
      initdb -D "$FLOX_ENV_CACHE/pgdata" --no-locale --encoding=UTF8
    fi
  }
  setup_database
"""
```

### プロファイル — 対話シェル設定

プロファイルコードはユーザーのシェルセッションで利用可能になる。

```toml
[profile]
common = """
  dev() { npm run dev; }
  test() { npm run test -- "$@"; }
"""
```

## アンチパターン

### 絶対パス

```toml
# BAD — breaks on other machines
[vars]
PROJECT_DIR = "/home/alice/projects/myapp"

# GOOD — use Flox environment variables
[vars]
PROJECT_DIR = "$FLOX_ENV_PROJECT"
```

### フック内での exit

```toml
# BAD — kills the shell
[hook]
on-activate = """
  if [ ! -f config.json ]; then
    echo "Missing config"
    exit 1
  fi
"""

# GOOD — return from hook, don't exit
[hook]
on-activate = """
  if [ ! -f config.json ]; then
    echo "Missing config — run setup first"
    return 1
  fi
"""
```

### マニフェストへのシークレット格納

```toml
# BAD — manifest is committed to git
[vars]
API_KEY = "<set-at-runtime>"

# GOOD — reference external config or pass at runtime
# Use: API_KEY="<your-api-key>" flox activate
[vars]
API_KEY = "${API_KEY:-}"
```

### 冪等ガードなしの遅いフック

```toml
# BAD — reinstalls every activation
[hook]
on-activate = """
  pip install -r requirements.txt
"""

# GOOD — skip if already installed
[hook]
on-activate = """
  if [ ! -f "$FLOX_ENV_CACHE/.deps_installed" ]; then
    uv pip install -r requirements.txt --quiet
    touch "$FLOX_ENV_CACHE/.deps_installed"
  fi
"""
```

### フック内へのユーザーコマンド配置

```toml
# BAD — hook functions aren't available in the interactive shell
[hook]
on-activate = """
  deploy() { kubectl apply -f k8s/; }
"""

# GOOD — use [profile] for user-invokable functions
[profile]
common = """
  deploy() { kubectl apply -f k8s/; }
"""
```

## フルスタック例

PostgreSQL 付き Python API の完全な環境。

```toml
[install]
python.pkg-path = "python311"
uv.pkg-path = "uv"
postgresql.pkg-path = "postgresql_16"
redis.pkg-path = "redis"
jq.pkg-path = "jq"
curl.pkg-path = "curl"

[vars]
UV_CACHE_DIR = "$FLOX_ENV_CACHE/uv-cache"
DATABASE_URL = "postgres://localhost:5432/myapp"
REDIS_URL = "redis://localhost:6379"

[hook]
on-activate = """
  if [ ! -d "$FLOX_ENV_CACHE/pgdata" ]; then
    initdb -D "$FLOX_ENV_CACHE/pgdata" --no-locale --encoding=UTF8
  fi

  venv="$FLOX_ENV_CACHE/venv"
  if [ ! -d "$venv" ]; then
    uv venv "$venv" --python python3
  fi
  if [ -f "$venv/bin/activate" ]; then
    source "$venv/bin/activate"
  fi

  if [ -f requirements.txt ] && [ ! -f "$FLOX_ENV_CACHE/.deps_installed" ]; then
    uv pip install --python "$venv/bin/python" -r requirements.txt --quiet
    touch "$FLOX_ENV_CACHE/.deps_installed"
  fi
"""

[profile]
common = """
  serve() { uvicorn app.main:app --reload --host 0.0.0.0 --port 8000; }
  migrate() { alembic upgrade head; }
"""

[services]
postgres.command = "postgres -D $FLOX_ENV_CACHE/pgdata -k $FLOX_ENV_CACHE"
redis.command = "redis-server --port 6379 --daemonize no"

[options]
systems = ["x86_64-linux", "aarch64-linux", "x86_64-darwin", "aarch64-darwin"]
```

サービス付きで起動: `flox activate --start-services`

## 環境の共有

Flox 環境は git ネイティブである。`.flox/` ディレクトリを commit すれば、コラボレータ全員が同一環境を得られる。

```bash
git add .flox/
git commit -m "Add Flox environment"
# Teammates just run:
git clone <repo> && cd <repo> && flox activate
```

プロジェクト横断で再利用可能なベース環境は FloxHub に push する。

```bash
flox push                         # Push environment to FloxHub
flox activate -r owner/env-name   # Activate remote environment anywhere
```

`[include]` で環境を合成する。

```toml
[include]
base.floxhub = "myorg/python-base"

[install]
# Project-specific additions on top of base
fastapi.pkg-path = "python311Packages.fastapi"
```

## AI 支援・vibe coding

Flox は AI 支援開発と vibe coding ワークフローに最適である。AI エージェントが現環境に未存在のツール（コンパイラ・DB・linter・CLI ユーティリティ）を必要としたとき、Flox マニフェストへ追加できる。sudo・システム汚染・サンドボックス制約は不要である。

**エージェントにとって重要な理由:**
- **sudo 不要** — `flox install` は完全にユーザー空間で動作する。昇格権限なしにエージェントがパッケージを追加できる
- **プロジェクトスコープ** — パッケージはプロジェクト環境のみにインストールされる。グローバルではない。異プロジェクトで衝突せず異なるバージョンを持てる
- **サンドボックス親和** — サンドボックスまたは制限された環境で動くエージェントでも Flox で必要ツールをインストールできる
- **可逆** — すべての変更は `manifest.toml` に記録される。不要パッケージはシステム残渣なしにクリーンに削除できる
- **再現可能** — エージェントが環境をセットアップすると、その正確な構成が git にコミットされ、全員に対して動作する

**エージェントのワークフローパターン:**

```bash
# Agent discovers it needs a tool (e.g., jq for JSON processing)
flox search jq                    # Verify the package exists
flox install jq                   # Install into project environment

# Or for more control, edit the manifest directly
tmp_manifest="$(mktemp)"
flox list -c > "$tmp_manifest"
# Add the package to [install] section, then apply
flox edit -f "$tmp_manifest"

# Run a command with the tool available
flox activate -- jq '.results[]' data.json
```

これにより Flox は、Claude Code 等の AI エージェントがオンザフライでプロジェクトツールを bootstrap する任意のワークフローに自然に適合する。

## デバッグ

```bash
flox list -c                      # Show raw manifest
flox activate -- which python     # Check which binary resolves
flox activate -- env | grep FLOX  # See Flox environment variables
flox search <package> --all       # Broader package search (case-sensitive)
```

**よくある問題:**
- **パッケージが見つからない:** 検索は大文字小文字を区別する。`flox search --all` を試す
- **パッケージ間のファイル衝突:** 勝たせたいパッケージに `priority` を追加する
- **フック失敗:** `exit` ではなく `return` を使う。`${FLOX_ENV_CACHE:-}` でガードする
- **依存パッケージの陳腐化:** `$FLOX_ENV_CACHE/.deps_installed` フラグファイルを削除する

## 関連スキル

[Flox Claude Code プラグイン](https://github.com/flox/flox-agentic)の一部として、より深い統合のため以下のスキルが利用可能である。

- **flox-services** — サービス管理、DB セットアップ、バックグラウンドプロセス
- **flox-builds** — Flox による再現可能ビルドとパッケージング
- **flox-containers** — Flox 環境から Docker/OCI コンテナを生成
- **flox-sharing** — 環境合成、リモート環境、チームパターン
- **flox-cuda** — CUDA・GPU 開発環境

詳細とインストールは [flox.dev/docs](https://flox.dev/docs/install-flox/install/) を参照。
