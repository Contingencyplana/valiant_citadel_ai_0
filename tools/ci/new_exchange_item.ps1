Param(
  [Parameter(Mandatory=$true)] [string]$Type,
  [string]$Owner = 'valiant_citadel_ai_0',
  [string]$Out = 'exchange/outbox',
  [string[]]$Approver = @(),
  [hashtable]$Fields,
  [string]$FieldsJson
)

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[new-item] $m" }
function Fail($m){ Write-Host "[new-item] ERROR: $m" -ForegroundColor Red; exit 1 }

function Load-Config {
  $yamlPath = 'policies/safety_config.yaml'
  $jsonPath = 'policies/safety_config.json'
  $cfg = $null
  if (Test-Path $yamlPath) {
    try {
      if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
        $cfg = Get-Content -Raw -Path $yamlPath | ConvertFrom-Yaml
      }
    } catch {}
  }
  if (-not $cfg -and (Test-Path $jsonPath)) {
    try { $cfg = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json } catch {}
  }
  return $cfg
}

$cfg = Load-Config
if (-not (Test-Path $Out)) { New-Item -ItemType Directory -Force -Path $Out | Out-Null }

$utc = [DateTime]::UtcNow
$ts = $utc.ToString('yyyy-MM-ddTHH:mm:ssZ')
$stamp = $utc.ToString('yyyyMMdd-HHmmss')
$rand = Get-Random -Minimum 100 -Maximum 999
$id = "valiant-citadel-$Type-$stamp-$rand"

# Validate approvals requirement when config present
if ($cfg -and ($cfg.approvals_required.PSObject.Properties.Name -contains $Type)) {
  $required = [int]$cfg.approvals_required.$Type
  if ((@($Approver).Count) -lt $required) {
    Fail "Type '$Type' requires $required approvals; provided $(@($Approver).Count)."
  }
}

$payload = [ordered]@{
  type = $Type
  id = $id
  timestamp = $ts
  owner = $Owner
}

if ($Approver -and $Approver.Count -gt 0) { $payload['approvals'] = @($Approver) }
if ($FieldsJson) {
  try {
    $parsed = $FieldsJson | ConvertFrom-Json -AsHashtable
    if ($parsed) { $Fields = $parsed }
  } catch { Fail "Failed to parse FieldsJson: $_" }
}

if ($Fields) {
  foreach ($k in $Fields.Keys) { $payload[$k] = $Fields[$k] }
}

$json = ($payload | ConvertTo-Json -Depth 6)
$outPath = Join-Path $Out ($id + '.json')
$json | Set-Content -NoNewline -Path $outPath

Info "Wrote $outPath"
