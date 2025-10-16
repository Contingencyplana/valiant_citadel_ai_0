Param(
  [ValidateSet('armed','disabled')] [string]$State,
  [string]$Reason = ''
)

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[kill-switch] $m" }
function Fail($m){ Write-Host "[kill-switch] ERROR: $m" -ForegroundColor Red; exit 1 }

$yamlPath = 'policies/safety_config.yaml'
$jsonPath = 'policies/safety_config.json'
$flag = 'safety_kill_switch_disabled.flag'

function Save-Config($obj){
  if (Get-Command ConvertTo-Yaml -ErrorAction SilentlyContinue) {
    $obj | ConvertTo-Yaml | Set-Content -NoNewline -Path $yamlPath
  } else {
    Info 'ConvertTo-Yaml not available; skipping YAML write.'
  }
  $obj | ConvertTo-Json -Depth 12 | Set-Content -NoNewline -Path $jsonPath
}

function Load-Config(){
  $cfg = $null
  if (Test-Path $yamlPath -and (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
    try { $cfg = Get-Content -Raw -Path $yamlPath | ConvertFrom-Yaml } catch {}
  }
  if (-not $cfg -and (Test-Path $jsonPath)) { $cfg = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json }
  if (-not $cfg) { Fail 'Could not load safety config.' }
  return $cfg
}

$cfg = Load-Config
$cfg.kill_switch.state = $State
if ($State -eq 'disabled') {
  if ([string]::IsNullOrWhiteSpace($Reason)) { Fail 'Disabled state requires -Reason' }
  $cfg.kill_switch.disabled_reason = $Reason
  New-Item -ItemType File -Force -Path $flag | Out-Null
} else {
  $cfg.kill_switch.disabled_reason = ''
  if (Test-Path $flag) { Remove-Item -Force $flag }
}

Save-Config $cfg
Info "Kill-switch set to $State"
