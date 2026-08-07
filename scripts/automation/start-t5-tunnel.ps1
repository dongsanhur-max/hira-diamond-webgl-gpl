<#
.SYNOPSIS
  Starts a temporary public HTTPS URL for T5 mobile device testing.

.DESCRIPTION
  Starts the Vite dev server (with server.allowedHosts widened just for
  this session -- see t5-tunnel-vite.config.mjs) and a Cloudflare quick
  tunnel (cloudflared) pointed at it, then prints the public
  *.trycloudflare.com URL to use on the test devices.

  This is a temporary, account-less tunnel per docs/TEST_PLAN.md's T5
  network requirement (a real HTTPS URL reachable on Wi-Fi and mobile
  data). It is NOT a deployment: nothing is published anywhere persistent,
  no DNS changes are made, and the URL stops working the moment this
  script exits. Press Ctrl+C when testing is done to stop both processes.

.PARAMETER CloudflaredPath
  Path to the standalone cloudflared.exe (no install required). Defaults
  to the copy already downloaded to hira-review-automation\bin.

.EXAMPLE
  .\start-t5-tunnel.ps1
#>

[CmdletBinding()]
param(
    [string]$CloudflaredPath = "C:\Users\chuck\hira-review-automation\bin\cloudflared.exe"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$ConfigPath = Join-Path $ScriptDir "t5-tunnel-vite.config.mjs"

if (-not (Test-Path $CloudflaredPath)) {
    Write-Error "cloudflared not found at $CloudflaredPath. Download it from https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    exit 1
}

$tmpDir = Join-Path $ScriptDir ".tmp"
if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null }

Write-Host "Starting Vite dev server (allowedHosts widened for tunnel testing only)..."
# Start-Process needs the actual .cmd shim, not the bare "npx" name -- the
# bare name resolves via PATHEXT for `&` / cmd.exe but not for Start-Process,
# which otherwise tries to launch it as a native binary and fails.
$viteOutLog = Join-Path $tmpDir "vite-tunnel.log"
$viteErrLog = Join-Path $tmpDir "vite-tunnel.err.log"
$vite = Start-Process -FilePath "npx.cmd" -ArgumentList "vite --config `"$ConfigPath`"" -WorkingDirectory $RepoRoot -PassThru -WindowStyle Hidden -RedirectStandardOutput $viteOutLog -RedirectStandardError $viteErrLog
Start-Sleep -Seconds 4

Write-Host "Starting Cloudflare quick tunnel..."
$tunnelLog = Join-Path $tmpDir "cloudflared-tunnel.log"
$tunnelErrLog = Join-Path $tmpDir "cloudflared-tunnel.err.log"
$cloudflared = Start-Process -FilePath $CloudflaredPath -ArgumentList "tunnel --url http://localhost:5173" -PassThru -WindowStyle Hidden -RedirectStandardOutput $tunnelLog -RedirectStandardError $tunnelErrLog

$publicUrl = $null
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 1
    # cloudflared logs its INF lines (including the assigned URL) to stderr,
    # not stdout -- search both since which stream carries it isn't a
    # promise worth relying on.
    foreach ($logFile in @($tunnelErrLog, $tunnelLog)) {
        if (Test-Path $logFile) {
            $match = Select-String -Path $logFile -Pattern "https://[a-z0-9-]+\.trycloudflare\.com" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($match) {
                $publicUrl = $match.Matches[0].Value
                break
            }
        }
    }
    if ($publicUrl) {
        break
    }
}

if (-not $publicUrl) {
    Write-Error "Tunnel URL did not appear within 20 seconds -- check $tunnelLog"
    Stop-Process -Id $vite.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $cloudflared.Id -Force -ErrorAction SilentlyContinue
    exit 1
}

# Safety net: Start-Process children are independent OS processes, not tied
# to this script's lifetime. Ctrl+C hits the finally block below and cleans
# them up correctly, but an abrupt kill of this script itself (closing the
# terminal, a task-manager kill, etc.) skips finally and leaks them running
# -- confirmed happening in testing. Write their PIDs so stop-t5-tunnel.ps1
# can clean up after the fact if that happens.
$pidFile = Join-Path $tmpDir "t5-tunnel.pids.json"
@{ vitePid = $vite.Id; cloudflaredPid = $cloudflared.Id; startedAt = (Get-Date -Format "o") } |
    ConvertTo-Json | Set-Content -Path $pidFile -Encoding utf8

Write-Host ""
Write-Host "=================================================================="
Write-Host "  T5 test URL (temporary, expires when this script stops):"
Write-Host "  $publicUrl/jewelry/"
Write-Host "=================================================================="
Write-Host ""
Write-Host "Open that URL on the test device(s) over Wi-Fi, then again over"
Write-Host "mobile data, per docs/TEST_PLAN.md section 11. Press Ctrl+C here"
Write-Host "when done to stop the tunnel and dev server."
Write-Host "(If this window gets closed/killed some other way instead, run"
Write-Host " stop-t5-tunnel.ps1 afterward to make sure both processes stopped.)"
Write-Host ""

try {
    Wait-Process -Id $cloudflared.Id
} finally {
    Write-Host "Stopping tunnel and dev server..."
    Stop-Process -Id $cloudflared.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Id $vite.Id -Force -ErrorAction SilentlyContinue
}
