# Research: Spec 2 — App Restructure + Sections

## 1. NAVIGATION — Current Routing and Section-Hub Options

### Current routing chain
```
main.dart
  HomeBudgetApp (StatefulWidget)
    MaterialApp(home: HomeScreen)
      HomeScreen
        Navigator.push → DailyExpensesScreen
        Navigator.push → ExpensesScreen
        Navigator.push → SavingsScreen
        Navigator.push → RemindersScreen
```

`_HomeBudgetAppState` holds `String _language` and a `changeLanguage()` callback. It passes both to `HomeScreen` by constructor. `LanguageService` (from Spec 1) is also held here and passed into `HomeBudgetApp`.

Four screens have no entry point anywhere: `income_screen`, `report_screen`, `electricity_screen`, `gas_screen`. They exist as files but are unreachable.

### Navigation options assessed

**Option A — BottomNavigationBar (recommended)**
A new `SectionShell` widget replaces `HomeScreen` as `MaterialApp.home`. It owns a `BottomNavigationBar` with tabs: Home | Reports | Zakat. An `IndexedStack` holds one widget per tab so state is preserved across tab switches. The existing `HomeScreen` becomes the body of Tab 0 — completely unchanged internally. `Navigator.push` calls from HomeScreen push routes on top of the MaterialApp navigator, covering the bottom bar during sub-screen visits, then the back button restores it. This is exactly how standard Flutter bottom-nav apps work and requires zero changes inside the existing screens.

**Option B — Drawer**
A sidebar drawer with section links. More appropriate for 5+ sections. For 3 sections it adds friction (swipe gesture or hamburger tap required). No significant advantage over bottom nav here.

**Option C — Hub Grid Screen**
Replace the current home with a grid of section tiles. Would add one extra tap before reaching any of the existing 4 screens (Home tile → HomeScreen → DailyExpenses). Breaks the existing user muscle memory with no benefit.

**Verdict: Option A.** Three sections fit perfectly in a bottom nav. Code impact is minimal: one new `SectionShell` file, a one-line change to `main.dart`.

---

## 2. HOME GROUPING — What Moves

The current `MaterialApp.home: HomeScreen(...)` becomes `MaterialApp.home: SectionShell(...)`.

`SectionShell` receives: `language`, `onLanguageChange`, and `langService` (same props currently on `HomeBudgetApp`).

`HomeScreen` is passed into `IndexedStack` at index 0, receiving `language` and `onLanguageChange` exactly as it does today. Nothing inside `HomeScreen` changes structurally — the four big buttons and language switcher remain as-is.

Files to create: `lib/screens/section_shell.dart`  
Files to change: `lib/main.dart` (two lines: import + home property)  
Files unchanged: `home_screen.dart`, `daily_expenses_screen.dart`, `expenses_screen.dart`, `savings_screen.dart`, `reminders_screen.dart`

The `SectionShell` also needs to receive the ReportsScreen and ZakatScreen and pass `language` to both, since those screens will need translations.

---

## 3. HOMESCREEN TRANSLATION GAP

`home_screen.dart` lines 8–37 contain an inline `translations` map and `getText()` helper — the FR-T2 gap carried over from Spec 1.

**What's already in the central file:** `lib/l10n/strings_en/ur/sd.dart` each already have a `'home'` scope with all 6 keys that HomeScreen uses:
```
app_title, daily_expenses, monthly_budget, savings_goal, bill_reminders, language
```
All three languages are already translated. No new strings needed.

**The fix is mechanical:**
1. Delete lines 8–37 of `home_screen.dart` (the inline `translations` map and `getText` function)
2. Add `import '../l10n/translations.dart';`
3. Replace every `getText(key, language)` call with `t('home', key, language)` — there are 6 call sites

This is a clean, zero-risk change to make during the restructure since HomeScreen is already being touched to wire it into `SectionShell`.

---

## 4. REPORTS DATA — Available Data and fl_chart Requirements

### Data sources available in SharedPreferences

| Key | Format (after Spec 1) | Contents |
|---|---|---|
| `daily_expenses` | JSON array of `DailyExpense` | {id, category, amount (int paisa), date (ISO)} |
| `expenses` | JSON object | {grocery, school, bills, transport, other} → int paisa values |
| `bill_reminders` | JSON array of `BillReminder` | {id, billType, dueDate, amount? (int paisa), isPaid} |
| `savings_goal` | String (int paisa) | Single int, written by PersistenceService |
| `savings_saved` | String (int paisa) | Single int, written by PersistenceService |
| `income_sources` | JSON array of `IncomeSource` | {id, type, amount (int paisa)} — old data may be double |

