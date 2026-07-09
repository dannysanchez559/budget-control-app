# QA Checklist — Budget Control

Manual on-device testing checklist before TestFlight. Based on the **implemented** SwiftUI codebase (`BudgetControl.xcodeproj`), not the PRD alone.

**Tester:** ____________________  
**Date:** ____________________  
**Device model:** ____________________  
**iOS version:** ____________________ (minimum deployment target: **iOS 17.0**)  
**Build:** ____________________  
**Xcode scheme:** `BudgetControl`

---

## Setup

- [ ] Connect a physical iPhone (not Simulator) via USB or Wi-Fi debugging
- [ ] Open `BudgetControl.xcodeproj` in Xcode
- [ ] Select the **BudgetControl** scheme and the connected device as the run destination
- [ ] In **Signing & Capabilities**, confirm a valid Team is selected and provisioning succeeds (no signing errors)
- [ ] Product → **Run** (⌘R) — app installs and launches on the device
- [ ] Confirm the installed app name is **Budget Control** on the home screen
- [ ] Record device model and iOS version in the header above (e.g. iPhone 15 Pro, iOS 17.4)
- [ ] For a clean first-launch test: delete the app from the device, then reinstall via Xcode
- [ ] For regression testing: keep an existing install and verify data persists across relaunch

---

## Onboarding

- [ ] On first launch (fresh install), the 4-screen onboarding pager appears before the main tab shell
- [ ] **Screen 1** — “Take control of your money”: SF Symbol icon badge (`target`), title, body text, dot indicator, **Continue** button; **Skip** is hidden/disabled
- [ ] **Screen 2** — “All your wallets in one place”: displays correctly; **Skip** is visible and tappable
- [ ] **Screen 3** — “Built for life on the go”: displays correctly; **Skip** works
- [ ] **Screen 4** — “Your data stays with you”: displays correctly; CTA reads **Get Started**
- [ ] Swiping horizontally between pages works; dot indicator updates
- [ ] **Continue** advances one screen at a time (screens 1–3)
- [ ] **Get Started** on screen 4 dismisses onboarding and shows the main tab bar (Home, Stats, Calendar, Plans, All)
- [ ] **Skip** from screen 2 or 3 completes onboarding immediately (same result as Get Started)
- [ ] Force-quit and relaunch — onboarding does **not** appear again
- [ ] Default seed data is present after onboarding: 3 wallets (Cash, Card, Savings) and 13 categories (8 expense, 5 income)

---

## Add / Edit Transaction

Opened via the floating **+** button (all tabs except Plans) or by tapping a transaction row.

### Fields & validation

- [ ] Sheet title is **New Transaction** (add) or **Edit Transaction** (edit)
- [ ] **Cancel** dismisses without saving
- [ ] **Type toggle** — Expense / Income switches accent color (expense red, income green) and filters the category grid
- [ ] **Amount** — large numeric field with currency symbol from active display currency; decimal keyboard accepts values (e.g. `12.50`, comma as decimal separator if locale allows)
- [ ] **Wallet selector** — horizontal chip row with SF Symbol badges; one wallet can be selected; defaults to first default wallet (Cash) on new transactions
- [ ] **Category grid** — 4-column layout with SF Symbol badges; only categories matching the selected type are shown
- [ ] Switching type auto-selects a valid category for that type (does not leave an invalid selection)
- [ ] **Date picker** — compact style; defaults to today on new transactions
- [ ] **Note** — optional free text
- [ ] **Tags** — optional comma-separated text; saved as trimmed individual tags
- [ ] **Save** is disabled (muted) until **amount > 0**, a **wallet** is selected, and a **category** is selected
- [ ] **Save** commits the transaction, triggers haptic feedback, and dismisses the sheet
- [ ] **Save Changes** label appears in edit mode

### Edit mode

- [ ] Open an existing transaction — all fields pre-fill: type, amount, wallet, category, date, note, tags
- [ ] Edits persist after save and appear correctly on Home, All, Stats, and Calendar

### Active trip auto-tagging

