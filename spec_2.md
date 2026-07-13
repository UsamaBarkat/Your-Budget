# Spec 2 — App Restructure + Sections

## Goal

Transform the app from a single-screen hub into a three-section app. A persistent BottomNavigationBar provides access to: **Home** (the current app, unchanged), **Reports** (a spending chart built from existing data), and **Zakat** (an Islamic almsgiving calculator). No existing screen behavior changes. All Spec 1 rules remain in force.

---

## User Scenarios

**Section navigation**
- U1. A user opens the app and sees the Home tab exactly as it was when they last used it — scroll position, any open sub-screen navigation, all preserved by IndexedStack.
- U2. A user taps "Reports" in the bottom bar, views charts, then taps "Home" to return — the Home tab is exactly as they left it.
- U3. A user on the Daily Expenses sub-screen taps Back — returns to the Home tab with the bottom bar visible.
- U4. A user changes the language on the Home tab — all three tabs immediately display the new language.

**Zakat**
- Z1. A user enters their cash, gold value, silver value, and business assets, plus the current silver price per gram. The app displays total assets, the nisab threshold, and either the zakat amount due or a "below nisab" message.
- Z2. A user with assets below the nisab threshold sees a clear localised message that zakat is not obligatory, and Rs. 0 for zakat due.
- Z3. A user reopens the Zakat tab — their previously entered values are pre-filled from the last successful save.

**Reports**
- R1. A user opens Reports and sees a line chart of their daily spending for the current calendar month.
- R2. A user who has not recorded any expenses this month sees a graceful empty-state message instead of a chart.

---

## Functional Requirements

### Part A — Navigation Restructure

**FR-A1** A `SectionShell` widget replaces `HomeScreen` as `MaterialApp.home`. It renders a `BottomNavigationBar` with exactly three tabs — Home (index 0), Reports (index 1), Zakat (index 2) — visible at all times except when a sub-screen is active on the navigator stack.

**FR-A2** The shell uses `IndexedStack` to hold one widget per tab. Switching tabs preserves each tab's full widget state (scroll position, field values, in-memory data). `SectionShell` passes an `isActive` bool to `ReportsScreen` that is `true` when tab index 1 is selected. `ReportsScreen` overrides `didUpdateWidget` and calls `_loadData()` when `isActive` flips from `false` to `true`. This reloads SharedPreferences data without destroying or recreating the widget. `ZakatScreen` does not need this — its inputs are user-entered, not derived from SharedPreferences changes made elsewhere.

**FR-A3** Tab 0 renders `HomeScreen` receiving `language` and `onLanguageChange` exactly as today. All four `Navigator.push` routes from `HomeScreen` (Daily Expenses, Monthly Budget, Savings Goal, Bill Reminders) work unchanged. No Spec 1 behaviour regresses.

**FR-A4** Tab labels are looked up via `t('shell', key, language)` — no inline strings in `SectionShell`. Icons are fixed: `Icons.home` (Home), `Icons.show_chart` (Reports), `Icons.volunteer_activism` (Zakat). A new `'shell'` scope is added to all three language files covering the three tab labels.

**FR-A5** When `onLanguageChange` is called from anywhere inside Tab 0, the callback reaches `_HomeBudgetAppState` unmodified. Because `_HomeBudgetAppState` calls `setState`, the `language` prop passed into `SectionShell` — and therefore into all three tab widgets — updates on the next build.

**FR-A6 (FR-T2 gap close)** `HomeScreen`'s inline `translations` map and `getText()` function are removed. Every call site is replaced with `t('home', key, language)`. All six keys (`app_title`, `daily_expenses`, `monthly_budget`, `savings_goal`, `bill_reminders`, `language`) already exist in the `'home'` scope of the central translation files in all three languages — no new strings are required.

**FR-A7** The four unreachable screens (`income_screen.dart`, `report_screen.dart`, `electricity_screen.dart`, `gas_screen.dart`) are byte-for-byte untouched throughout this spec.

---

### Part B — Zakat Calculator

#### Inputs

**FR-B1** `ZakatScreen` (Tab 2) presents six input fields in two groups:

