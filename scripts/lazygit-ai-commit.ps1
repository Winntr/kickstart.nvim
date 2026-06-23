# ponytail: Windows-native lazygit AI commit via Cursor agent; no WSL/bash required
param(
  [Parameter(Mandatory)]
  [ValidateSet('staged', 'all')]
  [string]$Scope
)

$ErrorActionPreference = 'Stop'

function Invoke-Git {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  $output = & git @GitArgs 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
  $ErrorActionPreference = $prev
  if ($null -eq $output) { return '' }
  if ($output -is [array]) { return ($output -join "`n") }
  return [string]$output
}

$agent = Join-Path $env:LOCALAPPDATA 'cursor-agent\agent.cmd'
if (-not (Test-Path -LiteralPath $agent)) {
  Write-Error "Cursor agent not found at $agent"
  exit 1
}

if ($Scope -eq 'staged') {
  $diff = Invoke-Git diff --cached --diff-algorithm=minimal
  if (-not $diff) {
    Write-Error 'Nothing staged'
    exit 1
  }
} else {
  $diff = Invoke-Git diff HEAD --diff-algorithm=minimal
  if (-not $diff) {
    Write-Error 'No uncommitted changes'
    exit 1
  }
}

$prompt = @'
You are a commit message generator. Analyze the provided git diff and output ONLY the commit message, nothing else. Rules: Use imperative mood. Start with capital letter. No period at end. Max 72 chars. Be specific. Describe WHAT changed. Never use generic words alone. No conventional commit prefixes. Plain English.
'@

$msg = ($diff | & $agent -p $prompt 2>$null | Select-Object -First 1).Trim()
if (-not $msg) {
  Write-Error 'Failed to generate commit message'
  exit 1
}

& git commit -e -m $msg
