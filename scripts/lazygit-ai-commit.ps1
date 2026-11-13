# ponytail: lazygit AI commit via `claude --print`
param(
  [Parameter(Mandatory)]
  [ValidateSet('staged', 'all')]
  [string]$Scope
)

$ErrorActionPreference = 'Stop'

# Override with $env:CLAUDE_COMMIT_MODEL
$DefaultModel = 'haiku'
$MaxDiffChars = 32000

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

function Invoke-ClaudePrint {
  param(
    [string]$Query,
    [string]$Model
  )
  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Error 'claude CLI not found on PATH'
    exit 1
  }
  $output = & claude --model $Model --print $Query 2>&1
  if ($LASTEXITCODE -ne 0) {
    $err = ($output | Out-String).Trim()
    if ($err -ne '') {
      Write-Error "Claude failed: $err"
    } else {
      Write-Error 'Claude failed'
    }
    exit 1
  }
  return ($output | Out-String).Trim()
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

if ($diff.Length -gt $MaxDiffChars) {
  $diff = $diff.Substring(0, $MaxDiffChars) + "`n... (diff truncated)"
}

$model = if ($env:CLAUDE_COMMIT_MODEL -and $env:CLAUDE_COMMIT_MODEL.Trim() -ne '') {
  $env:CLAUDE_COMMIT_MODEL.Trim()
} else {
  $DefaultModel
}

$prompt = @'
You are a commit message generator. Analyze the git diff below and output ONLY the commit message, nothing else.

Rules: imperative mood; start with a capital letter; no period at end; max 72 characters; be specific about WHAT changed; no conventional-commit prefixes; plain English.

Diff:
'@

$query = $prompt + "`n" + $diff
$raw = Invoke-ClaudePrint -Query $query -Model $model
$msg = ($raw -split "`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -First 1).Trim()
if (-not $msg) {
  Write-Error 'Failed to generate commit message'
  exit 1
}

& git commit -e -m $msg
