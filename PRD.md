# Product Requirements Document
## Budget Control — iOS App (MVP)

**Version:** 1.0  
**Date:** May 18, 2026  
**Client:** Natalia Zhyvopystseva  
**Developer:** Daniel Sanchez  
**Contract:** Upwork Fixed-Price, $5,000 USD  

---

## 1. Product Overview

Budget Control is a personal finance management iOS app targeting users — particularly women — who want a simple, beautiful, and private way to track their money. The product originated as a React/JSX web prototype built in Claude Code and is being rebuilt natively in SwiftUI for the Apple App Store.

The core philosophy: **local-first, privacy-first, no accounts, no servers, no ads.** All data lives on the user's device.

### 1.1 Problem Statement

Many people, especially those without a financial background, struggle to track where their money goes. Existing finance apps are either too complex, require bank account linking, or feel cold and corporate. There is a gap in the market for a friendly, approachable, and private finance tracker that makes managing money feel manageable rather than intimidating.

### 1.2 Target User

- Primary: Women ages 20–40 who are not naturally finance-savvy but want to become more aware of their spending
- Secondary: Anyone who values privacy and prefers not to connect bank accounts to third-party apps
- Use case: Daily expense logging, monthly budget tracking, savings goal setting, travel expense tracking

### 1.3 Business Goals (MVP)

- Launch a polished, free iOS app on the U.S. App Store under the client's Apple Developer account
- Validate product-market fit with real users before investing in monetization or Android
- Build a foundation for future features: in-app purchases, bank integration, Android version, worldwide release

---

## 2. Scope

### 2.1 In Scope (This Contract)

- Full SwiftUI iOS app faithfully porting all features from the React prototype
- iOS-specific polish: haptics, safe area handling, native animations, Swift Charts
- App Store submission and approval (U.S. only)
- Two coaching video calls with the client
- Source code delivery and basic documentation

### 2.2 Out of Scope (Future Phases)

| Feature | Notes |
|---|---|
| Android / Google Play | Separate engagement post-iOS validation |
| Bank / card integration | Requires Plaid API, backend, financial compliance |
| In-app purchases / paywall | V2 once product-market fit is confirmed |
| Live currency exchange rates | Static display only in MVP |
| Cloud sync / backend | All data local in MVP |
| Marketing / ASO / social | Client-managed independently |
| International App Store release | U.S. only for MVP |
| Ongoing maintenance retainer | Available at $75/hr post-launch |

---

## 3. Tech Stack

| Layer | Decision | Rationale |
|---|---|---|
| Language | Swift | Native performance, Apple ecosystem |
| UI Framework | SwiftUI | Modern declarative UI, faster App Store approval, easier for solo developer to maintain |
| Persistence | SwiftData | iOS 17+ native, no third-party dependencies |
| Charts | Swift Charts | Native, no third-party libraries needed |
| Icons | SF Symbols | Native, no dependencies |
| Min iOS Version | iOS 17 | Required for SwiftData |
| Distribution | Apple App Store (U.S.) | MVP target market |
| Build/Submit | Xcode + App Store Connect | Standard native workflow |

**Why SwiftUI over React Native:** Single codebase for iOS only, smaller binary, no bridge overhead, direct access to all iOS APIs, simpler App Store submission, and lower cost for this scope. React Native would be reconsidered if Android is added in a future phase.

---

## 4. Feature Requirements

### 4.1 Onboarding

- 4-screen pager shown on first launch only
- Screens: Welcome → Multiple Wallets → Travel Friendly → Privacy First
- Each screen: large emoji, serif title, body description
- "Continue" button advances; "Skip" available from screen 2 onward
- "Get Started" on final screen sets `hasOnboarded = true` in UserDefaults and dismisses

### 4.2 Home Screen (Dashboard)

**Header**
- Month + year title (serif font)
- Search icon → opens Search sheet
- Settings icon → opens Settings sheet
- Active trip banner: teal strip showing trip name, tap to deactivate

