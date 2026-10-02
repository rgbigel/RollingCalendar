---
name: ReviewCommitGovernancePolicy
description: Authoritative governance policy for Review-Gated Commits, Completion with Edits, and Forced Commit Overrides.
globs: "*"
---
# File: ReviewCommitGovernancePolicy.md

Module: ReviewCommitGovernancePolicy  
Purpose: Defines mandatory review-gated commit rules, review disposition handling, authorized bypass exceptions, audit logging, and single-session directory junction reviews.  
Path: .agents/rules/ReviewCommitGovernancePolicy.md  
Authors: Rolf, LCM_AI Governance  
Version: 8.4.0  
Status: Authoritative Policy  
Date: 2026-10-02  

---

## 1. Governance Rules

### RULE-REV-001: Mandatory Review-Gated Commits & Gate 2 Non-Circumvention Invariant
1. **Mandatory Visual Review Gate (Gate 2)**: Every Git commit action for source code, configuration, tools, modules, or structural assets (`*.ps1`, `*.psm1`, `.vscode/settings.json`, `.lcm/*`, `docs/*`) in any LCM-governed repository requires a prior validated review disposition (`COMPLETED` or `COMPLETED_WITH_EDITS`) produced via the formal Beyond Compare 5 visual review gate (`Invoke-BeyondCompareReview.ps1`), with transparent junction traversal via `FollowSymLinks` (`RULE-REV-008`).
2. **Strict Gate 2 Non-Circumvention Baseline**: Beyond Compare visual diff review is non-circumventable for code/tools/specs across all items by default. Even critical, urgent, or internally generated BUGs normally execute in `DOIT` mode (`always-proceed = $true`) without a Gate 1 planning pause, but halt at Gate 2 for operator review before reaching `COMMITTED`.
3. **Authorized Exceptions to Gating**:
   There are two (2) authorized exceptions to this rule:
   1. **Explicit Operator Directive (`IMMEDIATELY`, `FORCE`)**: The user can explicitly INSTRUCT (`IMMEDIATELY`, `FORCE`) to bypass review confirmation and advance directly into the Implementation Phase / review commit without confirming the visual review.
   2. **Critical Flow-Impeding BUG & Loop Breaker**: The system has detected a BUG that impedes the intended flow in a critical manner, especially when the task would lead to an unavoidable loop or recursion that the user cannot circumvent or fix. In this scenario, the system may proceed autonomously, engaging `-MinimalTests` to prevent cascading test recursions, but there `MUST BE NO MORE THAN TWO (2) ATTEMPTS` to resolve the issue before halting.
   - **Mandatory Audit Logging Invariant**: In either exception case, the fact, rationale, and specific trigger `MUST` be explicitly documented in the accompanying `BUG` or `CRP` proposal bundle and recorded in the Configuration Management ledger.
   - **Quality Gate, Syntax & Language Non-Bypass Invariant**: Taking an authorized exception to bypass manual visual review strictly waives only the interactive visual diff inspection step. It `MUST NEVER` bypass, waive, or relax syntax validation (PowerShell AST parser checks, Python compilation), language rules ([`LanguagePolicy.md`](file:///d:/Git_Repositories/.agents/rules/LanguagePolicy.md) English invariant), or baseline repository readiness quality gates (`Test-RepoReadiness.ps1`). All modified files `MUST` compile cleanly with zero syntax errors and satisfy all language and formatting invariants prior to commit.
4. **Exemption Scope**: Only purely mechanical telemetry artifacts defined in `RULE-EFF-001` (`inventory.json`, `INVENTORY_DASHBOARD.md`, `out/test_results.json`, and activity logs) are exempt from visual review gating.
5. **BCompare Materiality Authority**: Beyond Compare is the sole authority for whether a difference is material. The review launcher MUST enable its insignificant-difference controls, and post-review staging MUST record only explicit operator selections made in the visual session. Raw-byte, Git-diff, line-ending, or whitespace comparisons MUST NOT create review candidates or obstruct review disposition.
6. **Non-Interactive / Headless Environment Fallback**: If Beyond Compare 5 or Session 1 interactive GUI execution is physically unavailable (e.g. running inside a headless CI/CD runner, container, or non-GUI remote SSH terminal), the agent `SHALL` present unified console diffs alongside the proposal's `Walkthrough.md` verification evidence for explicit terminal disposition before committing.

### RULE-REV-002: Completed with Edits Qualification
When a review outcome is recorded as `Completed with Edits` (or `Completed with Change`):
1. The modified codebase `MUST` execute and satisfy all repository quality gates (`Test-RepoReadiness.ps1`).
2. The modifications `MUST NOT` introduce rule violations, regression errors, or broken dependencies.
3. Upon satisfying all quality gates, the state `SHALL` be classified as fully `COMPLETED` and committed to Git.
4. When `-MinimalTests` is engaged under operator instruction or automated loop circumvention, the readiness gate executes fast-tier syntax and structure validation while bypassing heavy integration cascades; the resulting commit is recorded as `completed [minimal-tests]` with `"test_scope": "minimal"` per `RULE-LCM-023`.

### RULE-REV-003: Override & Force Authority for Rejected/Deferred States
If a review outcome is `REJECTED` or `DEFERRED`:
1. Automated commit and push pipelines `MUST` halt immediately.
2. Committing or pushing changes in a rejected or deferred state `IS FORBIDDEN` unless explicitly commanded by the user with a forced override instruction (e.g., `-Force` parameter or unambiguous explicit override prompt).

### RULE-REV-004: Precedence Over General Permission Rules
The review-gating rules (`RULE-REV-001` through `RULE-REV-003`) take strict precedence over any general "all commands are permitted" or automated background execution policies in effect across the workspace.

### RULE-REV-005: Universal Audit & Change Request Traceability
Every review disposition (`Completed`, `CompletedWithEdits`, `Rejected`, `Deferred`) `MUST` be recorded with an immutable timestamp, reviewer identity, repository HEAD SHA, and notes into:
1. `LCM_Inventory/logs/cm_activity.log` (Append-only CM audit ledger).
2. `LCM_Inventory/data/reviews/REVIEW-<Repo>-<Timestamp>.json` (Structured review evidence).
3. The active Change Request (CR) record in `LCM_Inventory/data/change_requests.json` and mirrored proposal Markdown files when modifying governed baselines.

### RULE-REV-006: Mandatory Review Stop & Lifecycle Step Invariant
1. **Mandatory Review Stop**: Whenever an agent carries out a CRP or code modification reaching the visual review stage (Gate 2), the agent `MUST` launch `Invoke-BeyondCompareReview.ps1` and **immediately terminate the current response turn without making additional tool calls**.
2. **`Proceed` at Gate 2**: Upon operator submission of **`Proceed`** (or `Proceed <ID>`) after review inspection:
   - The proposal advances by exactly one status pulse: `REVIEW` $\rightarrow$ **`COMMITTED`**.
   - The local Git commit is created with the required SemVer increment per `RULE-REV-007`.
3. **`PUSH` (Publication Trigger)**:
   - `PUSH` is the only lifecycle command that may invoke a remote push.
   - It pushes only a fully preflighted cohort of `COMPLETED` proposals and `LCM_Inventory` in lockstep.
   - Uncommitted proposals remain strictly in their local state.
   - Enforces the Push Auto-Reset Invariant: both `LCM Mode` and `Testing Mode` unconditionally revert to `ON`.

### RULE-REV-007: Mandatory Automatic Semantic Version Increment per Change Invariant
1. **Universal Version Increment Invariant**: Every change, proposal, or bug fix committed to any LCM-governed repository `MUST` increment that repository's semantic version before or during review commit:
   - **Patch Increment (`+0.0.1`)**: Standard default for all bug fixes, refinements, single-purpose enhancements, and incremental proposal completions.
   - **Minor Increment (`+0.1.0`)**: For substantive new feature sets, new tools, new sub-frameworks, or major multi-component proposals.
   - **Major Increment (`+1.0.0`)**: For global platform architectural transitions, governed by `RULE-DOC-005`.
2. **Synchronized Artifact Updates**:
   - The incremented version `MUST` be updated in:
     - DOX metadata headers of modified scripts and modules (`Version: M.Y.Z`).
     - Tripartite specifications (`Architecture.md`, `Requirements.md`, `Implementation.md`).
     - Top-level `README.md` and repository manifests.
     - `LCM_Inventory/data/inventory.json` repository record.
   - Commit messages and review receipts `MUST` record the resulting semantic version (e.g. `feat(cm): ... [v7.1.1]`).
3. **LCM_Inventory Operational Data Exemption**:
   - Routine data accounting mutations within `LCM_Inventory` (specifically `data/inventory.json`, `data/proposals/proposals.json`, `logs/cm_activity.log`, `docs/INVENTORY_DASHBOARD.md`, and `data/reviews/*`) occurring as a standard byproduct of reviews, audits, proposal lifecycle transitions, or push recording `SHALL NOT` increment `LCM_Inventory`'s semantic version.
   - Semantic version increments for `LCM_Inventory` apply strictly when source code (`tools/*.ps1`, `modules/*.psm1`), specifications (`docs/*.md`), or governance policies are modified.

### RULE-REV-008: Transparent Single-Session Directory Junction Review (FollowSymLinks)
1. **Transparent Directory Junction Traversal**: Beyond Compare 5 review sessions `MUST` configure `<FollowSymLinks Value="True"/>` in `BCSessions.xml`, enabling Beyond Compare to traverse NTFS directory junctions (such as `.agents\rules`) inline within the primary review session.
2. **Unified Single-Window Invariant**: Dual-session Beyond Compare review dispatch is retired. All repository review comparisons execute in a single Beyond Compare window without opening a separate junction review instance.
3. **Composite Local Baseline Identity**: The left pane `MUST` be exported from the target repository's explicitly resolved local `BaseCommit`; it `MUST NOT` implicitly resolve, fetch, or substitute a remote reference. Where that commit exposes a junction-backed path, the scratch tree `MUST` replace the junction with a committed rules snapshot selected in this order: the target `BaseCommit`, the nearest target-history ancestor whose Git tree contains the junction path, then the local committed `HEAD` of the live junction authority. The selected source repository, relative path, and SHA `MUST` be recorded alongside the target SHA.
4. **Historical Junction Semantics**: The baseline `MUST` contain only files present in the selected committed rules snapshot. A file visible through the live junction but absent from every available committed snapshot `MUST` remain absent on the left and appear as a live-only addition on the right; the launcher `MUST NOT copy` mutable working-tree authority content into a historical baseline.
5. **Identity and Cache Clarity**: The baseline cache identity and pane title `MUST` display the target local SHA, selected rules source, and selected rules SHA. A launcher `MUST NOT` invent or fall back to an unrelated version label when a real version artifact is unavailable.
6. **Exclusion Filter Alignment**: Review exclusion filter lists `MUST NOT` filter out `-.agents\rules\`, ensuring all governance rule diffs remain directly inspectable in the primary review pane.

### RULE-REV-009: Review Discovery Disclosure and Durable Governance Closure
1. **Operator Visibility**: When an agent discovers that a review defect, tool repair, or validation result changes the durable review contract, it `MUST` tell the operator before claiming the implementation is complete. The disclosure `MUST` distinguish the implemented code change from the pending governance or documentation change.
2. **Same-Change-Set Policy Update**: Where the finding defines a recurring review behavior, the agent `MUST` update this policy in the same governed change set, including the exact invariant, evidence fields, and required tool behavior. A tool-only repair is incomplete until this policy update is present or the operator explicitly defers it.
3. **Synchronized Discovery Surface**: Any update under this rule `MUST` synchronize the root `AGENTS.md` rule index and `LCM_AI/docs/LCM-Rules-Cross-Reference.md` under `RULE-AUTH-002`.

