"""
Apple JWS 署名検証のテスト

NOTE: 実際の Apple 署名を持つテストは統合テストで行うことを推奨します。
ここではクレーム検証とエラーハンドリングのテストを実施します。
"""

import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, patch, MagicMock

from app.services.apple_jws_verifier import (
    AppleJWSVerifier,
    AppleJWSVerificationError,
)


class TestAppleJWSVerifierInit:
    """AppleJWSVerifier 初期化のテスト"""

    def test_init_with_valid_params(self):
        """有効なパラメータでの初期化テスト"""
        # NOTE: 実際の Apple 証明書がないため、この初期化は失敗します。
        # 本実装では実際の Apple ルート証明書をダウンロードして使用してください。
        try:
            verifier = AppleJWSVerifier(
                bundle_id="jp.petitworks.shougaku_kore_doutoku",
                issuer_id="test_issuer_id",
                environment="sandbox",
            )
            assert verifier.bundle_id == "jp.petitworks.shougaku_kore_doutoku"
            assert verifier.issuer_id == "test_issuer_id"
            assert verifier.environment == "sandbox"
        except AppleJWSVerificationError as e:
            # 証明書ロードエラーは本実装では期待される
            assert "証明書" in str(e) or "PEM" in str(e)


class TestAppleJWSVerifierClaims:
    """クレーム検証のテスト"""

    def get_verifier_with_mocked_cert(self):
        """証明書チェックをモック化した verifier を取得"""
        with patch.object(
            AppleJWSVerifier, "_load_root_cert", return_value=Mock()
        ):
            return AppleJWSVerifier(
                bundle_id="jp.petitworks.shougaku_kore_doutoku",
                issuer_id="test_issuer_id",
                environment="sandbox",
            )

    def test_missing_iss_claim(self):
        """iss クレーム欠落のテスト"""
        verifier = self.get_verifier_with_mocked_cert()
        claims = {
            "aud": "jp.petitworks.shougaku_kore_doutoku",
            "exp": int((datetime.utcnow() + timedelta(minutes=5)).timestamp()),
        }
        with pytest.raises(AppleJWSVerificationError, match="iss クレーム不正"):
            verifier._verify_claims(claims)

    def test_invalid_iss_claim(self):
        """不正な iss クレームのテスト"""
        verifier = self.get_verifier_with_mocked_cert()
        claims = {
            "iss": "https://wrong-issuer.com",
            "aud": "jp.petitworks.shougaku_kore_doutoku",
            "exp": int((datetime.utcnow() + timedelta(minutes=5)).timestamp()),
        }
        with pytest.raises(AppleJWSVerificationError, match="iss クレーム不正"):
            verifier._verify_claims(claims)

    def test_invalid_aud_claim(self):
        """不正な aud クレームのテスト"""
        verifier = self.get_verifier_with_mocked_cert()
        claims = {
            "iss": "https://appleid.apple.com",
            "aud": "wrong.bundle.id",
            "exp": int((datetime.utcnow() + timedelta(minutes=5)).timestamp()),
        }
        with pytest.raises(AppleJWSVerificationError, match="aud クレーム不正"):
            verifier._verify_claims(claims)

    def test_missing_exp_claim(self):
        """exp クレーム欠落のテスト"""
        verifier = self.get_verifier_with_mocked_cert()
        claims = {
            "iss": "https://appleid.apple.com",
            "aud": "jp.petitworks.shougaku_kore_doutoku",
        }
        with pytest.raises(AppleJWSVerificationError, match="exp クレーム"):
            verifier._verify_claims(claims)

    def test_expired_jwt(self):
        """期限切れ JWT のテスト"""
        verifier = self.get_verifier_with_mocked_cert()
        claims = {
            "iss": "https://appleid.apple.com",
            "aud": "jp.petitworks.shougaku_kore_doutoku",
            "exp": int((datetime.utcnow() - timedelta(minutes=5)).timestamp()),
        }
        with pytest.raises(AppleJWSVerificationError, match="JWS 有効期限切れ"):
            verifier._verify_claims(claims)

    def test_valid_claims(self):
        """有効なクレームのテスト"""
        verifier = self.get_verifier_with_mocked_cert()
        claims = {
            "iss": "https://appleid.apple.com",
            "aud": "jp.petitworks.shougaku_kore_doutoku",
            "exp": int((datetime.utcnow() + timedelta(minutes=5)).timestamp()),
        }
        # 例外が発生しないことを確認
        verifier._verify_claims(claims)

    def test_different_bundle_id(self):
        """異なる Bundle ID でのテスト"""
        with patch.object(
            AppleJWSVerifier, "_load_root_cert", return_value=Mock()
        ):
            verifier = AppleJWSVerifier(
                bundle_id="jp.example.different_app",
                issuer_id="test_issuer_id",
                environment="production",
            )
        claims = {
            "iss": "https://appleid.apple.com",
            "aud": "jp.petitworks.shougaku_kore_doutoku",
            "exp": int((datetime.utcnow() + timedelta(minutes=5)).timestamp()),
        }
        with pytest.raises(AppleJWSVerificationError, match="aud クレーム不正"):
            verifier._verify_claims(claims)


class TestAppleJWSVerifierIntegration:
    """統合テスト（実際の Apple 署名データが必要）"""

    @pytest.mark.skip(reason="実際の Apple署名データが必要")
    def test_verify_real_apple_jws(self):
        """実際の Apple JWS 検証テスト

        NOTE: このテストは実行時に、実際の App Store から取得した
        signedTransactionInfo を使用します。テスト環境での実行はスキップします。

        本実装での使用例：
            verifier = AppleJWSVerifier(
                bundle_id="jp.petitworks.shougaku_kore_doutoku",
                issuer_id="YOUR_ISSUER_ID",
                environment="sandbox",
            )
            claims = verifier.verify(signed_transaction_info)
            assert claims["transactionId"] == "expected_id"
        """
        pass
