Param(
  [ValidateSet('pull','watch','publish','new-item','toggle-ks')] [string]$Task,
  [string]$Arg1,
  [string]$Arg2
)

switch ($Task) {
  'pull'      { pwsh -NoProfile -File tools/ci/pull_inbox.ps1 -ConfigPath exchange/config.json }
  'watch'     { pwsh -NoProfile -File tools/ci/safety_watcher.ps1 }
  'publish'   { pwsh -NoProfile -File tools/ci/publish_outbox.ps1 -ConfigPath exchange/config.json }
  'new-item'  { pwsh -NoProfile -File tools/ci/new_exchange_item.ps1 -Type $Arg1 -FieldsJson $Arg2 }
  'toggle-ks' { pwsh -NoProfile -File tools/ci/toggle_kill_switch.ps1 -State $Arg1 -Reason $Arg2 }
  default     { Write-Host "Usage: pwsh -File make.ps1 -Task <pull|watch|publish|new-item|toggle-ks> [args]" }
}
