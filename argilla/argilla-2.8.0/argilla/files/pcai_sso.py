"""
PCAI SSO bridge for Argilla.

On HPE PCAI the Istio gateway's oauth2-proxy ext_authz replaces the request's
Authorization header with the user's Keycloak token, so Argilla never sees its own
login token and answers 401. This ASGI wrapper sits in front of argilla_server:app:

  * Authorization: Bearer <valid Argilla JWT>  -> passed through unchanged
  * Authorization: Bearer <Keycloak JWT>       -> signature verified against the realm
    JWKS (RS256, issuer checked); the user is looked up / created in Argilla and the
    header is replaced with an Argilla token for that user
  * anything else                               -> passed through unchanged

Keycloak realm roles are honoured on user creation and synced on change:
  argilla_role:owner|admin|annotator, argilla_workspace:<name>

Env:
  PCAI_SSO_ISSUER       https://keycloak.<domain>/realms/UA   (required)
  PCAI_SSO_WORKSPACES   comma separated default workspaces     (default: "default")
  PCAI_SSO_USERNAME_CLAIM                                       (default: preferred_username)

If Keycloak discovery fails at start-up (CA, DNS, Keycloak down), only the native
"Sign in with Keycloak" button is disabled; the server still starts.

Run with: UVICORN_APP=pcai_sso:app
"""

import asyncio
import logging
import os
import time

import httpx
from jose import jwt as jose_jwt
from jose.exceptions import JWTError

log = logging.getLogger("pcai_sso")
if not log.handlers:
    _h = logging.StreamHandler()
    _h.setFormatter(logging.Formatter("%(levelname)s:     [pcai_sso] %(message)s"))
    log.addHandler(_h)
    log.setLevel(logging.INFO)
    log.propagate = False


from argilla_server.security.settings import settings as _security_settings


def _preflight_native_oauth() -> None:
    """Argilla builds its Keycloak provider during start-up and exits if Keycloak's OIDC
    discovery fails (bad CA, DNS, Keycloak down). Check first and, if it is unreachable,
    disable only the "Sign in with Keycloak" button so the server still starts."""
    issuer = os.environ.get("PCAI_SSO_ISSUER", "").rstrip("/")
    cfg = _security_settings.oauth_cfg
    if not issuer or not cfg or not os.path.exists(cfg):
        return
    url = f"{issuer}/.well-known/openid-configuration"
    last = None
    for attempt in range(3):
        try:
            httpx.get(url, timeout=10).raise_for_status()
            return
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(3)
    logging.getLogger("pcai_sso").error(
        "Keycloak OIDC discovery failed (%s): %s -- 'Sign in with Keycloak' disabled. "
        "Check ezua.sso.issuer and ezua.sso.caCert.", url, last
    )
    _security_settings.oauth_cfg = "/nonexistent/oauth.yaml"


_preflight_native_oauth()

from argilla_server import app as argilla_app  # noqa: E402
from argilla_server.contexts import accounts
from argilla_server.database import AsyncSessionLocal
from argilla_server.enums import UserRole
from argilla_server.errors import UnauthorizedError
from argilla_server.models import Workspace, WorkspaceUser
from argilla_server.security.authentication.jwt import JWT

ISSUER = os.environ.get("PCAI_SSO_ISSUER", "").rstrip("/")
JWKS_URL = f"{ISSUER}/protocol/openid-connect/certs"
DEFAULT_WORKSPACES = [w.strip() for w in os.getenv("PCAI_SSO_WORKSPACES", "default").split(",") if w.strip()]
USERNAME_CLAIM = os.getenv("PCAI_SSO_USERNAME_CLAIM", "preferred_username")

_ROLE_RANK = {UserRole.annotator: 1, UserRole.admin: 2, UserRole.owner: 3}
_JWKS_TTL = 600
_TOKEN_TTL = 300


class _State:
    jwks = None
    jwks_at = 0.0
    lock = asyncio.Lock()
    # keycloak token -> (argilla token, cache expiry)
    cache = {}


