Param(
  [string]$Inbox = 'exchange/inbox',
  [string]$Outbox = 'exchange/outbox'
)

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[watcher] $m" }
function Warn($m){ Write-Host "[watcher] WARNING: $m" -ForegroundColor Yellow }
function Block($m){ Write-Host "[watcher] BLOCKED: $m" -ForegroundColor Red }

# Ensure folders exist
New-Item -ItemType Directory -Force -Path $Inbox | Out-Null
New-Item -ItemType Directory -Force -Path $Outbox | Out-Null

Info "Scanning inbox: $Inbox"

$items = Get-ChildItem -File -Path $Inbox -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.json', '.yml', '.yaml' }

if (-not $items) {
  Info 'No pending exchange items found.'
  exit 0
}

# Simple heuristic checks (placeholders to be replaced with real schema checks)
foreach ($f in $items) {
  $content = Get-Content -Raw -Path $f.FullName

  if ($content -match '"order":\s*"safety_freeze"') {
    Warn "Freeze order observed: $($f.Name). Ensure dual-key approvals present."
    if ($content -notmatch '"approvals":\s*\[.*\].*\[.*\]') { Block "Freeze order lacks dual approvals: $($f.Name)" }
  }

  if ($content -match '"rate":\s*(\d{4,})') {
    Warn "Abnormally large rate detected in $($f.Name)."
  }

  if ($content -match '"acceptance":\s*"blocked"') {
    Info "Acknowledged blocked acceptance in $($f.Name)."
  }
}

Info 'Scan complete.'