**Balance Card**
- "This Month" label + tappable currency selector button
- Large serif net balance (income − expenses), colored positive/negative
- Month-over-month spending change (% vs prior month) with directional arrow
- Income total and Expense total side by side

**Wallets Row**
- Horizontal scroll of wallet cards: emoji, name, all-time balance
- Tap any wallet card to open edit/delete sheet
- "+ Add" button creates a new custom wallet

**Quick Actions Strip**
- Horizontal scroll of up to 6 saved shortcuts
- Each chip: category emoji, label, amount
- Tap executes the transaction immediately with today's date
- × button removes a quick action
- Any transaction can be saved as a Quick Action from the transaction list (max 6)

**Budget Alert Banners**
- Inline banners for any expense category at 80%+ of its monthly budget
- Orange at 80–99%, red at 100%+
- Show category emoji, name, percentage used, spent vs limit

**Recent Transactions**
- Last 3 days of transactions grouped by date label (Today / Yesterday / date)
- Each row: category emoji in colored circle, category name, wallet + note subtitle, amount
- Tap to edit, trash icon to delete, repeat icon to save as Quick Action

### 4.3 Add / Edit Transaction Sheet

- Type toggle: Expense / Income (changes category list and color theme)
- Amount input: large serif numeric field with currency symbol, numeric keyboard
- Wallet selector: horizontal chip row (default: Cash)
- Category grid: 4-column emoji+label grid, "+ New" opens Add Category sheet
- Date picker (compact style, defaults to today)
- Note field (optional)
- Tags field (optional, comma-separated)
- If a trip is active and type is Expense, transaction is auto-tagged to that trip
- Save button disabled until amount > 0
- Edit mode pre-fills all fields from the existing transaction

### 4.4 Categories

**Defaults — Expense:** Food 🍕, Transport 🚌, Home 🏠, Fun 🎬, Health 💊, Shopping 🛍️, Travel ✈️, Other 📌  
**Defaults — Income:** Salary 💼, Freelance 💻, Gift 🎁, Investment 📈, Other ✨

- Default categories cannot be deleted
- Custom categories: name, emoji (picker from ~40 choices), color (picker from 14 swatches)
- Custom categories can be edited or deleted
- Categories are typed (expense or income) and filtered accordingly in the add transaction sheet

### 4.5 Wallets

**Defaults:** Cash 💵, Card 💳, Savings 🐷  
- Default wallets cannot be deleted
- Custom wallets: name, emoji, color
- Per-wallet balance = all-time sum of (income − expense) transactions for that walletId
- Total balance shown in the Wallets section header = sum across all wallets

### 4.6 Stats Tab

**Period Selector:** Week (last 7 days) / Month (current month) / Year (current year)

**Spending Breakdown Card**
- Pie chart (Swift Charts SectorMark) with donut hole showing total spent amount
- Legend list below: color swatch, emoji, category name, percentage, amount
- Sorted by amount descending

**Budgets Card**
- "Manage" button opens Budget Manager sheet
- Progress bar per category: spent vs limit, color shifts red at 100%
- Budget Manager: list of expense categories, each with a numeric limit input field
- Limits persisted to UserDefaults as `[categoryId: Double]`

### 4.7 Calendar Tab

- Month navigation: chevron left/right, "Month Year" serif header
- Weekday header: Mon Tue Wed Thu Fri Sat Sun
- Grid of day cells: day number + small amount if transactions exist
- Today highlighted with accent border
- Tap a day: expands detail card below grid showing that day's transactions
- Navigate between months freely

### 4.8 Plans Tab

**Recurring Transactions**
- Create rules: type (income/expense), amount, frequency (weekly/monthly/yearly), wallet, category, note
- On app launch: auto-generate missed transactions since last run, update lastRun date
- View and delete active rules
- Each rule shows: emoji, name/note, frequency, amount colored by type

**Trips**
- Create a trip: name + optional total budget
- Activate a trip: only one active at a time, stored in UserDefaults
- Active trip auto-tags new expense transactions
- Trip card: name, total spent, budget progress bar (if budget set), Start/Stop button, delete button

