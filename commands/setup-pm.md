---
description: 好みのパッケージマネージャ（npm/pnpm/yarn/bun）を設定する / Configure your preferred package manager (npm/pnpm/yarn/bun)
disable-model-invocation: true
---

# Package Manager Setup

このプロジェクトまたはグローバルに、好みのパッケージマネージャを設定する。

## Usage

```bash
# Detect current package manager
node scripts/setup-package-manager.js --detect

# Set global preference
node scripts/setup-package-manager.js --global pnpm

# Set project preference
node scripts/setup-package-manager.js --project bun

# List available package managers
node scripts/setup-package-manager.js --list
```

## 検出優先順位

どのパッケージマネージャを使うかを決定する際、以下の順序で確認される：

1. **環境変数**：`CLAUDE_PACKAGE_MANAGER`
2. **プロジェクト設定**：`.claude/package-manager.json`
3. **package.json**：`packageManager` フィールド
4. **Lock ファイル**：package-lock.json、yarn.lock、pnpm-lock.yaml、または bun.lockb の存在
5. **グローバル設定**：`~/.claude/package-manager.json`
6. **フォールバック**：最初に利用可能なパッケージマネージャ（pnpm > bun > yarn > npm）

## 設定ファイル

### グローバル設定
```json
// ~/.claude/package-manager.json
{
  "packageManager": "pnpm"
}
```

### プロジェクト設定
```json
// .claude/package-manager.json
{
  "packageManager": "bun"
}
```

### package.json
```json
{
  "packageManager": "pnpm@8.6.0"
}
```

## 環境変数

他のすべての検出方法を上書きするために `CLAUDE_PACKAGE_MANAGER` を設定する：

```bash
# Windows (PowerShell)
$env:CLAUDE_PACKAGE_MANAGER = "pnpm"

# macOS/Linux
export CLAUDE_PACKAGE_MANAGER=pnpm
```

## 検出を実行する

現在のパッケージマネージャ検出結果を見るには、実行する：

```bash
node scripts/setup-package-manager.js --detect
```
