"""PCAI Keycloak pluggable auth service for Langflow 1.10.0.

Registered at runtime via lfx.toml:

    [services]
    auth_service = "pcai_keycloak.auth:KeycloakAuthService"

No custom Docker image is required. This module is mounted onto PYTHONPATH from
a ConfigMap and discovered by lfx's ServiceManager (config-file discovery path),
which registers it as the `auth_service`, overriding the built-in JWT factory.

Topology (PCAI / EzUA):
    The Istio gateway runs oauth2-proxy via a CUSTOM AuthorizationPolicy. That
    proxy performs the interactive Keycloak OIDC redirect/callback and forwards
    the authenticated identity to Langflow as a bearer token. Langflow itself
    therefore needs no login-redirect routes; it only validates the forwarded
    token and JIT-provisions the user.

Split-horizon OIDC:
    OIDC_ISSUER   -> external HTTPS issuer URL, used to verify the `iss` claim.
    OIDC_JWKS_URL -> internal in-cluster certs endpoint, used to fetch signing keys.
"""

from __future__ import annotations

import os
import secrets
from datetime import datetime, timezone

import jwt
from jwt import PyJWKClient

from langflow.services.auth.exceptions import (
    InactiveUserError,
    InvalidTokenError,
)
from langflow.services.auth.service import AuthService
from langflow.services.database.models import SSOUserProfile
from langflow.services.database.models.user.crud import get_user_by_username
from langflow.services.database.models.user.model import User
from lfx.log.logger import logger
from sqlmodel import select

SSO_PROVIDER = os.getenv("OIDC_PROVIDER_NAME", "keycloak")


def _env(name: str, default: str | None = None) -> str | None:
    val = os.getenv(name, default)
    return val.strip() if isinstance(val, str) else val


