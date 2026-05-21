# Shared Button Action Test Report

Date: 2026-03-08
Scope: Core shared button widgets
Command: `flutter test test/core/shared_widgets`
Result: Passed (`12/12`)

## Covered Widgets

- `AppBackButton`
  - Custom callback executes on press
  - Default behavior pops the current route

- `AppButton`
  - All variants trigger their callbacks
  - Loading state shows a spinner and blocks the action
  - Icon button renders icon and label together

- `SolidActionButton`
  - Normal press executes callback
  - Loading state blocks the action

- `SolidActionChip`
  - Tap executes callback

- `VerticalActionButton`
  - Tap executes callback

- `QuickActionsFab`
  - Hidden actions do not trigger while the menu is collapsed
  - Expanded action executes callback and collapses back

- `SimpleFab`
  - Icon-only FAB executes callback
  - Extended FAB executes callback

## Issue Found And Fixed

- `QuickActionsFab` actions were still tappable while visually collapsed because the action items stayed interactive inside the widget tree.
- Fix applied: wrapped each collapsed action item with `IgnorePointer(ignoring: !_isExpanded)`.

## Files Added Or Updated

- `test/core/shared_widgets/back_button_test.dart`
- `test/core/shared_widgets/app_button_test.dart`
- `test/core/shared_widgets/dashboard/action_button_test.dart`
- `test/core/shared_widgets/quick_actions_fab_test.dart`
- `lib/core/shared_widgets/quick_actions_fab.dart`
