# ErvenWallet — Refined Implementation Plan

This plan refines the spec at [`../Erven finance app spec and plan.md`](../Erven%20finance%20app%20spec%20and%20plan.md). Changes from the spec are called out inline.

## Phase 0 — Validation Spike (2–3 days) — NEW

**Goal:** de-risk the two highest-unknown items before committing to 14 weeks of work.

Tracked in [`PHASE-0-SPIKE.md`](PHASE-0-SPIKE.md). Decision gate at the end: go / downscope / fallback to Apple `NaturalLanguage`.

## Phase 1 — Foundation + Dogfoodable Core (Weeks 1–2)

**Goal:** working app you actually use daily by end of Week 2.

**Changes from spec:**
- Transfers land in Phase 1 (spec defers to Phase 2 but schema already implies them)
- JSON export lands in Phase 1 (spec puts in Phase 4 — too late for safe dogfooding across schema changes)
- `RecurringRule` stub included in the base schema to avoid SwiftData migration in Phase 4
- GitHub Actions CI set up Day 3
- Minimal onboarding (seed categories + first account) lives here, not Phase 5
- `BGTaskScheduler` identifiers registered in Info.plist even though unused

**Tasks:**
- [ ] Xcode project: iOS App, SwiftUI, SwiftData, Swift Testing, iOS 17 min, bundle `com.ervenderr.ervenwallet`
- [ ] Folder structure per spec §3.2
- [ ] Git + GitHub repo (public, MIT)
- [ ] Decimal/currency formatter (PHP)
- [ ] Enums: `AccountType`, `TransactionType`, `CategoryType`, `Frequency`
- [ ] SwiftData models: `Account`, `Transaction`, `Category`, `RecurringRule` (stub), `Budget`, `SavingsGoal`, `Debt` (stub for Phase 3)
- [ ] Default PHP categories seeded on first launch
- [ ] Tab bar scaffold (Wallet / Transactions / Budget / Goals / More)
- [ ] `WalletView`, `AddAccountSheet` (cash/bank/e-wallet; CC deferred to Phase 3)
- [ ] `AddTransactionSheet` — expense, income, transfer
- [ ] `TransactionListView` with filter
- [ ] JSON export (bare minimum)
- [ ] Dark mode verification
- [ ] GitHub Actions: build + test on push
- [ ] Unit tests: models, currency math, category seeding
- [ ] Decide iCloud sync (yes/no) — affects every model
- [ ] Register `BGTaskScheduler` identifiers in Info.plist

## Phase 2 — Budgets & Goals (Weeks 3–4)

- [ ] `Budget` CRUD, `BudgetOverviewView` with progress bars
- [ ] `spent` as computed query, not stored
- [ ] Local notifications: permission flow, 80%/100% alerts
- [ ] `SavingsGoal` CRUD, `GoalsListView`, "save X/day" calc
- [ ] Integration tests: budget calculation vs seeded transactions

## Phase 3 — Credit Cards & Debt (Weeks 5–6)

- [ ] `Account` CC fields: `creditLimit`, `statementDay`, `dueDay`
- [ ] "This Statement" logic (heavy unit tests — edge cases: month boundaries, leap years)
- [ ] CC payment flow (transfer from bank → CC reduces balance)
- [ ] `Debt` model + payment logging
- [ ] `PlannedPaymentsView` timeline (derived from CC + debts)

## Phase 4 — Recurring & Reports (Weeks 7–8)

- [ ] `RecurringRule` full implementation
- [ ] `BGAppRefreshTask` for recurring generation (with launch-time backstop)
- [ ] Recurring management UI
- [ ] Swift Charts: income vs expense, category pie, trend line, net worth
- [ ] CSV export

## Phase 5 — Polish & Deploy (Weeks 9–10) — **real v1 ship date**

- [ ] Receipt photo attachment (PhotosUI)
- [ ] Calendar view for transactions
- [ ] Haptics, app icon, onboarding polish
- [ ] Widget (home screen balance) — or defer
- [ ] TestFlight upload, README screenshots
- [ ] Apple Developer enrollment (if not done earlier)

## Phase 6 — On-Device AI (Weeks 11–14)

Each week independently shippable behind a feature flag.

- **Week 11:** LiteRT-LM package, `GemmaService`, `ModelDownloadManager`, `ModelSetupView`, basic `AIChatView`
- **Week 12:** `TransactionParser` + function calling; Taglish/shorthand handling; `TransactionConfirmCard`; fallback to manual form on parse failure
- **Week 13:** `FinancialQueryEngine` + context injection; `InsightGenerator` + weekly notification
- **Week 14 (stretch):** Receipt vision via E4B; agent skills; thermal/memory tuning

If Week 14 slips → ship Weeks 11–13 as "AI v1", receipt scan as v1.1.

## Testing Strategy

- Unit tests per phase: models, math, date logic, parser JSON validity
- Integration tests: SwiftData CRUD, budget aggregation, debt payment, recurring generation, JSON export/import round-trip
- Device tests: Phase 0 spike, Phase 5 TestFlight build, Phase 6 AI flows
- Target: **80% coverage**, enforced in CI via `xccov`

## Risks (top 5)

1. **LiteRT-LM SDK maturity** — Phase 0 spike with hard decision gate
2. **Swift learning curve** — front-load 2 days of Apple tutorials; accept Phase 1 may be 3 weeks
3. **SwiftData migrations during dogfooding** — JSON export in Phase 1
4. **CC statement math bugs** — heavy unit tests with fixture edge cases
5. **Phase 6 scope creep** — feature-flag everything; v1 already shipped at Phase 5

## Success criteria

- [ ] Phase 0: documented go/no-go decision
- [ ] Phase 1: log expense/income/transfer, balances update, data persists, JSON export works, CI green
- [ ] Phase 2: monthly budgets track real transactions; goals show progress
- [ ] Phase 3: CC statement amount matches hand calc; debts reduce on payment
- [ ] Phase 4: recurring auto-generates; all four charts render; CSV export works
- [ ] Phase 5: installed on physical iPhone via TestFlight; portfolio-ready
- [ ] Phase 6: NL transaction parsing >90% success on test set; weekly insight fires
- [ ] Throughout: 80%+ coverage, no hardcoded secrets, immutable patterns
