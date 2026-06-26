# ponytail: Windows-native lazygit AI commit via Cursor agent --print (direct node.exe; no agent.cmd hop)
param(
  [Parameter(Mandatory)]
  [ValidateSet('staged', 'all')]
  [string]$Scope
)

$ErrorActionPreference = 'Stop'

# Match lua/custom/cursor_agent.lua MODEL_COMMIT; override with $env:CURSOR_COMMIT_MODEL
$DefaultModel = 'composer-2.5-fast'
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

function Get-CursorAgentEntrypoint {
  $base = Join-Path $env:LOCALAPPDATA 'cursor-agent\versions'
  if (-not (Test-Path -LiteralPath $base)) {
    return $null
  }
  $latest = Get-ChildItem -LiteralPath $base -Directory |
    Where-Object { -not $_.Name.EndsWith('.zip') } |
    Sort-Object Name |
    Select-Object -Last 1
  if (-not $latest) {
    return $null
  }
  $node = Join-Path $latest.FullName 'node.exe'
  $index = Join-Path $latest.FullName 'index.js'
  if (-not (Test-Path -LiteralPath $node) -or -not (Test-Path -LiteralPath $index)) {
    return $null
  }
  return @{ Node = $node; Index = $index }
}

function Invoke-CursorPrint {
  param(
    [string]$Query,
    [string]$Model
  )
  $entry = Get-CursorAgentEntrypoint
  if (-not $entry) {
    Write-Error 'Cursor agent not found under %LOCALAPPDATA%\cursor-agent\versions'
    exit 1
  }
  if (-not $env:NODE_COMPILE_CACHE) {
    $env:NODE_COMPILE_CACHE = Join-Path $env:LOCALAPPDATA 'cursor-compile-cache'
  }
  $env:CURSOR_INVOKED_AS = 'agent'
  $output = & $entry.Node $entry.Index --trust --force --model $Model --print --output-format text $Query 2>&1
  if ($LASTEXITCODE -ne 0) {
    $err = ($output | Out-String).Trim()
    if ($err -ne '') {
      Write-Error "Cursor agent failed: $err"
    } else {
      Write-Error 'Cursor agent failed'
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

$model = if ($env:CURSOR_COMMIT_MODEL -and $env:CURSOR_COMMIT_MODEL.Trim() -ne '') {
  $env:CURSOR_COMMIT_MODEL.Trim()
} else {
  $DefaultModel
}

$prompt = @'
You are a commit message generator. Analyze the git diff below and output ONLY the commit message, nothing else.

Rules: imperative mood; start with a capital letter; no period at end; max 72 characters; be specific about WHAT changed; no conventional-commit prefixes; plain English.

Diff:
'@

$query = $prompt + "`n" + $diff
$raw = Invoke-CursorPrint -Query $query -Model $model
$msg = ($raw -split "`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -First 1).Trim()
if (-not $msg) {
  Write-Error 'Failed to generate commit message'
  exit 1
}

& git commit -e -m $msg
