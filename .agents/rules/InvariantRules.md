---
name: InvariantRules
description: Authoritative workspace invariants for determinism, formatting, line endings, encoding, and conciseness.
globs: "*"
---
# File: InvariantRules.md

Module: InvariantRules  
Purpose: Authoritative invariant rules for workspace behavior, encoding, determinism, and generation.  
Path: .agents/rules/InvariantRules.md  
Authors: Rolf  
Version: 8.2.0  
Status: Authoritative Invariant Rule  
Date: 2026-10-03  

---

## 1. Core Invariant Rules

### INVARIANT-RULES
- **determinism**: Identical input $\rightarrow$ identical output.
- **reproducibility**: No randomness or speculative inferences.
- **ascii-default**: ASCII required unless explicit exceptions apply:
  - Markdown (`.md`) files may contain Unicode (arrows, bullets, umlauts, typographic symbols).
  - PowerShell literal strings and comments may contain umlauts.
  - HTML and UI presentation assets (`.html`, `.css`, `.js`) may contain Unicode glyphs and standard UI emojis as defined in DisplayStandardsPolicy.md.
- **no-non-ascii-identifiers**: Identifiers, variables, function names, and file names must be ASCII-only.
- **constant-string-apostrophes**: Use single ASCII apostrophes (`'...'`) for constant strings.
- **indent-2**: Indentation level is exactly 2 spaces (no tabs).
- **newline-crlf**: Windows-native files must end with CRLF.
- **utf8-without-bom**: All text and code files must be saved as UTF-8 without BOM.
- **structure**: Clear hierarchical markdown sections, bulleted lists, and typed code blocks.
- **no-assumptions**: State unknown facts rather than guessing; never invent facts or speculate.
- **zero-assumption-testing**: The AI assistant `MUST NOT` assume or claim that code, scripts, configurations, or proposals are valid, functional, or ready without actively running mechanical tests, compilation, or parser verification. Relying on visual inspection alone or declaring ready without executing test verification is strictly prohibited.
- **mandatory-pre-handoff-syntax-gate**: Every created or modified script, module, or configuration file (`*.ps1`, `*.psm1`, `*.py`, `*.json`, `*.cmd`) `MUST` pass automated syntax parsing or compilation (`ParseInput` for PowerShell, `py_compile` for Python, `ConvertFrom-Json` for JSON) before concluding a turn, proposing review, or claiming completion. Zero syntax errors or parse warnings are tolerated.
- **no-verbosity**: Minimal, direct, and non-repetitive communication; zero conversational padding or pleasantries.
- **zero-conversational-padding**: Prohibit conversational filler, greetings, pleasantries, or preamble/postamble framing.
- **explicit-reasoning**: Provide clear, deterministic technical rationale for all actions, architecture, and diagnostics.
- **english-default-language**: English invariant for all code, comments, documentation, and commit messages.
- **timestamp-header-rule**: Mandatory response output header on every assistant response in the exact format:
  `YYYYMMDD_HHMM "<short-task-description>"`
  Permanent, automated mechanism inherited across all sessions (replaces manual `@tsr` / `@THR` / `@TRH` prompting).
- **tool-and-log-timestamp-precision**: Tool execution timestamps, generated log file names, and internal log entries `MUST` include at least second-level precision (`ss`) (e.g. `yyyyMMdd_HHmmss` or `yyyy-MM-dd HH:mm:ss[.fff]`). The minute-level format (`YYYYMMDD_HHMM`) applies strictly and exclusively to the assistant chat response header, never to tools or logs.
- **no-backtick-line-continuations**: Script generation must not use backticks (`` ` ``) for line continuation; use splatting, pipeline wrapping, or parenthesized expressions instead.

---

## 2. Activation Commands & Legacy Macro Compatibility

- **Native Rule Inheritance**: Rules in this file are auto-inherited across all agent interactions via `.agents/rules/`.
- `@tsr` / `@THR` / `@TRH` / `@IRA`: Legacy prompt macros for TimestampHeaderRule and InvariantRules. Now superseded by persistent, native rule enforcement.
- `@ml`: Shows ordered visible messages in current chat.



