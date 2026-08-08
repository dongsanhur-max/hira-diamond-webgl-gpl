<#
.SYNOPSIS
  Starts, stops, restarts, or reports the local Claude review watcher.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("start", "stop", "restart", "status")]
    [string]$Action = "status",
    [string]$Branch = "compat/t4c-scale-calibration",
    [int]$PollSeconds = 90,
    [int]$ReviewTimeoutSeconds = 300
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WatcherPath = Join-Path $ScriptDir "watch-and-review.ps1"
$StateDir = Join-Path $ScriptDir ".state"
$LogsDir = Join-Path $ScriptDir ".logs"
$ControlFile = Join-Path $StateDir "watcher-process.json"

foreach ($dir in @($StateDir, $LogsDir)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

function Get-ControlState {
    if (-not (Test-Path -LiteralPath $ControlFile)) { return $null }
    try { return Get-Content -LiteralPath $ControlFile -Raw | ConvertFrom-Json } catch { return $null }
}

function Get-WatcherProcess {
    $state = Get-ControlState
    if (-not $state) { return $null }
    return Get-Process -Id $state.pid -ErrorAction SilentlyContinue
}

function Show-Status {
    $state = Get-ControlState
    $process = Get-WatcherProcess
    if ($process) {
        Write-Output "RUNNING pid=$($process.Id) branch=$($state.branch) started=$($state.startedAt)"
        Write-Output "stdout=$($state.stdoutLog)"
        Write-Output "stderr=$($state.stderrLog)"
        return
    }
    if ($state) { Write-Output "STOPPED stalePid=$($state.pid) branch=$($state.branch)" }
    else { Write-Output "STOPPED" }
}

function Stop-Watcher {
    $process = Get-WatcherProcess
    if ($process) {
        Stop-Process -Id $process.Id
        $process.WaitForExit(5000) | Out-Null
        Write-Output "Stopped watcher pid=$($process.Id)."
    } else {
        Write-Output "Watcher is not running."
    }
    Remove-Item -LiteralPath $ControlFile -Force -ErrorAction SilentlyContinue
}

function Start-Watcher {
    $existing = Get-WatcherProcess
    if ($existing) {
        throw "Watcher is already running with pid=$($existing.Id). Use restart to replace it."
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $stdoutLog = Join-Path $LogsDir "watcher-$stamp.log"
    $stderrLog = Join-Path $LogsDir "watcher-$stamp.err.log"
    $powerShell = (Get-Command powershell.exe -ErrorAction Stop).Source
    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ('"{0}"' -f $WatcherPath),
        "-Branch", ('"{0}"' -f $Branch),
        "-PollSeconds", $PollSeconds,
        "-ReviewTimeoutSeconds", $ReviewTimeoutSeconds
    )

    $process = Start-Process -FilePath $powerShell `
        -ArgumentList $arguments `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -PassThru

    Start-Sleep -Milliseconds 750
    if ($process.HasExited) {
        $errorText = if (Test-Path $stderrLog) { Get-Content $stderrLog -Raw } else { "" }
        throw "Watcher exited during startup (exit=$($process.ExitCode)): $errorText"
    }

    @{
        pid = $process.Id
        branch = $Branch
        startedAt = (Get-Date -Format "o")
        stdoutLog = $stdoutLog
        stderrLog = $stderrLog
    } | ConvertTo-Json | Set-Content -LiteralPath $ControlFile -Encoding utf8

    Write-Output "Started watcher pid=$($process.Id) for origin/$Branch."
    Write-Output "stdout=$stdoutLog"
    Write-Output "stderr=$stderrLog"
}

switch ($Action) {
    "start" { Start-Watcher }
    "stop" { Stop-Watcher }
    "restart" { Stop-Watcher; Start-Watcher }
    "status" { Show-Status }
}
