# À lancer UNE fois sur le PC, en administrateur :
#   powershell -ExecutionPolicy Bypass -File D:\klip\agents\scripts\installer_agents.ps1
# Crée les tâches planifiées Windows (heure locale du PC = heure de Paris).
$Dir = 'D:\klip\agents\scripts'
$Lanceur = Join-Path $Dir 'lancer_agent.ps1'
$Base = 'D:\klip\Klip Agency\_agents'
New-Item -ItemType Directory -Force "$Base\rapports","$Base\logs" | Out-Null
Copy-Item 'D:\klip\agents\LISEZMOI_AGENTS.md' "$Base\LISEZMOI_AGENTS.md" -Force

function Action($agent) { New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Lanceur`" -Agent $agent" }
function Toutes($h, $minute, $debut = 0, $fin = 23) {
    for ($x = $debut; $x -le $fin; $x += $h) { New-ScheduledTaskTrigger -Daily -At ('{0:D2}:{1:D2}' -f $x, $minute) }
}
$Reglages = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 3) -StartWhenAvailable

$taches = @{
  'Klip - Chercheur'    = @{ a='chercheur';    t=@((New-ScheduledTaskTrigger -Daily -At 11:37),(New-ScheduledTaskTrigger -Daily -At 17:37)) }
  'Klip - Prospection'  = @{ a='prospection';  t=(Toutes 3 43 2 23) }
  'Klip - Clipping'     = @{ a='clipping';     t=(Toutes 3 13 1 22) }
  'Klip - Verificateur' = @{ a='verificateur'; t=(Toutes 1 38) }
  'Klip - Livraison'    = @{ a='livraison';    t=(Toutes 3 13 2 23) }
  'Klip - Rapport'      = @{ a='rapport';      t=@(New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 19:47) }
}
foreach ($nom in $taches.Keys) {
    Register-ScheduledTask -TaskName $nom -Action (Action $taches[$nom].a) -Trigger $taches[$nom].t -Settings $Reglages -Force | Out-Null
    Write-Host "OK  $nom"
}

# Chien de garde : toutes les 2 minutes.
$t = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2)
$a = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Dir\chien_de_garde.ps1`""
Register-ScheduledTask -TaskName 'Klip - Chien de garde' -Action $a -Trigger $t -Settings $Reglages -Force | Out-Null
Write-Host "OK  Klip - Chien de garde"
Write-Host "Terminé. Vérifie dans le Planificateur de tâches, dossier racine, les tâches 'Klip - ...'."
