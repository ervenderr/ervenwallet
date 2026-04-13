# ErvenWallet

A personal, offline-first, privacy-first iOS finance tracker. Single-user, open-source, Philippine-peso-native. No backend, no login, no telemetry — all data lives on-device.

Built around one user's actual financial workflow: cash + bank + GCash/Maya, credit cards with statement and due dates, debts (owing and owed), savings goals, recurring bills, and a natural-language quick-add.

## Features

- **Accounts** — cash, bank, e-wallet, and credit cards with statement day, due day, and credit-limit math (available credit, days-until-due, statement-period spend)
- **Transactions** — expenses, income, and transfers between accounts. Day-grouped list with segmented filter (All / Expense / Income / Transfer), search over notes/category/account/amount, and date-range picker (This Month / Last Month / Last 30 / Last 90 / All Time)
- **Quick-add** — type `lunch 250` or `uber 120 yesterday` and the rules-based parser extracts amount, category, and date in one keystroke. ~40 keyword aliases tuned for Filipino daily spending (jollibee, meralco, grab, etc.)
- **Budgets** — monthly per-category limits with gradient progress bars and launch-time over-budget notifications
- **Savings goals** — target amount, optional target date, daily-required calculation, one-tap contribution with success haptic
- **Debts** — track money you owe and money owed to you with running remaining-balance and payment log
- **Recurring rules** — daily/weekly/biweekly/monthly/yearly schedules, auto-materialized on launch
- **Reports** — Swift Charts visuals for month income/expense, category breakdown, 30-day spending trend, and net-worth-over-time
- **Account detail** — tap any account to see its gradient balance card, monthly stats, and full transaction history
- **Edit everywhere** — tap to edit any account, transaction, budget, goal, debt, recurring rule, or category
- **Category management** — add/edit/delete categories with a 42-icon picker
- **Local notifications** — credit card bill reminders 2 days before due date + budget-exceeded alerts
- **JSON export** — full schema-versioned export for backup or migration

## What about the AI?

The original spec called for on-device Gemma for natural-language entry, but my iPhone 11 (A13, 4 GB RAM) can't run it. So v1 ships with a rules-based parser that covers ~80% of daily phrases instantly and offline — no ML model, no API key, no network. When I upgrade to an A16+ device later, Gemma 3n via MediaPipe can slot in as an enhancement.

## Stack

| Layer | Tech |
|-------|------|
| Language | Swift 5.10+ |
| UI | SwiftUI (iOS 17+) |
| Persistence | SwiftData |
| Charts | Swift Charts |
| Notifications | UserNotifications (local only) |
| Testing | Swift Testing |
| CI | GitHub Actions (xcodebuild on macos-15) |

## Design

"Quiet Ledger" — deep teal (`#0F766E`) primary with warm gold (`#F59E0B`) accent. Gradient hero cards, rounded elevated-surface rows, animated counters via `.contentTransition(.numericText())`, and a consistent card-based layout across tabs. Dark mode inherits the system background.

All design tokens live in [`Branding/Theme.swift`](ErvenWallet/ErvenWallet/Branding/Theme.swift) — palette, gradients, spacing, radii, shadows.

## Running it yourself

Free Apple ID install (7-day cert, renew by rebuilding):

1. Clone the repo
2. Open `ErvenWallet/ErvenWallet.xcodeproj` in Xcode 16+
3. Project → Signing & Capabilities → pick your personal team, set a unique bundle ID
4. Plug in your iPhone, select it as the destination, `Cmd+R`

Project is iOS 17.0+.

## Project structure

```
ervenwallet/
├── docs/
│   ├── PLAN.md              # Roadmap and phase breakdown
│   └── PHASE-0-SPIKE.md
├── ErvenWallet/             # Xcode project
│   └── ErvenWallet/
│       ├── Branding/        # Theme, Haptics, FloatingAddButton, AppLogo
│       ├── Models/          # SwiftData @Model types
│       ├── Services/        # DataExport, Recurring, QuickAddParser, Notifications
│       ├── Utilities/       # CurrencyFormatter, CreditCardMath, DefaultCategories
│       └── Views/           # Wallet, Transactions, Budget, Goals, Debts, Recurring, Reports, Categories, More
└── LICENSE
```

## License

MIT — see [LICENSE](LICENSE).
