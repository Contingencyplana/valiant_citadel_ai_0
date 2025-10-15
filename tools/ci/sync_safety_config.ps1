Param(
  [string]$YamlPath = 'policies/safety_config.yaml',
  [string]$JsonPath = 'policies/safety_config.json'
)

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[sync-config] $m" }
function Fail($m){ Write-Host "[sync-config] ERROR: $m" -ForegroundColor Red; exit 1 }

if (-not (Test-Path $YamlPath)) { Fail "YAML not found: $YamlPath" }

if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
  Fail 'ConvertFrom-Yaml is not available. Install powershell-yaml or regenerate JSON manually.'
}

$yaml = Get-Content -Raw -Path $YamlPath
$obj = $yaml | ConvertFrom-Yaml
$json = $obj | ConvertTo-Json -Depth 12

$outDir = Split-Path -Parent $JsonPath
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$json | Set-Content -NoNewline -Path $JsonPath
Info "Wrote JSON mirror: $JsonPath"