- [ ] With an active trip (Plans → Trips → **Start**, or active trip banner on Home): new **expense** transactions are auto-assigned that `tripId`
- [ ] New **income** transactions are **not** trip-tagged
- [ ] Editing an expense while a trip is active sets/overwrites `tripId` to the active trip on save
- [ ] Quick actions executed from Home also auto-tag expenses to the active trip

### New category (known gap)

- [ ] **+ New** cell is visible in the category grid
- [ ] Tapping **+ New** currently does **nothing** (stub — Add Category sheet not wired). Confirm the app does not crash

---

## Home Screen

### Header & navigation

- [ ] Greeting line (“Good morning”) and current **month + year** title display
- [ ] Search icon (magnifying glass) opens the **Search** sheet
- [ ] Settings avatar button (“F” circle) opens **Settings** sheet

### Active trip banner

- [ ] When a trip is active, a teal **Active trip** banner shows the trip name and “Tap to end”
- [ ] Tapping the banner deactivates the trip (`activeTripId` cleared)

### Balance card (hero)

- [ ] Gradient hero card shows **Working balance** = current calendar month income − expenses
- [ ] Month label under the balance matches the current month
- [ ] **Income** and **Expenses** inner cards show correct current-month totals
- [ ] Balance animates when underlying totals change (after adding/removing transactions)
- [ ] Tapping the currency chip cycles through all **14** currencies in order: USD → EUR → GBP → AED → RUB → JPY → CNY → KZT → TRY → INR → CHF → CAD → AUD → THB → (wraps to USD)
- [ ] Selected currency persists after force-quit and relaunch
- [ ] Currency change updates amount formatting app-wide (symbol placement, JPY shows 0 decimal places)

### Accounts (wallets)

- [ ] Horizontal scroll shows pastel **AccountCard** tiles for each wallet
- [ ] Each card shows wallet name and **all-time** balance (income − expense for that wallet, not month-scoped)
- [ ] Balances update immediately after adding/editing/deleting transactions
- [ ] **Edit** button in section header is visible but **not wired** (TODO) — confirm it does not crash

### Budgets

- [ ] With no limits set: empty hint “Tap Manage to set spending limits”
- [ ] **Manage** opens **Budget Manager** sheet
- [ ] After setting limits: 2-column grid of **BudgetCard** tiles for categories with limits > 0
- [ ] Each card shows category label, spent amount, “of {limit}”, and progress bar
- [ ] Spent amount reflects **current calendar month** expenses for that category
- [ ] Progress bar fill ratio matches spent ÷ limit (capped at 100% width)
- [ ] Note: Home budget cards use pastel tint for the bar — **not** the orange/red threshold colors (those appear on the Stats tab)

### Quick Add

- [ ] Section hidden when no quick actions exist
- [ ] After saving a quick action (repeat icon on a transaction row): chip appears with category icon and formatted amount
- [ ] Tapping a chip immediately creates a transaction with today’s date and the saved fields
- [ ] Long-press / context menu → **Remove** deletes the quick action
- [ ] Maximum **6** quick actions — repeat button is disabled (faded) when at cap
- [ ] Quick actions persist after relaunch

### Recent transactions

- [ ] Shows transactions from the last **3 calendar days** (today + previous 2 days)
- [ ] Grouped by day label: **Today**, **Yesterday**, or abbreviated date (e.g. “12 Jun”)
- [ ] Each row: category SF Symbol badge, category name, wallet name subtitle, signed amount (green + / red −)
- [ ] Note text is **not** shown in the row subtitle (wallet name only)
- [ ] Tapping a row opens **Edit Transaction**
- [ ] **Repeat** icon saves the row as a quick action (respects 6 cap)
- [ ] **See all** opens the full **All Transactions** sheet
- [ ] Empty state: wallet icon, “No entries yet”, “Tap + to add your first record”
- [ ] Note: Home recent rows do **not** have swipe-to-delete (delete is available on the All tab)

### Floating + button & safe area

- [ ] Floating **+** button (56pt accent circle) is visible on Home, Stats, Calendar, and All tabs
- [ ] Floating **+** is **hidden** on the Plans tab (add flows live in each Plans section header instead)
- [ ] Bottom content is not obscured by the floating button or custom tab bar (100pt bottom inset)

