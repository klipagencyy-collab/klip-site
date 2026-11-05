# Klip Agency — site

Site vitrine de Klip Agency (agence de clipping) : https://klipagency.netlify.app

- `index.html` : toute la page (HTML, CSS et JavaScript dans un seul fichier).
- `assets/telephone.jpg` : image affichée dans le téléphone en haut à droite (format vertical 9:16).
- `assets/miniature.jpg` : miniature de vidéo longue derrière le téléphone (format 16:9).
- `clips/` : clips test montrés dans la page.
- Les formulaires créateurs et clippeurs envoient les candidatures vers Google Forms.

Pour publier avec GitHub Pages : Settings → Pages → Branch `main`, dossier `/ (root)`.

## Espace créateur (`/espace/`)
- `espace/index.html` : connexion des créateurs, stats (vues, j'aime, courbes), clips, liens WeTransfer, panneau admin. Aperçu : `/espace/?demo`.
- `espace/supabase.sql` : à lancer une fois dans Supabase (tables, sécurité, temps réel).
- `espace/maj_stats.py` + `.github/workflows/stats.yml` : robot qui lit les stats TikTok via Apify à 6 h et 18 h (secrets GitHub : SUPABASE_URL, SUPABASE_SERVICE_KEY, APIFY_TOKEN).
