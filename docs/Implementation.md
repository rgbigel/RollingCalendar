# Implementation — RollingCalendar

Module: RollingCalendar/docs/Implementation.md
Purpose: Code blueprint, script inventory, parameter signatures, and constituent manifest for the RollingCalendar tool.
Path: RollingCalendar/docs/Implementation.md
Authors: rgbig, Workspace_AI Governance
Version: 1.0.0
Status: Authoritative Standard
Date: 2026-09-30

---

## 1. Constituent Manifest

| Relative Path | Role / Layer | Primary Entrypoints | Pester Test Suite |
|:---|:---|:---|:---|
| `Invoke-RollingCalendar.ps1` | Main script / orchestrator | Script root | — |
| `docs/Architecture.md` | Tripartite — Architecture | — | — |
| `docs/Requirements.md` | Tripartite — Requirements | — | — |
| `docs/Implementation.md` | Tripartite — Implementation | — | — |
| `install/Installation.md` | Install runbook | — | — |
| `.gitignore` | VCS exclusion | — | — |
| `output/` | PDF output directory (git-ignored) | — | — |

---

## 2. Script Parameters

| Parameter | Type | Default | Description |
|:---|:---|:---|:---|
| `-Time` | `string` | `'0'` | Scheduler time (HH:mm / HHmm). `'0'` = immediate export only. |
| `-Frequency` | `ValidateSet` | `'4w'` | Grid span: `1w`, `2w`, `3w`, `4w`. Also controls scheduler interval. |
| `-OutputDir` | `string` | `"$PSScriptRoot\output"` | Target directory for generated PDF and temp HTML. |
| `-OpenAfterExport` | `switch` | off | Opens generated PDF in default viewer after rendering. |
| `-SendToPrinter` | `switch` | off | Sends PDF to Windows default printer after rendering. |
| `-ResetUrl` | `switch` | off | Forces re-prompt and re-persistence of the ICS URL. |

---

## 3. Internal Functions

| Function | Verb compliance | Purpose |
|:---|:---|:---|
| `Test-IsAdmin` | `Test-` ✓ | Returns `$true` if running as Administrator. |
| `Resolve-ValidTime` | `Resolve-` ✓ | Interactive loop validating and normalizing HH:mm / HHmm input; returns `$null` for `'0'`. |
| `Test-IcsUrl` | `Test-` ✓ | HTTP GET probe confirming URL returns HTTP 200 and `BEGIN:VCALENDAR`. |
| `Get-OrPromptIcsUrl` | `Get-` ✓ | Reads ICS URL from `HKCU:\Environment`; prompts and persists if absent or `-ResetUrl`. |
| `Register-CalendarTask` | `Register-` ✓ | Creates a weekly Task Scheduler job starting on the next non-past Monday. |
| `Add-SpanEvent` | `Add-` ✓ | Inserts an event entry into `$events` hashtable for each day it spans within the window. |

---

## 4. Data Structures

### `$events` Hashtable

```
$events = @{
  'YYYY-MM-DD' = [List[PSCustomObject]] @(
    @{ Time = 'HH:MM'; Summary = '...'; IsMultiDay = $false }
    ...
  )
}
```

Keyed by ISO date string. Populated by `Add-SpanEvent` during ICS parse.

### Edge Headless Invocation

```powershell
Start-Process -FilePath $edgePath -ArgumentList @(
  '--headless',
  '--disable-gpu',
  '--run-all-compositor-stages-before-draw',
  '--no-pdf-header-footer',
  "--print-to-pdf=`"$outputPdf`"",
  "`"$fileUri`""
) -Wait -NoNewWindow
```

---

## 5. Registry Contract

| Key | `HKCU:\Environment` |
|:---|:---|
| **Value name** | `OUTLOOK_ROLLING_CALENDAR_ICS_URL` |
| **Type** | `String` (REG_SZ) |
| **Scope** | Current user only |
| **Lifetime** | Persistent across sessions; overwritten by `-ResetUrl` |

---

## 6. Output Naming Convention

| Artifact | Pattern |
|:---|:---|
| PDF | `Calendar_<N>W_<YYYY-MM-DD>.pdf` |
| Temp HTML | `temp_calendar.html` (overwritten each run, git-ignored) |
