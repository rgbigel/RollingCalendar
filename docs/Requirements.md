# Requirements — RollingCalendar

Module: RollingCalendar/docs/Requirements.md
Purpose: Normative technical constraints, environmental prerequisites, and safety invariants for the RollingCalendar tool.
Path: RollingCalendar/docs/Requirements.md
Authors: rgbig, Workspace_AI Governance
Version: 1.0.0
Status: Authoritative Standard
Date: 2026-09-30

---

## 1. Environmental Prerequisites

| Requirement | Constraint |
|:---|:---|
| **PowerShell** | 7.0 or later (`pwsh`) |
| **OS** | Windows 10 / Windows 11 |
| **Microsoft Edge** | Installed at `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe` or `C:\Program Files\Microsoft\Edge\Application\msedge.exe` |
| **Internet access** | Reachable HTTPS endpoint for the Outlook ICS URL |
| **Elevation** | Required only when `-Time` is provided (Task Scheduler registration) |
| **Registry access** | Read/write to `HKCU:\Environment` for ICS URL persistence |

---

## 2. Normative Invariants

- **MUST** declare `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` at script scope.
- **MUST** validate the ICS URL via HTTP 200 + `BEGIN:VCALENDAR` check before persisting to registry.
- **MUST NOT** schedule a Task Scheduler trigger in the past; the first Monday candidate is always advanced by 7 days if it falls at or before the current timestamp.
- **MUST** unfold RFC 5545 folded lines before parsing VEVENT blocks.
- **MUST** HTML-encode all event summaries before injection into the HTML template (`[System.Web.HttpUtility]::HtmlEncode`).
- **MUST** write the temporary HTML file as UTF-8 (`Set-Content -Encoding utf8`) before dispatching Edge Headless.
- **MUST** exclude `output\` and `temp_calendar.html` from version control via `.gitignore`.

---

## 3. RRULE Support Invariants

| Rule token | Supported |
|:---|:---|
| `FREQ=DAILY` | Yes |
| `FREQ=WEEKLY` | Yes, with optional `BYDAY` |
| `FREQ=MONTHLY` | Yes |
| `INTERVAL=N` | Yes |
| `UNTIL=YYYYMMDD` | Yes |
| `COUNT=N` | Yes (hard-capped at 500 to prevent runaway expansion) |
| `FREQ=YEARLY` | No (falls through to single-event render) |

---

## 4. Error Handling

| Condition | Behavior |
|:---|:---|
| ICS URL not reachable | `Write-Warning`; operator prompted to re-enter URL |
| Invalid time format | Interactive re-prompt loop until valid or `0` supplied |
| Edge not found at primary path | Falls back to secondary path; if both missing, `Start-Process` throws |
| ICS fetch fails at runtime | `catch` block re-prompts for URL, then retries once |

---

## 5. Security Constraints

- ICS URL stored in `HKCU:\Environment` (current user only, no machine-wide exposure).
- Task Scheduler action uses `-WindowStyle Hidden` to suppress console windows during scheduled runs.
- No credentials are stored; the ICS URL is treated as a pre-authorized sharing link.
