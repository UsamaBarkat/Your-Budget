# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get
flutter run
flutter build apk --debug        # release requires key.properties (not in repo)
flutter analyze
flutter test
dart run flutter_launcher_icons  # regenerate from assets/icon/app_icon.png
```

## Project Constitution

**MONEY** — Never store or calculate money as `double`/`float`. All new money handling uses integer paisa (smallest unit). Existing `double` storage will be migrated via a dedicated spec — do not ad-hoc fix it.

**PERSISTENCE** — Every SharedPreferences write must be `await`ed and its failure handled explicitly. No fire-and-forget saves.

**DATA SAFETY** — Any change to a stored model's JSON shape (field added, renamed, removed, type changed) requires an explicit migration step. There is no schema versioning yet — adding one is a prerequisite for any model change.

**TRANSLATIONS** — Do not add inline translation maps inside screen files. New strings go in the central translations file (to be created per spec). Existing per-screen maps (`dailyTranslations`, `expenseTranslations`, etc.) are legacy — do not extend them.

**STRUCTURE** — No file over 300 lines. For any new or rewritten code, UI, business logic, and persistence must live in separate files. Model classes belong in `lib/models/`, not inside screen files.

**PROCESS** — Spec-Driven Development: no feature work without an approved `spec.md`. Sequence: research → spec → clarify → build → verify against spec → commit per verified task.

**SCOPE** — Personal budget app for Pakistani users: PKR only, HESCO/SSGC bill calculators, three languages (English/Urdu/Sindhi). Keep solutions proportional. Do not introduce packages without justification in the spec.

**CONVENTIONS** — `snake_case` files, `PascalCase` classes, `_Screen` suffix on every screen, `_buildX()` for private widget helpers, `.withAlpha()` not `.withOpacity()`.

## Navigation & State

All navigation is imperative `Navigator.push`. Language (`'en'`/`'ur'`/`'sd'`) is the only app-wide state, held in `_HomeBudgetAppState` and passed via constructor to every screen. Four screens exist in `lib/screens/` but have no entry point: `income_screen.dart`, `report_screen.dart`, `electricity_screen.dart`, `gas_screen.dart`.

## SharedPreferences Keys

`daily_expenses` · `expenses` · `bill_reminders` · `income_sources` · `savings_goal` · `savings_saved` — all defined as bare string literals inside their owner screen. A constants file does not yet exist.
