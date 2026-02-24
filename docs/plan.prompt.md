# AL AI Showcase — Implementation Plan v2

## Overview

An AI-first Business Central AL Extension that showcases everything possible within the AL language, written entirely by AI. Leverages AL-Go CI/CD, tests (unit and end-user), documentation (technical and end-user), and explores the full SDLC with AI toolchains.

**Goal:** Copilot automates as much as possible of the software development lifecycle — plan features, code, compile, write tests, run tests, deploy to environment, and repeat autonomously until the feature meets requirements.

**Repo:** https://github.com/Professional-Advantage-SDG/AL-AI-Showcase

## Key Decisions

| Decision | Value |
|---|---|
| GitHub Org | `Professional-Advantage-SDG` |
| Repo Name | `AL-AI-Showcase` |
| Template | `microsoft/AL-Go-PTE` |
| Local Path | `C:\Work\GitHub\AL-AI-Showcase\` |
| Publisher | `BW-PA` |
| BC Country | `au` (Australia) |
| App ID Range | `50100..50249` (150 IDs) |
| Test ID Range | `50250..50299` (50 IDs) |
| BC Version | 27.0, Runtime 16.0 |
| Namespace | `BWPA.ALAIShowcase` |
| Test Namespace | `BWPA.ALAIShowcase.Test` |
| Work Items | Azure DevOps Boards (Azure Boards GitHub integration) |
| AI Agents | Copilot coding agent, Claude Code |
| MCP Servers | Azure DevOps, GitHub, Playwright, Filesystem/Terminal |
| License | MIT |
| E2E Framework | Playwright (TypeScript) |
| Main App Folder | `AL AI Showcase/` |
| Test App Folder | `AL AI Showcase.Test/` |

## ID Allocation

| Range | Purpose |
|---|---|
| 50100–50109 | Tables |
| 50110–50119 | Table Extensions |
| 50120–50139 | Pages |
| 50140–50149 | Page Extensions |
| 50150–50159 | Codeunits |
| 50160–50169 | Reports |
| 50170–50179 | Enums / Enum Extensions |
| 50180–50189 | Queries |
| 50190–50199 | XMLports |
| 50200–50209 | Interfaces / Permissions |
| 50210–50249 | Reserved (future) |
| 50250–50299 | Test Codeunits |

---

## Testing Strategy

Three complementary test layers, each introduced at a specific phase and targeting a distinct concern.

### Layer 1 — Unit & Integration Tests (AL Test Framework)

| Attribute | Detail |
|---|---|
| **Technology** | AL Test Framework (`[Test]` attribute, `Library Assert`, `Library Variable Storage`) |
| **Format** | AL test codeunits (ID range 50250–50299) in the `AL AI Showcase.Test/` app project |
| **Introduced** | Phase 4 — scaffolded via `CreateTestApp.yaml` |
| **Runs in** | BC Docker container (local) or AL-Go CI pipeline (cloud) |
| **Scope** | Business logic, data validation, event subscribers, permission checks, error paths |
| **Naming** | `[Feature]_[Scenario]_[ExpectedResult]` — e.g., `CustomerCreation_WhenNameIsBlank_ThrowsError` |
| **Pattern** | GIVEN / WHEN / THEN with explicit `Library Assert` calls including AI-diagnostic failure messages |
| **AI fit** | Excellent — AL agents generate test codeunits natively, compiler validates syntax, AL-Go runs them automatically |

### Layer 2 — Performance Tests (BC Performance Toolkit)

| Attribute | Detail |
|---|---|
| **Technology** | BCPT — AL codeunits implementing `BCPTTestContext` interface |
| **Format** | Separate BCPT test app project, scaffolded via `CreatePerformanceTestApp.yaml` |
| **Introduced** | Phase 19+ (future, once showcase features exist to stress-test) |
| **Runs in** | BC online sandbox with BCPT suite configuration |
| **Scope** | Throughput, scalability, response time under concurrent load |
| **Measures** | Operations/second, average duration, SQL read/write counts |
| **AI fit** | Good — implements a known interface, AI generates the loop body. Results are numeric and machine-parseable |

### Layer 3 — E2E / UI Tests (Playwright)

| Attribute | Detail |
|---|---|
| **Technology** | Playwright (TypeScript) with custom BC page-object model |
| **Format** | TypeScript test files in `e2e/` directory, run via `npx playwright test` |
| **Introduced** | Phase 5+ (after Devcontainer, once a deployed sandbox exists) |
| **Runs in** | GitHub Actions via Playwright Docker image, or locally via Playwright MCP |
| **Scope** | Full page flows, UI behavior, cross-page navigation, lookup interactions, notification verification, end-to-end business scenarios |
| **AI fit** | Excellent — Playwright MCP lets AI agents drive the browser in real-time, inspect elements, take screenshots, and self-correct failing tests |

#### Why Playwright over Page Scripting

| Factor | Playwright | Page Scripting |
|---|---|---|
| **Maturity** | GA, stable API, semantic versioning | Preview, breaking changes expected |
| **Schema / Types** | Full TypeScript types — compile-time validation | No published YAML schema — trial-and-error |
| **AI generation quality** | High — massive training corpus, rich examples | Low — minimal community, few examples |
| **AI autonomous loop** | MCP server: drive browser, screenshot, inspect DOM, retry | No MCP, no programmatic interaction |
| **AI failure debugging** | Trace viewer, console logs, screenshots | YAML error line only |
| **Tooling** | Codegen recorder, VS Code extension, HTML reporter | Rough recording/editing UI |
| **Scope** | BC + external integrations + APIs + Power Platform | BC pages only |
| **BC DOM risk** | Mitigated by page-object model (see below) | Not applicable (BC-native abstraction) |

#### Playwright Page-Object Model for BC

To bridge the "not BC-aware" gap, we build a `bc-playwright-helpers/` library:

```typescript
// bc-playwright-helpers/src/BCPage.ts
export class BCPage {
  constructor(private page: Page) {}

