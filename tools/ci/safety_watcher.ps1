Param(
  [string]$Inbox = 'exchange/inbox',
  [string]$Outbox = 'exchange/outbox'
)

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[watcher] $m" }
function Warn($m){ Write-Host "[watcher] WARNING: $m" -ForegroundColor Yellow }
function Block($m){ Write-Host "[watcher] BLOCKED: $m" -ForegroundColor Red }

function Load-Config {
  $yamlPath = 'policies/safety_config.yaml'
  $jsonPath = 'policies/safety_config.json'
  $cfg = $null
  if (Test-Path $yamlPath) {
    try {
      if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
        $cfg = Get-Content -Raw -Path $yamlPath | ConvertFrom-Yaml
      }
    } catch {
      Warn "YAML parse failed; will try JSON mirror. $_"
    }
  }
  if (-not $cfg -and (Test-Path $jsonPath)) {
    try { $cfg = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json } catch { Warn "JSON parse failed: $_" }
  }
  return $cfg
}

function Parse-Item($path) {
  $ext = [IO.Path]::GetExtension($path).ToLowerInvariant()
  $raw = Get-Content -Raw -Path $path
  try {
    if ($ext -eq '.json') { return $raw | ConvertFrom-Json }
    if ($ext -eq '.yaml' -or $ext -eq '.yml') {
      if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) { return $raw | ConvertFrom-Yaml }
    }
  } catch { Warn "Parse failed for ${path}: $_" }
  return $null
}

# Ensure folders exist
New-Item -ItemType Directory -Force -Path $Inbox | Out-Null
New-Item -ItemType Directory -Force -Path $Outbox | Out-Null

$config = Load-Config
if ($null -eq $config) {
  Warn 'No safety_config found or parsed; running with heuristic warnings only.'
}
else {
  try {
    $ks = $config.kill_switch
    if ($ks -and ($ks.state -eq 'disabled')) {
      $reason = ''
      if ($ks.PSObject.Properties.Name -contains 'disabled_reason') { $reason = [string]$ks.disabled_reason }
      if ([string]::IsNullOrWhiteSpace($reason)) { Warn 'Kill-switch state is DISABLED.' } else { Warn ("Kill-switch DISABLED: " + $reason) }
    }
  } catch { Warn "Kill-switch check failed: $_" }
}

Info "Scanning inbox: $Inbox"

$items = Get-ChildItem -File -Path $Inbox -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.json', '.yml', '.yaml' }

if (-not $items) {
  Info 'No pending exchange items found.'
  exit 0
}

foreach ($f in $items) {
  $obj = Parse-Item -path $f.FullName
  $content = if (Test-Path $f.FullName) { Get-Content -Raw -Path $f.FullName } else { '' }

  # Heuristic: detect freeze orders even if parsing failed
  if ($content -and ($content -match '"order":\s*"safety_freeze"' -or $content -match '"type":\s*"safety_freeze"')) {
    Warn "Freeze order observed: $($f.Name). Ensure dual-key approvals present."
  }

  # Config-driven checks
  if ($null -ne $config -and $null -ne $obj) {
    $type = $obj.type
    $owner = $obj.owner
    $timestamp = $obj.timestamp
    $approvals = $obj.approvals

    if ($config.watcher_rules.require_owner -and (-not $owner)) { Block "$($f.Name): missing owner" }
    if ($config.watcher_rules.require_timestamp -and (-not $timestamp)) { Block "$($f.Name): missing timestamp" }

    # Dual approvals for protected orders
    if ($type -and $config.approvals_required.PSObject.Properties.Name -contains $type) {
      $required = [int]$config.approvals_required.$type
      $count = 0
      if ($approvals -is [System.Collections.IEnumerable]) { $count = @($approvals).Count }
      # Dual-key warning if globally required
      $dualKey = $false
      if ($config.kill_switch -and ($config.kill_switch.PSObject.Properties.Name -contains 'dual_key_required')) {
        $dualKey = [bool]$config.kill_switch.dual_key_required
      }
      if ($dualKey -and $required -ge 2 -and $count -lt 2) {
        Warn "$($f.Name): dual-key required; approvals $count < 2"
      }
      if ($count -lt $required) { Block "$($f.Name): approvals $count < required $required for $type" }
    }

    # Rate checks (if present in payload)
    $rateField = $null
    if ($obj.PSObject.Properties.Name -contains 'rate') { $rateField = [int]$obj.rate }
    if ($rateField -and $config.thresholds.abnormal_rate_trigger -and $rateField -ge [int]$config.thresholds.abnormal_rate_trigger) {
      Warn "$($f.Name): abnormal rate $rateField >= $($config.thresholds.abnormal_rate_trigger)"
    }
  } else {
    # Fallback heuristics
    if ($content -match '"rate":\s*(\d{4,})') { Warn "Abnormally large rate detected in $($f.Name)." }
  }

  if ($content -match '"acceptance":\s*"blocked"') { Info "Acknowledged blocked acceptance in $($f.Name)." }
}

Info 'Scan complete.'
