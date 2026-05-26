---
name: safety-guard
description: 本番システムでの作業時やエージェントを自律実行する際に、破壊的操作を防ぐためにこのスキルを使用する（prevent destructive operations on production or in autonomous agent mode）。
origin: ECC
---

# Safety Guard — 破壊的操作を防止

## 使用するタイミング

- 本番システムで作業しているとき
- エージェントが自律実行（フルオートモード）しているとき
- 編集を特定ディレクトリに制限したいとき
- センシティブ操作中（マイグレーション、デプロイ、データ変更）

## 動作の仕組み

3 つの保護モード：

### モード 1：Careful モード

破壊的コマンドを実行前にインターセプトし警告する：

```
監視対象パターン：
- rm -rf（特に /、~、プロジェクトルート）
- git push --force
- git reset --hard
- git checkout .（すべての変更を破棄）
- DROP TABLE / DROP DATABASE
- docker system prune
- kubectl delete
- chmod 777
- sudo rm
- npm publish（誤公開）
- --no-verify 付きの任意のコマンド
```

検出時：コマンドの動作を表示し、確認を求め、より安全な代替案を提案する。

### モード 2：Freeze モード

ファイル編集を特定のディレクトリツリーにロックする：

```
/safety-guard freeze src/components/
```

`src/components/` 外への Write/Edit は説明付きでブロックされる。エージェントに無関係なコードを触らせずに 1 つの領域に集中させたいときに有用。

### モード 3：Guard モード（Careful + Freeze 統合）

両方の保護がアクティブ。自律エージェントに最大の安全性。

```
/safety-guard guard --dir src/api/ --allow-read-all
```

エージェントは何でも読めるが `src/api/` にのみ書き込める。破壊的コマンドはどこでもブロックされる。

### アンロック

```
/safety-guard off
```

## 実装

PreToolUse フックを使って Bash、Write、Edit、MultiEdit ツール呼び出しをインターセプトする。実行を許可する前に、アクティブなルールに対してコマンド／パスをチェックする。

## 統合

- `codex -a never` セッションでデフォルトで有効化
- ECC 2.0 のオブザーバビリティリスクスコアリングとペアリング
- ブロックされたアクションをすべて `~/.claude/safety-guard.log` に記録
