# Règles communes des agents Klip (ce fichier prime sur les prompts)

À copier dans D:\klip\Klip Agency\_agents\LISEZMOI_AGENTS.md.

## Base
- PC principal : Windows, D:\klip. Fichiers partagés : D:\klip\Klip Agency\_agents\
  - CREATEURS.md : registre (statut actif / pause / test, clips restants, consignes).
  - etat_clips.json : un objet par clip. Cycle : a_rendre → rendu → valide | a_corriger (→ bloque après 2 renvois) → livre (+ retire).
  - journal.md : UNE ligne par passage : `AAAA-MM-JJ HH:MM | <agent> | <résumé> | <code: ok/erreur>`.
  - a_decider.md : tout problème ou choix non tranché, lu par Aydan.
- Google Sheet « Klip — Suivi des agents » : 1ARTYpPGpBH7AS3UQ9oF2lqIIdbfXQdAxOgIXxkKpSFI (onglets Créateurs, Clips, Journal, Moments non retenus, Prospects).
- Outils : ffmpeg D:\klip\outils\ffmpeg\bin ; Python D:\klip\outils\python\tools\python.exe ; kit D:\klip\kit ; transcription D:\klip\projets\winiey\tr_win.py (GPU) ; rendu NVENC (KLIP_ENC=nvenc, KLIP_CQ=17).
- Drive : G:\Mon Drive (compte klip.agencyy). Mail : klip.agencyy@gmail.com.

## Verrous (corrige les sessions doublées)
- Le verrou est posé et retiré par `lancer_agent.ps1`, PAS par l'agent. Un agent lancé à la main vérifie `_agents\<agent>.lock` : s'il a moins de 2 h → s'arrêter tout de suite en écrivant une ligne au journal.
- Un verrou de plus de 3 h est considéré mort : le lanceur le supprime et le note dans a_decider.md.

## Écriture des fichiers partagés
- etat_clips.json : relire juste avant d'écrire, modifier uniquement ses propres clips, écrire dans un fichier .tmp puis renommer (jamais de fichier à moitié écrit).
- Ne jamais supprimer une entrée : changer son statut.

## Mails (corrige les erreurs du 24/11)
- INTERDIT d'envoyer un mail à klip.agencyy@gmail.com ou à une adresse Klip : vérifier le destinataire avant chaque envoi.
- Avant chaque envoi : dédoublonnage Gmail `in:sent to:<email>` + onglet Prospects.
- Une description de clip dans un mail doit venir de la transcription du clip réellement rendu (hook + début/fin dans etat_clips.json), jamais de mémoire.
- Aucun prix, fait ou promesse inventé. Tarifs vrais uniquement (voir prospection.md).

## Limites d'utilisation
- Si une limite d'utilisation est atteinte : terminer proprement l'étape en cours, écrire au journal « limite atteinte, reprise au prochain passage », ne pas relancer en boucle.

## Style Klip (sauf consigne contraire du créateur)
- 3 premières secondes = le moment le plus fort, sans mise en place.
- Phrases entières, ne jamais couper la parole ; couper les passages peu utiles.
- Sous-titres vérifiés mot à mot ; pas de titre incrusté.
- Mèmes ~0,5 s avec bruitage aux moments drôles ; bruitages variés.
- Jamais de fait inventé sur une vraie personne.
- Saino → caméra EN HAUT, pas de sous-titres/effets/bruitages.
- drwhynot → sous-titres + effets + bruitages obligatoires, visage visible, jeu visible pendant l'action.

## Notifications à Aydan
Format court avec emoji : 📞 Call, 💰 Commande, 📦 Livraison, ✅ Commande terminée, 🔴 Problème, 📊 Semaine.