### Charts that this data can support

**Pie chart — monthly spending breakdown** (most useful, already in existing dead ReportScreen):
- Combine `expenses` (5 budget categories) + sum of current-month `daily_expenses`
- Each slice = one category, value = paisa total
- fl_chart: `PieChart(PieChartData(sections: List<PieChartSectionData>))`
  - Each `PieChartSectionData(value: double, color: Color, title: String)`
  - Values are passed as double to fl_chart — convert from paisa: `paisa / 100.0`

**Bar chart — daily spending over last N days:**
- Group `daily_expenses` by date (strip time), sum paisa per day
- fl_chart: `BarChart(BarChartData(barGroups: List<BarChartGroupData>))`
  - Each `BarChartGroupData(x: dayIndex, barRods: [BarChartRodData(toY: amount)])`
  - x = days ago (0 = today, 6 = 6 days ago) or day-of-month
  - A 7-day or 30-day view is practical

**Progress indicator — savings goal:**
- `savings_goal` and `savings_saved` from SharedPreferences as `int.tryParse(getString())`
- `LinearProgressIndicator` or `PieChart` with 2 sections (saved vs remaining)
- SavingsScreen already shows a `CircularProgressIndicator` — Reports can show the same data differently

**Bill reminders summary:**
- Count of paid vs unpaid this month
- Simple counts — no chart required, a stat card is sufficient

### Existing dead ReportScreen analysis
`lib/screens/report_screen.dart` (375 lines, unreachable) already has:
- `PieChart` from fl_chart for expense breakdown
- `LinearProgressIndicator` for per-category bars
- Reads `expenses` and `daily_expenses` from SharedPreferences

**Critical flaw:** it reads `(value as num).toDouble()` for amounts. After Spec 1, amounts are int paisa — so it would display Rs 50 as "50" when it should be "0.50" (or actually 5000 paisa = Rs 50 displayed via `paisaToDisplay`). The existing ReportScreen code is usable as a starting skeleton but needs the full money migration (same treatment as the 4 screens in Spec 1). It also still uses inline translations.

The new ReportsScreen should be written fresh (using the dead screen as a reference for fl_chart structure) rather than modified in-place.

---

## 5. ZAKAT — Structural Assessment

### What a zakat calculation needs

Zakat = 2.5% of net zakatable assets, only if the total exceeds the nisab threshold.

**Standard inputs:**
- Cash on hand / in bank
- Gold value
- Silver value
- Business inventory / stock value
- Receivables (money owed to you)
- Debts owed by you (deducted)
- Nisab reference value (threshold — typically 87.48g of silver, priced in PKR)

In a minimal app implementation the user enters each asset category in rupees, the app sums them, deducts liabilities, checks against the nisab, and shows the 2.5% result. The nisab value can be a user-entered field (since gold/silver prices change) or a hardcoded advisory value.

### Where it fits structurally

**Screen:** `lib/screens/zakat_screen.dart` — a new StatefulWidget (Tab 2 in SectionShell).

**Data persistence:** Two options:
1. *Ephemeral calculator* — no storage, form resets on exit. Simplest. Good if the user just wants a quick calculation.
2. *Persisted inputs* — store the last-entered values in SharedPreferences under key `zakat_data` as `Map<String, int>` JSON (paisa). The user fills it once and it's ready on next open.

