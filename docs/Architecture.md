# Architecture — RollingCalendar

Module: RollingCalendar/docs/Architecture.md
Purpose: Operator mental model, CLI entry points, data-flow topology, and external boundaries for the RollingCalendar tool.
Path: RollingCalendar/docs/Architecture.md
Authors: rgbig, Workspace_AI Governance
Version: 1.1.1
Status: Authoritative Standard
Date: 2026-09-30

---

## 1. Overview

**RollingCalendar** is a single-script PowerShell tool that produces a DIN A4 landscape PDF calendar from an Outlook ICS feed. The PDF covers 1 to 4 rolling weeks starting from the current Monday, suitable for direct printing or archiving.

```
Operator
   │
   ▼
Invoke-RollingCalendar.ps1
   │
   ├─► HKCU:\Environment       (ICS URL persistence)
   ├─► Outlook ICS Feed URL    (HTTP/HTTPS fetch)
   ├─► RFC 5545 ICS Parser     (in-memory, no external module)
   ├─► HTML Matrix Generator   (inline here-string template)
   ├─► Microsoft Edge Headless (--print-to-pdf)
   └─► C:\Temp\Calendar_NW_YYYY-MM-DD.pdf
```

---

## 2. CLI Entry Points

| Invocation | Effect |
|:---|:---|
| `.\Invoke-RollingCalendar.ps1` | Immediate 4-week PDF export |
| `.\Invoke-RollingCalendar.ps1 -Frequency 2w` | 2-week grid |
| `.\Invoke-RollingCalendar.ps1 -Time 06:00` | Register weekly Task Scheduler job + immediate export |
| `.\Invoke-RollingCalendar.ps1 -NoShow` | Export without opening the PDF viewer |
| `.\Invoke-RollingCalendar.ps1 -SendToPrinter` | Export then print to Windows default printer |
| `.\Invoke-RollingCalendar.ps1 -ResetUrl` | Force re-entry of ICS URL and persist to registry |

---

## 3. ICS URL Persistence

The Outlook ICS publishing URL is stored once in `HKCU:\Environment` under the variable name `OUTLOOK_ROLLING_CALENDAR_ICS_URL`. On subsequent runs the URL is read from the registry without prompting. `-ResetUrl` forces re-prompt and overwrites the stored value.

---

## 4. Self-Elevation Model

Task Scheduler registration requires administrator privileges. When `-Time` is provided and the current session is not elevated, the script relaunches itself via `Start-Process -Verb RunAs`, passing all original parameters. The non-elevated process exits immediately after dispatch.

---

## 5. Calendar Grid Model

| Parameter | Grid width | Weeks rendered |
|:---|:---|:---|
| `-Frequency 1w` | 7 columns × 1 row | Current week Mon–Sun |
| `-Frequency 2w` | 7 columns × 2 rows | 14 days |
| `-Frequency 3w` | 7 columns × 3 rows | 21 days |
| `-Frequency 4w` (default) | 7 columns × 4 rows | 28 days |

The grid always starts on the **Monday of the current calendar week**.

---

## 6. Output Topology

```
RollingCalendar\
├── Invoke-RollingCalendar.ps1
├── .gitignore
├── README.md
├── docs\
│   ├── Architecture.md
│   ├── Requirements.md
│   └── Implementation.md
├── install\
│   └── Installation.md
```

Generated PDFs and temporary HTML are written to `C:\Temp` by default, outside
the repository working tree.
```
