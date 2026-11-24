# Agents Klip

Recréation des 7 agents décrits dans AGENTS_KLIP.md (état au 24/11/2026).

| Agent | Fichier | Horaire (heure de Paris) |
|---|---|---|
| 👔 CEO | prompts/ceo.md | à la demande (`claude` puis coller le prompt, ou skill klip-ceo) |
| 🔎 Chercheur | prompts/chercheur.md | 11h37 et 17h37 |
| 📬 Prospection | prompts/prospection.md | toutes les 3 h à :43 (2h43 → 23h43) |
| 🎬 Clipping | prompts/clipping.md | toutes les 3 h à :13 (1h13 → 22h13) |
| 🔍 Vérificateur | prompts/verificateur.md | toutes les heures à :38 + à la demande |
| 📦 Livraison | prompts/livraison.md | toutes les 3 h à :13, de 2h à 23h + à la demande |
| 📊 Rapport | prompts/rapport.md | dimanche 19h47 |

## Installation sur le PC (une seule fois)
1. Copier ce dossier `agents` dans `D:\klip\agents`.
2. Vérifier que `claude` (Claude Code) est installé et connecté, avec Gmail / Drive / Sheets.
3. PowerShell **en administrateur** :
   `powershell -ExecutionPolicy Bypass -File D:\klip\agents\scripts\installer_agents.ps1`

## Corrections des points fragiles
- **Agent local figé** : `chien_de_garde.ps1` (toutes les 2 min) tue le processus figé et son verrou AVANT de relancer `agent_klip.ps1`.
- **Tâches orphelines** : déplacées de `taches\en_cours` vers `taches\orphelines` après 130 min, avec une ligne dans a_decider.md.
- **Sessions doublées** : le verrou est géré par `lancer_agent.ps1` + Windows `MultipleInstances IgnoreNew`.
- **Limites d'utilisation** : règle d'arrêt propre dans LISEZMOI_AGENTS.md.
- **Mails à notre propre adresse / descriptions fausses** : règles bloquantes dans LISEZMOI_AGENTS.md + contrôle par le Vérificateur.

## À savoir
`lancer_agent.ps1` lance `claude -p ... --dangerously-skip-permissions` : les agents tournent sans demander d'autorisation (nécessaire sans surveillance). Retire cette option si tu préfères valider à la main.
