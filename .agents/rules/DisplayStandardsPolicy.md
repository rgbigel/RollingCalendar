---
name: DisplayStandardsPolicy
description: Authoritative governance policy for LCM HTML Displays, Interactive Table Dashboards, CSS Tokens, Sticky Filter Headers, Theme Synchronization, and Desktop Dispatching.
globs: "*"
---
# File: DisplayStandardsPolicy.md

Module: DisplayStandardsPolicy  
Purpose: Governs presentation standards, CSS design system tokens, application topbars, control toolbars, status rails, Lucide iconography, WPF/WinForms desktop GUIs, print-to-PDF paged media, theme persistence, and interactive desktop dispatching across all LCM-generated UI presentations and dashboards.  
Path: .agents/rules/DisplayStandardsPolicy.md  
Authors: Rolf, LCM_AI Governance  
Version: 9.3.0
Status: Authoritative Policy
Date: 2026-10-02

---

## 1. Scope & Motivation

Multiple LCM tools, subsystem viewers, inventory explorers, and diagnostic scripts generate interactive user interfaces across web dashboards (e.g. `Show-LcmControl.ps1`, `Show-ToolsExplorer.ps1`, `Show-Rules.ps1`, `Show-Subsystems.ps1`, `Show-HaInventoryApp.ps1`), native Windows desktop applications (WPF modals, Windows Forms System Tray), headless print matrices, and terminal console atoms.

To ensure a cohesive, professional, accessible, high-performance, and visually unified user experience across all repositories and tools, all LCM presentation layers `MUST` adhere to these authoritative Display Standards.

The architectural pattern established in `LCM_Inventory/assets/CM_CONTROL_HUB_IMPLEMENTATION_0.html` serves as the authoritative reference standard for all modern LCM web applications.

---

## 2. Authoritative Rules

### RULE-DSP-001: Canonical Design System Tokens & Typography
1. **Typography Standard**:
   - **Technical Content**: Code blocks, file paths, IDs (`CRP-###`, `BUG-###`), hashes, parameters, and numerical metrics `MUST` use `IBM Plex Mono` (weights 400, 500, 600), Consolas, monospace.
   - **General Interface**: UI labels, headers, buttons, navigation, and body prose `MUST` use `IBM Plex Sans` (weights 400, 500, 600, 700), "Segoe UI", sans-serif.
2. **Canonical Antigravity-IDE-like Light Mode Color Palette (Default)**:
   All web presentations `MUST` import or embed the canonical design system variables derived from the `CM_CONTROL_HUB_IMPLEMENTATION_0.html` prototype. This color model represents the **Antigravity-IDE-like Light Mode**, which is the **authoritative default for all LCM tools and displays in the future** (crisp light canvas, clean card surfaces, and soft semantic fills contrasted with an authoritative deep-slate topbar and gold accent):
   - **Canvas & Surface Tokens**: `--canvas: #edf1ef`, `--surface: #ffffff`, `--surface-soft: #f6f8f7`, Topbar Deep Slate: `#132b33`, Gold Accent Line: `#d8a840`.
   - **Text & Line Tokens**: Primary Text (`--ink: #172127`), Muted Secondary (`--muted: #5d6b72`), Subtle Line (`--line: #ccd5d1`), Strong Border (`--line-strong: #aab8b2`).
   - **Semantic Status Tokens**:
     - Active / Progress: `--blue: #176b87` (Soft: `--blue-soft: #e0f0f4`)
     - Complete / Healthy: `--green: #2d764d` (Soft: `--green-soft: #e4f2e8`)
     - Review / Attention: `--amber: #9a6510` (Soft: `--amber-soft: #fff2d7`)
     - Blocked / Error: `--red: #a53d36` (Soft: `--red-soft: #fce8e5`)
     - Held / Specialized: `--violet: #6b4c8d` (Soft: `--violet-soft: #eee8f5`)
3. **Zero Hardcoded Colors**: Direct hardcoded styling colors (e.g. `color: #111`, `background: white`) `SHALL NOT` be used in tables, containers, or components; all elements `MUST` reference canonical CSS variables.

### RULE-DSP-002: Antigravity-IDE Light Mode Default & Dynamic Theme Persistence
1. **Light Mode Authoritative Default**:
   - The default, primary presentation of all future LCM dashboards, table viewers, and status displays `MUST` be the **Antigravity-IDE-like Light Mode**.
   - In the absence of an explicit user override stored in `localStorage`, displays `SHALL` initialize in Light Mode.
