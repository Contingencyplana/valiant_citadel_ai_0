Param(
  [string]$ConfigPath = 'exchange/config.json'
)

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[pull] $m" }
function Warn($m){ Write-Host "[pull] WARNING: $m" -ForegroundColor Yellow }
function Fail($m){ Write-Host "[pull] ERROR: $m" -ForegroundColor Red; exit 1 }

function Load-Json($p){ if (-not (Test-Path $p)) { Fail "Missing config: $p" }; Get-Content -Raw -Path $p | ConvertFrom-Json }

$cfg = Load-Json $ConfigPath
$inboxLocal = 'exchange/inbox'
if (-not (Test-Path $inboxLocal)) { New-Item -ItemType Directory -Force -Path $inboxLocal | Out-Null }

if ($cfg.upstream.mode -ne 'local') {
  Warn "Only 'local' upstream mode is supported by this script without network. Update config to include a local 'path'."
}

$upstreamRoot = $cfg.upstream.path
if (-not $upstreamRoot) { Fail 'Config upstream.path is required for local mode.' }
if (-not (Test-Path $upstreamRoot)) { Fail "Upstream path not found: $upstreamRoot" }

# Pull reports inbox
$reportFrom = Join-Path $upstreamRoot $cfg.mapping.inbox_pull
if (Test-Path $reportFrom) {
  $rep = Get-ChildItem -File -Path $reportFrom -Filter *.json -ErrorAction SilentlyContinue
  foreach ($f in $rep) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $inboxLocal $f.Name) -Force; Info "Pulled $($f.Name)" }
} else { Warn "Upstream reports inbox not found: $reportFrom" }

# Optionally pull orders pending
if ($cfg.mapping.PSObject.Properties.Name -contains 'orders_pending_pull') {
  $orderFrom = Join-Path $upstreamRoot $cfg.mapping.orders_pending_pull
  if (Test-Path $orderFrom) {
    $ord = Get-ChildItem -File -Path $orderFrom -Filter *.json -ErrorAction SilentlyContinue
    foreach ($f in $ord) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $inboxLocal $f.Name) -Force; Info "Pulled $($f.Name)" }
  } else { Warn "Upstream orders pending not found: $orderFrom" }
}

# Optionally pull acknowledgements pending
if ($cfg.mapping.PSObject.Properties.Name -contains 'acks_pending_pull') {
  $acksFrom = Join-Path $upstreamRoot $cfg.mapping.acks_pending_pull
  if (Test-Path $acksFrom) {
    $acks = Get-ChildItem -File -Path $acksFrom -Filter *.json -ErrorAction SilentlyContinue
    foreach ($f in $acks) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $inboxLocal $f.Name) -Force; Info "Pulled $($f.Name)" }
  } else { Warn "Upstream acknowledgements pending not found: $acksFrom" }
}

Info 'Pull complete.'
