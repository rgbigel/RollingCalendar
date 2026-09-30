# Installation — RollingCalendar

Module: RollingCalendar/install/Installation.md
Purpose: 7-phase installation and servicing runbook for the RollingCalendar tool.
Path: RollingCalendar/install/Installation.md
Authors: rgbig, Workspace_AI Governance
Version: 1.1.1
Status: Authoritative Standard
Date: 2026-09-30

---

## Phase 1 — Prerequisites & Environmental Dependencies

| Requirement | Verification Command |
|:---|:---|
| PowerShell 7+ | `pwsh --version` |
| Microsoft Edge installed | `Test-Path 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'` |
| Internet access to Outlook ICS URL | `Invoke-WebRequest -Uri <your-ics-url> -UseBasicParsing` |
| User write access to `HKCU:\Environment` | `Set-ItemProperty -Path HKCU:\Environment -Name TEST -Value 1; Remove-ItemProperty -Path HKCU:\Environment -Name TEST` |

No third-party modules or NuGet packages are required.

---

## Phase 2 — Target Destination Layout

```
D:\Git_Repositories\RollingCalendar\     <- repository root
├── Invoke-RollingCalendar.ps1           <- operator entrypoint
├── .gitignore
├── README.md
├── docs\                                <- tripartite specifications
├── install\                             <- this runbook
```

The operator invokes the script directly from the repository root or via a shortcut / scheduled task.
Generated PDFs and temporary HTML are written to `C:\Temp` by default.

---

## Phase 3 — Preflight System Health Checks

```powershell
# Verify Edge path
$edgePrimary   = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$edgeSecondary = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe'
if (-not (Test-Path $edgePrimary) -and -not (Test-Path $edgeSecondary)) {
  Write-Error 'Microsoft Edge not found. Install Edge before proceeding.'
}

# Verify PowerShell edition
if ($PSVersionTable.PSVersion.Major -lt 7) {
  Write-Error 'PowerShell 7 or later required. Run: winget install Microsoft.PowerShell'
}
```

---

## Phase 4 — Step-by-Step Deployment & Configuration

### 4.1 Clone / Place Repository

```powershell
# If cloning from remote
git clone <remote-url> D:\Git_Repositories\RollingCalendar

# If already present, no action required
```

### 4.2 Set Execution Policy (once per machine)

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### 4.3 First Run — ICS URL Registration

```powershell
cd D:\Git_Repositories\RollingCalendar
.\Invoke-RollingCalendar.ps1
```

On first run, the script prompts for the Outlook ICS publishing URL.

**To obtain the Outlook ICS URL:**
1. Open Outlook → Calendar → Share Calendar → Publish to WebDAV / Internet.
2. Copy the ICS link shown under "Published Calendar".
3. Paste it at the prompt.

The URL is verified (HTTP 200 + `BEGIN:VCALENDAR`) and saved to `HKCU:\Environment`.

### 4.4 Optional — Register Weekly Scheduled Task

```powershell
# Requires administrator — script self-elevates automatically
.\Invoke-RollingCalendar.ps1 -Time 06:00 -Frequency 4w -NoShow
```

The task runs every Monday at 06:00, starting from the next non-past Monday.
The script accepts `HH:mm`, `HHmm`, `yyyyMMdd_HHmm`, and
`yyyyMMdd_HHmmss` for `-Time`; timestamps are normalized to their time of day.

---

## Phase 5 — Post-Deployment Verification & Health Checks

```powershell
# Confirm ICS URL is stored
(Get-ItemProperty -Path HKCU:\Environment -Name OUTLOOK_ROLLING_CALENDAR_ICS_URL).OUTLOOK_ROLLING_CALENDAR_ICS_URL

# Confirm PDF was generated
Get-ChildItem C:\Temp\Calendar_*.pdf | Select-Object Name, LastWriteTime
```

---

## Phase 6 — Ongoing Servicing & Update Runbook

1. Pull latest changes: `git -C D:\Git_Repositories\RollingCalendar pull`
2. Re-run the script to verify output: `.\Invoke-RollingCalendar.ps1`
3. If the Outlook ICS URL changes: `.\Invoke-RollingCalendar.ps1 -ResetUrl`
4. To update the Task Scheduler job (new time or frequency):
   ```powershell
   Unregister-ScheduledTask -TaskName 'Outlook-RollingCalendar-Export' -Confirm:$false
   .\Invoke-RollingCalendar.ps1 -Time 07:00 -Frequency 2w
   ```

---

## Phase 7 — Rollback & Uninstallation

```powershell
# Remove scheduled task
Unregister-ScheduledTask -TaskName 'Outlook-RollingCalendar-Export' -Confirm:$false

# Remove stored ICS URL from registry
Remove-ItemProperty -Path HKCU:\Environment -Name OUTLOOK_ROLLING_CALENDAR_ICS_URL -ErrorAction SilentlyContinue

# Remove repository directory
Remove-Item -Path D:\Git_Repositories\RollingCalendar -Recurse -Force
```
