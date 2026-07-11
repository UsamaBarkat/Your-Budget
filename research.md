# Your-Budget — Research Phase Report
> Phase 1 of Spec-Driven Development. Read-only analysis. No code was modified.
> Date: 2026-07-05

---

## Table of Contents
1. [Tech Stack & Build](#1-tech-stack--build)
2. [Architecture & Structure](#2-architecture--structure)
3. [Data Layer](#3-data-layer)
4. [Features & Conventions](#4-features--conventions)
5. [Top 5 Risks Before Upgrading](#5-top-5-risks-before-upgrading)

---

## 1. Tech Stack & Build

### SDK Versions

| Constraint | Value |
|---|---|
| Dart SDK (pubspec.yaml) | `^3.10.8` (requires >=3.10.8 <4.0.0) |
| Flutter (pubspec.lock resolved) | `>=3.35.0` |
| App version | `1.0.0+1` |

**Critical note:** Dart 3.10.8 does not exist on the stable Flutter channel as of mid-2025 (stable is ~3.7.x). This project requires Flutter master/dev channel. `flutter pub get` will fail on any standard stable Flutter installation.

### Dependencies

| Package | Version | Purpose |
|---|---|---|
| `shared_preferences` | `2.5.4` | All data persistence — the entire storage layer |
| `intl` | `0.19.0` | Date formatting in DailyExpensesScreen only |
| `fl_chart` | `0.69.2` | Pie chart in ReportScreen (which is currently unreachable) |
| `cupertino_icons` | `1.0.8` | iOS-style icons |
| `flutter_lints` (dev) | `6.0.0` | Static analysis |
| `flutter_launcher_icons` (dev) | `0.14.4` | Build-time launcher icon generation |

**The dependency footprint is minimal.** No database, no HTTP client, no state management library, no notification package, no routing package.

### Android Build Configuration

| Setting | Value |
|---|---|
| Application ID | `com.homebudget.home_budget_app` |
| Android Gradle Plugin | `8.11.1` |
| Kotlin | `2.2.20` |
| Gradle Wrapper | `8.14` |
| Java compatibility | `VERSION_17` |
| compileSdk / minSdk / targetSdk | Delegated to Flutter SDK (no hardcoded values) |
| Signing config | Reads from `key.properties` — **file not in repo** (expected) |

No permissions are declared in `AndroidManifest.xml`. Appropriate for a fully offline app.

### Build Risks

| Severity | Issue |
|---|---|
| **CRITICAL** | Dart SDK constraint `^3.10.8` exceeds current stable release. Must use Flutter master/dev channel or fix the constraint. |
| **HIGH** | `key.properties` not in repo — release builds will fail without it on any new machine. |
| **MEDIUM** | AGP 8.11.1 + Kotlin 2.2.20 + Gradle 8.14 is a bleeding-edge toolchain. Requires Flutter >=3.35.0 to be compatible. Any lower Flutter version will fail. |

---

## 2. Architecture & Structure

### Directory Tree

```
lib/
├── main.dart                          # App root; MaterialApp + language string state
└── screens/
    ├── home_screen.dart               # Main menu: 4 nav buttons + language toggle
    ├── daily_expenses_screen.dart     # Log timestamped daily cash expenses by category
    ├── expenses_screen.dart           # Set monthly budget amounts per category (replace, not accumulate)
    ├── savings_screen.dart            # Single savings goal with circular progress display
    ├── reminders_screen.dart          # Bill due-date reminders with status badges
    ├── income_screen.dart             # Income sources + balance card — UNREACHABLE FROM UI
    ├── report_screen.dart             # Pie chart spending summary — UNREACHABLE FROM UI
    ├── electricity_screen.dart        # HESCO slab-rate bill calculator — UNREACHABLE FROM UI
    └── gas_screen.dart               # SSGC slab-rate bill calculator — UNREACHABLE FROM UI
```

No `models/`, `services/`, `widgets/`, or `utils/` directories exist. Everything is flat inside `screens/`.

### Entry Point (`main.dart`)

- No async initialization, no splash screen.
- Calls `runApp(const HomeBudgetApp())` directly.
- `HomeBudgetApp` is a `StatefulWidget` that holds `String _language` (the only app-wide state).
- Theme: Material 3, seed color `Colors.green`.
- **No named routes, no go_router.** All navigation is imperative `Navigator.push`.

### Navigation Flow

```
HomeBudgetApp (StatefulWidget)
  └── HomeScreen (StatelessWidget) — root
        ├── Navigator.push → DailyExpensesScreen
        ├── Navigator.push → ExpensesScreen
        ├── Navigator.push → SavingsScreen
        └── Navigator.push → RemindersScreen

Dead (no entry point):
  IncomeScreen, ReportScreen, ElectricityScreen, GasScreen
```

4 of 9 screens are fully implemented but never navigated to. From a user's perspective they do not exist.

### State Management

**Verdict: Pure `setState` only. No library.**

- Every screen is a `StatefulWidget` with local `State`.
- All state changes go through `setState(() { ... })`.
- No `Provider`, `Riverpod`, `Bloc`, `GetX`, or `InheritedWidget` anywhere.
- Language propagates via constructor drilling: `main.dart` → `HomeScreen` → each child screen via constructor parameter.

**Business logic lives entirely inside widget `State` classes.** There is no service layer, no repository pattern, no ViewModel. Every screen directly calls `SharedPreferences.getInstance()`, parses JSON, mutates local state, and rebuilds.

### File Size (Lines of Code)

| File | Lines | Primary bloat source |
|---|---|---|
| `reminders_screen.dart` | 498 | Translation map + dialog logic |
| `daily_expenses_screen.dart` | 459 | Translation map + model class inline |
| `income_screen.dart` | 416 | Translation map + duplicate SP load logic |
| `savings_screen.dart` | 401 | Translation map |
| `report_screen.dart` | 374 | Translation map + chart code |
| `gas_screen.dart` | 306 | Translation map |
| `expenses_screen.dart` | 290 | Translation map |
| `electricity_screen.dart` | 288 | Translation map |
| `home_screen.dart` | 238 | Translation map |

**Every single screen exceeds 250 lines.** The translation maps (inline in each file) account for roughly 30–40% of each file's line count.

### Duplicated Logic (Critical)

1. **Translation system** — 9 independent `Map<String, Map<String, String>>` translation tables, one per file, with a paired `getXText(key, lang)` function. Structurally identical, just different data. Should be a single `AppLocalizations` class.

2. **SharedPreferences load/save boilerplate** — The pattern `SharedPreferences.getInstance()` → `prefs.getString(key)` → `json.decode()` → `setState()` is copy-pasted verbatim into every screen.

3. **Expense totals re-computed independently in 3 screens** — `IncomeScreen`, `ReportScreen`, and `ExpensesScreen` each load and sum the same `expenses` and `daily_expenses` SP keys independently. No shared data source. If the key name changes in one place, the others silently break.

4. **`AlertDialog` with number input** — The same dialog structure (TextField + Cancel + Save buttons) is copy-pasted across 5 screens with minor label variations.

5. **`_buildStatCard` helper** — Defined independently in `IncomeScreen` and `SavingsScreen` with near-identical signatures and layouts.

6. **Electricity / Gas screens are structural clones** — Differ only in color accent and slab arithmetic. Share state variable names (`_bill`, `_rate`, `_calculated`, `_unitsController`), method names (`_calculate`, `_clear`), and widget tree structure.

### Code Health Summary

- No separation of concerns at any level.
- Model classes (`DailyExpense`, `BillReminder`, `IncomeSource`) are defined inline in their owner screen files — not importable without importing the screen.
- SharedPreferences keys are bare string literals scattered across files, not constants.
- `withOpacity` (deprecated) used in one file; `withAlpha` used in all others.
- The one test (`widget_test.dart`) is the unmodified Flutter default scaffold test and tests nothing meaningful.

---

## 3. Data Layer

### Persistence Technology

**All data stored in `SharedPreferences` as serialized JSON strings or primitive doubles.**

No SQL (no sqflite), no embedded database (no Hive, Isar, Drift, ObjectBox). This is a flat key-value store with no relational capability, no transactions, and no schema enforcement.

### Complete SharedPreferences Key Inventory

| Key | Type in SP | Owner Screen | Purpose |
|---|---|---|---|
| `daily_expenses` | `String` (JSON array) | DailyExpensesScreen | All individual timestamped expense entries |
| `expenses` | `String` (JSON map) | ExpensesScreen | Monthly budget category amounts |
| `bill_reminders` | `String` (JSON array) | RemindersScreen | Bill due-date reminders |
| `income_sources` | `String` (JSON array) | IncomeScreen | Income entries by type |
| `savings_goal` | `double` | SavingsScreen | The savings target |
| `savings_saved` | `double` | SavingsScreen | Amount saved so far |

**Language preference is NOT persisted.** It resets to English (`'en'`) on every app restart.

### Data Models

#### `DailyExpense`
Defined in `lib/screens/daily_expenses_screen.dart`.

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | `DateTime.now().millisecondsSinceEpoch.toString()` |
| `category` | `String` | One of: chai_snacks, transport, food, shopping, mobile, other |
| `amount` | `double` | **Float — precision risk** |
| `date` | `DateTime` | ISO 8601 string in storage |

#### `BillReminder`
Defined in `lib/screens/reminders_screen.dart`.

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | millisecondsSinceEpoch |
| `billType` | `String` | electricity, gas, water, internet, mobile, school, rent, other |
| `dueDate` | `DateTime` | ISO 8601 string in storage |
| `amount` | `double?` | **Nullable** — amount is optional |
| `isPaid` | `bool` | Mutable field (not `final`) — breaks immutability convention |

#### `IncomeSource`
Defined in `lib/screens/income_screen.dart`.

| Field | Type | Notes |
|---|---|---|
| `id` | `String` | millisecondsSinceEpoch |
| `type` | `String` | salary, business, rent_income, other |
| `amount` | `double` | **Float — precision risk** |

#### Monthly Expenses (no class)
Not a model class — a raw `Map<String, double>` with 5 hardcoded keys:
`grocery`, `school`, `bills`, `transport`, `other`.

#### Savings (no class)
Two standalone `double` values in SP: `savings_goal` and `savings_saved`.

### Data Flow: Adding a Daily Expense (Full Trace)

1. User taps a category button → `_buildCategoryButton()` calls `_showAddDialog(category)`.
2. `AlertDialog` with a `TextField` is shown.
3. User types a number, taps "Save".
4. `double.tryParse(controller.text) ?? 0` — invalid input becomes `0`.
5. Guard `if (amount > 0)` — zero not saved.
6. `DailyExpense` object created with `id = millisecondsSinceEpoch`, current timestamp.
7. `setState(() { _expenses.add(expense); })` — in-memory list updated, UI rebuilds immediately.
8. `_saveExpenses()` called **without await** (fire-and-forget).
9. Inside `_saveExpenses()`: `SharedPreferences.getInstance()` → encode entire list to JSON → `prefs.setString('daily_expenses', encoded)`.
10. UI already reflects the change from step 7. No callback on save completion.

### Data Risks

| # | Risk | Severity |
|---|---|---|
| 1 | All monetary amounts stored as `double` (IEEE 754 float). Accumulated arithmetic can produce `Rs. 99.99999999999`. `toStringAsFixed(0)` masks but doesn't fix this. | **HIGH** |
| 2 | No migration strategy. Adding a required field to any model will crash on deserialization of old data on the next app update. | **HIGH** |
| 3 | Full list rewritten on every mutation — no atomicity. App kill mid-write can corrupt data. Also a performance issue as lists grow. | **HIGH** |
| 4 | Language preference never written to SharedPreferences — resets to English on every restart. | **HIGH** (UX) |
| 5 | `_saveExpenses()` and all save methods are called without `await`. Write failures are silently swallowed. UI shows update; data may not be durably persisted. | **MEDIUM** |
| 6 | IDs generated from `millisecondsSinceEpoch` — collision possible if two items created in same millisecond. `_deleteExpense` uses `removeWhere(id == x)` and would delete both. | **MEDIUM** |
| 7 | `ExpensesScreen` uses replace semantics (`expenses[category] = amount`), not accumulate. Entering a new value overwrites the old total. Undocumented, likely confusing to users. | **MEDIUM** |
| 8 | `IncomeScreen` loads expense totals once in `initState` — stale if expenses change while screen is mounted. | **MEDIUM** |
| 9 | HESCO electricity slab rates hardcoded (7.74, 10.06, 14.11, 17.60, 22.95, 26.00 PKR/kWh + Rs.150 fixed + Rs.3.5 fuel adj). SSGC gas rates hardcoded (121, 212, 400, 738, 1107, 1476 PKR/HM³ + 17% GST). These change periodically — no update mechanism. | **MEDIUM** |
| 10 | No input validation against negative amounts in `ExpensesScreen` and `SavingsScreen`. A user can enter `-5000` and corrupt totals. | **MEDIUM** |
| 11 | Weekly total has an off-by-one boundary bug — includes Sunday of the prior week due to `isAfter` being exclusive on the computed `weekStart`. | **LOW** |
| 12 | `BillReminder.isPaid` is mutable — mutated directly with `reminder.isPaid = !reminder.isPaid`. Not safe in reactive contexts. | **LOW** |
| 13 | Derived values (`_balance`, `_remaining`) independently recomputed per screen from raw SP data — divergence risk if load logic ever differs. | **LOW** |

---

## 4. Features & Conventions

### Feature Inventory

| # | Feature | Status | Notes |
|---|---|---|---|
| 1 | Daily Expenses | **COMPLETE** | Full CRUD, category buttons, today/week/month totals, delete per entry |
| 2 | Monthly Budget | **COMPLETE** | 5 fixed categories, set amounts (replace semantics), clear all |
| 3 | Savings Goal | **COMPLETE** | Set goal, add savings, circular progress, reset |
| 4 | Bill Reminders | **COMPLETE** | 8 bill types, due-date status badges, paid toggle, delete |
| 5 | Language Selector | **COMPLETE** | EN / Urdu / Sindhi toggle on home screen |
| 6 | Income & Balance | **PARTIAL** | Fully implemented screen; **never reachable from UI** |
| 7 | Monthly Report (Pie Chart) | **PARTIAL** | Fully implemented screen with fl_chart; **never reachable from UI** |
| 8 | Electricity Calculator | **PARTIAL** | Full HESCO slab calculator; **never reachable from UI** |
| 9 | Gas Calculator | **PARTIAL** | Full SSGC slab calculator; **never reachable from UI** |

### Absent Features

Authentication, date-range filtering, transaction history browsing, CSV/PDF export, OS push/local notifications (reminders are visual-only), dark mode, custom categories, multi-currency, budget limit alerts, search/filter.

### Naming Conventions

| Element | Convention | Consistency |
|---|---|---|
| File names | `snake_case_screen.dart` | Consistent — every file |
| Screen class names | `PascalCaseScreen` | Consistent |
| State class names | `_PascalCaseScreenState` (private) | Consistent |
| Model class names | `PascalCase` (no suffix) | Consistent |
| Instance variables | `_camelCase` (private), `camelCase` (local) | Consistent |
| Build helper methods | `_buildDescriptiveName()` | Consistent |
| Translation maps | `<prefix>Translations` | Minor break: home screen uses `translations` (no prefix) |
| SP key strings | `snake_case` bare string literals | Consistent but uncentralized — no constants file |

### Structural Conventions

- `StatelessWidget` used only for `HomeScreen` (no local state). Everything else is `StatefulWidget`.
- `AppBar` convention: `centerTitle: true` + `backgroundColor: Theme.of(context).colorScheme.primaryContainer` — 100% consistent across all 9 screens.
- All dialogs: `showDialog` + `AlertDialog` + Cancel/Save `actions` pair.
- Dialogs needing internal state use `StatefulBuilder` inside the builder (seen in `RemindersScreen`).
- Data passed to screens via constructor parameters only — no `InheritedWidget`, no global state.
- All `Navigator.push` calls use `MaterialPageRoute` with inline `builder` closures.

### Convention Inconsistencies

1. `expenses_screen.dart` uses `.withOpacity(0.2)` (deprecated in Flutter 3.x); all other screens use `.withAlpha(n)`.
2. Home screen translation map is named `translations`; all others are `<prefix>Translations`.
3. Home screen getter is named `getText`; all others are `get<Prefix>Text`. Name collision risk if files merged.
4. Model classes live inside screen files, not a `models/` directory.
5. `BillReminder.isPaid` is mutable; all other model fields are `final`.
6. `daily_expenses_screen.dart` imports `intl` for `DateFormat`; no other screen does. All other date display is done ad hoc with string interpolation.

### Tests

One file: `test/widget_test.dart`. Contains the unmodified Flutter default scaffold test:

```dart
testWidgets('App loads correctly', (WidgetTester tester) async {
  await tester.pumpWidget(const HomeBudgetApp());
  expect(find.text('Home Budget'), findsOneWidget);
});
```

**Zero meaningful tests exist.** No unit tests for model serialization, calculation logic, date filtering, bill calculations, or savings math. No integration tests.

---

## 5. Top 5 Risks Before Upgrading

### Risk 1 — SDK Constraint Mismatch Will Block Every Developer
**Severity: CRITICAL**

`pubspec.yaml` declares `sdk: ^3.10.8`. Dart 3.10.8 does not exist on the Flutter stable channel as of mid-2025. Anyone cloning this repo and running `flutter pub get` on stable Flutter will get an immediate failure. The project requires Flutter master/dev channel. Before any upgrade work begins, the Dart SDK constraint must be corrected to match the actual stable Flutter version being used (likely the constraint should be `^3.5.0` or whatever the target stable channel provides). Until this is fixed, the repo is not buildable by anyone without knowing to switch channels.

**Fix before upgrading:** Pin to the specific stable Flutter version you actually use, and update `pubspec.yaml` accordingly.

---

### Risk 2 — All Monetary Values Use Floating-Point (`double`)
**Severity: HIGH**

Every amount stored in this app — daily expenses, monthly budgets, income, savings — is a Dart `double` (IEEE 754 64-bit float). This is universally recognized as wrong for financial applications. Repeated addition of float amounts produces values like `Rs. 99.99999999999`. The display code uses `toStringAsFixed(0)` which masks the error visually but does not fix it in storage — over time, accumulated rounding errors will silently corrupt totals.

**Fix before upgrading:** Decide on a representation (integer paisa/cents is canonical) and migrate all stored values. If you add any new feature that does math on these values first, you'll bake the error in deeper.

---

### Risk 3 — No Schema Migration Strategy Means Every App Update Is a Data Bomb
**Severity: HIGH**

All data lives as raw JSON strings in SharedPreferences, parsed with hand-written `fromJson()` methods that assume exact field presence. There is no version number, no migration runner, no fallback. The moment any upgrade changes a model — renames a field, adds a required field, changes a type — every existing user's app will crash on the first screen load after update. `fromJson` will throw `Null check operator used on a null value` on old stored data, and there is no recovery path.

**Fix before upgrading:** Implement a versioned migration system before any model changes. At minimum: store a `schema_version` integer in SharedPreferences and run field-level migrations on app start when the version is stale.

---

### Risk 4 — Four Complete Screens Are Dead Code (Never Reachable by the User)
**Severity: HIGH**

`IncomeScreen`, `ReportScreen`, `ElectricityScreen`, and `GasScreen` are fully built (416 + 374 + 288 + 306 lines respectively) but are never imported or navigated to from anywhere in the app. The user cannot reach them. This means:

- The most analytically useful features (income/balance view, spending pie chart) are invisible.
- `fl_chart` is a package dependency pulled in solely for `ReportScreen` — dead weight if that screen stays unreachable.
- Any upgrade plan must decide: wire these screens in, or delete them. Upgrading dead code is wasted effort; leaving them creates ongoing confusion about what the app actually does.

**Fix before upgrading:** Decide the intended scope. If these screens should be accessible, add navigation buttons to `HomeScreen`. If they are abandoned, delete them and remove `fl_chart` from dependencies.

---

### Risk 5 — Zero Test Coverage on Business-Critical Logic
**Severity: HIGH**

The only test is the unmodified Flutter scaffold test. There are no tests for:

- Model serialization/deserialization (the most fragile part of the system)
- Bill calculator math (slab rate arithmetic is non-trivial and currently has hardcoded rates)
- Savings/balance computations
- Date boundary logic (the weekly total has a known off-by-one bug)
- SharedPreferences load/save round-trips

Any upgrade — adding features, migrating models, changing storage — is made completely blind. There is no safety net to tell you if a refactor broke something. The weekly total off-by-one bug (inflates weekly expense total by including the previous Sunday) exists today and is undetected because there are no tests.

**Fix before upgrading:** Write tests for at minimum: model `toJson`/`fromJson` round-trips, slab calculator arithmetic, and savings math. This is the prerequisite that makes all other upgrade work safe.

---

*End of research phase. No code was modified during this analysis.*