2. **Dynamic Light/Dark Theme Support**:
   - All interactive viewers `MUST` support dynamic Light (default) and Dark theme modes.
   - The active theme `MUST` synchronize with `localStorage.getItem('lcm_theme')` so that theme preferences persist seamlessly across all tools, tabs, and sessions.
3. **Instantaneous Theme Switching**:
   - Theme switching `SHALL` be instantaneous and toggled via standard UI buttons (`☀️ Theme` / `🌙 Theme`) in the application topbar without requiring a page reload.

### RULE-DSP-003: Application Topbar, Control Row Toolbar & Status Rail Pipeline Architecture
1. **Application Topbar (`.topbar`)**:
   - Deep slate container (`#132b33`) with gold indicator bottom border (`3px solid #d8a840`).
   - Integrated context selector / app switcher (e.g. `Foundation`, `App: 1`).
   - Prominent dynamic tool version pill/badge reflecting the live, authoritative version (`RULE-DSP-016`).
   - Centered global search bar with embedded magnifying glass icon.
   - Live synchronization indicator (`.sync-dot` pulsing green).
   - Top action cluster: Theme toggle, Refresh, Help, and Back navigation.
2. **Compact Control Row Toolbar (`.control-row`)**:
   - A single horizontal toolbar dividing controls into clean segmented `.control-group` dividers for Preset, Mode (`Work queue`), Intern filter check, Status dropdown, Scope dropdown, and Sort selector.
   - Right-aligned Reset button with distinctive red accent (`.reset-button`).
3. **Status Rail Pipeline Bar (`.status-rail`)**:
   - Multi-stage horizontal pipeline visualization showing live proposal counts across states:
     `Open` (recorded) $\rightarrow$ `Active` (in progress) $\rightarrow$ `Review` (BCR disposition) $\rightarrow$ `Complete` (commit ready) $\rightarrow$ `Published` (remote baseline) $\rightarrow$ `Held` (reason required) $\rightarrow$ `Cancelled` (superseded).
   - Dynamic active underline and soft accent fill indicating current cohort filter.

### RULE-DSP-004: Table Layout, Two-Row Filtering & Row Selection Highlights
1. Data tables `MUST` implement a sticky header layout (`position: sticky; top: 0; z-index: 10;`) so table headers remain visible during vertical scrolling.
2. Row selection checkboxes `MUST` highlight selected rows with a soft accent background and a 3px active left indicator border (`box-shadow: inset 3px 0 0 var(--blue)`).
3. Two-row header layouts are authorized for high-density tabular explorers, where Row 1 provides column titles and click-to-sort controls, and Row 2 provides column-aligned filter inputs.

### RULE-DSP-005: Vector Iconography Standard (Lucide SVG Integration)
1. Interactive web dashboards `MUST` leverage **Lucide vector SVG icons** (`<i data-lucide="...">` and `lucide.createIcons()`), replacing legacy raw Unicode emoji characters.
2. Dashboards `MUST` include local vendor bundling or graceful fallback to ensure crisp rendering when offline or in air-gapped environments.
3. Action icons (Inspect, Copy, Run, Help, More) `MUST` have a minimum touch/click target of 32px and distinct hover animations.

### RULE-DSP-006: Column-Qualified Negation Search Engine & Live Match Counters
1. Primary filter inputs `MUST` support tokenized search including column-qualified expressions (`Column:value`, `Column:!value`, `!Column:value`) and general negation tokens (`!exclude`).
2. All standard table dashboards `MUST` leverage `LcmTableEngine.filterTable()` / `LcmTableEngine.bindSearch()` or implement equivalent column-qualified negation matching.
3. Every filtered view `MUST` display a live, dynamic counter showing match progress (e.g., `Showing 6 of 24 results`).

### RULE-DSP-007: Headless Print-to-PDF & CSS Paged Media Standard
1. Tools and reports emitting printable HTML reports, audit documents, or calendars (`RollingCalendar`, table exports) `MUST` adhere to CSS Paged Media standards:
   - Explicit `@page` rules declaring margins (`margin: 5mm` or `10mm`) and orientation.
   - Repeating table headers across page splits (`thead { display: table-header-group; }`).
   - Row break avoidance (`tr, .grid-row { break-inside: avoid; }`).