---

## Stats

### Period selector

- [ ] Segmented control: **Week** / **Month** / **Year**
- [ ] **Week** = rolling last 7 days (not calendar week)
- [ ] **Month** = current calendar month
- [ ] **Year** = current calendar year
- [ ] Switching period updates donut chart, legend, center total, and budget rows

### Spending breakdown

- [ ] With expense data in the period: donut chart (Swift Charts) renders with inner hole showing **Total** and formatted amount
- [ ] Legend lists categories sorted by amount descending: color dot, icon badge, name, **percentage**, amount
- [ ] Legend percentages sum to **100%** (±1% rounding acceptable)
- [ ] With no expenses in the period: empty state with pie icon and “No spending data yet”

### Budgets card

- [ ] **Manage** opens Budget Manager sheet; limits refresh after dismiss
- [ ] Categories with limits show progress bars: spent / limit text
- [ ] Progress bar colors: accent below 80%, **orange** (`warning`) at 80–99%, **expense red** at 100%+
- [ ] Empty hint when no limits are set

### Budget Manager sheet

- [ ] Lists all expense categories alphabetically with icon, label, numeric limit field, and clear (×) button
- [ ] Entering a limit > 0 and tapping **Done** saves to UserDefaults
- [ ] Clearing a field (or ×) and **Done** removes that category’s limit
- [ ] Blank/zero fields do not create limits

---

## Calendar

- [ ] Month header shows full month name + year (serif style)
- [ ] **Chevron left/right** navigates to previous/next month
- [ ] Weekday header: Mon Tue Wed Thu Fri Sat Sun (Monday-first grid)
- [ ] Day cells show day number; days with transactions show a small **accent dot** (amounts are not shown on cells)
- [ ] **Today** has accent-tinted background; selected day has solid accent fill with white text
- [ ] Tapping a day selects it and updates the detail card below
- [ ] Detail card header shows full weekday + date (uppercase)
- [ ] Selected day lists that day’s transactions (newest first) using `TransactionRowView`
- [ ] Empty day: calendar icon and “No transactions on this day”
- [ ] Navigating to another month preserves or resets selection appropriately; dots reflect that month’s data

---

## Plans — Recurring

- [ ] Section card with header, **+** button opens **New Recurring** form
- [ ] Empty state: “No recurring rules yet”
- [ ] Create a **weekly** rule: type, amount, wallet, category, optional note — saves and appears in list
- [ ] Create **monthly** and **yearly** rules — frequency badge displays correctly
- [ ] Row shows category icon, title (note or category label), frequency pill, signed amount
- [ ] **Force-quit and relaunch** — `processRecurringRules` runs on launch; missed intervals since `lastRun` generate transactions with note suffixed **" (auto)"** and `fromRecurringId` set
- [ ] Re-launch does **not** duplicate previously generated auto-transactions
- [ ] Swipe left on a row reveals delete; confirmation dialog; delete removes the rule (existing auto-transactions remain)

---

## Plans — Trips

- [ ] **+** opens **New Trip** form: name (required), optional budget
- [ ] Create trip **without** budget — card shows “Spent {amount}” only
- [ ] Create trip **with** budget — progress bar and “spent / budget” text
- [ ] **Start** activates trip; **Active** badge appears; only one trip active at a time
- [ ] Starting a second trip deactivates the first (both in UI and `UserDefaults activeTripId`)
- [ ] **Stop** deactivates the trip
- [ ] Active trip: new expense transactions auto-tagged (verify on Home / All)
- [ ] Budget progress bar ratio = total trip expenses ÷ budget (expenses only)
- [ ] Trash button → confirmation → deletes trip; if it was active, `activeTripId` is cleared
- [ ] Empty state: “No trips yet”

---

## Plans — Savings Goals

