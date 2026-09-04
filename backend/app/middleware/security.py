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
    """Enhanced rate limiting with per-endpoint limits"""

    # Per-endpoint rate limits (requests per minute)
    ENDPOINT_LIMITS = {
        "/api/v1/auth/login": 5,         # Strict limit on login
        "/api/v1/auth/register": 5,      # Strict limit on registration
        "/api/v1/auth/firebase": 10,     # Firebase login slightly more lenient
    }
    DEFAULT_LIMIT = 100  # Default for all other endpoints

    def __init__(self, app, requests_per_minute: int = 100):
        super().__init__(app)
        self.default_limit = requests_per_minute
        # Track requests by "ip:endpoint" key for per-endpoint limits
        self.requests: dict[str, list[datetime]] = defaultdict(list)
        self.window_duration = timedelta(minutes=1)

    def _get_rate_limit(self, path: str) -> int:
        """Get rate limit for specific endpoint"""
        for endpoint_pattern, limit in self.ENDPOINT_LIMITS.items():
            if path.startswith(endpoint_pattern):
                return limit
        return self.DEFAULT_LIMIT

    def reset_requests(self):
        """Reset all request tracking (for testing)"""
        self.requests.clear()

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        client_ip = request.client.host if request.client else "unknown"
        path = request.url.path

        # Get the appropriate rate limit for this endpoint
        rate_limit = self._get_rate_limit(path)

        # Use composite key: IP:Endpoint for auth endpoints, IP only for others
        if path.startswith("/api/v1/auth/"):
            limit_key = f"{client_ip}:{path}"
        else:
            limit_key = client_ip

        now = datetime.now()

        # Remove old requests outside the time window
        cutoff_time = now - self.window_duration
        self.requests[limit_key] = [
            req_time for req_time in self.requests[limit_key]
            if req_time > cutoff_time
        ]

        # Check if rate limit exceeded
        if len(self.requests[limit_key]) >= rate_limit:
            logger.warning(
                f"SECURITY: Rate limit exceeded for {client_ip} on {path}: "
                f"{len(self.requests[limit_key])}/{rate_limit} requests"
            )
            # Suggest retry after 60 seconds for auth endpoints
            retry_after = "60" if path.startswith("/api/v1/auth/") else "5"
            return PlainTextResponse(
                "Rate limit exceeded. Please try again later.",
                status_code=429,
                headers={"Retry-After": retry_after},
            )

        # Record this request
        self.requests[limit_key].append(now)

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
