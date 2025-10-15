Param(
  [string]$ConfigPath = 'exchange/config.json',
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[publish] $m" }
function Warn($m){ Write-Host "[publish] WARNING: $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "[publish] ERROR: $m" -ForegroundColor Red; exit 1 }

function Load-Json($p){ if (-not (Test-Path $p)) { Fail "Missing config: $p" }; Get-Content -Raw -Path $p | ConvertFrom-Json }

function Ensure-Dir($p){ if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

function Classify-Type([string]$type){
  $orders = @('safety_freeze','safety_rollback','safety_policy_update','safety_red_team_exercise')
  $reports = @('safety_incident_report','safety_postmortem','safety_readiness','safety_onboarding_ack')
  if ($orders -contains $type) { return 'order' }
  if ($reports -contains $type) { return 'report' }
  return 'unknown'
}

$cfg = Load-Json $ConfigPath
$outbox = 'exchange/outbox'
Ensure-Dir $outbox

if ($cfg.upstream.mode -ne 'local') {
  Warn "Only 'local' upstream mode is supported by this script without network. Update config to include a local 'path'."
}

$upstreamRoot = $cfg.upstream.path
if (-not $upstreamRoot) { Fail 'Config upstream.path is required for local mode.' }
if (-not (Test-Path $upstreamRoot)) { Fail "Upstream path not found: $upstreamRoot" }

$orderTarget = Join-Path $upstreamRoot $cfg.mapping.orders_outbox
$reportTarget = Join-Path $upstreamRoot $cfg.mapping.reports_outbox
Ensure-Dir $orderTarget; Ensure-Dir $reportTarget

$items = Get-ChildItem -File $outbox -Filter *.json -ErrorAction SilentlyContinue
if (-not $items) { Info 'No outbox items to publish.'; exit 0 }

foreach ($f in $items) {
  try {
    $obj = (Get-Content -Raw -Path $f.FullName | ConvertFrom-Json)
  } catch { Warn "Invalid JSON: $($f.Name)"; continue }

  $kind = Classify-Type $([string]$obj.type)
  $destDir = if ($kind -eq 'order') { $orderTarget } elseif ($kind -eq 'report') { $reportTarget } else { $reportTarget }
  $dest = Join-Path $destDir $f.Name

  if ($DryRun) {
    Info "DRY RUN: would publish $($f.Name) -> $dest"
  } else {
    Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
    Info "Published $($f.Name) -> $dest"
  }
}

Info 'Publish complete.'
