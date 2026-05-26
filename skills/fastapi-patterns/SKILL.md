---
name: fastapi-patterns
description: 非同期 API、DI、Pydantic リクエスト/レスポンスモデル、OpenAPI ドキュメント、テスト、セキュリティ、本番準備性のための FastAPI パターン（FastAPI, async API, DI, Pydantic, OpenAPI）。
origin: community
---

# FastAPI パターン

FastAPI サービスの本番志向パターンである。

## 利用タイミング

- FastAPI アプリの構築・レビュー
- ルーター・スキーマ・依存関係・DB アクセスの分割
- DB や外部サービスを呼び出す非同期エンドポイントの記述
- 認証・認可・OpenAPI ドキュメント・テスト・デプロイ設定の追加
- コピペ可能例と本番リスクの観点での FastAPI PR レビュー

## 仕組み

FastAPI アプリは、明示的な依存関係とサービスコードの上に薄く乗る HTTP レイヤとして扱う。

- `main.py`: アプリ生成、middleware、例外ハンドラ、ルーター登録
- `schemas/`: Pydantic のリクエスト/レスポンスモデル
- `dependencies.py`: DB・認証・ページネーション・リクエストスコープ依存
- `services/` または `crud/`: ビジネスロジックと永続化操作
- `tests/`: 本番リソースを開かず依存関係をオーバーライド

ルーターは小さく保ち、`response_model` を明示する。生 ORM オブジェクト・シークレット・フレームワーク globals をレスポンススキーマに含めない。

## プロジェクトレイアウト

```text
app/
|-- main.py
|-- config.py
|-- dependencies.py
|-- exceptions.py
|-- api/
|   `-- routes/
|       |-- users.py
|       `-- health.py
|-- core/
|   |-- security.py
|   `-- middleware.py
|-- db/
|   |-- session.py
|   `-- crud.py
|-- models/
|-- schemas/
`-- tests/
```

## アプリケーションファクトリ

ファクトリを使うことで、テストやワーカーが制御された設定でアプリを構築できる。

```python
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import health, users
from app.config import settings
from app.db.session import close_db, init_db
from app.exceptions import register_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await close_db()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.api_title,
        version=settings.api_version,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=bool(settings.cors_origins),
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
    )

    register_exception_handlers(app)
    app.include_router(health.router, prefix="/health", tags=["health"])
    app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
    return app


app = create_app()
```

`allow_origins=["*"]` と `allow_credentials=True` を併用してはならない。ブラウザがその組合せを拒否し、Starlette もクレデンシャル付きリクエストでは不許可とする。

## Pydantic スキーマ

リクエスト・更新・レスポンスモデルを分離する。

```python
from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserBase(BaseModel):
    email: EmailStr
    full_name: Annotated[str, Field(min_length=1, max_length=100)]


class UserCreate(UserBase):
    password: Annotated[str, Field(min_length=12, max_length=128)]


class UserUpdate(BaseModel):
    email: EmailStr | None = None
    full_name: Annotated[str | None, Field(min_length=1, max_length=100)] = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime
```

レスポンスモデルには、パスワードハッシュ・アクセストークン・リフレッシュトークン・内部認可状態を含めてはならない。

## 依存関係

リクエストスコープのリソースには DI を使う。

```python
from collections.abc import AsyncIterator
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_token
from app.db.session import session_factory
from app.models.user import User


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def get_db() -> AsyncIterator[AsyncSession]:
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = decode_token(token)
    user_id = UUID(payload["sub"])
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    return user
```

ルートハンドラ内でセッション・クライアント・クレデンシャルをインラインで作らないこと。

## 非同期エンドポイント

I/O を行うルートハンドラは async にし、内部で非同期ライブラリを使う。

```python
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.user import UserResponse


router = APIRouter()


@router.get("/", response_model=list[UserResponse])
async def list_users(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(User).order_by(User.created_at.desc()).limit(limit).offset(offset)
    )
    return result.scalars().all()
```

async ハンドラからの外部 HTTP 呼び出しには `httpx.AsyncClient` を使う。async ルートで `requests` を呼ばないこと。

## エラーハンドリング

ドメイン例外を集約し、レスポンス形状を安定化する。

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class ApiError(Exception):
    def __init__(self, status_code: int, code: str, message: str):
        self.status_code = status_code
        self.code = code
        self.message = message


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def api_error_handler(request: Request, exc: ApiError):
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": {"code": exc.code, "message": exc.message}},
        )
```

## OpenAPI カスタマイズ

カスタム OpenAPI 関数を `app.openapi` に代入する。一度だけ呼ぶのではない。

```python
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi


def install_openapi(app: FastAPI) -> None:
    def custom_openapi():
        if app.openapi_schema:
            return app.openapi_schema
        app.openapi_schema = get_openapi(
            title="Service API",
            version="1.0.0",
            routes=app.routes,
        )
        return app.openapi_schema

    app.openapi = custom_openapi
```

## テスト

`Depends` が用いる依存関係をオーバーライドする。ルートハンドラが参照しない内部ヘルパーをオーバーライドしないこと。

```python
import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db
from app.main import create_app


@pytest.fixture
async def client(test_session: AsyncSession):
    app = create_app()

    async def override_get_db():
        yield test_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as test_client:
        yield test_client
    app.dependency_overrides.clear()
```

## セキュリティチェックリスト

- パスワードは `argon2-cffi`、`bcrypt`、または現行 passlib 互換ハッシャでハッシュする
- JWT の issuer・audience・expiry・署名アルゴリズムを検証する
- CORS オリジンは環境固有にする
- 認証および書き込みヘビーなエンドポイントにレート制限を設ける
- すべてのリクエストボディに Pydantic モデルを使う
- ORM のパラメータバインドまたは SQLAlchemy Core 式を使う。f 文字列で SQL を組み立てない
- ログからトークン・Authorization ヘッダ・cookie・パスワードをマスクする
- CI で依存パッケージ監査ツールを実行する

## パフォーマンスチェックリスト

- DB 接続プーリングを明示的に構成する
- 一覧エンドポイントにページネーションを付ける
- N+1 クエリを警戒し、意図的に eager loading を使う
- async 経路では async HTTP/DB クライアントを使う
- 圧縮はペイロードサイズと CPU のトレードオフを確認した後に追加する
- 高コストかつ安定な read は明示的な invalidation 付きでキャッシュする

## 例

これらはプロジェクト全体テンプレートではなく、パターンとして使う。

- アプリケーションファクトリ: `create_app` で middleware とルーターを一度だけ構成する
- スキーマ分割: `UserCreate`・`UserUpdate`・`UserResponse` は責務が異なる
- 依存関係オーバーライド: テストで `get_db` を直接オーバーライドする
- OpenAPI カスタマイズ: `app.openapi = custom_openapi` を代入する

## 関連

- Agent: `fastapi-reviewer`
- Command: `/fastapi-review`
- Skill: `python-patterns`
- Skill: `python-testing`
- Skill: `api-design`