*Monetary amounts (rupees → paisa):*

| Field key stored in `zakat_data` | Label | Validator | Storage unit |
|---|---|---|---|
| `cash` | Cash on hand and in bank accounts | `validateRupeeInput` (≤2 dp) | int paisa |
| `business` | Business inventory and investments | `validateRupeeInput` (≤2 dp) | int paisa |
| `gold_price_pg` | Gold price per gram (PKR) | `validateRupeeInput` (≤2 dp) | int paisa/gram |
| `silver_price_pg` | Silver price per gram (PKR) | `validateRupeeInput` (≤2 dp) | int paisa/gram |

*Weight amounts (grams → milligrams):*

| Field key stored in `zakat_data` | Label | Validator | Storage unit |
|---|---|---|---|
| `gold_mg` | Gold owned (grams, e.g. 50.125) | `validateGramInput` (≤3 dp) | int milligrams |
| `silver_mg` | Silver owned (grams, e.g. 612.36) | `validateGramInput` (≤3 dp) | int milligrams |

`validateGramInput` and `gramsToMilligrams` are pure functions defined in `lib/core/zakat.dart`. They follow the same pattern as `validateRupeeInput` and `rupeesToPaisa` in `money.dart`: reject empty/non-numeric/more-than-3-decimal-place input; convert `"50.125"` → `50125` (milligrams). Grams are stored as milligrams so that all subsequent arithmetic is integer-only.

**FR-B2** All six values are persisted to SharedPreferences under the key `'zakat_data'` as a single JSON object `Map<String, int>` (units as defined in FR-B1) via a single explicit **Save button** at the bottom of the form. The write uses `PersistenceService` — awaited, failure handled with snackbar+retry — consistent with Spec 1 FR-P1 through FR-P7. The unsaved indicator is shown on the Save button itself (or an adjacent warning icon) when the in-memory values differ from the last-persisted values, rather than per-field, since all six values are written atomically. Design rationale: matches every other screen's explicit-save pattern (no silent loss), keeps persistence behaviour consistent across the app, and avoids excessive writes on every keystroke.

**FR-B3** When `ZakatScreen` is mounted, the last-saved values from `'zakat_data'` are loaded and pre-filled into the input fields (converting storage units back to display strings: milligrams → gram string via `milligramsToGrams`, paisa → rupee string via `paisaToDisplay`). Fields with no saved value are blank.

#### Calculation (pure functions in `lib/core/zakat.dart`)

All functions are pure (no I/O, no Flutter imports). All monetary inputs/outputs are int paisa. Weight inputs are int milligrams.

**FR-B4** `computeMetalValue(int metalMg, int pricePerGramPaisa) → int`  
Returns the PKR value (in paisa) of a metal holding:  
`value = (metalMg × pricePerGramPaisa + 500) / 1000`  
Integer division with round-half-up (adding 500 = half of 1000 before dividing). This is the single rounding point; no intermediate float is used.  
Example: 50125 mg of gold × 1500000 paisa/gram = (50125 × 1500000 + 500) / 1000 = 75187500500 / 1000 = 75187500 paisa = Rs 751875.

**FR-B5** `computeTotalAssets(int cash, int goldValue, int silverValue, int business) → int`  
Returns `cash + goldValue + silverValue + business`. Integer addition only. `goldValue` and `silverValue` are each the result of `computeMetalValue`.

**FR-B6** `computeNisab(int silverPricePerGramPaisa) → int`  
Returns the nisab threshold in paisa using the silver standard (612.36 grams = 612360 mg):  
`nisab = (silverPricePerGramPaisa × 612360 + 500) / 1000`  
The constant 612360 is 612.36 × 1000, expressed as an integer number of milligrams — consistent with the milligram storage unit. Rounding is round-half-up.  
Example: silver at Rs 200/g (20000 paisa): nisab = (20000 × 612360 + 500) / 1000 = 12247200500 / 1000 = 12247200 paisa = Rs 122472.

