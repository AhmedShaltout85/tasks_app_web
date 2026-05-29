# Responsive Web Implementation Plan for tasks_app

## Project Overview

| Aspect | Details |
|--------|---------|
| **Framework** | Flutter 3.38.9 |
| **State Management** | Provider |
| **Language** | Arabic (RTL) |
| **Target** | Web + Mobile (Android/iOS) |
| **Current State** | Mobile-only, hardcoded pixel values, no responsive patterns |

## Goals

1. Make the app fully responsive for web (mobile, tablet, desktop breakpoints)
2. Persistent sidebar navigation on desktop, drawer on mobile
3. BottomSheet forms → Dialog forms on desktop
4. Single-column task lists → multi-column grids on desktop
5. Proper viewport scaling in web

---

## Step 1: Add dependency & configure web viewport

### 1a. `pubspec.yaml`
Add to dependencies:
```yaml
responsive_framework: ^1.5.1
```

### 1b. `web/index.html`
- Remove `user-scalable=no` from viewport meta
- Set `width=device-width, initial-scale=1.0`

### 1c. `lib/main.dart`
- Import `responsive_framework`
- Wrap `MaterialApp` with `ResponsiveWrapper.builder`
- Configure breakpoints:
  - Mobile: default (< 600px)
  - Tablet: 600px - 1024px
  - Desktop: > 1024px
- Set `minWidth: 320` to allow very small screens

---

## Step 2: Create responsive navigation shell

### New file: `lib/common_widgets/responsive/responsive_scaffold.dart`

`ResponsiveScaffold` widget that replaces `Scaffold` wrapper in all screens:
- **Mobile (< 1024px)**: Standard `drawer` behavior (slide-in hamburger menu)
- **Desktop (≥ 1024px)**: Persistent sidebar panel (using Drawer item list) + divider + content

```dart
class ResponsiveScaffold extends StatelessWidget {
  final DrawerItem drawer;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final int selectedIndex;
  final void Function(int) onDrawerItemTap;
  // ...
}
```

The sidebar shows the drawer content (navigation items + logout) in a fixed-width panel (~260px) on the left, with the content taking remaining space. No animation or toggle needed for sidebar - it's always visible on desktop.

---

## Step 3: Adapt drawer widgets for sidebar mode

### 3a. Extract reusable drawer item list

Create `lib/common_widgets/responsive/drawer_items.dart`:
- `DrawerItemsList` widget that renders a list of `ListTile` navigation items
- Accepts: `items` list, `selectedIndex`, `onTap` callback
- Used by both `custom_drawer.dart` and `custom_user_drawer.dart`
- Desktop sidebar renders these items in a Column (expanded to fill)

### 3b. `lib/common_widgets/custom_widgets/custom_drawer.dart`
- Extract item rendering into `DrawerItemsList`
- Keep existing drawer for mobile (wrap in `Drawer` widget)
- Desktop sidebar uses same `DrawerItemsList` without `Drawer` wrapper

### 3c. `lib/common_widgets/custom_widgets/custom_user_drawer.dart`
- Same treatment as custom_drawer.dart

---

## Step 4: Create responsive Dialog for BottomSheets

### New file: `lib/common_widgets/responsive/responsive_form_container.dart`

- `ResponsiveFormContainer` wrapper widget
- **Mobile (< 1024px)**: Renders as a standard `showModalBottomSheet`
- **Desktop (≥ 1024px)**: Renders as a `showDialog` with max-width constraint (~500px), centered, with title and close button

This wrapper will be used in `reusable_widgets.dart` and `reusable_user_bottom_sheet.dart` to replace all `showModalBottomSheet` calls.

---

## Step 5: Update common widgets for responsive sizing

### 5a. `lib/common_widgets/custom_widgets/custom_button.dart`
- Replace hardcoded `width: 200, height: 50`
- Use `ButtonStyle(minimumSize: MaterialStatePropertyAll(Size(120, 50)))` with responsive max-width
- Use `ResponsiveValue` from `responsive_framework` to scale button dimensions

### 5b. `lib/common_widgets/custom_widgets/custom_text_field.dart`
- Replace `EdgeInsets.symmetric(horizontal: 36)` with responsive padding
- Use breakpoint-aware values

---

## Step 6: Update auth screens (login, signup)

### 6a. `lib/screens/login/login_screen.dart`
- Wrap form in a `Center` + `ConstrainedBox(maxWidth: 500)` on desktop
- Replace fixed `horizontal: 30` padding with responsive padding
- Keep `SafeArea` and existing form fields unchanged

### 6b. `lib/screens/signup/signup_screen.dart`
- Same responsive centering and padding adjustments

---

## Step 7: Update task screens

### 7a. `lib/screens/task/task_screen.dart` (admin)
- Replace `Scaffold` with `ResponsiveScaffold` (uses admin drawer)
- Task list: use `LayoutBuilder` to determine columns → 1 (mobile), 2 (tablet), 3 (desktop)
- Replace fixed `SizedBox(width: 120)` gaps with responsive spacing
- Use `ResponsiveFormContainer` for the task creation bottom sheet

