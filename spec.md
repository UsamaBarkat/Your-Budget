# Spec 1 — Foundation Hardening

**Phase:** Specify  
**Status:** DRAFT — Clarify in progress  
**Scope:** Correctness fixes and structural cleanup only. Zero new features. Zero visible UI changes except the weekly total bug fix.

---

## Goal

Make the app's data handling correct and its code maintainable before any feature work begins. A user who uses the app after this spec is applied should notice no difference except that:

- Their language choice survives closing and reopening the app.
- The "this week" total on the Daily Expenses screen is accurate.

All other behavior is identical to today.

---

## User Scenarios

**S1 — Language persists across restarts**  
A user switches the app to Urdu. They close the app completely and reopen it. The app opens in Urdu without requiring them to switch again.

**S2 — Money totals are precise**  
A user adds several expenses over multiple sessions. The Today, This Week, and This Month totals always display as exact rupee amounts. No rounding artifacts (e.g., "Rs. 99" never displays as "Rs. 98" or "Rs. 100" due to float arithmetic).

**S3 — Weekly total is correct**  
A user opens the Daily Expenses screen on a Wednesday. The "This Week" total shows only expenses entered on Monday, Tuesday, and Wednesday of the current calendar week. Expenses from the previous Sunday are not included.

**S4 — Save failure is surfaced**  
A user adds an expense and the device storage write fails. The app notifies the user that the save did not succeed. The in-memory state is not presented as durably saved when it is not.

**S5 — Translation behavior is unchanged**  
A user switches between English, Urdu, and Sindhi. Every screen shows the same strings as before. No string is missing or falls back unexpectedly.

---

## Functional Requirements

### FR-MONEY

**FR-M1** — All monetary values stored in SharedPreferences are integers representing paisa (1 Rs. = 100 paisa). No floating-point type is used for money storage or arithmetic.

**FR-M2** — User input is accepted in rupees with 0, 1, or 2 decimal places. The conversion to paisa is exact: multiply the entered value by 100 and store as an integer (e.g. 500.50 → 50,050 paisa; 99.99 → 9,999 paisa; 500 → 50,000 paisa).

**FR-M3** — Input with more than 2 decimal places (e.g. "99.999") is rejected at the input field before any save is attempted. A validation message is shown inline. The message text must be present in all three languages in the central translations file.

**FR-M4** — The conversion from stored paisa to displayed rupees happens at the UI layer only. If the paisa amount is an exact multiple of 100, display as whole rupees with no decimal (9,999,900 paisa → Rs. 99,999). If it has a remainder, display with exactly two decimal places (50,050 paisa → Rs. 500.50). The displayed value must always equal the exact stored value — no rounding, no truncation.

**FR-M5** — Arithmetic on monetary values (summing totals, computing balance, computing remaining savings) is performed entirely in paisa as integers.

### FR-PERSISTENCE

**FR-P1** — Every write to SharedPreferences is awaited. No write is fire-and-forget.

**FR-P2** — If a write fails, a snackbar appears with a "Retry" action button. The snackbar text must be translatable (present in all three languages in the central translations file).

**FR-P3** — Tapping "Retry" re-attempts the write. If the retry also fails, the snackbar appears again with the "Retry" button, allowing the user to keep retrying indefinitely. The entry remains in memory across all retry attempts.

**FR-P4** — After any failed write (initial or retry), the app remains fully usable. The in-memory state reflects the user's last action.

**FR-P5** — Failed writes are visually marked as unsaved until successfully persisted. The indicator varies by element type:
- **List items** (daily expense entry, bill reminder, income source): a small warning icon on the list item itself.
- **Monthly budget category rows**: a warning icon on the edited category row only. The other four rows are not marked — their values were already persisted from earlier successful writes and are not at risk.
- **Savings stat cards**: a warning badge (corner icon) on the affected stat card (goal card if the goal write failed; saved-amount card if the saved-amount write failed).
- **Language preference**: no persistent visual indicator. The retry snackbar alone is sufficient; worst case is the language resets on restart, which is annoying but not data loss.

