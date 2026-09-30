# RollingCalendar

Renders a rolling Outlook calendar view (1–4 weeks from the current Monday) as a DIN A4 landscape PDF via Microsoft Edge Headless.

## Tripartite Specifications

| Document | Purpose |
|:---|:---|
| [Architecture.md](docs/Architecture.md) | Operator mental model, entry points, output topology |
| [Requirements.md](docs/Requirements.md) | Prerequisites, normative invariants, error handling |
| [Implementation.md](docs/Implementation.md) | Script inventory, parameter signatures, constituent manifest |

## Quick Start

```powershell
# Immediate 4-week PDF export
.\Invoke-RollingCalendar.ps1

# 2-week export, open after rendering
.\Invoke-RollingCalendar.ps1 -Frequency 2w -OpenAfterExport

# Schedule weekly export every Monday at 06:00 (requires elevation)
.\Invoke-RollingCalendar.ps1 -Time 06:00 -Frequency 1w
```

## Installation

See [install/Installation.md](install/Installation.md) for the full 7-phase runbook.
