param(
    [string]$Root = ""
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

Write-Host ""
Write-Host "  ⚠️ Cowork bash wc -c may report stale byte counts due to mount-protocol caching" -ForegroundColor Yellow
Write-Host "     → Verify using this PS1 script on the Windows host and the Read tool, not bash alone" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Historical incidents (ten total):" -ForegroundColor Gray
Write-Host "    - RETRO-005 card 2       Health.jsx mount cache returned old byte counts" -ForegroundColor Gray
Write-Host "    - PM self-corrections #9 / #12       PS1 sync failure / warning mismatch" -ForegroundColor Gray
Write-Host "    - PM self-corrections #23 / #25      F-PREP-1 byte differences -5129B / -2913B" -ForegroundColor Gray
Write-Host "    - PM self-corrections #26 / #32 / #36 F-BRIEFING-1 / F-DEVIATION-2 differences including -4111B / -2913B" -ForegroundColor Gray
Write-Host "    - PROP-018 P1           Read verification confirmed writes after splitting CHANGELOG" -ForegroundColor Gray
Write-Host ""
Write-Host "  Four Cowork PM safeguards implemented under issue D:" -ForegroundColor Cyan
Write-Host "    ① Verify caution/danger file sizes with Read; do not rely on bash wc -c" -ForegroundColor Green
Write-Host "    ② After Edit / Write / apply_patch changes to framework files, immediately Read the tail to verify the write" -ForegroundColor Green
Write-Host "    ③ Refresh the mount or restart the Cowork session when git status differs" -ForegroundColor Green
Write-Host "    ④ For P4b caution-list byte counts, trust PS1 on the Windows host over Cowork bash" -ForegroundColor Green
Write-Host ""
Write-Host "  Issue D status: P0 → PROP-018 P2 implemented (2026-05-13)" -ForegroundColor Gray
Write-Host "  Follow-up: at PROP-018 P6 archival, consolidate with issues V/X/P into ADR-022 (cross-tool synchronization)" -ForegroundColor Gray

exit 0