**FR-P6** — When the user navigates away and the snackbar dismisses, previously-failed items remain marked as unsaved. The next time any write is triggered on any screen, the app first attempts to flush all pending unsaved items before writing the new item. If the flush succeeds, unsaved markers are removed. If it fails, the snackbar appears again.

**FR-P7** — Unsaved markers and the pending flush queue are in-memory only. They do not survive an app restart. If the user closes the app with unsaved items, those items are lost silently (the snackbar gave sufficient warning during the session).

### FR-BUG

**FR-B1** — "This week" means Monday 00:00:00 of the current calendar week through the current moment (inclusive). No expenses from prior weeks are included in this total, regardless of which day of the week the screen is viewed.

**FR-B2** — On Monday, "This week" and "Today" totals are equal (both cover only the current day).

### FR-LANGUAGE

**FR-L1** — When the user changes the language, the selection is written to persistent storage immediately.

**FR-L2** — On app startup, the language is read from persistent storage. If no stored value exists (first launch), the app detects the device locale: `ur` maps to Urdu, `sd` maps to Sindhi, any other locale maps to English. Once the user explicitly picks a language, the stored preference always wins over locale detection on all subsequent launches — locale detection runs only on first launch.

**FR-L3** — The language toggle on the home screen reflects the stored language on every launch.

### FR-TRANSLATIONS

**FR-T1** — A single central translations file contains all user-facing strings for all three languages (English, Urdu, Sindhi).

**FR-T2** — No accessible screen file defines its own translation map. All five accessible screens (`home_screen.dart`, `daily_expenses_screen.dart`, `expenses_screen.dart`, `savings_screen.dart`, `reminders_screen.dart`) read strings from the central translations file. The four unreachable screens (`income_screen.dart`, `report_screen.dart`, `electricity_screen.dart`, `gas_screen.dart`) are exempt from this requirement in this spec; their inline translation maps are removed when each screen is wired in under a future spec.

**FR-T3** — No string present in the current app is missing from the central translations file. No string falls back to English when Urdu or Sindhi is selected unless it already does so today.

**FR-T4** — The "save failed" notification string (from FR-P2) is added to the central translations file as part of this spec.

### FR-TESTS

**FR-TS1** — Tests exist for money conversion covering:
- Whole rupees: 500 → 50,000 paisa
- One decimal place: 500.5 → 50,050 paisa
- Two decimal places: 99.99 → 9,999 paisa; 500.50 → 50,050 paisa
- Zero: 0 → 0 paisa
- Large amount: 1,000,000 → 100,000,000 paisa
- Rejection: "99.999" (3 decimal places) is invalid; "99.9999" is invalid
- Display (whole rupees — no decimal): 50,000 paisa → "500"; 100,000 paisa → "1000"
- Display (with paise — two decimals): 9,999 paisa → "99.99"; 50,050 paisa → "500.50"; 1 paisa → "0.01"

**FR-TS2** — Tests exist for the weekly total boundary: an expense on the prior Sunday is excluded; an expense on Monday of the current week is included; an expense at 23:59 Saturday is excluded from the following week.

**FR-TS3** — Tests exist for save/load round-trips for each data model: a `DailyExpense`, a `BillReminder`, a `IncomeSource`, and the monthly expenses map each serialize to JSON and deserialize back to an equal value.

**FR-TS4** — Tests exist for the language persistence: stored language is read on startup; missing stored value with device locale `ur` defaults to Urdu, `sd` defaults to Sindhi, any other locale defaults to English; a stored preference always overrides locale detection.

**FR-TS5** — Tests exist for the persistence failure state machine, operating directly on the queue/flush logic (not on snackbar or widget visuals):
- A write failure adds the item to the pending queue and marks it unsaved.
- A subsequent write attempt flushes the pending queue before writing the new item.
- A successful flush removes items from the queue and clears their unsaved markers.
- If the flush itself fails, items remain in the queue and unsaved markers remain set.
- Flushing multiple queued items in sequence (e.g. two prior failures) clears all of them on success.

