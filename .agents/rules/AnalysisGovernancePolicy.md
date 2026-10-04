---
name: AnalysisGovernancePolicy
description: Authoritative analysis governance policy enforcing model-first read-only analysis protocol, provenance tagging, search fencing, implementation gating, and circuit breaker recovery.
globs: "*"
---
# File: AnalysisGovernancePolicy.md

Module: AnalysisGovernancePolicy  
Purpose: Defines modal separation between Read-Only Analysis and Governed Implementation, intent wake words, provenance tagging, search fencing, circuit breaker protocol, and Control Hub runtime state transparency.  
Path: .agents/rules/AnalysisGovernancePolicy.md  
Authors: Rolf, LCM_AI Engine  
Version: 8.6.0  
Status: Authoritative Invariant Rule  
Date: 2026-10-04  

---

## 1. Purpose & Motivation

In the Lifecycle Model (LCM), unconstrained speculative code modifications and premature implementations lead to architectural regressions and drift.

To establish predictable, disciplined pair-programming collaboration, this policy institutes strict modal separation between **READ-ONLY ANALYSIS** and **GOVERNED IMPLEMENTATION**. This guarantees that complex investigations produce verified, model-first analytical foundations before any source code, configuration, or governance files are modified.

---

## 2. Invariant Rules

### RULE-ANA-001 (Intent Wake Word Gating & Read-Only Analysis Lock)
1. **`ANALYZE` Wake Word**: When an operator prompt or session begins with the intent wake word **`ANALYZE`**, the AI assistant and runtime environment are immediately locked into **`READ_ONLY_ANALYSIS`** mode.
2. **Strict Tool Restriction**: While in `READ_ONLY_ANALYSIS` mode, file modification tools (`write_to_file`, `replace_file_content`, `multi_replace_file_content`), destructive shell commands, and Git mutation commands (`git commit`, `git push`, `git merge`, `git checkout`) are **STRICTLY PROHIBITED**.
3. **Model-First Mandate**: The AI must first formulate a structured mental or formal model defining:
   - Entities involved in the problem domain
   - State variables and lifecycles
   - Allowed actions and state transitions
   - Constraints, assumptions, and boundary conditions
4. **No Premature Solutions**: The agent `MUST NOT` produce concrete code diffs or commit proposals during this phase.
5. **Operational Scope (Review Gates & Suggested State)**: Operating in `READ_ONLY_ANALYSIS` mode is explicitly expected during the initial `suggested` proposal state and whenever execution is paused at lifecycle review gates (Gate 1 Planning Gate per `RULE-LCM-014` and Gate 2 Visual Review Gate per `RULE-REV-001`). During these checkpoints, analysis and structured reasoning precede code mutation.

---

### RULE-ANA-002 (Provenance Tagging & 4-Part Output Contract)
During active `READ_ONLY_ANALYSIS`, all generated responses must adhere to the 4-part analytical output contract:

1. **Structured Model Formulation**: High-level definition of domain entities, state variables, invariants, and boundaries.
2. **Evidence & Findings with Provenance Tags**: Every empirical statement must include explicit verifiable provenance:
   - `[VERIFIED: <filepath#line>]`: Empirically confirmed by reading the current working copy or AST.
   - `[INFERRED]`: Deductions logically derived from verified facts but not directly asserted in text.
   - `[GAP: <missing_data>]`: Unconfirmed points, missing specifications, or unverified assumptions.
3. **State Delta & Settled Facts**: Explicit recording of newly settled facts (`LCM_SettledFacts`) and retired hypotheses.
4. **Interactive Decision Gate**: Each analytical turn `MUST` conclude with exactly 2 to 3 actionable, structured choices (`Option A`, `Option B`, `Option C`) and pause execution for explicit human operator steering.

---

