import { Fault } from "./http.mjs";
// Only data fields used by reader DTOs; arbitrary upstream extension keys never cross.
const keys = new Set(
  `user userDefaultLibraryId serverSettings version serverVersion id username email type isActive isLocked permissions accessAllLibraries accessAllTags selectedTagsNotAccessible accessExplicitContent download update delete upload librariesAccessible itemTagsSelected mediaProgress bookmarks seriesHideFromContinueListening lastSeen createdAt name displayOrder mediaType icon provider settings language libraries results total limit page numPages numItems entities books items libraryItems libraryItem book series authors narrators tags genres collections title subtitle authorName authorNameLF authorNameLastFirst narratorName seriesName volumeName publishedYear publishedDate publisher description isbn asin language explicit abridged numTracks numAudioFiles numChapters numMissingParts numInvalidAudioFiles numEbooks size duration media metadata chapters tracks audioTracks audioFiles ebookFile libraryId libraryItemId episodeId mediaItemId mediaItemType userId bookId start end index startOffset mimeType codec coverAspectRatio coverPath addedAt updatedAt mtimeMs ctimeMs birthtimeMs userMediaProgress progress currentTime isFinished hideFromContinueListening ebookLocation ebookProgress lastUpdate startedAt finishedAt timeListening startTime playMethod mediaPlayer deviceInfo deviceId clientName clientVersion displayTitle displayAuthor date dayOfWeek episodes season episode episodeType enclosure pubDate author imagePath filterdata year count totalBooks totalDuration itemsPerPage sessions sessionId day days listeningStats today recentSessions totalTime`.split(
    /\s+/,
  ),
);
export function sanitize(value, itemId) {
  if (Array.isArray(value)) return value.map((x) => sanitize(x, itemId));
  if (!value || typeof value !== "object") return value;
  if (value.media && typeof value.id === "string" && /^[A-Za-z0-9_-]+$/.test(value.id))
    itemId = value.id;
  const result = {};
  for (const [key, v] of Object.entries(value)) {
    // Flutter uses this as a nonempty presence gate, never as the cover URL.
    // Keep filesystem paths private; the client constructs the item cover route.
    if (key === "ino") {
      if ((typeof v === "string" && /^[A-Za-z0-9_-]+$/.test(v)) ||
        (Number.isSafeInteger(v) && v >= 0)) result.ino = v;
      continue;
    }
    if (["label", "sequence", "numBooks"].includes(key)) {
      if ((typeof v === "string" && key !== "numBooks") ||
        (typeof v === "number" && Number.isFinite(v) && key !== "label"))
        result[key] = v;
      continue;
    }
    if (key === "collapsedSeries" || key === "libraryItemIds") {
      result[key] = sanitize(v, itemId);
      continue;
    }
    if (key === "contentUrl") {
      // Expanded item tracks may expose only this item's validated direct route.
      // No external authority, filesystem path, query credential or cross-item URL.
      const path = typeof v === "string" ? v.split("?")[0] : "";
      if (itemId && new RegExp(`^/api/items/${itemId}/file/[A-Za-z0-9_-]+$`).test(path))
        result.contentUrl = path;
      continue;
    }
    if (key === "coverPath") {
      if (typeof v === "string" && v.length) result.coverPath = "browser-cover";
      continue;
    }
    if (
      !keys.has(key) ||
      /token|password|secret|cookie|authorization/i.test(key) ||
      ["coverPath", "imagePath"].includes(key)
    )
      continue;
    if (key === "metadata" && value.contentUrl !== undefined) continue;
    result[key] = sanitize(v, itemId);
  }
  if (typeof value.username === "string" && typeof value.id === "string") {
    result.accessToken = "browser-cookie";
    result.refreshToken = "browser-cookie";
  }
  return result;
}
export async function getJSON(authorized, session, path, init) {
  const r = await authorized(session, path, init);
  if (!r.ok) {
    await r.body?.cancel();
    throw new Fault(
      r.status >= 400 && r.status < 500 ? r.status : 502,
      "upstream_rejected",
    );
  }
  return r.json();
}
export async function accessible(authorized, session, { entities = false } = {}) {
  const data = await getJSON(authorized, session, "/api/libraries");
  if (!Array.isArray(data.libraries))
    throw new Fault(502, "permission_enumeration_failed");
  const ids = new Set();
  const libraries = new Set();
  const authors = new Map(), series = new Map(), itemLibraries = new Map();
  const names = { narrators: new Map(), tags: new Map(), genres: new Map() };
  for (const lib of data.libraries) {
    if (!/^[A-Za-z0-9_-]+$/.test(lib.id))
      throw new Fault(502, "permission_enumeration_failed");
    libraries.add(lib.id);
    let total;
    let seen = new Set();
    for (let page = 0; page < 10000; page++) {
      const batch = await getJSON(
        authorized,
        session,
        `/api/libraries/${lib.id}/items?limit=200&page=${page}`,
      );
      if (
        !Number.isSafeInteger(batch.total) ||
        batch.total < 0 ||
        batch.total > 1000000 ||
        !Array.isArray(batch.results) ||
        (total !== undefined && total !== batch.total)
      )
        throw new Fault(502, "permission_enumeration_failed");
      total = batch.total;
      for (const item of batch.results) {
        if (typeof item?.id !== "string" || !/^[A-Za-z0-9_-]+$/.test(item.id) || ids.has(item.id) ||
          (item.libraryId !== undefined && item.libraryId !== lib.id))
          throw new Fault(502, "permission_enumeration_failed");
        seen.add(item.id);
        ids.add(item.id);
        itemLibraries.set(item.id, lib.id);
      }
      if (seen.size === total) break;
      if (!batch.results.length || seen.size > total || page === 9999)
        throw new Fault(502, "permission_enumeration_failed");
    }
  }
  // ABS 2.36 list pages ALWAYS use toOldJSONMinified: display names are
  // not identities. Read expanded associations only for entity-bearing routes.
  // This POST is a private read, never part of the browser write allowlist.
  if (entities) {
    const all = [...ids];
    for (let offset = 0; offset < all.length; offset += 100) {
      const requested = all.slice(offset, offset + 100);
      const batch = await getJSON(authorized, session, "/api/items/batch/get", {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ libraryItemIds: requested }),
      });
      const pending = new Set(requested);
      if (!Array.isArray(batch?.libraryItems) || batch.libraryItems.length !== pending.size)
        throw new Fault(502, "permission_enumeration_failed");
      for (const item of batch.libraryItems) {
        if (!item || !pending.delete(item.id) || item.libraryId !== itemLibraries.get(item.id) ||
          !item.media?.metadata || typeof item.media.metadata !== "object")
          throw new Fault(502, "permission_enumeration_failed");
        for (const [key, map] of [["authors", authors], ["series", series]]) {
          const raw = item.media.metadata[key];
          if (raw !== undefined && !Array.isArray(raw))
            throw new Fault(502, "permission_enumeration_failed");
          for (const entity of raw ?? []) {
            if (typeof entity?.id !== "string" || !/^[A-Za-z0-9_-]+$/.test(entity.id))
              throw new Fault(502, "permission_enumeration_failed");
            if (!map.has(entity.id)) map.set(entity.id, new Set());
            map.get(entity.id).add(item.id);
          }
        }
        for (const [key, map] of Object.entries(names)) {
          const raw = key === "tags" ? item.media.tags : item.media.metadata[key];
          if (raw !== undefined && (!Array.isArray(raw) || raw.some((name) => typeof name !== "string")))
            throw new Fault(502, "permission_enumeration_failed");
          for (const name of raw ?? []) {
            if (!map.has(name)) map.set(name, new Set());
            map.get(name).add(item.id);
          }
        }
      }
      if (session.revoked) throw new Fault(401, "authentication_expired");
    }
  }
  return { ids, libraries, authors, series, itemLibraries, ...names };
}
export function filterItems(value, ids, scope, kind) {
  if (Array.isArray(value))
    return value.map((x) => filterItems(x, ids, scope, kind)).filter((x) => x !== undefined);
  let associated;
  if (scope && ["authors", "series", "narrators", "tags", "genres"].includes(kind)) {
    const entity = kind === "series" && value?.series && !Array.isArray(value.series) ? value.series : value;
    const key = ["authors", "series"].includes(kind) ? entity?.id
      : typeof entity === "string" ? entity : entity?.name;
    associated = new Set([...(scope[kind].get(key) ?? [])].filter((id) => ids.has(id)));
    if (!associated.size) return undefined;
  }
  if (!value || typeof value !== "object") return value;
  if (typeof value.libraryItemId === "string" && !ids.has(value.libraryItemId))
    return undefined;
  if (value.id && value.media && !ids.has(value.id)) return undefined;
  if (
    value.libraryItem &&
    value.libraryItem.id &&
    !ids.has(value.libraryItem.id)
  )
    return undefined;
  if (value.book?.id && !ids.has(value.book.id)) return undefined;
  const out = {};
  let filteredLength;
  for (const [key, v] of Object.entries(value)) {
    // Context comes from pinned DTO keys, list routes and shelf type, never an arbitrary id.
    // ABS 2.36 sums every associated book for this series aggregate, even
    // when its nested books are permission-filtered. Do not release that sum.
    if (kind === "series" && key === "totalDuration") continue;
    const childKind = ["authors", "series", "narrators", "tags", "genres"].includes(key) ? key
      : key === "results" ? kind?.replace(/-list$/, "")
      : key === "entities" && ["authors", "series"].includes(value.type) ? value.type : undefined;
    const next = key === "libraryItemIds"
      ? (Array.isArray(v) ? [...new Set(v.filter((id) => typeof id === "string" && ids.has(id)))] : [])
      : filterItems(v, ids, key === "metadata" ? undefined : scope, childKind);
    if (next !== undefined) out[key] = next;
    if (scope && childKind && Array.isArray(next)) filteredLength = next.length;
    if (
      ["books", "items", "libraryItems", "entities", "results", "libraryItemIds"].includes(key) &&
      Array.isArray(next)
    ) {
      if (next.length !== (Array.isArray(v) ? v.length : 0)) filteredLength = next.length;
      if (!next.length && key !== "results") return undefined;
    }
  }
  const count = associated?.size ?? filteredLength;
  if (count !== undefined) {
    for (const key of ["total", "count", "numBooks", "totalBooks", "numItems"])
      if (key in out) out[key] = count;
  }
  return out;
}
const ID = "[A-Za-z0-9_-]+";
export const readAllowed = new RegExp(
  `^/api/(?:libraries|libraries/${ID}(?:/(?:items|search|personalized|series|authors|narrators)|/series/${ID})?|items/${ID}|authors/${ID}|series/${ID}|me/(?:progress(?:/${ID}(?:/${ID})?)?|bookmarks|listening-sessions|listening-stats|item/listening-sessions/${ID}(?:/${ID})?))$`,
);
const queries = new Set([
  "limit",
  "page",
  "itemsPerPage",
  "sort",
  "desc",
  "filter",
  "collapseSeries",
  "collapseseries",
  "shelves",
  "minified",
  "expanded",
  "include",
  "library",
  "q",
  "type",
  "series",
  "author",
  "width",
  "height",
  "format",
]);
export function readQuery(url) {
  const out = new URLSearchParams();
  for (const [key, v] of url.searchParams) {
    if (key === "token") continue;
    if (key === "library" && (!/^[A-Za-z0-9_-]+$/.test(v) || url.searchParams.getAll(key).length !== 1))
      throw new Fault(400, "unsupported_query");
    if (!queries.has(key) || v.length > 2048)
      throw new Fault(400, "unsupported_query");
    out.append(key, v);
  }
  return out.size ? "?" + out : "";
}
