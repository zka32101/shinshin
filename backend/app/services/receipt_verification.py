"""
課金レシート検証サービス

- Android: Google Play Developer API（Android Publisher API）
  サービスアカウントJSON鍵から自己署名JWTを作成し、OAuth2の
  "jwt-bearer" フローでアクセストークンを取得したのち、
  purchases.subscriptions.get を呼び出して購読状態を確認する。

- iOS: App Store Server API
  ES256で署名したJWTでApple側に対して認証し、
  GetTransactionInfo エンドポイントでトランザクションの真正性を確認する。
  ※ 本実装では App Store Server API が返す signedTransactionInfo (JWS) の
    ペイロードを復号して利用しているが、Appleのx5c証明書チェーンによる
    署名検証までは行っていない。本番運用前に完全な署名検証の追加を推奨する。

いずれも実際のサービスアカウント鍵・Apple鍵はこの環境には存在しないため、
設定は環境変数（app.config.Settings）経由で読み込む形にしてあり、
鍵が未設定の場合は ReceiptVerificationError を送出する。
"""

import json
import time
from datetime import datetime
from pathlib import Path
from typing import Optional

import httpx
from jose import jwt as jose_jwt

from app.config import Settings


class ReceiptVerificationError(Exception):
    """レシート/購入トークンの検証に失敗した場合の例外。

    retryable=True の場合は、サーバー側の一時的な問題（5xx等）を示し、
    呼び出し側で 502 として扱うことを想定している。
    """

    def __init__(self, message: str, *, retryable: bool = False):
        super().__init__(message)
        self.retryable = retryable


def ms_to_datetime(ms) -> datetime:
    """エポックミリ秒（str/int）を naive UTC datetime に変換する。"""
    return datetime.utcfromtimestamp(int(ms) / 1000)


# ---------------------------------------------------------------------------
# Google Play (Android)
# ---------------------------------------------------------------------------

GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_ANDROIDPUBLISHER_BASE = "https://androidpublisher.googleapis.com/androidpublisher/v3"
GOOGLE_PLAY_SCOPE = "https://www.googleapis.com/auth/androidpublisher"


class GooglePlayVerifier:
    """Google Play Developer API を使った購読購入の検証。"""

    def __init__(self, settings: Settings, http_client: Optional[httpx.AsyncClient] = None):
        self._settings = settings
        self._http = http_client
        self._owns_client = http_client is None

    def _load_service_account(self) -> dict:
        path = self._settings.google_play_credentials_path
        if not path:
            raise ReceiptVerificationError(
                "GOOGLE_PLAY_CREDENTIALS_PATH が設定されていません。"
                "Google Play Developer API用のサービスアカウントJSON鍵のパスを設定してください。"
            )
        try:
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
        except FileNotFoundError as e:
            raise ReceiptVerificationError(
                f"Google Playサービスアカウント鍵が見つかりません: {path}"
            ) from e
        except json.JSONDecodeError as e:
            raise ReceiptVerificationError(
                "Google Playサービスアカウント鍵のJSONが不正です"
            ) from e

    async def _get_access_token(self, client: httpx.AsyncClient) -> str:
        account = self._load_service_account()
        try:
            client_email = account["client_email"]
            private_key = account["private_key"]
        except KeyError as e:
            raise ReceiptVerificationError(
                f"Google Playサービスアカウント鍵に必要なフィールドがありません: {e}"
            ) from e

        now = int(time.time())
        claims = {
            "iss": client_email,
            "scope": GOOGLE_PLAY_SCOPE,
            "aud": GOOGLE_TOKEN_URL,
            "iat": now,
            "exp": now + 3600,
        }
        assertion = jose_jwt.encode(claims, private_key, algorithm="RS256")

        response = await client.post(
            GOOGLE_TOKEN_URL,
            data={
                "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                "assertion": assertion,
            },
        )
        if response.status_code != 200:
            raise ReceiptVerificationError(
                f"Google OAuth2トークン取得に失敗しました: {response.status_code} {response.text}",
                retryable=response.status_code >= 500,
            )
        data = response.json()
        token = data.get("access_token")
        if not token:
            raise ReceiptVerificationError("Google OAuth2アクセストークンが空です")
        return token

    async def verify_subscription(
        self,
        *,
        package_name: str,
        subscription_id: str,
        purchase_token: str,
    ) -> dict:
        """購読を検証し、Play Developer API の生レスポンス(dict)を返す。

        レスポンス形式（抜粋）:
          - paymentState: 0=支払い保留, 1=支払い完了, 2=無料トライアル中, 3=保留支払い(延期)
          - expiryTimeMillis: 有効期限（エポックミリ秒, 文字列）
          - cancelReason: キャンセルされた場合の理由コード
        """
        client = self._http or httpx.AsyncClient(timeout=10.0)
        try:
            token = await self._get_access_token(client)
            url = (
                f"{GOOGLE_ANDROIDPUBLISHER_BASE}/applications/{package_name}"
                f"/purchases/subscriptions/{subscription_id}/tokens/{purchase_token}"
            )
            response = await client.get(url, headers={"Authorization": f"Bearer {token}"})
            if response.status_code == 404:
                raise ReceiptVerificationError(
                    "購入が見つかりませんでした（無効な購入トークンです）"
                )
            if response.status_code != 200:
                raise ReceiptVerificationError(
                    f"Google Play購入検証に失敗しました: {response.status_code} {response.text}",
                    retryable=response.status_code >= 500,
                )
            return response.json()
        finally:
            if self._owns_client:
                await client.aclose()


