# Implementation — RollingCalendar

Module: RollingCalendar/docs/Implementation.md
Purpose: Code blueprint, script inventory, parameter signatures, and constituent manifest for the RollingCalendar tool.
Path: RollingCalendar/docs/Implementation.md
Authors: rgbig, Workspace_AI Governance
Version: 1.1.1
Status: Authoritative Standard
Date: 2026-09-30

---

## 1. Constituent Manifest

| Relative Path | Role / Layer | Primary Entrypoints | Pester Test Suite |
|:---|:---|:---|:---|
| `Invoke-RollingCalendar.ps1` | Main script / orchestrator | Script root | `tests/Invoke-RollingCalendar.Tests.ps1` |
| `tests/Invoke-RollingCalendar.Tests.ps1` | Static quality contract | Pester | — |
| `docs/Architecture.md` | Tripartite — Architecture | — | — |
| `docs/Requirements.md` | Tripartite — Requirements | — | — |
| `docs/Implementation.md` | Tripartite — Implementation | — | — |
| `install/Installation.md` | Install runbook | — | — |
| `.gitignore` | VCS exclusion | — | — |

---

## 2. Script Parameters

| Parameter | Type | Default | Description |
|:---|:---|:---|:---|
| `-Time` | `string` | `'0'` | Scheduler time (`HH:mm`, `HHmm`, `yyyyMMdd_HHmm`, or `yyyyMMdd_HHmmss`). `'0'` = immediate export only. |
| `-Frequency` | `ValidateSet` | `'4w'` | Grid span: `1w`, `2w`, `3w`, `4w`. Also controls scheduler interval. |
| `-OutputDir` / `-o` | `string` | `C:\Temp` | Target directory for generated PDF and temp HTML. |
| `-NoShow` | `switch` | off | Suppresses the default behavior of opening the generated PDF after rendering. |
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
| `Add-SpanEvent` | `Add-` ✓ | Inserts an event entry into its explicit event collection for each day it spans within the supplied window. |
| `Invoke-EdgePdfExport` | `Invoke-` ✓ | Renders the PDF with captured Edge diagnostics and verifies the result. |

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

`Invoke-EdgePdfExport` launches Edge with redirected standard output and error.
It suppresses only the known non-fatal renderer fallback diagnostic after a
nonempty PDF is created; other diagnostics are shown as warnings, while an Edge
failure or missing PDF terminates the run.

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
| Temp HTML | `temp_calendar.html` (overwritten each run) |
| Default directory | `C:\Temp` |
