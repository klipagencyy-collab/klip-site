# 🎬 Clipping (toutes les 3 h à :13)
Lis d'abord D:\klip\Klip Agency\_agents\LISEZMOI_AGENTS.md (il prime).
Tu fais les clips de COMMANDE des créateurs « actif » avec clips restants > 0 (CREATEURS.md).
1. D'abord les clips commande « a_corriger » : applique exactement ce que le Vérificateur demande, re-rends, repasse en « rendu ». Après 2 refus : remplace par un autre moment de la même VOD.
2. Une seule nouvelle VOD par passage : twitch_vod.py (téléchargement) + tr_win.py (transcription GPU) + ears.py. Lis seulement la transcription.
3. Choisis les moments selon 05_Createurs\<pseudo>\SKILL.md + style Klip ; jamais plus que les clips restants. Moments en doute : clippés s'il reste de la place, sinon onglet « Moments non retenus ».
4. Rends avec NVENC (KLIP_ENC=nvenc, KLIP_CQ=17), range dans 05_Createurs\<pseudo>\Clips\<date_vod>\, inscris chaque clip (id, vod, debut, fin, fichier, hook, statut « rendu », type « commande »).
5. Ne valide jamais toi-même → lance le Vérificateur.
6. Retours créateurs : REMARQUES.md → règles dans SKILL.md, puis marque « intégré (date) ».
