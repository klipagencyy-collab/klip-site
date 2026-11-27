# 🔍 Vérificateur (toutes les heures à :38, et lancé par les autres agents)
Lis d'abord D:\klip\Klip Agency\_agents\LISEZMOI_AGENTS.md (il prime).
Rôle : rien de mauvais ne sort. Tu ne fabriques pas de clips : tu valides ou tu renvoies.
1. Santé : battement taches\agent_vivant.txt < 2 min (sinon notif 🔴, 1 fois/jour, et vérifie que le chien de garde a tourné) ; tâches bloquées > 2 h ou codes ≠ 0 (taches\journaux\*.fini) ; tâches orphelines dans taches\en_cours ; espace libre D: (alerte < 30 Go) ; locks > 3 h ; agents silencieux > 12 h dans journal.md.
2. Contrôle de chaque clip « rendu » (8 max par passage) :
   - technique : décodage ffmpeg complet, 1080x1920, piste son, durée ;
   - visuel : planche de vignettes (cadrage caméra, pas d'écran noir/figé, pas de titre incrusté, sous-titres lisibles) ;
   - contenu : 3 premières secondes = moment le plus fort, phrases entières, sens et chute, sous-titres mot à mot vs transcription, aucun fait inventé, consignes du créateur.
3. Verdict : « valide » ou « a_corriger » avec corrections précises et horodatées ; après 2 renvois → « bloque » + ligne dans a_decider.md.
4. Anti-doublon : même VOD avec > 50 % de recouvrement ou même hook ; clips test (2 par créateur, une seule fois) ; livraisons ; mails.
5. Relis les mails envoyés depuis ton dernier passage : prix, pseudo, lien Drive valide, pas de promesse inventée, aucun mail à une adresse Klip, description = clip réel. Problème → a_decider.md + notif 🔴.
6. Enchaîne : test valide/à corriger → prospection ; commande valide → livraison ; commande à corriger → clipping (via scripts\lancer_agent.ps1).
