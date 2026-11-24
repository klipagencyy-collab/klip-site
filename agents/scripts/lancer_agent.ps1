# Lance un agent Klip avec verrou (empêche deux passages en même temps).
# Usage : powershell -ExecutionPolicy Bypass -File lancer_agent.ps1 -Agent clipping
param([Parameter(Mandatory)][ValidateSet('chercheur','prospection','clipping','verificateur','livraison','rapport','ceo')][string]$Agent)

$Base   = 'D:\klip\Klip Agency\_agents'
$Prompt = 'D:\klip\agents\prompts\' + $Agent + '.md'
$Lock   = Join-Path $Base "$Agent.lock"
$Log    = Join-Path $Base "logs\$Agent`_$(Get-Date -f yyyyMMdd_HHmm).log"
New-Item -ItemType Directory -Force (Split-Path $Log) | Out-Null

function Journal($msg) { Add-Content (Join-Path $Base 'journal.md') "$(Get-Date -f 'yyyy-MM-dd HH:mm') | $Agent | $msg" -Encoding UTF8 }

if (Test-Path $Lock) {
    $age = (Get-Date) - (Get-Item $Lock).LastWriteTime
    if ($age.TotalHours -lt 2) { Journal "passage ignoré : verrou actif ($([int]$age.TotalMinutes) min)"; exit 0 }
    if ($age.TotalHours -ge 3) { Add-Content (Join-Path $Base 'a_decider.md') "- $(Get-Date -f 'yyyy-MM-dd HH:mm') verrou mort $Agent supprimé ($([int]$age.TotalHours) h)" -Encoding UTF8 }
    else { Journal "passage ignoré : verrou de $([int]$age.TotalMinutes) min (attente 3 h avant suppression)"; exit 0 }
}

Set-Content $Lock "$PID $(Get-Date -f o)"
try {
    Set-Location 'D:\klip'
    $env:KLIP_ENC = 'nvenc'; $env:KLIP_CQ = '17'
    $texte = Get-Content $Prompt -Raw -Encoding UTF8
    # Sans surveillance : pas de demande d'autorisation. Voir README pour le choix.
    & claude -p $texte --dangerously-skip-permissions *>&1 | Tee-Object -FilePath $Log
    $code = $LASTEXITCODE
    if ($code -ne 0) { Journal "claude a quitté avec le code $code (voir $Log)" }
} finally {
    Remove-Item $Lock -Force -ErrorAction SilentlyContinue
}
