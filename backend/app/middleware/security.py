"""
セキュリティ関連のミドルウェア
- セキュリティヘッダー追加
- HTTPS リダイレクト
- レート制限
"""

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import PlainTextResponse
from datetime import datetime, timedelta
from collections import defaultdict
from typing import Callable
import logging

logger = logging.getLogger(__name__)


class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """セキュリティヘッダーを追加するミドルウェア"""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        response = await call_next(request)

        # X-Content-Type-Options: MIME タイプの自動判定を防止
        response.headers["X-Content-Type-Options"] = "nosniff"

        # X-Frame-Options: クリックジャッキング防止
        response.headers["X-Frame-Options"] = "DENY"

        # X-XSS-Protection: XSS 防止（古いブラウザ対応）
        response.headers["X-XSS-Protection"] = "1; mode=block"

        # Strict-Transport-Security: HTTPS強制
        response.headers["Strict-Transport-Security"] = (
            "max-age=31536000; includeSubDomains; preload"
        )

        # Content-Security-Policy: CSP
        response.headers["Content-Security-Policy"] = (
            "default-src 'self'; "
            "script-src 'self'; "
            "style-src 'self' 'unsafe-inline'; "
            "img-src 'self' data: https:; "
            "font-src 'self'; "
            "connect-src 'self'; "
            "frame-ancestors 'none'; "
            "base-uri 'self'; "
            "form-action 'self'"
        )

        # Referrer-Policy: リファラー情報の公開制限
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

        # Permissions-Policy（旧Feature-Policy）
        response.headers["Permissions-Policy"] = (
            "camera=(), "
            "microphone=(), "
            "geolocation=(), "
            "payment=(), "
            "usb=(), "
            "magnetometer=(), "
            "gyroscope=(), "
            "accelerometer=()"
        )

        return response


class HTTPSRedirectMiddleware(BaseHTTPMiddleware):
    """HTTP を HTTPS にリダイレクトするミドルウェア"""

    def __init__(self, app, enabled: bool = False):
        super().__init__(app)
        self.enabled = enabled

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        if self.enabled and request.url.scheme == "http":
            url = request.url.replace(scheme="https")
            return Response(
                status_code=301,
                headers={"location": str(url)},
            )

        return await call_next(request)


class RateLimitMiddleware(BaseHTTPMiddleware):
    """シンプルなレート制限ミドルウェア"""

    def __init__(self, app, requests_per_minute: int = 100):
        super().__init__(app)
        self.requests_per_minute = requests_per_minute
        self.requests: dict[str, list[datetime]] = defaultdict(list)
        self.window_duration = timedelta(minutes=1)

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        client_ip = request.client.host if request.client else "unknown"
        now = datetime.now()

        # 古いリクエストを削除
        cutoff_time = now - self.window_duration
        self.requests[client_ip] = [
            req_time for req_time in self.requests[client_ip]
            if req_time > cutoff_time
        ]

        # リクエスト数をチェック
        if len(self.requests[client_ip]) >= self.requests_per_minute:
            logger.warning(
                f"Rate limit exceeded for {client_ip}: "
                f"{len(self.requests[client_ip])} requests"
            )
            return PlainTextResponse(
                "Rate limit exceeded",
                status_code=429,
                headers={"Retry-After": "60"},
            )

        # リクエストを記録
        self.requests[client_ip].append(now)

        return await call_next(request)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """リクエスト・レスポンスをログするミドルウェア"""

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # リクエスト情報
        method = request.method
        path = request.url.path
        client_ip = request.client.host if request.client else "unknown"

        # リクエストを処理
        response = await call_next(request)

        # ログ出力
        status_code = response.status_code
        log_level = (
            logging.WARNING if status_code >= 400 else logging.INFO
        )

        logger.log(
            log_level,
            f"{client_ip} {method} {path} -> {status_code}",
        )

        return response
