from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional
import warnings


class Settings(BaseSettings):
    # ========================================================================
    # Database設定
    # ========================================================================
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/shougaku"

    # ========================================================================
    # JWT認証設定
    # ========================================================================
    secret_key: str = ""  # Must be set via SECRET_KEY env var in production
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    # ========================================================================
    # Firebase設定
    # ========================================================================
    firebase_project_id: str = ""
    firebase_credentials_path: Optional[str] = None

    # ========================================================================
    # API設定
    # ========================================================================
    api_version: str = "v1"
    debug: bool = False

    # ========================================================================
    # エラー追跡設定（Sentry）
    # ========================================================================
    sentry_dsn: Optional[str] = None
    environment: str = "development"

    # ========================================================================
    # CORS設定
    # ========================================================================
    allowed_origins: str = "http://localhost:3000"  # 本番では comma-separated

    # ========================================================================
    # セキュリティ設定
    # ========================================================================
    force_https: bool = False
    security_headers_enabled: bool = True
    csrf_protection_enabled: bool = True
    rate_limit_per_minute: int = 100

    # ========================================================================
    # ログ設定
    # ========================================================================
    log_level: str = "INFO"
    log_file: Optional[str] = None

    # ========================================================================
    # Google Cloud / Vertex AI設定
    # ========================================================================
    gcp_project_id: Optional[str] = None
    vertex_ai_location: str = "asia-northeast1"
    gemini_model_id: str = "gemini-2.0-flash"

    # ========================================================================
    # メール設定（SendGrid）
    # ========================================================================
    sendgrid_api_key: Optional[str] = None

    # ========================================================================
    # Apple App Store設定
    # ========================================================================
    apple_team_id: Optional[str] = None
    apple_key_id: Optional[str] = None
    apple_issuer_id: Optional[str] = None

    # ========================================================================
    # Google Play設定
    # ========================================================================
    google_play_credentials_path: Optional[str] = None

    class Config:
        env_file = ".env"
        case_sensitive = False  # Allow DATABASE_URL → database_url mapping

    def __init__(self, **data):
        super().__init__(**data)
        self._validate_production_settings()

    def _validate_production_settings(self):
        """本番環境設定の検証"""
        if self.environment == "production":
            # SECRET_KEY チェック
            if self.secret_key == "dev-secret-change-in-production" or len(self.secret_key) < 64:
                raise ValueError(
                    "本番環境では SECRET_KEY を64文字以上の "
                    "ランダムな値に設定してください"
                )

            # DEBUG チェック
            if self.debug:
                raise ValueError("本番環境では DEBUG を False に設定してください")

            # CORS 設定チェック
            if self.allowed_origins == "http://localhost:3000":
                raise ValueError("本番環境では ALLOWED_ORIGINS を正しく設定してください")

            # Sentry チェック
            if not self.sentry_dsn:
                warnings.warn(
                    "本番環境では Sentry DSN の設定を推奨します",
                    UserWarning
                )

            # Firebase 設定チェック
            if not self.firebase_project_id or not self.firebase_credentials_path:
                warnings.warn(
                    "本番環境では Firebase 認証情報の設定を推奨します",
                    UserWarning
                )

    def get_allowed_origins(self) -> list[str]:
        """CORS許可オリジンを リスト化"""
        if self.environment == "development":
            return ["*"]
        return [origin.strip() for origin in self.allowed_origins.split(",")]


@lru_cache()
def get_settings() -> Settings:
    return Settings()
