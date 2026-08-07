<#
.SYNOPSIS
  Cleans up the T5 tunnel (dev server + cloudflared) if start-t5-tunnel.ps1
  didn't exit cleanly via Ctrl+C.

.DESCRIPTION
  start-t5-tunnel.ps1 normally stops both processes itself when you press
  Ctrl+C. But Start-Process children are independent OS processes, so if
  that script's window/process gets killed some other way instead, they
  can leak. This reads the PID file start-t5-tunnel.ps1 writes and force-
  stops both, plus (as a last-resort fallback) anything still listening on
  port 5173 or any cloudflared.exe process, in case the PID file itself is
  stale or missing.

.EXAMPLE
  .\stop-t5-tunnel.ps1
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $ScriptDir ".tmp\t5-tunnel.pids.json"

if (Test-Path $pidFile) {
    $ids = Get-Content $pidFile -Raw | ConvertFrom-Json
    foreach ($p in @($ids.vitePid, $ids.cloudflaredPid)) {
        if ($p) {
            Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
        }
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    Write-Host "Stopped processes recorded in $pidFile"
} else {
    Write-Host "No PID file found at $pidFile -- nothing recorded to stop."
}

# Fallback: catch anything the PID file missed (e.g. it was stale).
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$portOwner = Get-NetTCPConnection -LocalPort 5173 -State Listen -ErrorAction SilentlyContinue
if ($portOwner) {
    foreach ($conn in $portOwner) {
        Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Done. Verify with: netstat -ano | findstr :5173  (should be empty) and Get-Process cloudflared (should error)."