**Savings Goals**
- Create a goal: name, target amount, emoji (10 choices)
- Tap "+" on a goal to manually add an amount (text field alert)
- Progress bar: saved vs target
- Swipe to delete

**Subscriptions**
- Add subscriptions: name, amount, billing period (Monthly / Yearly)
- Quick-select presets: Netflix 🎬, Spotify 🎵, YouTube ▶️, iCloud ☁️, Apple Music 🎧, Gym 🏋️
- Monthly total footer = sum of (monthly amounts + yearly amounts ÷ 12)
- Swipe to delete

### 4.9 All Transactions Tab

- Complete transaction history, sorted by date descending
- Grouped by date label: Today / Yesterday / "12 Jun"
- Same row style as Home recent transactions
- Leading swipe: edit (blue)
- Trailing swipe: delete with confirmation (red)
- Repeat icon on each row to save as Quick Action (if under 6 limit)

### 4.10 Search

- Sheet presented from search icon in Home header
- Search bar auto-focused on open
- Searches across: note, category label, wallet name, amount string, tags
- Results in same transaction row style
- Empty state when query is blank

### 4.11 Settings

- **Appearance:** Light/Dark mode toggle (persisted to UserDefaults)
- **Currency:** Display currency picker — 14 currencies (USD, EUR, GBP, AED, RUB, JPY, CNY, KZT, TRY, INR, CHF, CAD, AUD, THB), static display only, no live exchange rates
- **Export CSV:** All transactions as CSV file, share sheet
- **Backup (JSON):** Full app data export (transactions, wallets, categories, budgets, goals, subscriptions, recurring rules), share sheet
- **Restore from Backup:** DocumentPicker for .json, decode and re-insert all records (with confirmation prompt)
- **About:** App version

### 4.12 Multi-Currency

- 14 supported currencies with symbol, code, and display position (before/after amount)
- Currency is a global display setting — no per-transaction conversion
- All amounts stored as plain doubles; currency is cosmetic only in MVP

---

## 5. Design & UX Requirements

### 5.1 Visual Direction

Inspired by Rocket Money — clean card-based layouts, clear typographic hierarchy, approachable and modern. Not a dark finance app; designed to feel friendly and accessible, especially to users who aren't natural finance people.

**Light Mode (Primary)**
- Background: `#FAFAF8` (soft off-white)
- Surface (cards): `#FFFFFF`
- Accent: muted rose `#A8796A`
- Income: sage green `#5A8C6A`
- Expense: muted red `#B86A5A`
- Text primary: `#1A1410`
- Text muted: `#8A7A6E`
- Border: `#EAE4DC`

**Dark Mode (User Toggle)**
- Available via Settings toggle
- Color language mirrors light mode, adapted for dark backgrounds
- Deep brown background with warm accent tones

### 5.2 Typography

- **Serif (New York or Georgia fallback):** Balance figures, large headings, card titles
- **SF Pro (system sans-serif):** All body text, labels, navigation, buttons

### 5.3 Layout

- Card-based: rounded corners 12–20pt radius throughout
- Bottom tab navigation: 5 tabs (Home, Stats, Calendar, Plans, All)
- Floating + button: 56pt circle, accent gradient, above tab bar
- Proper Safe Area handling for notched devices and Dynamic Island iPhones
- Smooth native iOS sheet presentations (drag indicator, half/full sheet)

### 5.4 Motion & Feedback

- Haptic feedback: medium impact on save, success notification on goal completion, light impact on tab switch
- Progress bars animate on appear (.easeOut 0.4s)
- Balance card amount changes animate with spring
- Transaction rows slide in from bottom on insertion

### 5.5 Empty States

- Each empty list/section shows a relevant SF symbol, a short title, and a hint
- Example: "No entries yet — Tap + to add your first record"

---

## 6. Data Architecture

### 6.1 Persistence

- **SwiftData** for all transactional data (transactions, wallets, categories, trips, goals, subscriptions, recurring rules)
- **UserDefaults** for lightweight settings (currency, theme, activeTripId, hasOnboarded, budget limits, quick actions)
- No network calls, no backend, no user accounts