### RULE-ANA-003 (Search Radius Fencing Standard)
1. **Fenced Discovery Radius**: When performing searches in `READ_ONLY_ANALYSIS` mode, search depth `MUST NOT` exceed `2` filesystem levels from the designated target component root (`LCM_SearchRadius = 2`).
2. **Match Capping**: File searches and grep queries must cap results to prevent unconstrained token floods (maximum 3 primary matches per query).
3. **Target Component Anchoring**: Searches must strictly originate from the specific repository or subsystem component directory under investigation, never traversing speculative relative paths across unrelated sibling repositories.

---

### RULE-ANA-004 (Implementation Transition & Phase Exclusion)
1. **`IMPLEMENT` Transition Word**: The session transitions from `READ_ONLY_ANALYSIS` to **`GOVERNED_IMPLEMENTATION`** solely upon receipt of the explicit operator transition word **`IMPLEMENT`** (or approval commands such as `do <ID>`).
2. **Path Binding**: Governed implementation `MUST` strictly follow and execute the consensus path, architecture decisions, and options settled during the prior `ANALYZE` phase.
3. **Phase Exclusion Invariant**: During active `READ_ONLY_ANALYSIS`, the formulation, staging, or execution of Implementation CRPs or code modification directives is **STRICTLY FORBIDDEN**.

---

### RULE-ANA-005 (Circuit Breaker Protocol & Resumption Gate)
1. **Automatic Trip Conditions**: If during `GOVERNED_IMPLEMENTATION`, the agent or runtime discovers:
   - An assumed API parameter, function, or symbol does not exist;
   - An environment path, configuration, or dependency is inaccessible;
   - The implementation requires invalidating an earlier verified consensus or constraint;
   Execution `MUST HALT IMMEDIATELY`. Guessing, speculative patching, or unverified workarounds are strictly forbidden.
2. **Immediate Mode Drop**: The session automatically transitions from `GOVERNED_IMPLEMENTATION` to **`CIRCUIT_BREAKER_HALT`** and drops back into `READ_ONLY_ANALYSIS`.
3. **Mandatory Output Header**: The assistant must output the standard circuit breaker notification:

```markdown
### [ANALYSIS RESUMED] - Implementation Block Encountered
Status: Implementation Halted | Reason: Ambiguity / Constraint Mismatch

1. Encountered Block
* [GAP / CONFLICT]: <Exact technical mismatch or undefined parameter>.
* Source Context: <File or component where divergence occurred>.

2. Impact on Previous Consensus
* Invalidation: <Why the previously chosen path cannot proceed as drafted>.

3. Recommended Next Steps (Decision Gate)
* Option A: <Alternative implementation branch addressing the gap>.
* Option B: <Re-open analysis of prerequisite components>.
* Option C: <Abort change and restore prior baseline>.
```
4. **Control Hub Flag**: The circuit breaker status is registered in the LCM Control Hub telemetry and halts execution runners until operator resolution.

---

### RULE-ANA-006 (Runtime State Telemetry & Control Hub Register Invariant)
The analysis engine and session runners must synchronize active governance variables to `active_session.json` and expose them to the LCM Control Hub:

| State Register | Type | Permitted Values | Enforcement & Display Rule |
|:---|:---|:---|:---|
| `LCM_OperatingMode` | String | `READ_ONLY_ANALYSIS`, `GOVERNED_IMPLEMENTATION`, `CIRCUIT_BREAKER_HALT` | Displayed in Control Hub topbar/status rail. If `READ_ONLY_ANALYSIS`, execution dispatchers reject write operations. |
| `LCM_ActiveGate` | String | `STEP_001` .. `STEP_nnn` | Identifies current node in the interactive decision DAG. |
| `LCM_SearchRadius` | Integer | Integer $\le 2$ (Default `2`) | Fences ripgrep / search tool exploration depth. |
| `LCM_SettledFacts` | Array[String] | Array of IDs (e.g. `["F-001", "F-002"]`) | Prevents redundant rediscovery of settled facts. |
| `LCM_OpenHypotheses`| Array[String] | Array of IDs (e.g. `["HYP-001", "HYP-002"]`) | Tracks open hypotheses currently under investigation. |
| `LCM_CircuitBreaker`| Boolean | `true`, `false` | True when tripped; displays resumption block alert. |
