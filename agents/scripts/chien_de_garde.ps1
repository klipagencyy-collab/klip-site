# Toutes les 2 min : redémarre l'agent local s'il est figé et range les tâches orphelines.
$Taches  = 'D:\klip\taches'
$Battement = Join-Path $Taches 'agent_vivant.txt'
$Script  = 'D:\klip\agent_klip.ps1'
$Base    = 'D:\klip\Klip Agency\_agents'
function Note($m) { Add-Content (Join-Path $Base 'a_decider.md') "- $(Get-Date -f 'yyyy-MM-dd HH:mm') chien de garde : $m" -Encoding UTF8 }

$fige = -not (Test-Path $Battement) -or (((Get-Date) - (Get-Item $Battement).LastWriteTime).TotalMinutes -gt 2)
if ($fige) {
    # Le processus figé garde son verrou : on le tue d'abord, sinon la relance échoue.
    Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe'" |
        Where-Object { $_.CommandLine -like '*agent_klip.ps1*' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Get-ChildItem $Taches -Filter '*.lock' -ErrorAction SilentlyContinue | Remove-Item -Force
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$Script`"" -WindowStyle Hidden
    Note "agent local figé, redémarré"
}

# Tâches orphelines : dans en_cours depuis > 2 h (120 min max) → remises en file avec trace.
$enCours = Join-Path $Taches 'en_cours'
if (Test-Path $enCours) {
    Get-ChildItem $enCours -File | Where-Object { ((Get-Date) - $_.LastWriteTime).TotalMinutes -gt 130 } | ForEach-Object {
        $dest = Join-Path $Taches ('orphelines\' + $_.Name)
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Move-Item $_.FullName $dest -Force
        Note "tâche orpheline $($_.Name) déplacée dans taches\orphelines (à relancer ou supprimer)"
    }
}