### 6.2 Data Models

| Model | Key Fields |
|---|---|
| Transaction | id, type, amount, currencyCode, categoryId, walletId, note, tags, tripId, date, fromRecurringId |
| Wallet | id, name, emoji, colorHex, isDefault |
| AppCategory | id, label, emoji, colorHex, type, isDefault |
| Trip | id, name, budget, isActive |
| SavingsGoal | id, name, target, saved, emoji |
| Subscription | id, name, amount, period, emoji |
| RecurringRule | id, type, amount, categoryId, walletId, note, frequency, startDate, lastRun |

### 6.3 Seed Data

Inserted on first launch if database is empty:
- 3 default wallets: Cash, Card, Savings
- 8 default expense categories
- 5 default income categories

---

## 7. App Store Requirements

### 7.1 Metadata

- **Category:** Finance
- **Age Rating:** 4+
- **Distribution:** U.S. App Store (MVP), worldwide considered post-launch
- **Price:** Free (no in-app purchases in V1)
- **Privacy Policy:** Required — static page hosted by client (template provided by developer)

### 7.2 Assets Required

- App icon: 1024×1024px PNG
- Screenshots for: 6.7" (iPhone 16 Pro Max), 6.5" (iPhone 14 Plus), 5.5" (iPhone 8 Plus)
- App Store description, subtitle (30 chars), keywords (100 chars)

### 7.3 Account Requirements

- Apple Developer account enrolled under **client's name and Apple ID** ($99/year, paid by client)
- Individual account acceptable for MVP; business account recommended if hiring additional developers later
- Developer (Daniel) added as team member temporarily for build upload
- Client must be available for 2FA prompts during submission

---

## 8. Milestones & Delivery

### Milestone 1 — $2,500 USD (~3 weeks from contract start)

- All features from Section 4 built and functional in SwiftUI
- Light and dark mode UI complete
- App deployed to TestFlight under client's Apple Developer account
- Client reviews, tests, and approves the build

### Milestone 2 — $2,500 USD (~1–2 weeks after M1 approval)

- Bug fixes and refinements from TestFlight feedback
- App Store listing assets and copy prepared
- App submitted to Apple Review
- App live on the U.S. App Store
- App Store submission walk-through video call with client
- Full source code and documentation delivered

**Total timeline:** 4–5 weeks from contract start and Milestone 1 funding.

---

## 9. Client Responsibilities

| Responsibility | Timing |
|---|---|
| Provide app name | Before development begins |
| Fund Milestone 1 ($2,500) on Upwork | Before any work starts |
| Enroll Apple Developer account ($99/year) | Before Milestone 2 begins |
| Host privacy policy at a public URL | Before App Store submission |
| Download and test app via TestFlight | During Milestone 1 review |
| Be available for 2FA prompts during submission | During Milestone 2 |
| Provide timely feedback (delays affect timeline) | Throughout project |

---

## 10. Success Criteria

The MVP is considered complete and successfully delivered when:

1. The app is live and downloadable from the U.S. App Store
2. All features listed in Section 4 are functional on a real iPhone running iOS 17+
3. The app passes Apple's review without outstanding violations
4. The client has received the full source code and can open the project in Xcode
5. The client has completed the App Store submission walk-through call and understands how to submit future updates

---

## 11. Future Roadmap (Post-MVP)

These are not committed features — they represent the natural next phases if the MVP validates the concept:

- **V1.1:** In-app purchases / subscription paywall (monthly/yearly)
- **V1.2:** Home screen widget (balance + quick add)
- **V1.3:** Local push notifications (budget alerts, recurring reminders)
- **V1.4:** Face ID / Touch ID lock
- **V2.0:** Android version (React Native or separate Swift/Kotlin)
- **V2.1:** Bank account / card integration (Plaid API)
- **V2.2:** Live currency exchange rates
- **V2.3:** iCloud sync / cloud backup
- **V3.0:** Worldwide App Store release
