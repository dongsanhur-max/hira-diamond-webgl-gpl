<#
.SYNOPSIS
  Watches a git branch for new commits and runs a headless Claude Code
  self-check review against it, for the hira-diamond-webgl-gpl project.

.DESCRIPTION
  This is a PRELIMINARY SELF-CHECK ONLY. A headless `claude -p` review is
  a fresh, stateless session with no access to the interactive Claude Code
  conversation's accumulated project context. It is a useful pre-filter to
  catch obvious issues before Codex hands off, but it does NOT replace
  review inside the interactive conversation, and it carries NO commit or
  push authority. This script itself never edits, commits, or pushes
  anything in the project repo — it only reads (via git fetch + diff, and
  a headless Claude session restricted to read-only tools) and writes
  report files under scripts\automation\.reports\ (git-ignored).

.PARAMETER RepoPath
  Path to the local clone of hira-diamond-webgl-gpl. Only `git fetch` and
  read-only diff/log commands are run here; the working tree is never
  checked out or modified by this script.

.PARAMETER Branch
  Remote branch to watch (default: compat/t4c-scale-calibration).

.PARAMETER BaseBranch
  Branch to diff against on first run, before any state is recorded
  (default: main).

.PARAMETER TaskBriefPath
  Markdown file with the task assignment Codex is working from. Its
  content is included in the review prompt so the self-check can verify
  the diff against the actual brief, not just general project docs.

.PARAMETER PollSeconds
  Seconds between checks when watching continuously (default: 90).

.PARAMETER Once
  Run a single check-and-exit instead of an infinite watch loop. Useful
  for a first manual test, or for wiring into Task Scheduler yourself
  instead of using the built-in loop.

.EXAMPLE
  # One-off manual test
  .\watch-and-review.ps1 -Once

.EXAMPLE
  # Continuous watch (leave running in its own terminal)
  .\watch-and-review.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoPath = "",
    [string]$Branch = "compat/t4c-scale-calibration",
    [string]$BaseBranch = "main",
    [string]$TaskBriefPath = "",
    [int]$PollSeconds = 90,
    [switch]$Once
)

$ErrorActionPreference = "Stop"

# $PSScriptRoot can be empty inside param() default-value expressions under
# Windows PowerShell 5.1 when invoked via `-File`; resolve paths here instead.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $RepoPath)      { $RepoPath = Split-Path -Parent (Split-Path -Parent $ScriptDir) }
if (-not $TaskBriefPath) { $TaskBriefPath = Join-Path $ScriptDir "task-briefs\t4c-scale-calibration.md" }

$StateDir   = Join-Path $ScriptDir ".state"
$ReportsDir = Join-Path $ScriptDir ".reports"
$TmpDir     = Join-Path $ScriptDir ".tmp"
foreach ($d in @($StateDir, $ReportsDir, $TmpDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
}

$BranchSafeName = ($Branch -replace '[\\/:*?"<>|]', '_')
$StateFile = Join-Path $StateDir "$BranchSafeName.json"

function Write-Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] $msg"
}

function Get-State {
    if (Test-Path $StateFile) {
        try { return Get-Content $StateFile -Raw | ConvertFrom-Json } catch { return $null }
    }
    return $null
}

function Save-State($lastReviewedSha) {
    $obj = @{ branch = $Branch; lastReviewedSha = $lastReviewedSha; updatedAt = (Get-Date -Format "o") }
    $obj | ConvertTo-Json | Set-Content -Path $StateFile -Encoding utf8
}