**FR-B7** `computeZakat(int totalAssets, int nisab) → int`  
- If `totalAssets < nisab`: return 0.  
- If `totalAssets >= nisab`: return `(totalAssets × 25 + 500) / 1000` using integer division.  
  Computes 2.5% (= 25/1000) rounded to the nearest paisa.

#### Display

**FR-B8** The results section shows four values, all formatted via `paisaToDisplay()`:
1. Total assets (= `computeTotalAssets(cash, goldValue, silverValue, business)`)
2. Nisab threshold in PKR (= `computeNisab(silverPricePerGramPaisa)`)
3. Zakat due (Rs. 0 if below nisab, `computeZakat(total, nisab)` if at or above)
4. A localised status message: "Zakat is obligatory" if `totalAssets >= nisab`; "Below nisab — zakat not obligatory" otherwise.

**FR-B9** Results are computed and displayed automatically whenever any input field changes (live calculation). Persistence is separate: a dedicated **Save button** writes all six values to SharedPreferences (FR-B2). If the user edits values and switches tabs without saving, the live calculation remains correct in memory for the session; only an explicit Save persists the values to disk.

#### Translations

**FR-B10** `ZakatScreen` uses `t('zakat', key, language)` exclusively. A new `'zakat'` scope is added to `strings_en.dart`, `strings_ur.dart`, and `strings_sd.dart`.

---

### Part C — Reports

**FR-C1** `ReportsScreen` (Tab 1) is a fresh implementation. It does not import or reference `lib/screens/report_screen.dart`. All amounts are read as int paisa and displayed via `paisaToDisplay()`.

**FR-C2** A line chart (fl_chart `LineChart`) shows daily total spending for the **current calendar month** (from day 1 through the current day-of-month inclusive). The x-axis represents day-of-month (integer, 1-based). The y-axis represents spending in rupees. Each data point's y-value is computed as `dayTotalPaisa / 100.0` (double division for fl_chart only — all aggregation is done in int paisa first). Days with no expenses have y = 0 and are plotted as flat points.

**FR-C3** Data sourcing: read `'daily_expenses'` from SharedPreferences, parse each entry via `DailyExpense.fromJson`, filter to `date.year == now.year && date.month == now.month`, group by `date.day`, and sum paisa totals per day. This bucketing logic lives in a pure function in `lib/core/report_utils.dart` so it is independently testable. `_loadData()` is called both in `initState` and in `didUpdateWidget` when `isActive` flips to true (per FR-A2).

**FR-C4** The x-axis displays day numbers. The y-axis displays integer rupee values (no decimals). Both axes must be legible without overlapping labels; fewer labels are shown when the month has many days.

**FR-C5** If no daily expenses exist for the current month, the chart area is replaced by a localised empty-state message and a relevant icon. No crash, no empty axes, no zero-height chart.

**FR-C6** Below the chart, a summary row shows: total spent this month (via `paisaToDisplay`) and the count of individual expense entries. Both figures are derived from the same filtered data as the chart.

**FR-C7** A savings progress section below the summary shows: goal (via `paisaToDisplay`), saved so far (via `paisaToDisplay`), and a `LinearProgressIndicator` with `value = (savedPaisa / goalPaisa).clamp(0.0, 1.0)` (double division for the indicator only). This section is hidden entirely when `goalPaisa == 0`.

**FR-C8** Savings data is read from SharedPreferences using `int.tryParse(prefs.getString(key) ?? '') ?? 0` — the string-int format written by Spec 1's `PersistenceService`. `prefs.getDouble()` is never called.

**FR-C9** `ReportsScreen` uses `t('reports', key, language)` exclusively. A new `'reports'` scope is added to all three language files.

---

## Edge Cases

**EC-1** Zakat: all inputs zero → total assets = 0 < nisab → "below nisab" shown; zakat = 0. No division by zero.

**EC-2** Zakat: `silverPricePerGram = 0` → nisab = 0 by `computeNisab`. Any positive total assets ≥ 0, so zakat is due if total assets > 0. If total assets = 0 too, zakat = 0 (formula: `0 × 25 / 1000 = 0`). Must not crash.

**EC-3** Zakat: total assets exactly equal to nisab → `computeZakat` uses `>=`, so zakat **is** due.