# ---------------------------------------------------------------------------
# App Store (iOS)
# ---------------------------------------------------------------------------

APPLE_PROD_BASE = "https://api.storekit.itunes.apple.com/inApps/v1"
APPLE_SANDBOX_BASE = "https://api.storekit-sandbox.itunes.apple.com/inApps/v1"


class AppleVerifier:
    """App Store Server API を使ったトランザクション検証。"""

    def __init__(self, settings: Settings, http_client: Optional[httpx.AsyncClient] = None):
        self._settings = settings
        self._http = http_client
        self._owns_client = http_client is None

    def _load_private_key(self) -> str:
        path = self._settings.apple_private_key_path
        if not path:
            raise ReceiptVerificationError(
                "APPLE_PRIVATE_KEY_PATH が設定されていません。"
                "App Store Server API用の.p8秘密鍵ファイルのパスを設定してください。"
            )
        try:
            return Path(path).read_text(encoding="utf-8")
        except FileNotFoundError as e:
            raise ReceiptVerificationError(f"Appleの秘密鍵が見つかりません: {path}") from e

    def _build_jwt(self) -> str:
        if not (
            self._settings.apple_key_id
            and self._settings.apple_issuer_id
            and self._settings.apple_bundle_id
        ):
            raise ReceiptVerificationError(
                "Apple の鍵設定（APPLE_KEY_ID / APPLE_ISSUER_ID / APPLE_BUNDLE_ID）が不足しています"
            )
        private_key = self._load_private_key()
        now = int(time.time())
        headers = {"alg": "ES256", "kid": self._settings.apple_key_id, "typ": "JWT"}
        claims = {
            "iss": self._settings.apple_issuer_id,
            "iat": now,
            "exp": now + 1800,  # Appleの上限は60分だが余裕を持って30分に設定
            "aud": "appstoreconnect-v1",
            "bid": self._settings.apple_bundle_id,
        }
        return jose_jwt.encode(claims, private_key, algorithm="ES256", headers=headers)

    async def verify_transaction(self, *, transaction_id: str) -> dict:
        """トランザクションを検証し、signedTransactionInfo のクレーム(dict)を返す。

        クレーム形式（抜粋）:
          - transactionId / originalTransactionId
          - productId
          - purchaseDate / expiresDate（エポックミリ秒）
          - revocationDate（返金・取消時のみ存在）
          - type ("Auto-Renewable Subscription" 等)
        """
        base = (
            APPLE_PROD_BASE
            if self._settings.apple_environment == "production"
            else APPLE_SANDBOX_BASE
        )
        token = self._build_jwt()
        client = self._http or httpx.AsyncClient(timeout=10.0)
        try:
            response = await client.get(
                f"{base}/transactions/{transaction_id}",
                headers={"Authorization": f"Bearer {token}"},
            )
            if response.status_code == 404:
                raise ReceiptVerificationError("トランザクションが見つかりませんでした")
            if response.status_code != 200:
                raise ReceiptVerificationError(
                    f"App Store取引検証に失敗しました: {response.status_code} {response.text}",
                    retryable=response.status_code >= 500,
                )
            body = response.json()
            signed_transaction_info = body.get("signedTransactionInfo")
            if not signed_transaction_info:
                raise ReceiptVerificationError("signedTransactionInfoが応答に含まれていません")

            # NOTE: ここではJWSペイロードの読み取りのみを行い、Appleのx5c証明書
            # チェーンによる署名検証は行っていない（呼び出し自体がApple発行の
            # 短命JWTによる認証済みAPI呼び出しであるため一定の真正性はあるが、
            # 完全な信頼を置くには署名検証の追加実装が必要）。
            claims = jose_jwt.get_unverified_claims(signed_transaction_info)
            return claims
        finally:
            if self._owns_client:
                await client.aclose()