async def _get_jwks(force: bool = False) -> dict:
    now = time.time()
    if not force and _State.jwks and now - _State.jwks_at < _JWKS_TTL:
        return _State.jwks
    async with _State.lock:
        if not force and _State.jwks and time.time() - _State.jwks_at < _JWKS_TTL:
            return _State.jwks
        # trust_env=True -> honours SSL_CERT_FILE (PCAI root CA bundle)
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(JWKS_URL)
            resp.raise_for_status()
            _State.jwks = resp.json()
            _State.jwks_at = time.time()
            log.info("loaded %d signing keys from %s", len(_State.jwks.get("keys", [])), JWKS_URL)
    return _State.jwks


async def _verify_keycloak(token: str):
    try:
        header = jose_jwt.get_unverified_header(token)
    except JWTError:
        return None
    if not header.get("alg", "").startswith("RS") or not header.get("kid"):
        return None

    jwks = await _get_jwks()
    if header["kid"] not in {k.get("kid") for k in jwks.get("keys", [])}:
        jwks = await _get_jwks(force=True)  # key rotation
    try:
        return jose_jwt.decode(
            token,
            jwks,
            algorithms=["RS256", "RS384", "RS512"],
            issuer=ISSUER,
            options={"verify_aud": False, "verify_at_hash": False},
        )
    except JWTError as e:
        log.warning("rejected Keycloak token: %s", e)
        return None


def _roles_from_claims(claims: dict):
    roles = (claims.get("realm_access") or {}).get("roles") or []
    role = None
    for r in roles:
        if r.startswith("argilla_role:"):
            try:
                candidate = UserRole(r.split(":", 1)[1])
            except ValueError:
                continue
            if role is None or _ROLE_RANK[candidate] > _ROLE_RANK[role]:
                role = candidate
    workspaces = [r.split(":", 1)[1] for r in roles if r.startswith("argilla_workspace:")]
    return role, workspaces


async def _argilla_token_for(claims: dict):
    username = claims.get(USERNAME_CLAIM) or claims.get("preferred_username") or claims.get("email")
    if not username:
        log.warning("Keycloak token has no %r claim", USERNAME_CLAIM)
        return None
    role, workspaces = _roles_from_claims(claims)
    workspaces = workspaces or DEFAULT_WORKSPACES

    async with AsyncSessionLocal() as db:
        user = await accounts.get_user_by_username(db, username)
        if user is None:
            for name in workspaces:
                if await Workspace.get_by(db, name=name) is None:
                    await Workspace.create(db, name=name, autocommit=False)
            user = await accounts.create_user_with_random_password(
                db,
                username=username,
                first_name=claims.get("given_name") or claims.get("name") or username,
                role=role or (UserRole.owner if username == os.getenv("USERNAME") else UserRole.annotator),
                workspaces=workspaces,
            )
            log.info("created Argilla user %r (role=%s, workspaces=%s)", username, user.role.value, workspaces)
        elif role is not None and user.role != role:
            user = await accounts.update_user(db, user=user, user_attrs={"role": role})
            log.info("synced role of %r to %s", username, role.value)
        return accounts.generate_user_token(user)


async def _translate(token: str):
    try:
        JWT.decode(token)
        return None  # already a valid Argilla token
    except UnauthorizedError:
        pass

    now = time.time()
    hit = _State.cache.get(token)
    if hit and hit[1] > now:
        return hit[0]

    claims = await _verify_keycloak(token)
    if claims is None:
        return None
    argilla_token = await _argilla_token_for(claims)
    if argilla_token:
        expiry = min(now + _TOKEN_TTL, float(claims.get("exp", now + _TOKEN_TTL)))
        if len(_State.cache) > 5000:
            _State.cache.clear()
        _State.cache[token] = (argilla_token, expiry)
    return argilla_token


class PcaiSSOMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http" and ISSUER:
            headers = scope.get("headers") or []
            auth = next((v for k, v in headers if k == b"authorization"), None)
            if auth and auth[:7].lower() == b"bearer ":
                try:
                    new_token = await _translate(auth[7:].decode("latin-1").strip())
                except Exception:  # never take the request down because of the bridge
                    log.exception("SSO bridge error")
                    new_token = None
                if new_token:
                    scope = dict(scope)
                    scope["headers"] = [(k, v) for k, v in headers if k != b"authorization"] + [
                        (b"authorization", b"Bearer " + new_token.encode())
                    ]
        await self.app(scope, receive, send)


if not ISSUER:
    log.warning("PCAI_SSO_ISSUER not set: SSO bridge disabled")

app = PcaiSSOMiddleware(argilla_app)
