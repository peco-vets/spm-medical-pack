---
description: アーキテクチャ、非同期の正確性、依存性注入、Pydantic スキーマ、セキュリティ、パフォーマンス、テスト容易性について FastAPI アプリケーションをレビューする / Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.
---

# FastAPI Review

`fastapi-reviewer` エージェントを起動し、FastAPI 特化のレビューを行う。

## Usage

```text
/fastapi-review [file-or-directory]
```

## レビュー範囲

- App factory、router の境界、ミドルウェア、例外ハンドラ。
- Pydantic リクエストとレスポンスのスキーマ分離。
- DB セッション、認証、ページネーション、設定の依存性注入。
- 非同期 DB と外部 HTTP のパターン。
- CORS、認証、レート制限、ロギング、シークレットハンドリング。
- OpenAPI メタデータと文書化されたレスポンスモデル。
- テストクライアントのセットアップと依存性のオーバーライド。

## 期待される出力

```text
[SEVERITY] Short issue title
File: path/to/file.py:42
Issue: What is wrong and why it matters.
Fix: Concrete change to make.
```

## 関連

- Agent: `fastapi-reviewer`
- Skill: `fastapi-patterns`
- Command: `/python-review`
- Skill: `security-scan`
