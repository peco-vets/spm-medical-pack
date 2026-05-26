---
description: PEP 8 準拠、型ヒント、セキュリティ、Pythonic なイディオムに関する包括的な Python コードレビュー。python-reviewer エージェントを起動する / Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent.
---

# Python Code Review

このコマンドは **python-reviewer** エージェントを起動し、包括的な Python 固有のコードレビューを行う。

## このコマンドが行うこと

1. **Python 変更を特定**：`git diff` で変更された `.py` ファイルを見つける
2. **静的解析実行**：`ruff`、`mypy`、`pylint`、`black --check` を実行する
3. **セキュリティスキャン**：SQL インジェクション、コマンドインジェクション、安全でないデシリアライズをチェックする
4. **型安全レビュー**：型ヒントと mypy エラーを分析する
5. **Pythonic コードチェック**：コードが PEP 8 と Python ベストプラクティスに従っているか確認する
6. **レポート生成**：重要度別に問題を分類する

## 利用シーン

以下の場合に `/python-review` を使用する：
- Python コードを書いた・変更した後
- Python 変更をコミットする前
- Python コードのプルリクエストをレビューする
- 新しい Python コードベースにオンボードする
- Pythonic なパターンとイディオムを学ぶ

## レビューカテゴリ

### CRITICAL（必須修正）
- SQL/コマンドインジェクション脆弱性
- 安全でない eval/exec 利用
- Pickle 安全でないデシリアライズ
- ハードコードされた認証情報
- YAML 安全でないロード
- エラーを隠す bare except 句

### HIGH（修正すべき）
- 公開関数の型ヒント不足
- ミュータブルなデフォルト引数
- 例外を黙って飲み込む
- リソースにコンテキストマネージャを使わない
- 内包表記の代わりに C 風ループ
- isinstance() の代わりに type() を使う
- ロックなしのレースコンディション

### MEDIUM（検討）
- PEP 8 フォーマット違反
- 公開関数の docstring 不足
- ロギングの代わりに print 文
- 非効率な文字列操作
- 名前付き定数なしのマジックナンバー
- フォーマットに f-strings を使わない
- 不必要な list 作成

## 実行される自動チェック

```bash
# Type checking
mypy .

# Linting and formatting
ruff check .
black --check .
isort --check-only .

# Security scanning
bandit -r .

# Dependency audit
pip-audit
safety check

# Testing
pytest --cov=app --cov-report=term-missing
```

## 使用例

`/python-review` を実行すると、変更されたファイルがレビューされ、静的解析結果と、重要度別の発見事項（CRITICAL: SQL インジェクション、HIGH: ミュータブルなデフォルト引数、MEDIUM: 型ヒント不足やコンテキストマネージャ未使用など）と修正案が示される。

## 承認基準

| ステータス | 条件 |
|--------|-----------|
| PASS: Approve | CRITICAL または HIGH の問題なし |
| WARNING: Warning | MEDIUM の問題のみ（注意してマージ） |
| FAIL: Block | CRITICAL または HIGH の問題あり |

## 他のコマンドとの統合

- まず `tdd-workflow` スキルでテストが通ることを確認する
- Python 固有でない懸念には `/code-review` を使う
- コミット前に `/python-review` を使う
- 静的解析ツールが失敗したら `/build-fix` を使う

## フレームワーク固有のレビュー

### Django プロジェクト
reviewer は以下をチェックする：
- N+1 クエリ問題（`select_related` と `prefetch_related` を使う）
- モデル変更のマイグレーション不足
- ORM で動く場面での raw SQL 利用
- マルチステップ操作の `transaction.atomic()` 不足

### FastAPI プロジェクト
reviewer は以下をチェックする：
- CORS の誤設定
- リクエストバリデーション用の Pydantic モデル
- レスポンスモデルの正確性
- 適切な async/await の利用
- 依存性注入パターン

### Flask プロジェクト
reviewer は以下をチェックする：
- コンテキスト管理（app context、request context）
- 適切なエラーハンドリング
- Blueprint の整理
- 設定管理

## 関連

- Agent: `agents/python-reviewer.md`
- Skills: `skills/python-patterns/`, `skills/python-testing/`

## 一般的な修正

### 型ヒントを追加する
- 戻り値と引数の型を明示する
- `typing` モジュールの `Union`、`Optional` などを利用

### コンテキストマネージャを使う
- `open()` などに `with` を使う

### list 内包表記を使う
- ループ + append のパターンを内包表記に置き換える

### ミュータブルなデフォルトを修正する
- デフォルトは `None` にして関数内で初期化する

### f-strings を使う（Python 3.6+）
- `+` や `.format()` の代わりに f-string を使う

### ループ内の文字列連結を修正する
- `+=` 連結の代わりに `"".join(...)` を使う

## Python バージョン互換性

reviewer は、より新しい Python バージョンの機能をコードが使うときに注記する：

| Feature | Minimum Python |
|---------|----------------|
| Type hints | 3.5+ |
| f-strings | 3.6+ |
| Walrus operator (`:=`) | 3.8+ |
| Position-only parameters | 3.8+ |
| Match statements | 3.10+ |
| Type unions (`x | None`) | 3.10+ |

プロジェクトの `pyproject.toml` または `setup.py` が正しい最小 Python バージョンを指定していることを確認する。