class KeycloakAuthService(AuthService):
    """Subclasses the stock JWT AuthService.

    Inherits the complete ``BaseAuthService`` surface (API keys, token issuance,
    superuser creation, MCP auth, encryption). Only token verification is
    overridden so that:
      * locally-issued Langflow JWTs still work (superuser / API-key flows), and
      * Keycloak-issued OIDC access tokens are accepted and JIT-provisioned.
    """

    def __init__(self, settings_service) -> None:
        super().__init__(settings_service)
        self.issuer = _env("OIDC_ISSUER")                                  # external (iss check)
        self.jwks_url = _env("OIDC_JWKS_URL")                              # internal (key fetch)
        self.audience = _env("OIDC_AUDIENCE")                              # optional aud check
        self.username_claim = _env("OIDC_USERNAME_CLAIM", "preferred_username")
        self.email_claim = _env("OIDC_EMAIL_CLAIM", "email")
        self._jwks_client: PyJWKClient | None = None
        if self.jwks_url:
            # PyJWKClient caches keys in-memory and matches by `kid`.
            self._jwks_client = PyJWKClient(self.jwks_url, cache_keys=True)
        logger.info(
            f"KeycloakAuthService active (provider={SSO_PROVIDER}, "
            f"issuer={self.issuer}, jwks={self.jwks_url})"
        )

    # ------------------------------------------------------------------ #
    # Token verification                                                 #
    # ------------------------------------------------------------------ #
    async def _authenticate_with_token(self, token: str, db) -> User:
        # 1) Stock path first: locally-issued Langflow access tokens
        #    (superuser login, refresh tokens, internal calls).
        try:
            return await super()._authenticate_with_token(token, db)
        except Exception:  # noqa: BLE001 - not a local token; try OIDC next
            pass

        # 2) Validate as a Keycloak OIDC token.
        if not self._jwks_client or not self.issuer:
            msg = "OIDC not configured (OIDC_ISSUER / OIDC_JWKS_URL missing)"
            raise InvalidTokenError(msg)

        try:
            signing_key = self._jwks_client.get_signing_key_from_jwt(token)
            claims = jwt.decode(
                token,
                signing_key.key,
                algorithms=["RS256"],
                issuer=self.issuer,
                audience=self.audience if self.audience else None,
                options={"verify_aud": bool(self.audience), "verify_exp": True},
            )
        except jwt.ExpiredSignatureError as exc:
            msg = "OIDC token expired"
            raise InvalidTokenError(msg) from exc
        except Exception as exc:  # noqa: BLE001
            logger.warning(f"OIDC token validation failed: {exc}")
            msg = "Invalid OIDC token"
            raise InvalidTokenError(msg) from exc

        user = await self.get_or_create_user_from_claims(claims, db)
        if not user.is_active:
            msg = "User account is inactive"
            raise InactiveUserError(msg)
        return user

    # ------------------------------------------------------------------ #
    # JIT provisioning                                                   #
    # ------------------------------------------------------------------ #
    def extract_user_info_from_claims(self, claims: dict) -> dict:
        sub = claims.get("sub")
        email = claims.get(self.email_claim)
        username = claims.get(self.username_claim) or email or (f"kc-{sub}" if sub else None)
        return {"sub": sub, "email": email, "username": username}

    async def get_or_create_user_from_claims(self, claims: dict, db) -> User:
        info = self.extract_user_info_from_claims(claims)
        sub = info["sub"]
        if not sub:
            msg = "OIDC token missing 'sub' claim"
            raise InvalidTokenError(msg)

        now = datetime.now(timezone.utc)

        # a) Existing SSO profile -> existing user (fast path).
        profile = (
            await db.exec(
                select(SSOUserProfile).where(
                    SSOUserProfile.sso_provider == SSO_PROVIDER,
                    SSOUserProfile.sso_user_id == sub,
                )
            )
        ).first()
        if profile is not None:
            user = await db.get(User, profile.user_id)
            if user is not None:
                profile.sso_last_login_at = now
                profile.updated_at = now
                user.last_login_at = now
                db.add(profile)
                db.add(user)
                await db.commit()
                await db.refresh(user)
                return user

        # b) Match an existing local user by username (email-as-username links
        #    a pre-existing account on first SSO login).
        username = info["username"]
        user = await get_user_by_username(db, username)

        # c) Create a new user with no usable local password.
        if user is None:
            user = User(
                username=username,
                password=self.settings.auth_settings.pwd_context.hash(secrets.token_urlsafe(32)),
                is_active=True,  # the gateway already authenticated them via Keycloak
                is_superuser=False,
                last_login_at=now,
            )
            db.add(user)
            await db.commit()
            await db.refresh(user)
            logger.info(f"JIT-provisioned SSO user '{username}' (sub={sub})")

        # Link / refresh the SSO profile for this user.
        profile = SSOUserProfile(
            user_id=user.id,
            sso_provider=SSO_PROVIDER,
            sso_user_id=sub,
            email=info["email"],
            sso_last_login_at=now,
        )
        db.add(profile)
        await db.commit()
        await db.refresh(user)
        return user


# ---------------------------------------------------------------------------- #
# Make the stock /api/v1/session endpoint read the token oauth2-proxy forwards.
#
# Stock 1.10.0 lazily does `from langflow.services.auth.utils import oauth2_login`
# inside the /session route but ships no definition of it (the SSO plugin is
# expected to supply it). We install it here at import time. Plugin import runs
# during ServiceManager.discover_plugins() on the first auth_service request
# (startup superuser bootstrap), i.e. before any /session call is served.
# ---------------------------------------------------------------------------- #
def _install_oauth2_login() -> None:
    import langflow.services.auth.utils as auth_utils

    async def oauth2_login(request) -> str | None:
        # oauth2-proxy forwards the IdP token in one of these carriers,
        # depending on its --pass-* / --set-* flags. Check in priority order.
        auth = request.headers.get("Authorization") or request.headers.get("authorization")
        if auth and auth.lower().startswith("bearer "):
            return auth.split(" ", 1)[1].strip()
        for header in ("X-Forwarded-Access-Token", "X-Auth-Request-Access-Token", "X-Id-Token"):
            value = request.headers.get(header)
            if value:
                return value.strip()
        for cookie in ("access_token_lf", "access_token", "_oauth2_proxy"):
            value = request.cookies.get(cookie)
            if value:
                return value
        return None

    auth_utils.oauth2_login = oauth2_login  # type: ignore[attr-defined]
    logger.info("Installed oauth2_login token extractor for /api/v1/session")


_install_oauth2_login()
