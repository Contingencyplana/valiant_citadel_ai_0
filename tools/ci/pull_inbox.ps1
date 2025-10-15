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

$fromDir = Join-Path $upstreamRoot $cfg.mapping.inbox_pull
if (-not (Test-Path $fromDir)) { Fail "Upstream inbox path not found: $fromDir" }

$items = Get-ChildItem -File -Path $fromDir -Filter *.json -ErrorAction SilentlyContinue
if (-not $items) { Info 'No upstream inbox items found.'; exit 0 }

foreach ($f in $items) {
  $dest = Join-Path $inboxLocal $f.Name
  Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
  Info "Pulled $($f.Name)"
}

Info 'Pull complete.'
