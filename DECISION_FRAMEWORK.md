# Technical Decision Framework

This document formalizes technical and product decision-making rules for all automated (AI agent) and manual (human engineering) development cycles within the repository.

---

## 1. Reversibility Matrix (One-Way vs. Two-Way Doors)

Decisions must be categorized by their level of reversibility before execution.

```
                   High Impact / Blast Radius
                              ▲
                              │
       [ONE-WAY DOORS]        │        [HIGH-RISK REVERSIBLE]
     Strict Review Required   │        Staged Rollout Needed
                              │
◄─────────────────────────────┼─────────────────────────────►
Irreversible                                        Reversible
                              │
       [NEGLIGIBLE RISK]      │        [TWO-WAY DOORS]
      Automated / Direct      │        Fast Execution & Bias
                              │        to Prototype
                              ▼
                   Low Impact / Blast Radius
```

### 1.1 One-Way Doors (Type 1 Decisions: Irreversible / High Reversal Cost)
*One-Way Doors represent decisions that are permanent, highly complex to reverse, or carry catastrophic blast radius risks upon failure.*

* **Core Categories & Examples:**
  * **Database Schema & Data Migrations:** Destructive column drops, core entity schema changes, data format migrations.
  * **Auth & Security Models:** Identity providers, encryption primitives, authentication flow shifts, keychain/token storage strategies, security scope permissions.
  * **Subscription & Financial Systems:** Payment gateways, billing ledgers, entitlement management, receipt validation.
  * **Public API Contracts & Core Protocols:** Breaking network contract modifications, core data model shifts affecting persistence layers.
  * **Core Infrastructure & Vendor Lock-In:** Core framework changes, fundamental third-party library dependencies.

* **Mandatory Governance Protocol:**
  * **Pre-Mortem Requirement:** Conduct a mandatory failure-mode analysis documenting potential breaking points, failure states, and data recovery vectors before writing production code.
  * **High Proof Bar:** Proof of necessity required via architectural RFC, benchmark data, or security threat modeling.
  * **Defensive Review & Sign-Off:** Requires thorough code review, explicit architectural sign-off, and strict automated test coverage.
  * **Rollback & Mitigation Plan:** Every One-Way Door implementation must include an explicit rollback strategy or migration fallback plan prior to merge.

---

### 1.2 Two-Way Doors (Type 2 Decisions: Reversible / Low Reversal Cost)
*Two-Way Doors represent decisions that can be easily undone, modified, or iterated upon with low operational friction and zero structural risk.*

* **Core Categories & Examples:**
  * **UI Layout & Presentation:** View hierarchy adjustments, styling tweaks, animation timings, layout spacing.
  * **Copy & Microcopy:** Text labels, button copy, messaging phrasing, localization string updates.
  * **Preset Defaults & Non-Critical Configs:** Default filter selections, UI state flags, non-destructive client settings.
  * **Internal Refactoring:** Code structure cleanups within localized module boundaries that do not alter external contracts.
  * **Experimental Features:** Any code isolated behind feature flags or runtime toggles.

* **Mandatory Governance Protocol:**
  * **Fast Execution:** Minimize process overhead and review latency.
  * **Low Friction:** Approval requires demonstrating local/unit correctness rather than exhaustive committee consensus.
  * **Bias for Action:** Favor building and testing directly over theoretical debate.

---

## 2. Action Bias & Capped Downside

### 2.1 Capped Downside Principle
* When downside risk is strictly bounded (e.g., isolated behind a toggle, affecting non-critical UI, or easily rolled back via a single commit), **incomplete data is not a valid reason for inaction**.
* Operating with 60%–80% confidence under capped downside is preferred over delaying execution to reach 100% certainty.
* The opportunity cost of delayed feedback exceeds the cost of a minor, reversible corrective iteration.

### 2.2 The 15-Minute Debate Cap
* **Rule:** Discussions regarding Two-Way Door decisions are strictly capped at **15 minutes** (synchronous or asynchronous equivalent).
* **Resolution Mechanism:** If team members or automated agents cannot reach consensus within 15 minutes:
  1. Halt debate immediately.
  2. Build a working prototype or feature branch directly in code.
  3. Validate hypotheses empirically through live execution, UI review, or performance instrumentation.
  4. Let empirical runtime data make the final decision.

---

## 3. Engineering Decision Protocol & Checklist

When evaluating pull requests, system architecture changes, or bug fixes, apply the following evaluation checklist against real-world constraints.

```
                          ┌────────────────────────┐
                          │   Proposed Change PR   │
                          └───────────┬────────────┘
                                      │
                                      ▼
                           Is it a One-Way Door?
                                 /         \
                              YES           NO
                              /               \
                             ▼                 ▼
                ┌────────────────────────┐  ┌────────────────────────┐
                │ - Mandatory Pre-Mortem │  │ - Apply 15-Min Cap     │
                │ - Rollback Strategy    │  │ - Prototype & Test     │
                │ - Strict Architectural │  │ - Fast Path Merge      │
                │   Review               │  └────────────────────────┘
                └────────────────────────┘
```

### Practical Review Checklist

| Constraint Dimension | Evaluation Questions | Decision Standard |
| :--- | :--- | :--- |
| **1. Time & Velocity** | • Is this the simplest implementation that solves the problem?<br>• Does this introduce unneeded abstraction or over-engineering?<br>• Is technical debt being intentionally created, documented, and capped? | Favor pragmatic, maintainable code over complex abstractions. |
| **2. Cost & Resources** | • Does this change increase runtime compute, memory footprints, or network bandwidth unnecessarily?<br>• Are third-party API usage limits or paid cloud resources affected? | Keep resource consumption within budgeted bounds. |
| **3. User Experience & Friction** | • Does this introduce UI latency, stuttering on the main loop, or extra interaction steps?<br>• Is the user path clear and free of unexpected regressions? | Main thread non-blocking; fluid, immediate feedback for user actions. |
| **4. System Failure Modes** | • What happens when a network call fails, or data is missing?<br>• Does the system degrade gracefully (fallbacks/circuit breakers) or crash hard?<br>• Is the blast radius isolated to the local component? | Graceful degradation required; no unhandled crashes for expected network/data anomalies. |
| **5. Observability & Maintainability** | • Are meaningful logs and diagnostics captured?<br>• Can another engineer or automated agent read and modify this code easily in 6 months? | Self-documenting code, clean interfaces, and clear diagnostic paths. |

---

## 4. Execution Guidelines for Automated & Manual Cycles

* **Automated Cycles (AI Agents):**
  1. Classify proposed changes as Type 1 (One-Way) or Type 2 (Two-Way) before planning code modifications.
  2. For Type 1 changes: Submit an explicit architectural proposal and request verification/sign-off before making modifications.
  3. For Type 2 changes: Implement rapidly, run automated verification/tests, and present working code.
* **Manual Cycles (Human Engineering):**
  1. Tag PRs or commits with decision types when introducing architectural changes.
  2. Use the 15-minute rule to unblock stale PR reviews or design disagreements.
