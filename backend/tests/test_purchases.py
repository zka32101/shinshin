import time
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, patch

import pytest
from httpx import AsyncClient

from app.services.receipt_verification import ReceiptVerificationError


def _future_ms(days: int = 30) -> str:
    return str(int((time.time() + days * 86400) * 1000))


def _past_ms(days: int = 1) -> str:
    return str(int((time.time() - days * 86400) * 1000))


# ---------------------------------------------------------------------------
# Google Play
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_verify_google_play_purchase_activates_premium(client: AsyncClient, auth_headers: dict):
    """有効な購読トークンの検証に成功したら、プレミアムが有効化される"""
    fake_response = {
        "paymentState": 1,
        "expiryTimeMillis": _future_ms(30),
        "orderId": "GPA.1234-5678-9012-34567",
    }
    with patch(
        "app.api.purchases.GooglePlayVerifier.verify_subscription",
        new=AsyncMock(return_value=fake_response),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "purchaseToken": "test-purchase-token-abc",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=auth_headers,
        )

    assert response.status_code == 200, response.text
    data = response.json()
    assert data["verified"] is True
    assert data["isPremium"] is True
    assert data["planType"] == "monthly"
    assert data["platform"] == "google_play"
    assert data["transactionId"] == "test-purchase-token-abc"

    status_resp = await client.get("/api/v1/purchases/status", headers=auth_headers)
    assert status_resp.status_code == 200
    status_data = status_resp.json()
    assert status_data["isPremium"] is True
    assert status_data["planType"] == "monthly"


@pytest.mark.asyncio
async def test_verify_google_play_purchase_yearly_plan(client: AsyncClient, auth_headers: dict):
    fake_response = {"paymentState": 1, "expiryTimeMillis": _future_ms(365)}
    with patch(
        "app.api.purchases.GooglePlayVerifier.verify_subscription",
        new=AsyncMock(return_value=fake_response),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.yearly",
                "purchaseToken": "test-purchase-token-yearly",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=auth_headers,
        )
    assert response.status_code == 200, response.text
    assert response.json()["planType"] == "yearly"


@pytest.mark.asyncio
async def test_verify_google_play_purchase_rejects_cancelled_subscription(
    client: AsyncClient, auth_headers: dict
):
    """支払い保留(paymentState=0)の購読は拒否される"""
    fake_response = {"paymentState": 0, "expiryTimeMillis": _future_ms(30)}
    with patch(
        "app.api.purchases.GooglePlayVerifier.verify_subscription",
        new=AsyncMock(return_value=fake_response),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "purchaseToken": "test-purchase-token-pending",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=auth_headers,
        )
    assert response.status_code == 400
    assert "有効な購読ではありません" in response.text


@pytest.mark.asyncio
async def test_verify_google_play_purchase_rejects_expired_subscription(
    client: AsyncClient, auth_headers: dict
):
    fake_response = {"paymentState": 1, "expiryTimeMillis": _past_ms(1)}
    with patch(
        "app.api.purchases.GooglePlayVerifier.verify_subscription",
        new=AsyncMock(return_value=fake_response),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "purchaseToken": "test-purchase-token-expired",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=auth_headers,
        )
    assert response.status_code == 400
    assert "有効期限が切れています" in response.text


@pytest.mark.asyncio
async def test_verify_google_play_purchase_propagates_verification_error(
    client: AsyncClient, auth_headers: dict
):
    """無効なトークン（Google APIが404）の場合は400を返す"""
    with patch(
        "app.api.purchases.GooglePlayVerifier.verify_subscription",
        new=AsyncMock(side_effect=ReceiptVerificationError("購入が見つかりませんでした")),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "purchaseToken": "invalid-token",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=auth_headers,
        )
    assert response.status_code == 400
    assert "購入が見つかりませんでした" in response.text


@pytest.mark.asyncio
async def test_verify_google_play_purchase_retryable_error_returns_502(
    client: AsyncClient, auth_headers: dict
):
    """Google側の一時的なサーバーエラーは502として返す"""
    with patch(
        "app.api.purchases.GooglePlayVerifier.verify_subscription",
        new=AsyncMock(
            side_effect=ReceiptVerificationError("Google Play購入検証に失敗しました: 503", retryable=True)
        ),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "purchaseToken": "some-token",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=auth_headers,
        )
    assert response.status_code == 502


@pytest.mark.asyncio
async def test_verify_google_play_rejects_unknown_product_id(client: AsyncClient, auth_headers: dict):
    response = await client.post(
        "/api/v1/purchases/verify/google",
        json={
            "productId": "jp.petitworks.shougaku_kore_doutoku.weekly",
            "purchaseToken": "some-token",
            "packageName": "jp.petitworks.shougaku_kore_doutoku",
        },
        headers=auth_headers,
    )
    assert response.status_code == 400
    assert "不明な商品ID" in response.text