### 7b. `lib/screens/task/user_task_screen.dart` (user)
- Replace `Scaffold` with `ResponsiveScaffold` (uses user drawer)
- Same responsive grid for task cards
- Use `ResponsiveFormContainer` for task creation bottom sheet
- Replace hardcoded `SizedBox(width: 10/18/10)` gaps

### 7c. `lib/screens/task/manager_task_screen.dart` (manager)
- Replace `Scaffold` with `ResponsiveScaffold` (replace `BottomNavigationBar` with sidebar navigation)
- Convert `BottomNavigationBar` to sidebar items (daily tasks, preventive, reports, etc.)
- Same responsive grid for task cards
- Use `ResponsiveFormContainer` for task creation bottom sheet

---

## Step 8: Update report screens

### 8a. `lib/screens/report/report_screen.dart`
- Replace `Scaffold` with `ResponsiveScaffold` if it uses a drawer
- Filter row: use `Wrap` instead of `Row` for filters
- Make stats row responsive (stacked on mobile, side-by-side on desktop)

### 8b. `lib/screens/report/preventive_maintenance_report_screen.dart`
- Same filter row responsive treatment
- Stats responsive layout

---

## Step 9: Update management screens

### 9a. `lib/screens/user/manage_users.dart`
- Wider card layout on desktop (2 columns if space permits)

### 9b. `lib/screens/user/manage_user_screen.dart`
- Use `ResponsiveFormContainer` for add/edit bottom sheet

### 9c. `lib/screens/places/manage_place_screen.dart`
- Use `ResponsiveFormContainer` for add/edit bottom sheet

### 9d. `lib/screens/preventive/preventive_item_screen.dart`
- Replace `Scaffold` with `ResponsiveScaffold` if it uses a drawer
- Filter chips wrap on desktop
- Use `ResponsiveFormContainer` for bottom sheet

### 9e. `lib/screens/preventive/manage_preventive_maintenance_screen.dart`
- Make form columns side-by-side on desktop

### 9f. `lib/screens/about_app/manage_about_app_screen.dart`
- Replace `Scaffold` with `ResponsiveScaffold` if it uses a drawer
- Grouped list in 2 columns on desktop

### 9g. `lib/screens/about_app/app_recommended_details_screen.dart`
- Use `ResponsiveFormContainer` for bottom sheet

---

## Step 10: Update settings screen

### `lib/screens/settings/settings_screen.dart`
- Replace `Scaffold` with `ResponsiveScaffold` (uses admin drawer)
- Profile section wider on desktop

---

## Files Summary

### New Files (3)
1. `lib/common_widgets/responsive/responsive_scaffold.dart` - Responsive navigation shell
2. `lib/common_widgets/responsive/drawer_items.dart` - Reusable drawer item list
3. `lib/common_widgets/responsive/responsive_form_container.dart` - Dialog/BottomSheet adapter

### Modified Files (~25)
- `pubspec.yaml`
- `web/index.html`
- `lib/main.dart`
- `lib/common_widgets/custom_widgets/custom_drawer.dart`
- `lib/common_widgets/custom_widgets/custom_user_drawer.dart`
- `lib/common_widgets/custom_widgets/custom_button.dart`
- `lib/common_widgets/custom_widgets/custom_text_field.dart`
- `lib/common_widgets/reuable_widgets/reusable_widgets.dart`
- `lib/common_widgets/reuable_widgets/reusable_user_bottom_sheet.dart`
- `lib/screens/login/login_screen.dart`
- `lib/screens/signup/signup_screen.dart`
- `lib/screens/task/task_screen.dart`
- `lib/screens/task/user_task_screen.dart`
- `lib/screens/task/manager_task_screen.dart`
- `lib/screens/report/report_screen.dart`
- `lib/screens/report/preventive_maintenance_report_screen.dart`
- `lib/screens/user/manage_users.dart`
- `lib/screens/user/manage_user_screen.dart`
- `lib/screens/places/manage_place_screen.dart`
- `lib/screens/preventive/preventive_item_screen.dart`
- `lib/screens/preventive/manage_preventive_maintenance_screen.dart`
- `lib/screens/about_app/manage_about_app_screen.dart`
- `lib/screens/about_app/app_recommended_details_screen.dart`
- `lib/screens/settings/settings_screen.dart`

### Unchanged Files
- All providers, models, services, network repos, utils (colors, theme, routes)
- All PDF generation widgets

---

## Implementation Order

1. **Foundation** (Steps 1-2): Package + web config + ResponsiveScaffold
2. **Drawer** (Step 3): Extract drawer items for sidebar
3. **Forms** (Step 4): ResponsiveFormContainer
4. **Common Widgets** (Step 5): Button & TextField responsive sizing
5. **Auth Screens** (Step 6): Login & Signup centering
6. **Task Screens** (Step 7): Main task screens with grid layout
7. **Report Screens** (Step 8): Filter responsive
8. **Management Screens** (Step 9): CRUD screens
9. **Settings** (Step 10): Final screen
