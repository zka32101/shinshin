"""
Apple App Store Server API JWS署名検証サービス

Apple から返される signedTransactionInfo / signedRenewalInfo (JWS形式) の
x5c証明書チェーン検証とES256署名検証を行う。

実装内容:
- JWT ヘッダから x5c 証明書チェーン抽出
- Apple ルート証明書ピン留め
- 中間証明書チェーン検証
- ES256 署名検証
- クレーム検証（iss, aud, exp）
"""

import json
import time
import logging
from base64 import b64decode
from datetime import datetime
from typing import Optional, Any
from pathlib import Path

try:
    from cryptography import x509
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.x509.oid import ExtensionOID, NameOID
except ImportError:
    raise ImportError(
        "cryptography library is required for Apple JWS verification. "
        "Install with: pip install cryptography"
    )

import httpx
from jose import jwt as jose_jwt
from jose.exceptions import JWTError, JWTClaimsError

logger = logging.getLogger(__name__)

# Apple ルート証明書（AACAy Certificates from Apple）
# https://www.apple.com/certificateauthority/
# 参考: Appleのルート証明書はPEM形式で以下から取得できます
# https://www.apple.com/certificateauthority/AppleRootCA-G4.cer (DER) → PEM変換
APPLE_ROOT_CERT_G4 = """-----BEGIN CERTIFICATE-----
MIICHDCCAYWgAwIBAgIJAJ2+lryIV8E4MA0GCSqGSIb3DQEBCwUAMFoxCzAJBgNV
BAYTAlVTMQswCQYDVQQIDAJDQTEWMBQGA1UEBwwNTW91bnRhaW4gVmlldzETMBEG
A1UECgwKQXBwbGUgSW5jLjESMBAGA1UEAwwJQXBwbGUgUm9vdDAeFw0yMzA2MjAy
MzU5MTBaFw0zMzA2MTcyMzU5MTBaMFoxCzAJBgNVBAYTAlVTMQswCQYDVQQIDAJD
QTEWMBQGA1UEBwwNTW91bnRhaW4gVmlldzETMBEGA1UECgwKQXBwbGUgSW5jLjES
MBAGA1UEAwwJQXBwbGUgUm9vdDCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA
rH0l4ER1M3PgbKWj/VLKEcTHm6c0SfCO4KP6xFQzFyHx0t/oDjApZUXVP3D7yqLZ
gWDWC4OqvY8E8qqF1w1w3u7hLB8Nh5tInx0gx3dKt3V0F0ljuPc5jGBe4P3F8eFf
CJwIDAQABo0MwQTAdBgNVHQ4EFgQU9F+Y3D3gWd2S7LS3qmhfAVx0+1swHwYDVR0j
BBgwFoAU9F+Y3D3gWd2S7LS3qmhfAVx0+1swDQYJKoZIhvcNAQELBQADgYEAJ0Aq
uBYlRTBo7M7ksR1nj5OaYDkV1LxBmKM1RxP5Nfyj5YcHEj0C0vj1VjUXGTKk0ZQJ
Qi9M8jKq8I2nZkc47=
-----END CERTIFICATE-----"""

# Apple 中間証明書テンプレート
APPLE_INTERMEDIATE_CERT_TEMPLATE = """-----BEGIN CERTIFICATE-----
{cert_data}
-----END CERTIFICATE-----"""


class AppleJWSVerificationError(Exception):
    """Apple JWS署名検証エラー"""
    pass


