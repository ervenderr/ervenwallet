# Phase 0 — Validation Spike

**Duration:** 2–3 days
**Goal:** de-risk LiteRT-LM/Gemma 4 on a real iPhone, and your Swift toolchain, before committing to 14 weeks of work.
**Exit criteria:** documented go / downscope / fallback decision.

---

## Day 1 — Environment + Swift ramp-up

### Toolchain
- [x] Xcode installed (`xcodebuild -version` → **Xcode 26.2** ✅)
- [ ] Launch Xcode once, accept license, install additional components
- [ ] Verify `xcode-select -p` points to `/Applications/Xcode.app/Contents/Developer`
- [ ] `xcrun simctl list devices` — confirm at least one iOS 17+ simulator
- [ ] Apple ID signed in to Xcode (Settings → Accounts)
- [ ] Decide: enroll in Apple Developer Program ($99/yr) now or later
  - **Now:** needed for TestFlight in Phase 5, but not for local device signing
  - **Later:** free signing works for dev, 7-day expiry on installed builds

### SwiftUI / SwiftData ramp (half to full day)
- [ ] Apple tutorial: [Meet SwiftData](https://developer.apple.com/videos/play/wwdc2023/10187/)
- [ ] Apple tutorial: [Discover Observation in SwiftUI](https://developer.apple.com/videos/play/wwdc2023/10149/)
- [ ] Apple tutorial: [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui) — at least the first 3 chapters
- [ ] Understand: `@Model`, `@Query`, `@Environment(\.modelContext)`, `@Observable`, `@State`, `@Binding`, `@Bindable`
- [ ] Understand: value types (struct) vs reference types (class), and when each is used
- [ ] Understand: `NavigationStack` + `NavigationPath` (ignore tutorials using `NavigationView`)
- [ ] Understand: `Decimal` vs `Double`, how to do arithmetic safely

**Gotcha:** LLM assistants hallucinate deprecated Swift APIs heavily. Always verify against Apple docs.

---

## Day 2 — LiteRT-LM / Gemma 4 spike

### Clone + build the reference app
- [ ] Clone `google-ai-edge/gallery` — the official open-source LiteRT-LM showcase
- [ ] Clone `google-ai-edge/LiteRT-LM` — read the Swift SDK README + iOS examples
- [ ] Open the iOS Gallery target in Xcode
- [ ] Select your physical iPhone as run destination (simulator ≠ real perf)
- [ ] Build and install — troubleshoot any signing / provisioning issues

### Run Gemma 4 E2B on device
- [ ] Launch Gallery, download Gemma 4 E2B when prompted
- [ ] **Record:** download size, download time on Wi-Fi
- [ ] Try a simple prompt ("What is 2+2?"), **record:** cold-start latency, tokens/sec
- [ ] Try a longer prompt (200+ tokens), **record:** sustained tokens/sec
- [ ] Monitor memory in Xcode Instruments, **record:** peak memory
- [ ] Run a 5-minute session, **record:** device temperature (hot? throttling?)

### Function-calling validity test (critical)
Build or reuse a simple test harness that sends 20 prompts and checks for valid JSON output. Save results to `phase-0-results.md`.

**Test prompts** (mix English, Taglish, shorthand):
- [ ] "Spent 350 on groceries at SM"
- [ ] "Got paid 25k from SparkSoft"
- [ ] "Transferred 5k from BDO to GCash"
- [ ] "Spent 200 sa Jollibee"
- [ ] "Bumili ako ng kape, 150"
- [ ] "5k load GCash"
- [ ] "Netflix 549"
- [ ] "Grab ride to BGC 180"
- [ ] "Kuryente bill 3200"
- [ ] "Freelance payment 15k from SEO Local"
- [ ] "Bayad kotse loan 8k"
- [ ] "Lunch 280"
- [ ] "Bought shirt 1200 sa SM North"
- [ ] "Allowance from mom 5k"
- [ ] "Subscription Spotify 149"
- [ ] "MRT fare 24"
- [ ] "Internet bill Converge 2500"
- [ ] "Dividends BDO 450"
- [ ] "Gas 1500 Shell"
- [ ] "Rent 15k"

**Score each:**
1. Did it return valid JSON?
2. Was the amount correct?
3. Was the type (expense/income/transfer) correct?
4. Was the category plausible?

### Decision gate

Record outcomes in `phase-0-results.md`. Use this matrix:

| Metric | Go | Downscope | Fallback |
|--------|----|-----------|----------|
| JSON validity | ≥90% | 70–90% | <70% |
| Latency per parse | ≤3s | 3–6s | >6s |
| Peak memory | <1.5GB (E2B) | 1.5–2GB | >2GB |
| Thermal | cool/warm after 5min | hot but usable | throttled |
| Function calling shipped in Swift SDK | yes | experimental | no |

- **Go:** proceed with Phase 6 as planned
- **Downscope:** ship chat + Q&A only; skip receipt vision; hybrid parser (regex → LLM)
- **Fallback:** drop LiteRT-LM entirely; use Apple `NaturalLanguage` + hand-rolled parser for Phase 6

---

## Day 3 — Hello-world SwiftUI app (if Days 1–2 went fast)

Prove your end-to-end dev loop works before starting the real project:
- [ ] Create throwaway `HelloErven` Xcode project
- [ ] One screen: tap button → increment counter stored in SwiftData
- [ ] Build + run on simulator
- [ ] Build + run on physical iPhone
- [ ] Confirm: you can edit code → rebuild → see change on device in <30s
- [ ] Delete project (or archive to `.scratch/`)

---

## Deliverables

- [ ] `phase-0-results.md` with measurements + decision
- [ ] Commit: `docs: phase 0 validation spike results`
- [ ] Green light to start Phase 1 — or documented pivot