**EC-9** Zakat: gram field with 3 decimal places (e.g. "50.125" → 50125 mg) — `validateGramInput` accepts it; `gramsToMilligrams` converts exactly.

**EC-10** Zakat: gram field with 4+ decimal places (e.g. "50.1234") — `validateGramInput` rejects it with the same inline error pattern as `validateRupeeInput`.

**EC-4** Reports: expenses exist only from prior months → current-month filter returns empty list → empty state shown per FR-C5.

**EC-5** Reports: today is the 1st of the month → chart has a single x-point at day 1. No crash from a single-point line chart.

**EC-6** Reports: `daily_expenses` contains entries from the same month-number but a different year → year filter (`date.year == now.year`) excludes them correctly.

**EC-7** Reports: `savings_goal` was written by the old app with `prefs.setDouble()` → `prefs.getString('savings_goal')` returns null → `int.tryParse('') ?? 0` → goal = 0 → savings section hidden. No crash.

**EC-8** Language switch while on Reports or Zakat tab → all visible strings, messages, and labels re-render in the new language on the next frame.

---

## Out of Scope

- The 4 unreachable screens (`income`, `electricity`, `gas`, `report`) — untouched
- Redesign or functional changes to any existing Home sub-screen
- Additional sections (Travel, Committee, etc.)
- Gold-standard nisab (only silver nisab is defined here)
- Historical reports spanning multiple months
- Release APK signing
- Zakat on livestock, crops, or other non-cash asset classes
- Push notifications
- Liabilities / debt deduction from zakat base (a common extension — explicitly out of scope here)

---

## Tests Required

### Zakat core (`lib/core/zakat.dart`) — FR-TS-Z

| Test | Assertion |
|---|---|
| TS-Z1 | `computeNisab(20000)` = `(20000 × 612360 + 500) / 1000` = 12 247 200 |
| TS-Z2 | `computeNisab(0)` = 0 |
| TS-Z3 | `computeZakat(0, 0)` = 0 |
| TS-Z4 | `computeZakat(49999, 50000)` = 0 (below nisab) |
| TS-Z5 | `computeZakat(50000, 50000)` > 0 (at nisab, zakat is due) |
| TS-Z6 | `computeZakat(100000, 50000)` = `(100000 × 25 + 500) / 1000` = 2500 |
| TS-Z7 | `computeZakat(100020, 50000)` = `(100020 × 25 + 500) / 1000` = 2501 (round-half-up) |
| TS-Z8 | `computeTotalAssets(1000, 2000, 3000, 4000)` = 10 000 |
| TS-Z9 | `computeMetalValue(50125, 1500000)` = `(50125 × 1500000 + 500) / 1000` = 75 187 500 |
| TS-Z10 | `computeMetalValue(0, 1500000)` = 0 |
| TS-Z11 | `gramsToMilligrams("50.125")` = 50125 |
| TS-Z12 | `gramsToMilligrams("50")` = 50000 |
| TS-Z13 | `validateGramInput("")` ≠ null (rejects empty) |
| TS-Z14 | `validateGramInput("50.1234")` ≠ null (rejects >3 dp) |
| TS-Z15 | `validateGramInput("50.125")` = null (accepts 3 dp) |

### Reports bucketing (`lib/core/report_utils.dart`) — FR-TS-R

| Test | Assertion |
|---|---|
| TS-R1 | Empty input list → returns empty map, no crash |
| TS-R2 | Entries from other months/years are excluded from the current-month bucket |
| TS-R3 | Multiple entries on the same day are summed (not overwritten) |
| TS-R4 | Single entry → map with one key; value equals the entry's amount |

---

## Translation Strings

All new strings for the three new scopes. These are the exact values to be placed into `strings_en.dart`, `strings_ur.dart`, and `strings_sd.dart`.

### `'shell'` scope

| key | en | ur | sd |
|---|---|---|---|
| `home` | Home | ہوم | گھر |
| `reports` | Reports | رپورٹس | رپورٽون |
| `zakat` | Zakat | زکوٰۃ | زڪوات |

