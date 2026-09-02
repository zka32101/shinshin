import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import get_settings
from app.api import auth, users, children, stories, quizzes, reports, progress, parent_coaching, rankings
from app.api.v1.endpoints import scheduled_tasks
from app.db.database import engine
from app.db.base import Base
from app.middleware.security import (
    SecurityHeadersMiddleware,
    HTTPSRedirectMiddleware,
    RateLimitMiddleware,
    RequestLoggingMiddleware,
)

settings = get_settings()
logging.basicConfig(level=logging.DEBUG if settings.debug else logging.INFO)
logger = logging.getLogger(__name__)

# Sentry 初期化
if settings.sentry_dsn:
    import sentry_sdk
    from sentry_sdk.integrations.fastapi import FastApiIntegration
    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.environment,
        traces_sample_rate=0.1,
        integrations=[FastApiIntegration()],
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: テーブル自動作成 (開発用)
    logger.info(f"Starting {app.title} [{settings.environment}]")
    if settings.debug:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    yield
    # Shutdown
    logger.info("Shutting down...")
    await engine.dispose()


app = FastAPI(
    title="小学コレ！道徳 API",
    description="小学3-4年生向け道徳学習アプリのバックエンドAPI",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# セキュリティミドルウェア（逆順で登録）
# 後に登録したものが先に実行される

# リクエストログ
app.add_middleware(RequestLoggingMiddleware)

# レート制限
app.add_middleware(
    RateLimitMiddleware,
    requests_per_minute=settings.rate_limit_per_minute,
)

# HTTPS リダイレクト
if settings.force_https:
    app.add_middleware(HTTPSRedirectMiddleware, enabled=True)

# セキュリティヘッダー
if settings.security_headers_enabled:
    app.add_middleware(SecurityHeadersMiddleware)

# CORS設定 - 本番環境では厳格に制限
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_allowed_origins(),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
    max_age=3600,  # プリフライトリクエストキャッシュ時間（秒）
)

# ルーター登録
PREFIX = f"/api/{settings.api_version}"
app.include_router(auth.router, prefix=f"{PREFIX}/auth", tags=["認証"])
app.include_router(users.router, prefix=f"{PREFIX}/users", tags=["ユーザー"])
app.include_router(children.router, prefix=f"{PREFIX}/children", tags=["子供"])
app.include_router(stories.router, prefix=f"{PREFIX}/stories", tags=["ストーリー"])
app.include_router(quizzes.router, prefix=f"{PREFIX}/quizzes", tags=["クイズ"])
app.include_router(reports.router, prefix=f"{PREFIX}/reports", tags=["レポート"])
app.include_router(progress.router, prefix=f"{PREFIX}/progress", tags=["進捗"])
app.include_router(rankings.router, prefix=f"{PREFIX}/rankings", tags=["ランキング"])
app.include_router(scheduled_tasks.router, prefix=f"{PREFIX}/scheduled", tags=["スケジュール"])
app.include_router(parent_coaching.router, prefix=PREFIX, tags=["親向けコーチング"])


@app.get("/health", tags=["ヘルスチェック"])
async def health_check():
    return {"status": "ok", "version": "1.0.0", "env": settings.environment}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=settings.debug)