@pytest.mark.asyncio
async def test_verify_google_play_purchase_requires_auth(client: AsyncClient):
    response = await client.post(
        "/api/v1/purchases/verify/google",
        json={
            "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
            "purchaseToken": "some-token",
            "packageName": "jp.petitworks.shougaku_kore_doutoku",
        },
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_verify_google_play_purchase_is_idempotent(client: AsyncClient, auth_headers: dict):
    """同一トークンでの再検証（リトライ）は同じ購入レコードを更新するだけで成功する"""
    fake_response = {"paymentState": 1, "expiryTimeMillis": _future_ms(30)}
    with patch(
        "app.api.purchases.GooglePlayVerifier.verify_subscription",
        new=AsyncMock(return_value=fake_response),
    ):
        first = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "purchaseToken": "repeat-token",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=auth_headers,
        )
        second = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "purchaseToken": "repeat-token",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=auth_headers,
        )
    assert first.status_code == 200
    assert second.status_code == 200
    assert first.json()["transactionId"] == second.json()["transactionId"]


@pytest.mark.asyncio
async def test_verify_google_play_purchase_transaction_owned_by_other_user_returns_409(
    client: AsyncClient, auth_headers: dict
):
    """既に別ユーザーに紐づく取引IDでの検証は409で拒否される（なりすまし対策）"""
    fake_response = {"paymentState": 1, "expiryTimeMillis": _future_ms(30)}

    other_register = await client.post(
        "/api/v1/auth/register",
        json={"email": "other-buyer@example.com", "password": "TestPassword123", "name": "他の保護者"},
    )
    assert other_register.status_code == 201, other_register.text
    other_headers = {"Authorization": f"Bearer {other_register.json()['accessToken']}"}

    with patch(
        "app.api.purchases.GooglePlayVerifier.verify_subscription",
        new=AsyncMock(return_value=fake_response),
    ):
        first = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "purchaseToken": "shared-token",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=auth_headers,
        )
        assert first.status_code == 200

        second = await client.post(
            "/api/v1/purchases/verify/google",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "purchaseToken": "shared-token",
                "packageName": "jp.petitworks.shougaku_kore_doutoku",
            },
            headers=other_headers,
        )
    assert second.status_code == 409


# ---------------------------------------------------------------------------
# App Store (Apple)
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_verify_apple_purchase_activates_premium(client: AsyncClient, auth_headers: dict):
    fake_claims = {
        "transactionId": "2000000123456789",
        "originalTransactionId": "2000000123456789",
        "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
        "purchaseDate": int((time.time() - 3600) * 1000),
        "expiresDate": int(float(_future_ms(30))),
        "type": "Auto-Renewable Subscription",
    }
    with patch(
        "app.api.purchases.AppleVerifier.verify_transaction",
        new=AsyncMock(return_value=fake_claims),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/apple",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "transactionId": "2000000123456789",
            },
            headers=auth_headers,
        )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["verified"] is True
    assert data["isPremium"] is True
    assert data["planType"] == "monthly"
    assert data["platform"] == "app_store"
    assert data["transactionId"] == "2000000123456789"


@pytest.mark.asyncio
async def test_verify_apple_purchase_rejects_revoked_transaction(client: AsyncClient, auth_headers: dict):
    fake_claims = {
        "transactionId": "2000000123456789",
        "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
        "expiresDate": int(float(_future_ms(30))),
        "revocationDate": int((time.time() - 3600) * 1000),
    }
    with patch(
        "app.api.purchases.AppleVerifier.verify_transaction",
        new=AsyncMock(return_value=fake_claims),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/apple",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "transactionId": "2000000123456789",
            },
            headers=auth_headers,
        )
    assert response.status_code == 400
    assert "返金/取り消し済み" in response.text


@pytest.mark.asyncio
async def test_verify_apple_purchase_rejects_expired_transaction(client: AsyncClient, auth_headers: dict):
    fake_claims = {
        "transactionId": "2000000123456789",
        "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
        "expiresDate": int(float(_past_ms(1))),
    }
    with patch(
        "app.api.purchases.AppleVerifier.verify_transaction",
        new=AsyncMock(return_value=fake_claims),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/apple",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "transactionId": "2000000123456789",
            },
            headers=auth_headers,
        )
    assert response.status_code == 400
    assert "有効期限が切れています" in response.text


@pytest.mark.asyncio
async def test_verify_apple_purchase_rejects_mismatched_product_id(client: AsyncClient, auth_headers: dict):
    fake_claims = {
        "transactionId": "2000000123456789",
        "productId": "jp.petitworks.shougaku_kore_doutoku.yearly",
        "expiresDate": int(float(_future_ms(30))),
    }
    with patch(
        "app.api.purchases.AppleVerifier.verify_transaction",
        new=AsyncMock(return_value=fake_claims),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/apple",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "transactionId": "2000000123456789",
            },
            headers=auth_headers,
        )
    assert response.status_code == 400
    assert "商品IDが一致しません" in response.text