### `'zakat'` scope

| key | en | ur | sd |
|---|---|---|---|
| `title` | Zakat Calculator | زکوٰۃ کیلکولیٹر | زڪوات ڪيلڪوليٽر |
| `cash` | Cash | نقد | نقد |
| `gold_grams` | Gold (grams) | سونا (گرام) | سون (گرام) |
| `silver_grams` | Silver (grams) | چاندی (گرام) | چاندي (گرام) |
| `business` | Business Assets | کاروباری اثاثے | ڪاروباري اثاثا |
| `gold_price_per_gram` | Gold Price / gram | سونے کی قیمت / گرام | سون جي قيمت / گرام |
| `silver_price_per_gram` | Silver Price / gram | چاندی کی قیمت / گرام | چاندي جي قيمت / گرام |
| `save` | Save | محفوظ کریں | محفوظ ڪريو |
| `total_assets` | Total Assets | کل اثاثے | ڪل اثاثا |
| `nisab` | Nisab Threshold | نصاب | نصاب |
| `zakat_due` | Zakat Due | واجب زکوٰۃ | واجب زڪوات |
| `obligatory` | Zakat is obligatory | زکوٰۃ واجب ہے | زڪوات واجب آهي |
| `below_nisab` | Below nisab — not obligatory | نصاب سے کم — واجب نہیں | نصاب کان گهٽ — واجب ناهي |
| `save_failed` | Save failed | محفوظ نہیں ہوا | محفوظ نه ٿيو |
| `retry` | Retry | دوبارہ کوشش | ٻيهر ڪوشش |
| `rupees` | Rs. | Rs. | Rs. |
| `grams` | g | g | g |

### `'reports'` scope

| key | en | ur | sd |
|---|---|---|---|
| `title` | Reports | رپورٹس | رپورٽون |
| `no_expenses` | No expenses recorded this month | اس مہینے کوئی اخراجات نہیں | هن مهيني ڪو خرچ ناهي |
| `total_spent` | Total Spent | کل خرچ | ڪل خرچ |
| `entries` | entries | اندراجات | داخلائون |
| `this_month` | This Month | اس مہینہ | هن مهيني |
| `savings_goal` | Savings Goal | بچت کا ہدف | بچت جو مقصد |
| `saved` | Saved | بچایا | بچايو |
| `of` | of | میں سے | مان |
| `save_failed` | Save failed | محفوظ نہیں ہوا | محفوظ نه ٿيو |

---

## Acceptance Criteria

**Navigation**
- AC-A1: Bottom bar is visible on all three root tabs; hidden when a sub-screen is pushed.
- AC-A2: Switching tabs and back preserves each tab's state (IndexedStack).
- AC-A3: Language change on the Home tab updates labels on all three tabs.
- AC-A4: `HomeScreen` contains no inline `translations` map and no `getText()` function.
- AC-A5: All 76 Spec 1 tests pass without modification after the restructure.

**Zakat**
- AC-B1: Entering 50g gold at Rs 15000/g with zero other assets → gold value = Rs 750000 shown; if above nisab, zakat is computed.
- AC-B2: Entering gold and silver below the silver nisab → Rs. 0 and "below nisab" message.
- AC-B3: Assets exactly equal to nisab → zakat shown as due.
- AC-B4: Reopening Zakat tab shows last-saved input values pre-filled.
- AC-B5: `computeZakat(100000, 50000)` = 2500 paisa ("25.00").
- AC-B6: `computeZakat(100020, 50000)` = 2501 paisa ("25.01").
- AC-B7: `computeMetalValue(612360, 20000)` = `(612360 × 20000 + 500) / 1000` = 12 247 200 paisa (exactly 612.36g at Rs 200/g = Rs 122472).
- AC-B8: All TS-Z tests pass.

**Reports**
- AC-C1: Line chart renders with one point per day-of-month that has expenses (y = 0 for days with none).
- AC-C2: No expenses this month → empty-state message shown, no crash.
- AC-C3: Savings section hidden when goal = 0; shown with correct progress when goal > 0.
- AC-C4: All TS-R tests pass.
