import { Fault } from "./http.mjs";
import { sanitize } from "./reads.mjs";
export function credentials(data, expected) {
  const u = data?.user;
  if (
    !u ||
    typeof u.id !== "string" ||
    (expected && u.id !== expected) ||
    typeof u.accessToken !== "string" ||
    !u.accessToken ||
    typeof u.refreshToken !== "string" ||
    !u.refreshToken
  )
    throw new Fault(502, "invalid_auth_response");
  return { access: u.accessToken, refresh: u.refreshToken, userId: u.id };
}
export function userDTO(user) {
  const out = {};
  for (const key of [
    "id",
    "username",
    "email",
    "type",
    "isActive",
    "isLocked",
    "permissions",
    "librariesAccessible",
    "itemTagsSelected",
    "seriesHideFromContinueListening",
    "lastSeen",
    "createdAt",
  ])
    if (user[key] !== undefined) out[key] = sanitize(user[key]);
  out.mediaProgress = [];
  out.bookmarks = [];
  out.accessToken = "browser-cookie";
  out.refreshToken = "browser-cookie";
  return out;
}
export function envelopeDTO(data) {
  return {
    user: userDTO(data.user),
    userDefaultLibraryId:
      typeof data.userDefaultLibraryId === "string"
        ? data.userDefaultLibraryId
        : null,
    serverSettings: sanitize(data.serverSettings ?? {}),
  };
}
export function authClient(call) {
  async function refresh(session) {
    if (session.revoked) throw new Fault(401, "authentication_expired");
    if (!session.refreshing)
      session.refreshing = (async () => {
        const r = await (session.call ?? call)("/auth/refresh", {
          method: "POST",
          headers: { "x-refresh-token": session.refresh },
        });
        if (r.status !== 200) {
          await r.body?.cancel();
          session.revoked = true;
          throw new Fault(401, "authentication_expired");
        }
        const data = await r.json();
        const next = credentials(data, session.userId);
        // Keep the rotated pair privately so retirement can revoke it. Never un-revoke.
        Object.assign(session, next);
        if (session.revoked) throw new Fault(401, "authentication_expired");
        return data;
      })()
        .catch((e) => {
          session.revoked = true;
          throw e;
        })
        .finally(() => {
          session.refreshing = null;
        });
    return session.refreshing;
  }
  async function authorized(session, path, init = {}, retry = true) {
    if (session.revoked) throw new Fault(401, "authentication_expired");
    const access = session.access;
    let r = await (session.call ?? call)(path, {
      ...init,
      headers: { ...init.headers, Authorization: `Bearer ${access}` },
    });
    if (r.status === 401 && retry) {
      await r.body?.cancel();
      if (session.access === access) await refresh(session);
      r = await authorized(session, path, init, false);
    }
    return r;
  }
  return { refresh, authorized };
}