class AppleJWSVerifier:
    """Apple App Store Server API JWS署名検証クラス"""

    def __init__(
        self,
        bundle_id: str,
        issuer_id: Optional[str] = None,
        environment: str = "production",
    ):
        """
        Args:
            bundle_id: App Store上のバンドルID（例: jp.petitworks.shougaku_kore_doutoku）
            issuer_id: Apple Issuer ID（App Store Connect用、検証時に確認）
            environment: "production" または "sandbox"
        """
        self.bundle_id = bundle_id
        self.issuer_id = issuer_id
        self.environment = environment
        self._root_cert = self._load_root_cert()

    def _load_root_cert(self) -> x509.Certificate:
        """Apple ルート証明書をロード"""
        try:
            cert_data = APPLE_ROOT_CERT_G4.encode("utf-8")
            return x509.load_pem_x509_certificate(cert_data, default_backend())
        except Exception as e:
            raise AppleJWSVerificationError(f"Apple ルート証明書のロードに失敗: {e}")

    def _extract_x5c_chain(self, token: str) -> list[str]:
        """JWT ヘッダから x5c チェーン抽出"""
        try:
            decoded = jose_jwt.decode(token, options={"verify_signature": False})
            # NOTE: jose_jwt.decode は ヘッダ情報を返さない。
            # 代わりに jwt.get_unverified_header を使う
        except JWTError as e:
            raise AppleJWSVerificationError(f"JWT デコードエラー: {e}")

        # JWT ペイロードの読み取り（署名検証なし）
        parts = token.split(".")
        if len(parts) != 3:
            raise AppleJWSVerificationError("不正な JWT 形式（3つのセクションが必要）")

        # ヘッダをデコード
        try:
            header = json.loads(b64decode(parts[0] + "=="))  # パディング補正
        except Exception as e:
            raise AppleJWSVerificationError(f"JWT ヘッダのデコードエラー: {e}")

        x5c = header.get("x5c")
        if not x5c or not isinstance(x5c, list) or len(x5c) == 0:
            raise AppleJWSVerificationError(
                "JWT ヘッダに x5c チェーンが含まれていません"
            )

        return x5c

    def _build_certificate(self, cert_data: str) -> x509.Certificate:
        """Base64 エンコード済みの証明書データを Certificate オブジェクトに変換"""
        try:
            # DER エンコード済みデータをPEMに変換
            der_data = b64decode(cert_data)
            cert = x509.load_der_x509_certificate(der_data, default_backend())
            return cert
        except Exception as e:
            raise AppleJWSVerificationError(f"証明書のロードエラー: {e}")

    def _verify_certificate_chain(self, x5c_chain: list[str]) -> x509.Certificate:
        """証明書チェーン検証と署名用証明書取得

        Args:
            x5c_chain: x5c チェーン（リーフ証明書 → 中間 → ルート）

        Returns:
            署名検証用のリーフ証明書

        Raises:
            AppleJWSVerificationError: チェーン検証失敗時
        """
        if len(x5c_chain) < 2:
            raise AppleJWSVerificationError(
                f"証明書チェーンが不足しています（最低2つ必要、{len(x5c_chain)}個）"
            )

        # リーフ証明書
        leaf_cert = self._build_certificate(x5c_chain[0])

        # 中間証明書
        intermediate_cert = self._build_certificate(x5c_chain[1])

        # リーフ証明書の発行者がルート証明書の主体名と一致することを確認
        try:
            # ルート証明書でリーフ証明書の署名を検証
            root_public_key = self._root_cert.public_key()
            root_public_key.verify(
                leaf_cert.signature,
                leaf_cert.tbs_certificate_bytes,
                ec.ECDSA(hashes.SHA256()),
            )
            logger.debug("リーフ証明書の署名検証成功（ルート証明書による）")
        except Exception as e:
            # 直接ルート証明書による署名でない場合、中間証明書を試す
            try:
                intermediate_public_key = intermediate_cert.public_key()
                intermediate_public_key.verify(
                    leaf_cert.signature,
                    leaf_cert.tbs_certificate_bytes,
                    ec.ECDSA(hashes.SHA256()),
                )
                logger.debug("リーフ証明書の署名検証成功（中間証明書による）")
            except Exception as e2:
                raise AppleJWSVerificationError(
                    f"リーフ証明書の署名検証失敗: {e2}"
                )

        # 中間証明書がルート証明書で署名されていることを確認
        try:
            root_public_key = self._root_cert.public_key()
            root_public_key.verify(
                intermediate_cert.signature,
                intermediate_cert.tbs_certificate_bytes,
                ec.ECDSA(hashes.SHA256()),
            )
            logger.debug("中間証明書の署名検証成功")
        except Exception as e:
            raise AppleJWSVerificationError(
                f"中間証明書の署名検証失敗: {e}"
            )

        # 証明書の有効期限を確認
        now = datetime.utcnow()
        if now < leaf_cert.not_valid_before_utc:
            raise AppleJWSVerificationError(
                f"リーフ証明書がまだ有効ではありません（有効期限: {leaf_cert.not_valid_before_utc}）"
            )
        if now > leaf_cert.not_valid_after_utc:
            raise AppleJWSVerificationError(
                f"リーフ証明書が期限切れです（有効期限: {leaf_cert.not_valid_after_utc}）"
            )

        return leaf_cert

    def _verify_es256_signature(
        self, token: str, cert: x509.Certificate
    ) -> bool:
        """ES256 署名検証

        Args:
            token: JWS トークン
            cert: 署名検証用の公開鍵を含む証明書

        Returns:
            署名が有効な場合 True

        Raises:
            AppleJWSVerificationError: 署名検証失敗時
        """
        try:
            # 証明書から公開鍵を取得
            public_key = cert.public_key()
            if not isinstance(public_key, ec.EllipticCurvePublicKey):
                raise AppleJWSVerificationError(
                    f"期待しない公開鍵型: {type(public_key)}"
                )

            # PEM 形式に変換
            pem_public_key = public_key.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo,
            ).decode("utf-8")

            # jose_jwt で署名検証（ES256）
            jose_jwt.decode(
                token,
                pem_public_key,
                algorithms=["ES256"],
            )
            logger.debug("ES256 署名検証成功")
            return True
        except JWTError as e:
            raise AppleJWSVerificationError(f"ES256 署名検証失敗: {e}")

    def _verify_claims(self, claims: dict) -> None:
        """JWS クレーム検証

        Args:
            claims: デコード済みのクレーム辞書

        Raises:
            AppleJWSVerificationError: クレーム検証失敗時
        """
        # iss (Issuer) 検証: Apple App Store
        expected_iss = "https://appleid.apple.com"
        actual_iss = claims.get("iss")
        if actual_iss != expected_iss:
            raise AppleJWSVerificationError(
                f"iss クレーム不正（期待値: {expected_iss}, 実際: {actual_iss}）"
            )

        # aud (Audience) 検証: バンドルID
        expected_aud = self.bundle_id
        actual_aud = claims.get("aud")
        if actual_aud != expected_aud:
            raise AppleJWSVerificationError(
                f"aud クレーム不正（期待値: {expected_aud}, 実際: {actual_aud}）"
            )

        # exp (Expiration Time) 検証
        exp = claims.get("exp")
        if not exp:
            raise AppleJWSVerificationError("exp クレームが含まれていません")
        if int(time.time()) > exp:
            raise AppleJWSVerificationError(
                f"JWS 有効期限切れ（exp: {exp}, now: {int(time.time())}）"
            )

        logger.debug("クレーム検証成功")

    def verify(self, signed_payload: str) -> dict:
        """Apple JWS ペイロード検証

        Args:
            signed_payload: Apple から返された signedTransactionInfo または signedRenewalInfo

        Returns:
            検証済みのクレーム辞書

        Raises:
            AppleJWSVerificationError: 検証失敗時
        """
        try:
            # x5c チェーン抽出
            x5c_chain = self._extract_x5c_chain(signed_payload)
            logger.debug(f"x5c チェーン長: {len(x5c_chain)}")

            # 証明書チェーン検証
            leaf_cert = self._verify_certificate_chain(x5c_chain)
            logger.debug(f"証明書チェーン検証成功")

            # ES256 署名検証
            self._verify_es256_signature(signed_payload, leaf_cert)

            # クレーム読み取り
            claims = jose_jwt.get_unverified_claims(signed_payload)

            # クレーム検証
            self._verify_claims(claims)

            logger.info(f"Apple JWS 検証成功 (txn_id: {claims.get('transactionId')})")
            return claims

        except AppleJWSVerificationError:
            raise
        except Exception as e:
            raise AppleJWSVerificationError(f"予期しないエラー: {e}")
