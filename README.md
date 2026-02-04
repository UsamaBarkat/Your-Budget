# Home Budget (Your Budget)

A Flutter app for tracking home budget, daily expenses, monthly spending, savings goals, and bill reminders. Built with **English**, **Urdu (اردو)**, and **Sindhi (سنڌي)** support and Pakistani Rupee (Rs.) as the default currency.

## Features

### From Home Screen

| Feature | Description |
|--------|-------------|
| **Daily Expenses** | Log day-to-day spending by category. View today’s total, this week, and this month. Categories: Chai/Snacks, Transport, Food, Shopping, Mobile Recharge, Other. Data is stored locally. |
| **Monthly Budget** | Set and track monthly spending by category: Grocery, School/Tuition, Bills, Transport, Other. View total and clear all. |
| **Savings Goal** | Set a savings target, add amounts as you save, and see progress in a circular indicator with goal, saved, and remaining. |
| **Bill Reminders** | Add reminders with bill type, due date, and optional amount. Mark as paid. Types: Electricity, Gas, Water, Internet, Mobile, School Fee, Rent, Other. Status: Due Today, Due Soon, Overdue, Paid. |

### Language Support

- **English (EN)**
- **Urdu (اردو)**
- **Sindhi (سنڌي)**

Language can be switched from the home screen; all main screens use the selected language.

### Additional Screens (in codebase)

These screens exist in the project and can be wired from the home screen or other entry points:

- **Income & Balance** – Set monthly income by source (Salary, Business, Rent Income, Other), compare with total expenses, and see balance (saving vs overspending).
- **Monthly Report** – Pie chart and category breakdown of spending (monthly expenses + daily expenses for the current month).
- **Electricity Bill** – Estimate bill from units (kWh) using HESCO-style slab rates (PKR).
- **Gas Bill** – Estimate bill from units (HM³) using SSGC-style domestic slab rates (PKR).

## Tech Stack

- **Flutter** (SDK ^3.10.8)
- **shared_preferences** – Local persistence for expenses, savings, reminders, income
- **intl** – Date/time formatting
- **fl_chart** – Pie chart on Report screen
- **cupertino_icons** – iOS-style icons
- **flutter_launcher_icons** – App icon from `assets/icon/app_icon.png`

## Project Structure

```
lib/
├── main.dart                 # App entry, theme, language state
└── screens/
    ├── home_screen.dart      # Main menu + language selector
    ├── daily_expenses_screen.dart
    ├── expenses_screen.dart  # Monthly budget
    ├── savings_screen.dart
    ├── reminders_screen.dart
    ├── income_screen.dart
    ├── report_screen.dart
    ├── electricity_screen.dart
    └── gas_screen.dart
```

Each screen that uses translations has its own `Map` for `en`, `ur`, and `sd`, plus a getter (e.g. `getDailyText`, `getExpenseText`).

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10.8 or compatible)
- A device or emulator (Android, iOS, or supported desktop)

### Run the app

```bash
# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

### Build

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

### Generate app icons

Icons are configured in `pubspec.yaml` (flutter_launcher_icons). To regenerate:

```bash
dart run flutter_launcher_icons
```

## Data Storage

All data is stored on the device using **SharedPreferences**:

- `daily_expenses` – List of daily expense entries (id, category, amount, date)
- `expenses` – Map of monthly budget category → amount
- `savings_goal`, `savings_saved` – Savings target and current saved amount
- `bill_reminders` – List of reminder objects (id, billType, dueDate, amount, isPaid)
- `income_sources` – List of income entries (id, type, amount)

No data is sent to any server.

## License

This project is a Flutter application starter. Use and modify as needed for your own projects.

## Resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