2. Headless PDF generation `MUST` be orchestrated via standard headless Edge (`msedge --headless --disable-gpu --run-all-compositor-stages-before-draw --print-to-pdf`) to ensure predictable vector pagination.

### RULE-DSP-008: Interactive Desktop Dispatch Routing
1. **Definition of Interactive Session (Session 1)**:
   - On Windows operating systems, the logged-on user's physical display and GUI shell run inside the primary **interactive console session (designated as Session ID 1)**.
   - Non-interactive services, background task runners, and IDE agent sub-processes often run isolated in headless or background contexts (e.g., Session 0 isolation or detached agent worker runspaces), where spawned GUI processes cannot access the physical desktop or display windows to the operator.
2. **Mandatory Dispatch Invariant**:
   - Any CLI script, background agent, or automation utility that builds or triggers an HTML viewer, browser dashboard, diff tool (Beyond Compare), text editor, or native desktop GUI `MUST` route execution through `Invoke-InteractiveDesktop.ps1` (per `RULE-PS-011`).
   - This ensures the process is dispatched into the active user's interactive desktop (Session 1) on the physical monitor.
3. **Prohibition of Direct Background Spawning**:
   - Direct `Start-Process` invocations targeting GUI applications from background runner tasks or Session 0 contexts without `Invoke-InteractiveDesktop.ps1` routing are strictly prohibited, as they spawn headless, invisible "ghost" windows that block review workflows.
4. **Forward-Compatibility: Default Browser vs. IDE Canvas Hosting**:
   - The presentation layer is currently dispatched to the default external browser window on Session 1 via `Invoke-InteractiveDesktop.ps1` because current IDE Canvas/Webview integrations exhibit instability and bugs.
   - However, presentation code and architecture `MUST NOT` preclude transitioning to an integrated **IDE Canvas** once that capability is stabilized.
   - HTML/CSS/JS presentation artifacts `MUST` remain container-agnostic so they can run either in a standalone browser window or embedded seamlessly within an IDE webview/canvas without code modifications.
5. **Stale Window Termination & Test Execution Window Hygiene**:
   - Automated test runs, test suites, and interactive launchers `MUST NOT` leave multiple abandoned windows (browser displays, PowerShell shells, or diff viewers) accumulated across test cycles.
   - **Pre-Test / Pre-Launch Window Cleanup**: Before entering automated testing or spawning a new session, testing harnesses and dispatchers `MUST` proactively locate and terminate any prior/stale instances of the same display or test shells to eliminate visual clutter and operator confusion.
   - **Inspection Gating**: Automated test runs `MUST` operate headless or close disposable test windows upon completion. A new display window `SHALL ONLY` be launched if explicit operator visual inspection is intended.


### RULE-DSP-009: Standard Desktop Dialog Specification (WPF & Modal UX Parity)
1. Desktop dialogs built using WPF (`PresentationFramework`) or WinForms `MUST` mirror the visual hierarchy, typography (`Segoe UI Variable` / `Inter`), and border radius tokens of `StandardTableDisplay.css`.
2. Password and secret entry dialogs `MUST` provide an interactive visibility peek toggle (`Show/Hide`) and clear previews of planned mutation actions.
3. Modal dialogs `MUST` support `Escape` key dismissal and center on the active cursor's monitor.

### RULE-DSP-010: System Tray Application Lifecycle & Single-Instance Mutex
1. Windows system tray applications (`NextBootTray`) built with `System.Windows.Forms.NotifyIcon` `MUST`:
   - Implement single-instance mutex gating to prevent duplicate tray icons.
   - Ensure clean shell notification area deregistration (`$notifyIcon.Dispose()`) upon process exit.
   - Execute on dedicated STA threads without blocking caller PowerShell runspaces.

### RULE-DSP-011: Execution Ledger Horizontal Timeline & Bulk Cohort Action Panel
1. Dashboards managing multi-step workflows `MUST` present a horizontal **Execution Ledger Timeline** (`.timeline` / `.step`) displaying lifecycle phases:
   $$\text{Scope} \rightarrow \text{Checkpoint} \rightarrow \text{Apply} \rightarrow \text{Design} \rightarrow \text{Verify} \rightarrow \text{BCR} \rightarrow \text{Commit} \rightarrow \text{Publish}$$
