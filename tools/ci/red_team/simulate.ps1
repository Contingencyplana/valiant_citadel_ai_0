Param(
  [string]$Out = 'exchange/inbox'
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Out)) { New-Item -ItemType Directory -Force -Path $Out | Out-Null }

$now = (Get-Date -AsUTC).ToString('yyyy-MM-ddTHH:mm:ssZ')

# Missing approvals scenario (protected order)
@{
  type = 'safety_policy_update'
  id = "rt-missing-approvals-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
  timestamp = $now
  owner = 'red_team'
} | ConvertTo-Json -Depth 5 | Set-Content -NoNewline -Path (Join-Path $Out 'rt-missing-approvals.json')

# Abnormal rate scenario
@{ 
  type = 'safety_readiness'
  id = "rt-abnormal-rate-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
  timestamp = $now
  owner = 'red_team'
  rate = 5000
} | ConvertTo-Json -Depth 5 | Set-Content -NoNewline -Path (Join-Path $Out 'rt-abnormal-rate.json')

# Missing fields scenario
@{ 
  type = 'ack'
  id = "rt-missing-fields-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
  ack = @{ message = 'test' }
} | ConvertTo-Json -Depth 5 | Set-Content -NoNewline -Path (Join-Path $Out 'rt-missing-fields.json')

# Gameplay exploit signal (griefing report)
@{
  type = 'safety_incident_report'
  id = "rt-griefing-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
  timestamp = $now
  owner = 'red_team'
  details = @{ category = 'griefing'; description = 'spawn-camping detected in canary' }
} | ConvertTo-Json -Depth 6 | Set-Content -NoNewline -Path (Join-Path $Out 'rt-griefing-report.json')

# Economy exploit probe (balance change without approvals)
@{
  type = 'safety_policy_update'
  id = "rt-balance-probe-$([DateTime]::UtcNow.ToString('yyyyMMddHHmmss'))"
  timestamp = $now
  owner = 'red_team'
  policy = @{ economy = @{ loot_multiplier = 9999 } }
} | ConvertTo-Json -Depth 6 | Set-Content -NoNewline -Path (Join-Path $Out 'rt-balance-probe.json')

Write-Host '[red-team] Seeded scenarios into inbox.'
