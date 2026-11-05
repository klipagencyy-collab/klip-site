"""Robot de stats : lit les vues / j'aime / commentaires / partages de chaque clip via Apify,
met à jour Supabase et garde l'historique (courbes). Lancé par GitHub Actions toutes les 12 h.
Secrets GitHub nécessaires : SUPABASE_URL, SUPABASE_SERVICE_KEY, APIFY_TOKEN."""
import json, os, re, sys, time, urllib.request, urllib.error
from datetime import datetime, timezone

SB = (os.environ.get("SUPABASE_URL") or "https://uinkjgbisypgrtnojuyo.supabase.co").rstrip("/")
KEY = os.environ.get("SUPABASE_SERVICE_KEY", "").strip()
APIFY = os.environ.get("APIFY_TOKEN", "").strip()
missing = [n for n, v in (("SUPABASE_SERVICE_KEY", KEY), ("APIFY_TOKEN", APIFY)) if not v]
if missing:
    # pas d'échec rouge tant que les clés ne sont pas ajoutées : simple avertissement visible dans GitHub
    print(f"::warning::Stats non mises à jour : il manque le(s) secret(s) GitHub {', '.join(missing)} "
          "(Settings > Secrets and variables > Actions).")
    sys.exit(0)
ACTOR = os.environ.get("APIFY_ACTOR", "clockworks~tiktok-scraper")
H = {"apikey": KEY, "Authorization": f"Bearer {KEY}", "Content-Type": "application/json"}


def req(method, url, body=None, headers=None, timeout=60, tries=3):
    for k in range(tries):
        r = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body is not None else None,
                                   headers={**H, **(headers or {})} if url.startswith(SB) else {"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(r, timeout=timeout) as f:
                t = f.read().decode()
                return json.loads(t) if t else None
        except urllib.error.HTTPError as e:
            msg = e.read().decode(errors="ignore")[:300]
            if e.code < 500 and e.code != 429:
                raise RuntimeError(f"{method} {url.split('?')[0]} -> {e.code} {msg}")
            err = f"{e.code} {msg}"
        except (urllib.error.URLError, TimeoutError) as e:
            err = str(e)
        time.sleep(5 * (k + 1))
    raise RuntimeError(f"{method} {url.split('?')[0]} : échec après {tries} essais ({err})")


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
    try:
        items += req("POST", f"https://api.apify.com/v2/acts/{ACTOR}/run-sync-get-dataset-items?token={APIFY}&timeout=280",
                     inp, timeout=300) or []
    except Exception as e:
        print(f"::warning::Apify, lot {i // 50 + 1} : {e}")
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
    if not any(st.values()):
        print("résultat vide (vidéo privée ou supprimée ?) pour", c["url"]); continue
    patch = dict(st, updated_at=now)
    if it.get("text"): patch["title"] = it["text"][:300]
    if (it.get("authorMeta") or {}).get("name"): patch["author"] = it["authorMeta"]["name"]
    cov = meta.get("coverUrl") or meta.get("originalCoverUrl")
    if cov: patch["cover_url"] = cov
    if it.get("createTimeISO"):
        patch["posted_at"] = it["createTimeISO"]
    try:
        req("PATCH", f"{SB}/rest/v1/clips?id=eq.{c['id']}", patch, {"Prefer": "return=minimal"})
        req("POST", f"{SB}/rest/v1/clip_stats", dict(st, clip_id=c["id"]), {"Prefer": "return=minimal"})
        ok += 1
    except Exception as e:
        print(f"::warning::clip {c['id']} : {e}")
print(f"{ok}/{len(clips)} clips mis à jour")
if clips and ok == 0:
    sys.exit("::error::Aucun clip n'a pu être mis à jour")