  async openPage(pageId: number) { /* navigate to BC web client page */ }
  async setField(label: string, value: string) { /* find field by aria-label, fill */ }
  async getFieldValue(label: string): Promise<string> { /* read field value */ }
  async runAction(actionName: string) { /* click action by text/label */ }
  async openLookup(fieldLabel: string) { /* trigger lookup on a field */ }
  async selectLookupRow(text: string) { /* pick a row from open lookup */ }
  async assertNotification(text: string) { /* verify notification banner */ }
  async assertErrorDialog(text: string) { /* verify error dialog content */ }
  async dismissDialog() { /* close modal dialog */ }
}
```

**Key locator strategies:**
- `getByRole('textbox', { name: 'Field Label' })` — uses `aria-label`, resilient to DOM changes
- `getByText('Action Name')` — action buttons/menu items
- `page.locator('[data-control-name="FieldName"]')` — BC's data attributes where available
- All selectors centralized in the page-object — if BC DOM changes between versions, fix once in the helper, not in every test

**Authentication pattern:**
- Playwright's `storageState` — authenticate via Entra ID once in `globalSetup`, save session state, reuse across all tests (no login per test)

#### E2E Test Structure

```
e2e/
├── playwright.config.ts          # BC URL, auth, browsers, retries
├── global-setup.ts               # Entra ID login, save storageState
├── bc-playwright-helpers/
│   └── src/
│       ├── BCPage.ts             # Core page-object model
│       ├── BCListPage.ts         # List page interactions
│       ├── BCCardPage.ts         # Card page interactions
│       ├── BCLookup.ts           # Lookup/dropdown helpers
│       └── BCAuth.ts             # Authentication helpers
├── tests/
│   ├── customer-list.spec.ts     # Customer List E2E scenarios
│   ├── customer-card.spec.ts     # Customer Card create/edit flows
│   └── ...
└── package.json                  # playwright, @playwright/test deps
```

#### CI Integration

```yaml
# .github/workflows/e2e-tests.yaml (custom, alongside AL-Go)
# Triggers after successful AL-Go CI/CD deploy
# 1. Wait for BC sandbox deployment to complete
# 2. Run Playwright tests against deployed sandbox
# 3. Upload trace + screenshot artifacts on failure
# 4. Post AI-parseable summary as PR comment
```

### Test Layer Summary

| Concern | Layer | When it runs | Failure = |
|---|---|---|---|
| Does the logic work? | Unit/Integration (AL) | Every push via AL-Go CI | Compilation or assertion error in AL |
| Does it scale? | Performance (BCPT) | On-demand / release gate | Throughput below threshold |
| Does the UI work? | E2E (Playwright) | Post-deploy via custom workflow | Screenshot diff / assertion on page state |

### AI Agent Test Workflow

1. **Implement feature** → AL code in `AL AI Showcase/src/`
2. **Write unit tests** → AL test codeunit in `AL AI Showcase.Test/src/` (prompt contract: `add-test.prompt.md`)
3. **Push** → AL-Go CI compiles + runs unit tests
4. **If unit tests green + deployed** → E2E workflow triggers Playwright tests
5. **If Playwright fails** → trace + screenshot artifacts posted → AI reads via MCP → fixes test or code → pushes again
6. **If all green** → PR ready for merge

---

## Phase 1 — Create Repository from AL-Go-PTE Template ✅

**Status:** COMPLETED 2025-02-24

**Steps:**

1. ✅ Run `gh repo create Professional-Advantage-SDG/AL-AI-Showcase --template microsoft/AL-Go-PTE --public --clone --description "AI-first Business Central AL Extension showcase - entirely written by AI"` from `C:\Work\GitHub\`
2. ✅ Verify clone at `C:\Work\GitHub\AL-AI-Showcase\`
3. ✅ Confirm AL-Go template structure: `.AL-Go/settings.json`, `.github/workflows/` (21 workflows), `.gitignore`, `al.code-workspace`, `localDevEnv.ps1`, `cloudDevEnv.ps1`
   - **Note:** Template also included `CODEOWNERS`, `README.md`, `SECURITY.md`, `SUPPORT.md`
4. ✅ Add `LICENSE` file (MIT)

**Outputs:** New public repo with full AL-Go CI/CD infrastructure and MIT license.

---

## Phase 2 — Configure AL-Go Settings ✅

**Status:** COMPLETED 2025-02-24

**Steps:**

5. ✅ Edit `.AL-Go/settings.json`:
   - Set `"country": "au"`
   - Set `"enableCodeCop": true`
   - Set `"enableUICop": true`
   - Set `"enablePerTenantExtensionCop": true`
   - Added `"useCompilerFolder": true`
6. ✅ Enable GitHub Pages (via API, `build_type: "workflow"`) for aldoc reference documentation
   - Pages URL: https://professional-advantage-sdg.github.io/AL-AI-Showcase/
7. ✅ Configure branch protection on `main`:
   - Require pull request before merging (no direct push)
   - Require status checks to pass (CI/CD)
   - Dismiss stale reviews, require 1 approving review
   - Block force pushes and deletions
   - **Note:** Admin can bypass (used for initial setup commits)
8. ✅ Create `.github/dependabot.yml`:
   - Enable npm updates for `e2e/` (Playwright deps) — weekly schedule
   - Enable GitHub Actions version updates — weekly schedule
9. ✅ Enable GitHub secret scanning and push protection on the repository
10. ✅ Commit: `chore(al-go): configure AU country, code analyzers, branch protection, and security`

**Outputs:** AL-Go configured for Australian BC sandbox with all cops enabled, branch protection enforced, and dependency/security scanning active.

---

## Phase 3 — Create Main App via AL-Go Workflow ✅

**Status:** COMPLETED 2025-02-24

**Steps:**

11. ✅ Trigger `CreateApp.yaml` workflow via `gh workflow run`:
    - Name: `AL AI Showcase`
    - Publisher: `BW-PA`
    - ID Range: `50100..50249`
    - Direct Commit: `true`
    - **Note:** Despite `directCommit=true`, branch protection caused a branch `create-pte/main/260224071222` to be created. Merged manually via fast-forward.
12. ✅ Pull/merge changes locally
13. ✅ Customize the generated app:
    - **Actual folder name:** `AL AI Showcase/` (not `app/` — AL-Go uses the app name as folder)
    - Updated `app.json`: runtime `16.0`, application `27.0.0.0`, description, url, `allowDownloadingSource: true`, `includeSourceInSymbolFile: true`
    - App GUID: `6d6bd24d-26cd-46ec-bdf7-6f851baef93c`
    - Restructured into `src/Table/`, `src/TableExtension/`, `src/Page/`, `src/PageExtension/`, `src/Codeunit/`, `src/Report/`, `src/Enum/`, `src/Query/`, `src/XMLport/`, `src/Interface/`, `src/Permission/`
    - Renamed `HelloWorld.al` → `src/PageExtension/CustomerListExt.PageExt.al` with namespace `BWPA.ALAIShowcase`
    - Added XML doc comments
14. ✅ Create `.vscode/settings.json`:
    - `"al.codeAnalyzers": ["CodeCop", "UICop", "PerTenantExtensionCop"]`
    - `"al.enableCodeActions": true`
    - `"al.packageCachePath": ".alpackages"`
15. ✅ Committed: `feat(app): customize app structure, namespace, and conventions`

**Outputs:** Main app project in `AL AI Showcase/` with proper folder structure, namespace, and VS Code workspace config.

---

## Phase 4 — Create Test App via AL-Go Workflow ✅

**Status:** COMPLETED 2025-02-24

**Steps:**

16. ✅ Trigger `CreateTestApp.yaml` workflow:
    - Name: `AL AI Showcase.Test`
    - Publisher: `BW-PA`
    - ID Range: `50250..50299`
    - Direct Commit: `true`
    - **Note:** Same branch protection behavior — created branch `create-test-app/main/260224072415`. Merged via fast-forward.
17. ✅ Pull/merge changes locally
18. ✅ Customize the generated test app:
    - **Actual folder name:** `AL AI Showcase.Test/` (not `test/` — AL-Go uses the app name as folder)
    - Test app GUID: `5bb2624f-fea1-41d0-a911-baf00bb47ca4`
    - Added dependency on main app (`AL AI Showcase`, `6d6bd24d-26cd-46ec-bdf7-6f851baef93c`)
    - Added `Library Variable Storage` dependency
    - Updated `app.json`: runtime `16.0`, application `27.0.0.0`, descriptions, source exposure
    - Added namespace `BWPA.ALAIShowcase.Test`
    - Renamed `HelloWorld.Test.al` → `src/PageExtension/CustomerListExtTest.Codeunit.al`
    - Applied GIVEN/WHEN/THEN test pattern
    - Applied AI-diagnostic error message format
    - Added XML doc comments
    - **Note:** AL-Go auto-generated a working test with `MessageHandler` — kept and enhanced
19. ✅ Committed: `test(scaffold): customize test app structure and conventions`

**Outputs:** Test app project in `AL AI Showcase.Test/` with dependency on main app, GIVEN/WHEN/THEN pattern, and AI-diagnostic error messages.

---

## Phase 5 — Devcontainer Configuration

**Steps:**

20. Create `.devcontainer/devcontainer.json` for GitHub Codespaces:
    - Base image: `mcr.microsoft.com/businesscentral/sandbox`
    - Extensions: `ms-dynamics-smb.al`, `ms-vscode.powershell`
    - Post-create: install BcContainerHelper, pull symbols
    - Forward ports: 443, 8080, 7049
21. Create `.devcontainer/post-create.ps1` script
22. Commit: `chore(devcontainer): configure Codespaces for BC development`

**Outputs:** One-click Codespaces environment for BC AL development.

---

## Phase 6 — Build Scripts & Local Dev

**Steps:**

23. Create `scripts/build.ps1` — headless compile via `alc.exe` (obtained from `Get-BcContainerCompilerFolder`), returns structured error output
24. Create `scripts/lint-errors.ps1` — parses compiler + CodeCop output, formats AI-diagnostic messages with WHAT/ACTUAL/EXPECTED/WHERE/HOW structure
25. Create `scripts/run-tests.ps1` — runs tests in BC container, outputs results in JUnit XML
26. Commit: `chore(scripts): add build, lint, and test runner scripts`

**Outputs:** CLI-driven build pipeline for local and CI use.

---

## Phase 7 — Prompt Contracts Framework

**Steps:**

27. Create `prompts/README.md` — explains prompt contract methodology with:
    - What prompt contracts are
    - Format: Context → Inputs → Expected Outputs → Success Criteria → Failure Conditions → Verification Steps
    - How AI agents should use them
    - Examples
28. Create initial prompt contracts:
    - `prompts/contracts/new-feature.prompt.md` — contract for implementing a new AL feature end-to-end
    - `prompts/contracts/fix-bug.prompt.md` — contract for diagnosing and fixing a bug
    - `prompts/contracts/add-test.prompt.md` — contract for writing tests for existing code
    - `prompts/contracts/refactor.prompt.md` — contract for safe refactoring with test preservation
    - `prompts/contracts/compile-fix.prompt.md` — contract for resolving compilation errors autonomously
    - `prompts/contracts/add-e2e-test.prompt.md` — contract for writing Playwright E2E tests using the BC page-object model
29. Commit: `docs(prompts): establish prompt contracts framework`

**Outputs:** Reusable prompt contract templates for autonomous AI agent workflows.

---

## Phase 8 — Documentation Suite

**Steps:**

30. Create `README.md`:
    - Project vision, architecture overview, ID allocation table, getting started (local + Codespaces), CI/CD overview, prompt contracts summary, contributing guide link
31. Create `CONTRIBUTING.md`:
    - Branch naming (`feature/`, `fix/`, `test/`, `docs/`), conventional commits, PR process, prompt contract usage, AI-diagnostic error message standards
32. Create `.github/copilot-instructions.md`:
    - AL coding conventions (PascalCase classes/methods/variables, camelCase parameters)
    - File naming: `<ObjectName>.<ObjectType>.al`
    - Namespace: `BWPA.ALAIShowcase` / `BWPA.ALAIShowcase.Test`
    - Error message format (AI-diagnostic with WHAT/ACTUAL/EXPECTED/WHERE/HOW)
    - ID allocation rules and lookup procedure
    - Test patterns (GIVEN/WHEN/THEN, Library Assert usage)
    - Prompt contract awareness
    - Conventional commit enforcement
33. Create `CLAUDE.md`:
    - Mirror of copilot-instructions.md adapted for Claude Code conventions
    - Additional: terminal commands, multi-file edit patterns, how to use MCP servers
34. Create `docs/id-allocation.md` — detailed ID allocation registry with claimed/available tracking
35. Create `docs/ai-diagnostic-errors.md` — reference guide for AI-diagnostic error message patterns with examples
36. Create `.github/CODEOWNERS` — assign default reviewers (org team or individuals) for AL, TypeScript, docs, and workflow files
37. Commit: `docs: add README, CONTRIBUTING, agent instructions, CODEOWNERS, and reference docs`

**Outputs:** Complete documentation for both human and AI contributors, with automated review assignment.

---

## Phase 9 — Architecture Decision Records (ADRs)

**Steps:**

38. Create `docs/adr/` directory with template `docs/adr/0000-template.md`
39. Create initial ADRs:
    - `0001-al-go-pte-template.md` — Why AL-Go-PTE over manual CI/CD
    - `0002-prompt-contracts.md` — Why structured prompt contracts for AI autonomy
    - `0003-ai-diagnostic-errors.md` — Why all errors must be AI-parseable
    - `0004-namespace-convention.md` — BWPA.ALAIShowcase namespace choice
    - `0005-id-allocation-strategy.md` — Fixed ranges per object type
    - `0006-mcp-server-strategy.md` — Multi-MCP approach for AI agents
    - `0007-azure-devops-integration.md` — Azure Boards + GitHub integration
    - `0008-playwright-over-page-scripting.md` — Why Playwright for E2E over BC Page Scripting (maturity, TypeScript types, MCP integration, AI generation quality, no published YAML schema for Page Scripting)
40. Commit: `docs(adr): establish Architecture Decision Records`

**Outputs:** Institutional memory for all architectural decisions.

---

## Phase 10 — PR Template & Auto-Retry CI Workflow

**Steps:**

41. Create `.github/pull_request_template.md`:
    - Checklist: prompt contract verified, ID allocation checked, AI-diagnostic errors, tests pass, conventional commit, `AB#<id>` linked
    - Sections: What changed, Why, How verified, Prompt contract used