---

## Edge Cases

**EC-1** — User enters a rupee amount with 1 or 2 decimal places (e.g. "500.50", "99.9"): accepted and converted exactly to paisa (50,050 and 9,900 paisa respectively). Input with more than 2 decimal places (e.g. "99.999"): rejected at the field with a translatable validation message; no save attempted.

**EC-2** — User enters "0" or submits an empty field. Existing guard (`amount > 0`) is preserved unchanged.

**EC-3** — A write fails on the very first save (e.g., storage is full on first launch). The app must not crash.

**EC-4** — The user changes language and the language write fails. FR-P2 applies: the user is notified. The in-memory language is still applied for the current session.

**EC-5** — App is opened exactly at Monday 00:00:00 (week boundary). Expenses from the prior Sunday remain excluded.

**EC-6** — Very large amounts: a savings goal of Rs. 10,000,000 (1,000,000,000 paisa). Must not overflow a 64-bit integer (Dart `int` is 64-bit; 10^9 is well within range).

---

## Out of Scope

- `income_screen.dart`, `report_screen.dart`, `electricity_screen.dart`, `gas_screen.dart` — untouched, no changes of any kind.
- New features of any description.
- Visual redesign, color changes, layout changes.
- State management library adoption.
- Navigation changes.
- Migration code for existing on-device data (no existing user data to preserve per project decision).
- Any change to the HESCO/SSGC hardcoded rate slabs.

---

## Acceptance Criteria

**Money**
- [ ] All monetary values in SharedPreferences are stored as integers. No `double` type appears in money storage, serialization, or arithmetic code.
- [ ] Entering "500.50" stores exactly 50,050 paisa and displays as Rs. 500.50.
- [ ] Entering "99.99" stores exactly 9,999 paisa and displays as Rs. 99.99.
- [ ] Entering "500" stores 50,000 paisa and displays as Rs. 500 (no decimal shown).
- [ ] Entering "99.999" is rejected at the input field with a validation message; no data is saved.
- [ ] 100 entries of "99.99" sum to 999,900 paisa and display as Rs. 9,999 (exact whole rupee — no decimal shown).

**Language**
- [ ] Selecting Urdu, force-closing the app, and reopening shows Urdu without any user action.
- [ ] On a fresh install with device locale `ur`, the app opens in Urdu. With `sd`, Sindhi. With any other locale, English.
- [ ] A stored language preference always overrides device locale on subsequent launches.

**Weekly total**
- [ ] The "This Week" total on Daily Expenses excludes any expense logged on the Sunday before the current Monday.
- [ ] On a Monday, "This Week" and "Today" totals are equal.

**Persistence failure**
- [ ] Adding an expense when SharedPreferences is unavailable shows a snackbar with a "Retry" button in the currently selected language.
- [ ] The affected list item, category row, or stat card shows a visible unsaved indicator after a write failure.
- [ ] Tapping "Retry" re-attempts the write; if it fails again the snackbar reappears with "Retry".
- [ ] The next write on any screen first flushes all pending-failed items; on success their unsaved indicators clear.
- [ ] An unsaved indicator does not survive an app restart.

**Translations**
- [ ] No accessible screen file defines a translation map. All five accessible screens resolve strings through the central translations file. The four unreachable screens are untouched.
- [ ] Switching between English, Urdu, and Sindhi on every accessible screen shows no missing or English-fallback strings that were not already falling back before this spec.

**Tests & analysis**
- [ ] All tests in FR-TS1 through FR-TS5 pass.
- [ ] `flutter analyze` reports zero errors.

**Untouched screens**
- [ ] `income_screen.dart`, `report_screen.dart`, `electricity_screen.dart`, and `gas_screen.dart` are byte-for-byte identical to their state before this spec was applied.