- [ ] **+** opens **New Goal**: name, target amount, icon picker (10 SF Symbol choices)
- [ ] Save disabled until name non-empty and target > 0
- [ ] Goal card shows icon, name, progress bar, saved / target amounts
- [ ] **+** (circle) on card opens **Add Savings** alert with amount field
- [ ] Deposit increases `saved`; multiple deposits accumulate
- [ ] Deposit is **capped at target** (cannot exceed target)
- [ ] Reaching target shows **checkmark.seal.fill** and green progress bar; success haptic fires once on completion
- [ ] Further deposits to an already-complete goal do not re-trigger haptic
- [ ] Swipe left → confirm → delete goal
- [ ] Empty state: “No savings goals yet”

---

## Plans — Subscriptions

- [ ] **+** opens **New Subscription** form
- [ ] Preset chips: Netflix, Spotify, YouTube, iCloud, Apple Music, Gym — tap fills name and icon
- [ ] Manual entry: name, amount, Monthly / Yearly period
- [ ] Save disabled until name and amount > 0
- [ ] Row shows icon, name, period badge, formatted amount
- [ ] **Monthly total** footer = sum of monthly amounts + (yearly amounts ÷ 12); verify with mixed monthly/yearly entries
- [ ] Swipe left → confirm → delete subscription
- [ ] Empty state: “No subscriptions yet” (no monthly total footer)

---

## All Transactions & Search

### All Transactions tab

- [ ] Full history displays, default sort: **date descending** (newest first)
- [ ] Grouped by day labels (Today / Yesterday / date) in date sort modes
- [ ] Toolbar sort toggle cycles: **date ↓** → **date ↑** → **amount ↓** (icons: `arrow.down.circle`, `arrow.up.circle`, `dollarsign.circle`)
- [ ] Amount sort: flat list, largest amounts first (no day grouping)
- [ ] Row layout matches Home: category badge, name, wallet, signed amount, repeat icon
- [ ] Tap row → edit sheet
- [ ] Leading swipe → **Edit** (accent)
- [ ] Trailing swipe → **Delete** → confirmation dialog → removes transaction
- [ ] Repeat icon saves quick action (6 cap; silently drops oldest if over cap in All tab implementation)
- [ ] Toolbar search icon opens **Search** sheet
- [ ] Empty state: “No transactions yet” with hint to tap +

### Search sheet

- [ ] Opened from Home header or All toolbar
- [ ] Search field auto-focuses on appear
- [ ] Blank query: placeholder “Search your transactions” with hint text
- [ ] Search matches: **note**, **category label**, **wallet name**, **amount string** (e.g. `12.50`), and **tags** (case-insensitive substring)
- [ ] Results list updates as you type; tap result → edit sheet
- [ ] No matches: “No results” with query echoed
- [ ] **Done** dismisses sheet

---

## Settings

### Appearance

- [ ] **Dark mode** toggle switches the entire app instantly (background, cards, text, pastels)
- [ ] Toggle state persists after force-quit and relaunch

### Currency

- [ ] **Display currency** row shows current code; opens **Currency Picker** sheet
- [ ] All 14 currencies listed with symbol, code, and full name
- [ ] Selecting a row updates global currency, shows checkmark, and dismisses
- [ ] Currency chosen here matches cycling on Home hero card (same `UserDefaults` value)

### Data export & backup

- [ ] **Export CSV** opens share sheet with `budget-control-transactions.csv`
- [ ] CSV opens in Numbers/Excel: header `id,date,type,amount,currency,category,wallet,note,tags`; rows match transaction count; dates ISO8601; fields properly quoted
- [ ] **Backup JSON** opens share sheet with `budget-control-backup.json`
- [ ] JSON is valid, pretty-printed; contains arrays: transactions, wallets, categories, trips, goals, subscriptions, recurringRules

### Restore

- [ ] **Restore from Backup** opens document picker (`.json` only)
- [ ] Selecting a valid backup shows confirmation: “Replace all data?”
- [ ] **Cancel** aborts with no changes
- [ ] **Replace** wipes all SwiftData records and re-inserts backup contents; success alert shown
- [ ] After restore: transactions, wallets, categories, trips, goals, subscriptions, recurring rules match backup
- [ ] Note: backup/restore does **not** include UserDefaults (budget limits, quick actions, `activeTripId`, currency, dark mode, `hasOnboarded`) — verify expected behavior after restore
- [ ] Invalid JSON file shows error alert (“not a valid Budget Control backup”)