2. Multi-item selection workflows `MUST` provide a **Selection & Bulk Work Cohort Panel** (`.selection-panel`) that validates actions across the entire cohort before offering dispatch triggers.

### RULE-DSP-012: Terminal Console Formatting, ANSI Palette & Progress Atoms
1. Console automation tools `MUST` employ structured ASCII/ANSI layouts with standardized status tags: `[INFO]`, `[WARN]`, `[ERROR]`, `[ACTION]`, and `[SUMMARY]`.
2. Long-running tasks `MUST` utilize `LCM_Shared/LcmProgressAtom.psm1` for percentage bars, spinner glyphs, and non-clobbering status updates.

### RULE-DSP-013: Universal Keyboard Shortcuts
1. Interactive web dashboards `MUST` support standard keyboard navigation:
   - `F5`: Instant data refresh without page reload.
   - `Escape`: Close active drawers, modals, and search inputs.
   - `/` or `Ctrl+F`: Instantly focus the primary search input.

### RULE-DSP-014: High-DPI Scaling & Per-Monitor V2 Resilience
1. Native Windows GUI utilities (WPF and WinForms) `MUST` declare Per-Monitor DPI V2 awareness to ensure crisp rendering on 4K and multi-monitor scaling setups.
2. Web UI layouts `MUST` enforce `min-width` safety (minimum 1440px desktop baseline) and prevent text clipping on scaled displays.

### RULE-DSP-015: Static Presentation Template vs. Dynamic Data Payload Separation
1. Web applications `MUST` strictly separate static presentation templates (`.html`, `.css`, `.js`) from dynamic operational data (`.json`).
2. HTML viewer files `MUST NOT` embed large static data blobs; data `MUST` be fetched or injected via deterministic REST endpoints or decoupled JSON payload files.

### RULE-DSP-016: Dynamic Tool Version & Runtime Provenance Display Invariant
1. **Dual Significance Version Parity (Constructing Script + Presentation Template)**:
   - Every compiled display, web dashboard, sidecar, or viewer constructed from a presentation template `MUST` prominently display the **dual significance provenance**:
     1. The version of the **constructing script** (author of the ledger artifact at compile time, e.g. `LCM-Show: v1.8.0`).
     2. The version of the **presentation template** asset (e.g. `Template: v1.2.0`).
   - Standard format across badges, titles, and provenance headers: `(LCM-Show: vX.Y.Z Template: vA.B.C)`.
   - Displayed versions `SHALL NOT` omit either axis; both the compiling engine and the presentation template must be identifiable to guarantee full transparency across iterations.
2. **Standardized Version Formatting & Double-'v' Artifact Prohibition**:
   - All version representations in UI headers, titles, topbar pills, badges, and subtitles `MUST` follow normalized semantic formatting `v<Major>.<Minor>.<Patch>`.
   - Duplicate prefix artifacts (such as `vv1.7.0` or `vvX.Y.Z`) are strictly prohibited across all displays.
   - Template placeholder tokens (e.g. `{{HUB_VERSION}}`, `{{TOOL_VERSION}}`, `{{SHOW_VERSION}}`, `{{TEMPLATE_VERSION}}`) `MUST` be standardized: constructing tools `MUST` inject normalized strings, and HTML/presentation templates `SHALL NOT` prepend a redundant literal `v` before a version token.
   - Launchers and compilers `MUST` defensively sanitize template replacements (e.g. normalizing any `v{{...}}` or replacing `vv` occurrences) to guarantee zero artifact defects reach the operator display.
3. **Prohibition of Stale Static Version Information**:
   - Presentation templates `SHALL NOT` embed hardcoded, static version numbers, dates, or metadata that can drift out of date when the constructing tool is modified or updated.
   - Any version pill, topbar badge, header label, or footer text that indicates tool version `MUST` be dynamically populated via the active runtime data contract (`.json`) or injected by the launcher script.
4. **Traceability & Environment Context**:
   - Where applicable, displays `SHOULD` complement the dynamic tool version with the constructing tool name, active repository commit SHA, or runtime mode (e.g., `Tool: Show-LcmControl v1.8.0 | Template: v1.2.0 | Baseline: 43a2b1c`) to ensure unambiguous provenance and traceability during operator inspection and review audits.


