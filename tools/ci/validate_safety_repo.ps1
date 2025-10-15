Param(
  [switch]$VerboseMode
)

$ErrorActionPreference = 'Stop'

function Write-Info($msg){ Write-Host "[safety-validate] $msg" }
function Fail($msg){ Write-Host "[safety-validate] ERROR: $msg" -ForegroundColor Red; exit 1 }

# Required structure
$requiredPaths = @(
  'exchange',
  'tools/runbooks',
  'policies'
)

foreach ($p in $requiredPaths) {
  if (-not (Test-Path $p)) { Fail "Missing required path: $p" }
}

# Required runbooks
$runbooks = @(
  'tools/runbooks/incident_freeze.md',
  'tools/runbooks/incident_rollback.md',
  'tools/runbooks/postmortem_template.md'
)

foreach ($rb in $runbooks) {
  if (-not (Test-Path $rb)) { Fail "Missing required runbook: $rb" }
}

# Basic README sanity: mention kill-switch
if (Test-Path 'README.md') {
  $readme = Get-Content -Raw -Path 'README.md'
  if ($readme -notmatch 'kill-?switch') { Fail 'README.md should mention kill-switch protocols' }
} else {
  Fail 'Missing README.md'
}

# Guard: if a disable flag is present, block commits
$disableFlag = 'safety_kill_switch_disabled.flag'
if (Test-Path $disableFlag) {
  Fail "Kill-switch disable flag present: $disableFlag"
}

Write-Info 'Repository safety structure validated.'