42. Create `.github/workflows/auto-retry-ci.yaml`:
    - Triggers on CI failure
    - Extracts error messages from failed build/test logs
    - Posts structured error summary as PR comment (AI-parseable)
    - Optionally re-triggers build after agent pushes fix
    - Max 3 retry attempts with backoff
43. Commit: `chore(ci): add PR template and auto-retry CI workflow`

**Outputs:** PR quality gates and autonomous CI failure recovery.

---

## Phase 11 — Custom CodeAnalyzer for Error Messages

**Steps:**

44. Research feasibility of custom AL CodeAnalyzer rules (ruleset XML or custom analyzer DLL)
45. If feasible: create `analyzers/` with rules enforcing:
    - Error() calls must include descriptive messages (no empty strings)
    - FieldError() calls must reference the field name
    - Test assertions must include failure message parameter
46. If not feasible via analyzer: create `scripts/lint-errors.ps1` enhanced validation that scans `.al` files for violations
47. Commit: `chore(lint): add error message quality enforcement`

**Outputs:** Automated enforcement of AI-diagnostic error message standards.

---

## Phase 12 — Test Coverage Tracking

**Steps:**

48. Create `scripts/test-coverage.ps1`:
    - Maps test codeunits to source objects via naming convention + dependency analysis
    - Generates coverage matrix (which objects have tests, which don't)
    - Tracks all three layers: AL unit tests, BCPT perf tests, Playwright E2E tests
    - Outputs `docs/test-coverage.md` with per-object coverage table and layer indicators
49. Create `.github/workflows/update-coverage.yaml`:
    - Runs on PR merge to main
    - Regenerates coverage matrix
    - Commits updated `docs/test-coverage.md`
50. Create `.github/workflows/e2e-tests.yaml`:
    - Triggers after successful AL-Go CI/CD deploy to sandbox
    - Runs `npx playwright test` against deployed BC environment
    - Uploads trace files + screenshots as artifacts on failure
    - Posts AI-parseable failure summary as PR comment (page, selector, expected vs actual, screenshot link)
51. Commit: `chore(test): add test coverage tracking and E2E workflow`

**Outputs:** Visibility into test coverage gaps across all three layers, plus automated E2E test execution post-deploy.

---

## Phase 13 — Conventional Commits & Auto-Changelog

**Steps:**

52. Create `scripts/validate-commits.ps1`:
    - Validates commit messages against `<type>(<scope>): <description>` format
    - Valid types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `perf`
    - Extracts `AB#<id>` references from footer
53. Create `.github/workflows/validate-pr-title.yaml`:
    - Runs on PR open/edit
    - Validates PR title follows conventional commit format
54. Create `scripts/generate-changelog.ps1`:
    - Parses git log for conventional commits
    - Groups by type, generates `CHANGELOG.md`
55. Commit: `chore(commits): add conventional commit validation and changelog generation`

**Outputs:** Structured commit history and automated changelog.

---

## Phase 14 — MCP Server Strategy Documentation

**Steps:**

56. Create `docs/mcp-strategy.md`:
    - Azure DevOps MCP: work item queries, state transitions, sprint planning, `AB#` linking
    - GitHub MCP: PR creation, CI status, code review, issue management
    - Playwright MCP: E2E UI testing against BC web client, page validation, workflow simulation
    - Filesystem/Terminal MCP: local file operations, build scripts, container management
    - Usage patterns: when to use which server, authentication setup, example workflows
57. Commit: `docs(mcp): document MCP server strategy for AI agents`

**Outputs:** AI agents know which MCP server to use for each task type.

---

## Phase 15 — Issue Templates

**Steps:**

58. Create `.github/ISSUE_TEMPLATE/`:
    - `feature-request.yml` — structured form with acceptance criteria, ID range impact, prompt contract reference
    - `bug-report.yml` — structured form with repro steps, expected/actual behavior, AB# link field
    - `ai-task.yml` — template for AI-assignable tasks with prompt contract selection and success criteria
59. Commit: `chore(github): add issue templates`

**Outputs:** Structured issue intake for both human and AI contributors.

---

## Phase 16 — Environment Provisioning

**Steps:**

60. Configure GitHub repository secrets:
    - `AUTHCONTEXT` — BC authentication context for AL-Go
    - `AZURE_DEVOPS_PAT` — for Azure Boards integration
    - `E2E_BC_USERNAME` / `E2E_BC_PASSWORD` — Entra ID credentials for Playwright E2E tests (service account or test user)
61. Test `CreateOnlineDevelopmentEnvironment.yaml` workflow to provision BC sandbox
62. Verify CI/CD pipeline: push → build → test → deploy cycle
63. Commit: `chore(env): configure secrets and verify deployment pipeline`

**Outputs:** Working end-to-end CI/CD with BC sandbox deployment and E2E auth configured.

---

## Phase 17 — Reference Documentation Deployment

**Steps:**

64. Configure `DeployReferenceDocumentation.yaml` workflow:
    - Ensure XML doc comments on all public procedures in main app
    - Configure aldoc settings in `.AL-Go/settings.json`
    - Trigger workflow and verify GitHub Pages deployment
65. Commit: `docs(aldoc): enable reference documentation generation`

**Outputs:** Auto-generated API documentation on GitHub Pages.

---

## Phase 18 — Version Compatibility Testing

**Steps:**

66. Configure `VerifyPRChanges.yaml` to test against multiple BC versions if supported
67. Ensure `CI/CD` workflow runs against AU-specific artifacts
68. Document supported BC version range in README

**Outputs:** Confidence in cross-version compatibility.

---

## Phase 19 — Showcase Features (Ongoing)

**Steps:**

69. Plan first feature set showcasing AL capabilities:
    - Custom Table + Page (List/Card pattern)
    - Table Extension on standard BC table
    - Enum with Enum Extension
    - Codeunit with business logic + events
    - Report with dataset and layout
    - Query object
    - XMLport for data import/export
    - Permission Set
    - Interface + implementations
    - Page customization and profiles
    - Notifications and error handling patterns
    - Job Queue integration
    - Web service exposure (API pages with v1.0/v2.0 versioning)
    - Dimension handling
    - Approval workflow integration
    - Upgrade codeunit (version migration logic)
    - ControlAddIn (JavaScript-based control extensibility)
    - Entitlements (licensing control object)
    - Data Classification on fields (privacy compliance)
    - Obsolete attribute patterns (deprecation lifecycle)
    - RecordRef / FieldRef (dynamic record handling)
    - Isolated Events (advanced event patterns)
    - Page Background Tasks (async page operations)
    - Retention Policy setup
    - Application Insights custom telemetry
    - Test data seeding patterns (sample data provisioning)
70. Each feature follows the autonomous loop:
    - AI agent reads prompt contract
    - Creates feature branch
    - Implements code + tests
    - Pushes → CI runs → if fail → reads AI-diagnostic errors → fixes → pushes again
    - PR created with conventional commit title and `AB#` link
    - Merged on green CI

**Outputs:** Comprehensive AL language showcase built entirely by AI.

---

## Phase 20 — Validation & Autonomous Loop Verification

**Steps:**

71. End-to-end validation:
    - AI agent picks up an Azure DevOps work item via MCP
    - Selects appropriate prompt contract
    - Implements feature + tests
    - Pushes to branch → CI builds → tests run
    - If CI fails: auto-retry workflow posts AI-diagnostic errors → agent reads → fixes → pushes
    - PR created with prompt contract verification checklist
    - Merged on green → deployed to BC sandbox
    - Work item state updated via Azure DevOps MCP
72. Document the autonomous loop in `docs/autonomous-loop.md` with metrics:
    - Average iterations to green CI
    - Common failure categories
    - Self-correction success rate

**Outputs:** Proven autonomous SDLC loop with documented metrics.

---

## Phase 21 — Release Strategy & Multi-Environment Deployment

**Steps:**

73. Define release strategy:
    - Semantic versioning via `IncrementVersionNumber.yaml` (major.minor.patch)
    - Release creation via `CreateRelease.yaml` triggered on version tags
    - Release notes auto-generated from conventional commit changelog
74. Configure multi-environment promotion pipeline:
    - **Dev sandbox** — automatic deploy on every green CI (already in Phase 16)
    - **QA/Staging sandbox** — deploy on release branch creation, manual approval gate
    - **Production tenant** — deploy on release tag, requires PR approval + all tests green
    - Use `PublishToEnvironment.yaml` with environment-specific `AUTHCONTEXT` secrets (`AUTHCONTEXT_DEV`, `AUTHCONTEXT_QA`, `AUTHCONTEXT_PROD`)
75. Create `docs/release-strategy.md` documenting the promotion flow and gating criteria
76. Commit: `chore(release): configure release strategy and multi-environment deployment`

**Outputs:** Structured release process with environment promotion gates.

---

## Standing Principles

### AI-Diagnostic Error Messages
All error messages throughout the codebase must follow this pattern:
```
Error('%1 failed: Expected %2 but got %3 in %4.%5. Fix: %6',
    <What>, <Expected>, <Actual>, <Object>, <Procedure>, <Resolution>);
```

### File Naming Convention
```
<ObjectName>.<ObjectType>.al
```
Examples: `Customer.Table.al`, `CustomerList.Page.al`, `CustomerMgmt.Codeunit.al`

### Test Naming Convention
```
[Feature]_[Scenario]_[ExpectedResult]
```
Example: `CustomerCreation_WhenNameIsBlank_ThrowsError`

### Conventional Commits
```
<type>(<scope>): <description>

AB#<work-item-id>
```
Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `perf`

### Prompt Contract Format
```markdown
## Context
[What the agent needs to know]

## Inputs
[What is provided]

## Expected Outputs
[What must be produced]

## Success Criteria
[How to verify success]

## Failure Conditions
[What constitutes failure]

## Verification Steps
[Concrete steps to validate]
```

---

## AL-Go Workflows to Leverage

| Workflow | Phase | Purpose |
|---|---|---|
| `CreateApp.yaml` | 3 | Scaffold main app project |
| `CreateTestApp.yaml` | 4 | Scaffold test app project |
| `CI/CD.yaml` | 16+ | Continuous build/test/deploy |
| `CreateOnlineDevelopmentEnvironment.yaml` | 16 | Provision BC sandbox |
| `DeployReferenceDocumentation.yaml` | 17 | aldoc → GitHub Pages |
| `VerifyPRChanges.yaml` | 18 | PR validation builds |
| `CreateRelease.yaml` | 21 | Release management |
| `CreatePerformanceTestApp.yaml` | Future | Performance testing |
| `PublishToEnvironment.yaml` | 21 | Multi-environment deployment |
| `UpdateGitHubGoSystemFiles.yaml` | Ongoing | Keep AL-Go up to date |
| `IncrementVersionNumber.yaml` | Ongoing | Semantic versioning |
| `AddExistingAppOrTestApp.yaml` | If needed | Import existing apps |
| `PullRequestHandler.yaml` | Ongoing | PR workflow automation |