### About

- [ ] **Version** row displays `CFBundleShortVersionString (CFBundleVersion)` — e.g. `1.0 (1)`

---

## Data Integrity

- [ ] **Mid-entry force-quit**: open Add Transaction, enter partial data (do not save), force-quit, relaunch — no phantom/partial transaction created; app launches normally
- [ ] **Persistence**: create wallets’ transactions, trips, goals, subscriptions, recurring rules, budgets, quick actions — force-quit, relaunch — all data intact
- [ ] **Fresh install**: delete app, reinstall — onboarding shows; seed data present; empty transaction history; empty states on all screens
- [ ] Deleting a transaction updates wallet balances, monthly totals, stats, calendar dots, and budget progress immediately
- [ ] Recurring auto-transactions use currency code active at generation time
- [ ] Restore backup then relaunch — data still consistent; recurring processor does not duplicate on second launch

---

## Visual QA

- [ ] **Light mode** audit: background `#F8F9FF`, surface cards white, hero gradient, pastel account/budget tiles, readable text hierarchy
- [ ] **Dark mode** audit on every screen: background, surfaces, hero card, pastels, borders, muted text — no illegible contrast
- [ ] **No emoji** rendered anywhere in the UI (icons are SF Symbols via `IconMap` / `IconBadge`; model `emoji` fields are not displayed)
- [ ] Pastel badge fills and icon colors consistent across Home, Stats, Plans, and transaction rows
- [ ] **Dynamic Type**: Settings → Accessibility → Larger Text — spot-check Home hero, transaction rows, Plans forms, Settings list — no severe clipping or overlap
- [ ] **Safe area** on notched / Dynamic Island device: status bar content clear; tab bar extends into home indicator; floating + and tab bar never cover tappable content
- [ ] Custom tab bar: 5 tabs (Home, Stats, Calendar, Plans, All); active tab shows accent icon, label, and dot indicator
- [ ] All SF Symbols render (no blank/missing glyphs) for default categories, wallets, onboarding, and tab bar
- [ ] Sheets present with drag indicator where configured (Add Transaction from main shell)
- [ ] No hardcoded wrong-theme colors obvious outside `AppTheme`

---

## Performance

- [ ] Seed or create **50+ transactions** — All Transactions tab scrolls smoothly (no stutter or blank rows)
- [ ] Same dataset: Home recent section and Calendar month grid remain responsive
- [ ] **Cold launch** to interactive Home feels reasonable (< 3 seconds on target device)
- [ ] Tab switching (Home ↔ Stats ↔ Calendar ↔ Plans ↔ All) has no visible lag
- [ ] Opening/closing sheets (Add Transaction, Settings, Budget Manager, Plans forms) is snappy
- [ ] Stats donut and budget bar animations do not block interaction
- [ ] Search with large dataset returns results without multi-second freeze

---

## Haptics & Feedback (spot-check)

- [ ] Medium haptic when saving a transaction
- [ ] Light haptic when tapping floating **+**
- [ ] Success haptic when a savings goal first reaches 100%
- [ ] Tab switches do **not** currently trigger haptics (not implemented in `CustomTabBar`)

---

## Known Implementation Gaps (verify status before sign-off)

Track these separately — they are stubs or PRD items not yet built:

- [ ] **Add Category** flow (`+ New` in Add Transaction) — button present, sheet not wired
- [ ] **Wallet management** (Home → Accounts → Edit) — button present, sheet not wired
- [ ] **Budget alert banners** on Home at 80%+ — not implemented (budget grid only)
- [ ] **Month-over-month spending change** on hero card — computed in code but not displayed in UI
- [ ] **Transaction row note** in subtitle — not shown (wallet name only)
- [ ] **Delete from Home recent list** — not available (delete via All tab only)
- [ ] **Backup/restore UserDefaults** — budget limits, quick actions, trip active state, currency, theme not in JSON backup

---

*End of checklist*