@pytest.mark.asyncio
async def test_verify_apple_purchase_propagates_verification_error(client: AsyncClient, auth_headers: dict):
    with patch(
        "app.api.purchases.AppleVerifier.verify_transaction",
        new=AsyncMock(side_effect=ReceiptVerificationError("トランザクションが見つかりませんでした")),
    ):
        response = await client.post(
            "/api/v1/purchases/verify/apple",
            json={
                "productId": "jp.petitworks.shougaku_kore_doutoku.monthly",
                "transactionId": "nonexistent",
            },
            headers=auth_headers,
        )
    assert response.status_code == 400
    assert "トランザクションが見つかりませんでした" in response.text


@pytest.mark.asyncio
async def test_verify_apple_purchase_requires_auth(client: AsyncClient):
    response = await client.post(
        "/api/v1/purchases/verify/apple",
        json={"productId": "jp.petitworks.shougaku_kore_doutoku.monthly", "transactionId": "123"},
    )
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# ステータス確認
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_purchase_status_defaults_to_not_premium(client: AsyncClient, auth_headers: dict):
    response = await client.get("/api/v1/purchases/status", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["isPremium"] is False
    assert data["planType"] is None


@pytest.mark.asyncio
async def test_purchase_status_reflects_expired_premium(client: AsyncClient, auth_headers: dict, db_session):
    """DB上でプレミアム期限が過去日になっている場合はfalseを返す"""
    from sqlalchemy import select
    from app.models.user import User

    result = await db_session.execute(select(User))
    user = result.scalars().first()
    user.is_premium = True
    user.premium_plan = "monthly"
    user.premium_expires_at = datetime.utcnow() - timedelta(days=1)
    await db_session.commit()

    response = await client.get("/api/v1/purchases/status", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["isPremium"] is False


# ---------------------------------------------------------------------------
# receipt_verification サービス単体テスト（設定不足時の挙動）
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_google_play_verifier_raises_when_credentials_path_missing():
    from app.services.receipt_verification import GooglePlayVerifier, ReceiptVerificationError
    from app.config import Settings

    settings = Settings(
        database_url="sqlite+aiosqlite:///:memory:",
        secret_key="x" * 64,
        google_play_credentials_path=None,
    )
    verifier = GooglePlayVerifier(settings)
    with pytest.raises(ReceiptVerificationError):
        await verifier.verify_subscription(
            package_name="jp.petitworks.shougaku_kore_doutoku",
            subscription_id="monthly",
            purchase_token="token",
        )


@pytest.mark.asyncio
async def test_apple_verifier_raises_when_key_settings_missing():
    from app.services.receipt_verification import AppleVerifier, ReceiptVerificationError
    from app.config import Settings

    settings = Settings(
        database_url="sqlite+aiosqlite:///:memory:",
        secret_key="x" * 64,
        apple_key_id=None,
        apple_issuer_id=None,
        apple_bundle_id=None,
    )
    verifier = AppleVerifier(settings)
    with pytest.raises(ReceiptVerificationError):
        await verifier.verify_transaction(transaction_id="123")


@pytest.mark.asyncio
async def test_google_play_verifier_builds_correct_request(tmp_path, monkeypatch):
    """ダミーのサービスアカウント鍵でJWT生成〜APIコールの導線が動くことを確認する"""
    import json
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.hazmat.primitives import serialization
    from app.services.receipt_verification import GooglePlayVerifier
    from app.config import Settings

    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption(),
    ).decode("utf-8")

    key_path = tmp_path / "dummy-service-account.json"
    key_path.write_text(
        json.dumps({"client_email": "dummy@test.iam.gserviceaccount.com", "private_key": pem})
    )

    settings = Settings(
        database_url="sqlite+aiosqlite:///:memory:",
        secret_key="x" * 64,
        google_play_credentials_path=str(key_path),
    )

    class FakeResponse:
        def __init__(self, status_code, json_data, text=""):
            self.status_code = status_code
            self._json = json_data
            self.text = text

        def json(self):
            return self._json

    class FakeAsyncClient:
        async def post(self, url, data=None):
            assert url == "https://oauth2.googleapis.com/token"
            assert data["grant_type"] == "urn:ietf:params:oauth:grant-type:jwt-bearer"
            return FakeResponse(200, {"access_token": "fake-access-token"})

        async def get(self, url, headers=None):
            assert headers["Authorization"] == "Bearer fake-access-token"
            assert "/purchases/subscriptions/" in url
            return FakeResponse(200, {"paymentState": 1, "expiryTimeMillis": _future_ms(30)})

    verifier = GooglePlayVerifier(settings, http_client=FakeAsyncClient())
    result = await verifier.verify_subscription(
        package_name="jp.petitworks.shougaku_kore_doutoku",
        subscription_id="jp.petitworks.shougaku_kore_doutoku.monthly",
        purchase_token="token-abc",
    )
    assert result["paymentState"] == 1
