# ErvenWallet

A personal, offline-first, privacy-first iOS finance tracker — single-user, open-source, PHP-centric, with an on-device Gemma 4 AI assistant.

> Status: **Phase 0 — Validation Spike**. No Xcode project yet.

## What it is

Native SwiftUI + SwiftData app for iOS 17+. No backend, no login, no telemetry. All data lives on-device. Built around one user's actual financial workflow: Philippine peso, credit cards, GCash/Maya, forex/trading, freelance + salary split.

The headline feature is a fully on-device AI assistant — Gemma 4 E2B/E4B running via Google's LiteRT-LM Swift SDK. Natural-language transaction entry, context-aware financial Q&A, and (stretch) receipt scanning. Zero cloud. Zero API keys. Your data never leaves your phone.

## Stack

| Layer | Tech |
|-------|------|
| Language | Swift 5.10+ |
| UI | SwiftUI (iOS 17+) |
| Persistence | SwiftData |
| Charts | Swift Charts |
| On-device AI | Gemma 4 E2B/E4B via LiteRT-LM |
| Testing | Swift Testing + XCTest |
| CI | GitHub Actions |

## Roadmap

See [`docs/PLAN.md`](docs/PLAN.md) for the full refined roadmap. High-level:

- **Phase 0** — LiteRT-LM validation spike (in progress)
- **Phase 1** — Foundation: data models, accounts, transactions (incl. transfers), JSON export, CI
- **Phase 2** — Budgets & savings goals
- **Phase 3** — Credit cards & debt tracking
- **Phase 4** — Recurring transactions & reports (Swift Charts)
- **Phase 5** — Polish & TestFlight ship (v1 — AI optional)
- **Phase 6** — On-device AI with Gemma 4

## Project structure

```
ervenwallet/
├── docs/              # Plan, phase notes, research
├── ErvenWallet/       # Xcode project (created in Phase 1)
├── LICENSE            # MIT
├── README.md
└── .gitignore
```

## License

MIT — see [LICENSE](LICENSE).
