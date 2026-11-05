"""Robot de stats : lit les vues / j'aime / commentaires / partages de chaque clip via Apify,
met à jour Supabase et garde l'historique (courbes). Lancé par GitHub Actions toutes les 12 h.
Secrets GitHub nécessaires : SUPABASE_URL, SUPABASE_SERVICE_KEY, APIFY_TOKEN."""
import json, os, re, sys, urllib.request
from datetime import datetime, timezone

SB = os.environ["SUPABASE_URL"].rstrip("/")
KEY = os.environ["SUPABASE_SERVICE_KEY"]
APIFY = os.environ["APIFY_TOKEN"]
ACTOR = os.environ.get("APIFY_ACTOR", "clockworks~tiktok-scraper")
H = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}


def req(method, url, body=None, headers=None, timeout=60):
    r = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body is not None else None,
                               headers={**H, **(headers or {})} if url.startswith(SB) else {"Content-Type": "application/json"})
    with urllib.request.urlopen(r, timeout=timeout) as f:
        t = f.read().decode()
        return json.loads(t) if t else None


def vid(u):
    m = re.search(r"/(?:video|photo)/(\d+)", u or "")
    return m.group(1) if m else None


clips = req("GET", f"{SB}/rest/v1/clips?select=id,url&order=id")
if not clips:
    print("aucun clip"); sys.exit(0)
print(len(clips), "clips à actualiser")
items = []
for i in range(0, len(clips), 50):
    batch = [c["url"] for c in clips[i:i + 50]]
    inp = {"postURLs": batch, "resultsPerPage": 1, "shouldDownloadVideos": False, "shouldDownloadCovers": False,
           "shouldDownloadSubtitles": False, "shouldDownloadSlideshowImages": False}
    items += req("POST", f"https://api.apify.com/v2/acts/{ACTOR}/run-sync-get-dataset-items?token={APIFY}&timeout=280",
                 inp, timeout=300) or []
by_id = {}
for it in items:
    for u in (it.get("webVideoUrl"), it.get("submittedVideoUrl"), it.get("url")):
        if vid(u):
            by_id[vid(u)] = it
        if u:
            by_id[u.rstrip("/")] = it
now = datetime.now(timezone.utc).isoformat()
ok = 0
for c in clips:
    it = by_id.get(vid(c["url"]) or "") or by_id.get(c["url"].rstrip("/"))
    if not it:
        print("pas de résultat pour", c["url"]); continue
    st = dict(views=int(it.get("playCount") or 0), likes=int(it.get("diggCount") or 0),
              comments=int(it.get("commentCount") or 0), shares=int(it.get("shareCount") or 0))
    meta = it.get("videoMeta") or {}
    patch = dict(st, updated_at=now, title=(it.get("text") or "")[:300], author=(it.get("authorMeta") or {}).get("name", ""),
                 cover_url=meta.get("coverUrl") or meta.get("originalCoverUrl") or "")
    if it.get("createTimeISO"):
        patch["posted_at"] = it["createTimeISO"]
    req("PATCH", f"{SB}/rest/v1/clips?id=eq.{c['id']}", patch, {"Prefer": "return=minimal"})
    req("POST", f"{SB}/rest/v1/clip_stats", dict(st, clip_id=c["id"]), {"Prefer": "return=minimal"})
    ok += 1
print(f"{ok}/{len(clips)} clips mis à jour")
