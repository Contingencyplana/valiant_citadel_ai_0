Param(
  [string]$Inbox = 'exchange/inbox',
  [string]$Outbox = 'exchange/outbox',
  [string]$LogPath = 'logs/safety_watcher.log',
  [switch]$ScanOutbox,
  [switch]$FailOnBlocked
)

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[watcher] $m"; Log $m }
function Warn($m){ Write-Host "[watcher] WARNING: $m" -ForegroundColor Yellow; Log "WARNING: $m"; $script:warnCount++ }
function Block($m){ Write-Host "[watcher] BLOCKED: $m" -ForegroundColor Red; Log "BLOCKED: $m"; $script:blockCount++ }

$script:pivotFivePythonInfo = $null
$script:pivotFiveHooks = @{}

try {
  $monitoringRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\monitoring')).Path
  $script:pivotFiveHooks = @{
    schema_guard = Join-Path $monitoringRoot 'schema_guard.py'
    narrator_log = Join-Path $monitoringRoot 'narrator_log.py'
    glyph_vo_audit = Join-Path $monitoringRoot 'glyph_vo_audit.py'
  }
} catch {
  $script:pivotFiveHooks = @{}
}

function Get-PythonInvocation {
  if ($script:pivotFivePythonInfo) { return $script:pivotFivePythonInfo }
  foreach ($candidate in @('python', 'py')) {
    try {
      $cmd = Get-Command $candidate -ErrorAction Stop
      if ($candidate -eq 'py') {
        $script:pivotFivePythonInfo = @{ Command = $cmd.Source; PrefixArgs = @('-3') }
      } else {
        $script:pivotFivePythonInfo = @{ Command = $cmd.Source; PrefixArgs = @() }
      }
      return $script:pivotFivePythonInfo
    } catch {}
  }
  Warn 'Python runtime not located; Pivot Five monitoring hooks skipped.'
  $script:pivotFivePythonInfo = $false
  return $script:pivotFivePythonInfo
}

function Invoke-PivotFiveHook {
  param(
    [string]$HookName,
    [string]$ScriptPath,
    [string[]]$Arguments
  )

  if (-not $ScriptPath -or -not (Test-Path $ScriptPath)) { return }
  $pythonInfo = Get-PythonInvocation
  if (-not $pythonInfo) { return }

  $command = $pythonInfo.Command
  $hookArgs = @()
  if ($pythonInfo.PrefixArgs) { $hookArgs += $pythonInfo.PrefixArgs }
  $hookArgs += ,$ScriptPath
  if ($Arguments) { $hookArgs += $Arguments }

  $output = & $command @hookArgs 2>&1
  $exitCode = $LASTEXITCODE
  if ($exitCode -ne 0) {
    $joined = $output -join '; '
  Warn ("$HookName hook exit ${exitCode}: $joined")
    return
  }
  foreach ($line in $output) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -like 'ALERT:*') {
      Warn "$HookName alert -> $line"
    } elseif ($line -like 'WARNING:*') {
      Warn "$HookName warning -> $line"
    } else {
      Info "$HookName -> $line"
    }
  }
}

function Rotate-Log($path){
  try {
    $dir = Split-Path -Parent $path
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if (Test-Path $path) {
      $fi = Get-Item $path
      if ($fi.Length -gt 1048576) { # 1MB
        $ts = (Get-Date -AsUTC).ToString('yyyyMMdd-HHmmss')
        Rename-Item -Path $path -NewName ("safety_watcher_"+$ts+".log") -Force
      }
    }
  } catch {}
}

function Log($m){
  if (-not $LogPath) { return }
  Rotate-Log -path $LogPath
  $ts = (Get-Date -AsUTC).ToString('o')
  $line = "[$ts] $m"
  Add-Content -Path $LogPath -Value $line
}

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

$script:warnCount = 0
$script:blockCount = 0

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

if ($ScanOutbox) {
  Info "Scanning outbox: $Outbox"
} else {
  Info "Scanning inbox: $Inbox"
}

$scanPath = if ($ScanOutbox) { $Outbox } else { $Inbox }
$items = Get-ChildItem -File -Path $scanPath -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.json', '.yml', '.yaml' }

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

    # Legacy grace window logic for missing fields
    $legacyWarnOnly = $false
    $legacyCutoff = $null
    if ($config.PSObject.Properties.Name -contains 'legacy') {
      $legacyWarnOnly = [bool]$config.legacy.warn_only
      if ($config.legacy.PSObject.Properties.Name -contains 'cutoff_utc') { $legacyCutoff = Get-Date $config.legacy.cutoff_utc }
    }
    $now = Get-Date -AsUTC

    if ($config.watcher_rules.require_owner -and (-not $owner)) {
      if ($legacyWarnOnly -and $legacyCutoff -and $now -lt $legacyCutoff) { Warn "$($f.Name): missing owner (legacy warn)" } else { Block "$($f.Name): missing owner" }
    }
    if ($config.watcher_rules.require_timestamp -and (-not $timestamp)) {
      if ($legacyWarnOnly -and $legacyCutoff -and $now -lt $legacyCutoff) { Warn "$($f.Name): missing timestamp (legacy warn)" } else { Block "$($f.Name): missing timestamp" }
    }

    # Schema validation (minimal required fields)
    try {
      $schemaPath = if ($type -eq 'ack' -or $type -eq 'safety_ack') { 'exchange/schemas/ack.schema.json' } elseif ($type -like 'safety_*' -and $type -ne 'ack') { 'exchange/schemas/report.schema.json' } else { 'exchange/schemas/order.schema.json' }
      if (Test-Path $schemaPath) {
        $schema = Get-Content -Raw -Path $schemaPath | ConvertFrom-Json
        if ($schema.required) {
          foreach ($req in $schema.required) {
            if (-not ($obj.PSObject.Properties.Name -contains $req)) { Block "$($f.Name): missing required field '$req' per schema" }
          }
        }
      }
    } catch { Warn "Schema validation failed for ${f.Name}: $_" }

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

  if ($null -ne $obj -and $obj.schema -eq 'factory-order@1.0' -and $script:pivotFiveHooks.Count -gt 0) {
    Invoke-PivotFiveHook -HookName 'schema_guard' -ScriptPath $script:pivotFiveHooks.schema_guard -Arguments @('--payload', $f.FullName)
    Invoke-PivotFiveHook -HookName 'narrator_log' -ScriptPath $script:pivotFiveHooks.narrator_log -Arguments @('--payload', $f.FullName)
    Invoke-PivotFiveHook -HookName 'glyph_vo_audit' -ScriptPath $script:pivotFiveHooks.glyph_vo_audit -Arguments @('--payload', $f.FullName)
  }
}

Info ("Scan complete. WARN=$warnCount BLOCKED=$blockCount")
if ($FailOnBlocked -and $blockCount -gt 0) { exit 2 }