Option 2 is more useful for a household budget app (assets don't change week to week). Recommended. Uses `PersistenceService` for writes per Spec 1 rules.

**Model:** A `Map<String, int>` is sufficient — no new model class needed. The keys are the asset/liability categories. Same pattern as `ExpensesScreen`.

**Translations:** New `'zakat'` scope to add to `strings_en/ur/sd.dart`.

**No external data required:** Zakat is a pure calculation — no API needed. The nisab field is user-input.

---

## 6. RISKS

### Risk 1 — ReportScreen reads Spec 1 data in the wrong format (HIGH)
The existing dead `ReportScreen` reads `daily_expenses` amounts as `(value as num).toDouble()` and `expenses` as double. After Spec 1, all amounts are stored as int paisa. A new ReportsScreen must use `(value as num).toInt()` and `paisaToDisplay()`. If this is missed, all monetary displays will be 100x wrong (50000 paisa shown as 50000 instead of 500.00).

Additionally, `savings_goal` and `savings_saved` were migrated to string storage (PersistenceService uses `setString`). The old report screen uses `prefs.getDouble(...)` which will return null — treated as 0. Must use `int.tryParse(prefs.getString(...) ?? '')`.

### Risk 2 — IndexedStack vs per-build switching (MEDIUM)
If `SectionShell` builds the active tab widget inline (e.g., `body: currentIndex == 0 ? HomeScreen(...) : ...`), the HomeScreen widget is destroyed and rebuilt on every tab switch — losing scroll position, form state, and any in-progress dialogs. Must use `IndexedStack` to preserve widget subtrees across tab switches.

### Risk 3 — Language change from HomeScreen must propagate to all tabs (MEDIUM)
`HomeScreen` has a language switcher. After Spec 1, `onLanguageChange` flows up to `_HomeBudgetAppState` which calls `setState`. With `SectionShell` in between, the language change must still reach `_HomeBudgetAppState.changeLanguage()`. If `SectionShell` intercepts but doesn't forward the callback correctly, ReportsScreen and ZakatScreen will be stuck in the original language even after the user switches.

The fix: `SectionShell` receives `onLanguageChange` from `_HomeBudgetAppState` and passes it through to `HomeScreen` without modification. Since `_HomeBudgetAppState` calls `setState`, the `language` prop it passes to `SectionShell` will update, and because `SectionShell` uses `IndexedStack`, all tab contents will rebuild with the new language.

### Risk 4 — Navigator.push from HomeScreen and bottom nav visibility (LOW)
When `HomeScreen` calls `Navigator.push(context, MaterialPageRoute(...))`, the route is pushed on the app's root navigator. The new screen covers the entire screen including the `BottomNavigationBar`. This is correct and expected behavior. The risk is if any sub-screen tries to pop and the navigator state is unexpected — but since none of the existing screens use `WillPopScope` or custom pop behavior, this is low risk.

### Risk 5 — 300-line limit (LOW)
`SectionShell` needs to hold 3 tab bodies and a `BottomNavigationBar`. Estimated ~80–100 lines. `ZakatScreen` with asset inputs, calculation, and display could approach 250 lines — manageable. `ReportsScreen` with two charts and a stats section is the most at risk; may need `_buildPieChart()` / `_buildDailyBar()` helpers to stay under 300.

### Risk 6 — SectionShell line file count vs CLAUDE.md structure rule (LOW)
CLAUDE.md requires "UI, business logic, and persistence must live in separate files for any new or rewritten code." `SectionShell` is pure UI (tab switcher). `ZakatScreen` calculation logic should live in `lib/core/zakat.dart` (pure functions, testable), not inline in the screen. Same pattern as `lib/core/money.dart` and `lib/core/date_utils.dart`.

---

## Recommendation: BottomNavigationBar in a SectionShell

**Architecture:**
```
MaterialApp(home: SectionShell)
  SectionShell (BottomNavigationBar + IndexedStack)
    Tab 0: HomeScreen (unchanged except FR-T2 gap fix)
    Tab 1: ReportsScreen (new, rewritten from dead screen skeleton)
    Tab 2: ZakatScreen (new)
```

**Reasoning:**
- 3 tabs is the sweet spot for bottom nav (2–5 is ideal; fewer needs no nav)
- Zero changes to the 4 existing sub-screens — Spec 1 behavior is preserved exactly
- `IndexedStack` keeps tab state alive across switches
- Language state already flows through `_HomeBudgetAppState` — adding `SectionShell` as a pass-through is one additional constructor argument per tab
- The FR-T2 HomeScreen gap is a natural fit for this spec since HomeScreen is being touched anyway
- Zakat calculation logic belongs in `lib/core/zakat.dart` (mirrors money.dart pattern), keeping ZakatScreen thin
- ReportsScreen reads all data fresh on mount; no cross-screen data sharing needed since SharedPreferences is the source of truth

**Files to create:** `section_shell.dart`, `reports_screen.dart`, `zakat_screen.dart`, `lib/core/zakat.dart`  
**Files to modify:** `main.dart` (2 lines), `home_screen.dart` (FR-T2 gap), `strings_en/ur/sd.dart` (new zakat + report scopes)  
**Files untouched:** All 4 existing sub-screens, all 4 dead screens