function Invoke-ReviewCheck {
    Write-Log "Fetching origin/$Branch and origin/$BaseBranch ..."
    try {
        & git -C $RepoPath fetch origin $Branch $BaseBranch --quiet 2>$null
    } catch {
        Write-Log "git fetch failed: $_"
        return
    }

    $remoteSha = (& git -C $RepoPath rev-parse "origin/$Branch" 2>$null)
    if (-not $remoteSha) {
        Write-Log "origin/$Branch does not exist yet (Codex hasn't pushed). Waiting."
        return
    }
    $remoteSha = $remoteSha.Trim()

    $state = Get-State
    $lastReviewedSha = if ($state) { $state.lastReviewedSha } else { $null }

    if ($lastReviewedSha -eq $remoteSha) {
        Write-Log "No new commits on $Branch since last check ($($remoteSha.Substring(0,10)))."
        return
    }

    $baseSha = $lastReviewedSha
    if (-not $baseSha) {
        $baseSha = (& git -C $RepoPath merge-base "origin/$BaseBranch" "origin/$Branch" 2>$null)
        if (-not $baseSha) {
            Write-Log "Could not compute merge-base with origin/$BaseBranch; skipping this cycle."
            return
        }
        $baseSha = $baseSha.Trim()
    }

    if ($baseSha -eq $remoteSha) {
        Write-Log "Base and head are identical ($($remoteSha.Substring(0,10))); nothing to review yet."
        Save-State $remoteSha
        return
    }

    Write-Log "New commit(s) detected on ${Branch}: $($baseSha.Substring(0,10)) -> $($remoteSha.Substring(0,10)). Building review prompt..."

    $commitLog = & git -C $RepoPath log --oneline "$baseSha..$remoteSha" 2>$null
    $diffText  = & git -C $RepoPath diff "$baseSha..$remoteSha" 2>$null

    if (-not $diffText) {
        Write-Log "Diff came back empty; skipping this cycle without advancing state (will retry)."
        return
    }

    $taskBrief = if (Test-Path $TaskBriefPath) {
        Get-Content $TaskBriefPath -Raw
    } else {
        "(Task brief file not found at $TaskBriefPath -- review against general project docs only.)"
    }

    $promptHeader = @"
SELF-CHECK ONLY -- this is a headless, stateless pre-filter run, not the
final project review. Say so plainly at the top of your output. The
interactive Claude Code conversation for this project still performs the
real review before anything gets treated as accepted; this run has no
commit/push authority and must not attempt to edit, commit, or push
anything itself.

You are reviewing a git diff from the hira-diamond-webgl-gpl repository,
branch '$Branch', range $baseSha..$remoteSha. Read $RepoPath\AGENTS.md,
$RepoPath\docs\DEFINITION_OF_DONE.md, $RepoPath\docs\TEST_PLAN.md, and
$RepoPath\docs\MODEL_AND_FILE_RULES.md yourself for the exact governance
rules -- do not rely only on the summary below.

The task this diff is supposed to implement:
---- TASK BRIEF START ----
$taskBrief
---- TASK BRIEF END ----

Commit log for this range:
---- COMMIT LOG START ----
$commitLog
---- COMMIT LOG END ----

Check specifically:
1. Did the diff touch any of the six protected .min.js files listed in
   AGENTS.md section 4? That is an automatic FAIL if so, no exceptions.
2. Does the diff stay within the "Owned files or globs" listed in the task
   brief? Flag anything outside that scope.
3. Does the diff attempt to fix the T4 material-role FAIL (metal/diamond
   shader distinction)? That is explicitly out of scope for this task --
   flag it if attempted.
4. Is there any attempt to merge into main, or any git config/remote change?
   Flag it.
5. For the actual scale-calibration work: is the derivation method
   (measuring a real reference dimension rather than reusing the old
   bounding-box-diagonal approximation) followed, and is it evidenced
   (recorded measurements, method, resulting scale) rather than just
   asserted?
6. Evidence discipline: does it preserve prior 0.1111-approximation
   evidence rather than overwriting it, and append new evidence/report
   sections rather than rewriting existing ones?
7. Any CHANGELOG.md entry for the material change, per AGENTS.md section 2?

Report using this project's result labels only: PASS, CONDITIONAL, FAIL,
BLOCKED -- one label per check above, with file/line references, plus one
overall self-check verdict. Keep it concise. End with a one-line reminder
that this is a preliminary self-check and the interactive conversation
still needs to do the real review.

Full diff follows.
---- DIFF START ----
"@

    $promptFooter = @"
---- DIFF END ----
"@

    $combinedFile = Join-Path $TmpDir "$BranchSafeName-$($remoteSha.Substring(0,10)).prompt.txt"
    $promptHeader + $diffText + "`n" + $promptFooter | Set-Content -Path $combinedFile -Encoding utf8

    Write-Log "Invoking headless claude -p (read-only tools, bypassPermissions since unattended)..."
    $reviewOutput = Get-Content -Raw $combinedFile | & claude -p `
        --tools "Read,Grep,Glob,Bash" `
        --permission-mode bypassPermissions `
        --output-format text `
        --no-session-persistence `
        --add-dir $RepoPath 2>&1

    $reportFile = Join-Path $ReportsDir "$BranchSafeName-$($remoteSha.Substring(0,10))-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    $reportHeader = "# Self-check report`n`nBranch: $Branch`nRange: $baseSha..$remoteSha`nGenerated: $(Get-Date -Format 'o')`n`n---`n`n"
    ($reportHeader + ($reviewOutput -join "`n")) | Set-Content -Path $reportFile -Encoding utf8

    Write-Log "Report written: $reportFile"

    $flagged = ($reviewOutput -join "`n") -match "FAIL|BLOCKED"
    try {
        [console]::beep(750, 300)
    } catch {}
    if ($flagged) {
        Write-Log "SELF-CHECK FLAGGED ISSUES (FAIL/BLOCKED found) -- opening report."
        try { Start-Process notepad.exe $reportFile } catch {}
    } else {
        Write-Log "Self-check found no FAIL/BLOCKED labels (still only a preliminary pre-filter, not final review)."
    }

    Save-State $remoteSha
}

Write-Log "Watching $Branch on $RepoPath (base: $BaseBranch). Reports: $ReportsDir"
if ($Once) {
    Invoke-ReviewCheck
} else {
    while ($true) {
        Invoke-ReviewCheck
        Start-Sleep -Seconds $PollSeconds
    }
}
