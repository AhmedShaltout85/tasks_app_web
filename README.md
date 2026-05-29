# tasks_app

**تطبيق المهام اليومية** — Arabic-language (RTL) daily task management and preventive maintenance application for IT departments.

Built with Flutter (Web + Android) and a REST API backend.

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running](#running)
- [Backend Configuration](#backend-configuration)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Roles and Access Control](#roles-and-access-control)
- [Screens](#screens)
- [API Reference](#api-reference)
- [Theme](#theme)
- [Responsive Design](#responsive-design)
- [PDF Report Generation](#pdf-report-generation)
- [Authentication Flow](#authentication-flow)
- [Assets](#assets)
- [Testing](#testing)

## Features

- **Daily Task Management** — Assign, track, and manage daily tasks with priorities, deadlines, locations, and co-operators
- **Preventive Maintenance** — Track preventive maintenance items and schedules for software/devices
- **User Management** — Role-based access control with 5 roles and department-based filtering
- **Place/Location Management** — Manage locations/sites where tasks are performed
- **Application Registry** — Manage software applications/devices by department with recommended values
- **Reports** — Daily task and preventive maintenance reports with PDF export (Arabic + English)
- **Responsive Design** — Adapts between mobile (drawer) and desktop (sidebar) layouts
- **Light/Dark Theme** — Full Material 3 theme support with persistence
- **Offline Handling** — Connectivity checking with retry dialogs

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Dart |
| Framework | Flutter 3.38.9 (via [FVM](https://fvm.app/)) |
| State Management | Provider (ChangeNotifier pattern) |
| HTTP Client | Dio 5.4.0 with JWT Bearer authentication |
| Local Storage | Hive 2.2.3 + SharedPreferences |
| Backend | REST API |
| PDF Generation | `pdf` 3.11.3 + `printing` 5.14.2 |
| Responsive | `responsive_framework` 1.5.1 |
| UI | Material 3, Cairo font, `awesome_dialog`, `fluttertoast` |
| Connectivity | `connectivity_plus` |

## Prerequisites

- Flutter SDK 3.38.9 (managed via [FVM](https://fvm.app/))
- Dart SDK ^3.5.3

## Installation

```bash
# Clone the repository
git clone <repo-url>
cd tasks_app

# Install FVM (if not already installed)
dart pub global activate fvm

# Use the pinned Flutter version
fvm install 3.38.9
fvm use 3.38.9

# Install dependencies
fvm flutter pub get

# Generate Hive adapters (if needed)
fvm dart run build_runner build

# Generate splash screen (if needed)
fvm dart run flutter_native_splash:create

# Generate app icons (if needed)
fvm dart run flutter_launcher_icons
```

## Running

```bash
# Run on web
fvm flutter run -d chrome

# Run on Android device/emulator
fvm flutter run -d <device-id>

# Build for web
fvm flutter build web

# Build for Android APK
fvm flutter build apk
```

## Backend Configuration

The app requires a REST API backend. The default API URL is configured in:

```
lib/newtork_repos/remote_repo/api_repos/dio_client.dart
```

### Available Environments

| Environment | URL | Status |
|-------------|-----|--------|
| Production | `http://41.33.226.211:8099/tasks-api/api` | Active (default) |
| Local Development | `http://localhost:9999/tasks-api/api` | Commented out |
| Local Network (Docker) | `http://172.18.0.101:9999/tasks-api/api` | Commented out |

To switch to a local development server, uncomment the desired URL in `DioClient._()`.

### DioClient Configuration

- Connect timeout: 30 seconds
- Receive timeout: 30 seconds
- Content-Type: `application/json`
- Authentication: JWT Bearer token via `Authorization` header

## Architecture

The app follows a **Provider + Repository** pattern:

```
Screens (UI)  →  Providers (State)  →  Repositories (Abstract)  →  API Implementations (Dio)
```

- **Screens** use `Consumer`/`Selector` widgets to rebuild on state changes
- **Providers** extend `ChangeNotifier` and manage business logic
- **Repositories** define abstract interfaces for data access
- **API Implementations** use Dio to communicate with the REST backend

### State Management

| Provider | Purpose |
|----------|---------|
| `UserProvider` | Auth, user CRUD, role management |
| `DailyTaskProvider` | Task CRUD and filtering |
| `PlaceNameProvider` | Location CRUD |
| `AboutAppProvider` | App registry CRUD |
| `PreventiveProvider` | Preventive items + maintenance CRUD |
| `ThemeProvider` | Light/dark theme toggle with persistence |

## Project Structure

```
lib/
├── main.dart                          # App entry point (MultiProvider, routes, ResponsiveBreakpoints)
├── common_widgets/                    # Reusable UI components
│   ├── custom_widgets/               # Custom widgets (buttons, drawers, dialogs, text fields)
│   │   ├── custom_bottom_sheet.dart
│   │   ├── custom_button.dart
│   │   ├── custom_drawer.dart         # Admin drawer navigation (7 items)
│   │   ├── custom_user_drawer.dart    # User drawer navigation (6 items)
│   │   ├── custom_text.dart
│   │   ├── custom_text_field.dart
│   │   ├── custom_textfield_signup.dart
│   │   ├── custom_logo_text.dart
│   │   ├── custom_reusable_bottom_nav_bar.dart
│   │   ├── custom_reusable_dialog.dart
│   │   └── custom_social_icon.dart
│   ├── responsive/                   # Responsive layout widgets
│   │   ├── responsive_scaffold.dart      # Sidebar on desktop, drawer on mobile
│   │   ├── responsive_form_container.dart # Dialog on desktop, BottomSheet on mobile
│   │   ├── responsive_content_container.dart
│   │   ├── drawer_items.dart              # Reusable drawer item list
│   │   └── empty_state_widget.dart
│   ├── resuable_widgets/             # Utility widgets
│   │   ├── reusable_widgets.dart         # Navigation helpers, common UI utilities
│   │   ├── reusable_toast.dart           # Toast notifications
│   │   ├── reusable_dialog.dart
│   │   └── reusable_user_bottom_sheet.dart
│   └── task_widgets/
│       └── shared_task_card.dart          # Shared task card widget
├── controller/                        # State management (Provider/ChangeNotifier)
│   ├── user_provider.dart
│   ├── daily_task_provider.dart
│   ├── place_name_provider.dart
│   ├── about_app_provider.dart
│   ├── preventive_provider.dart
│   ├── theme_provider.dart
│   └── local_control/
│       └── cache_helper.dart           # SharedPreferences wrapper
├── models/                            # Data models
│   ├── user_model.dart                 # User with role, department, enabled status
│   ├── daily_task_model.dart           # Task with title, status, priority, dates
│   ├── place_name_model.dart           # Location model
│   ├── about_app_model.dart            # Application/device registry
│   ├── preventive_item_model.dart      # Preventive maintenance item
│   ├── preventive_maintenance_model.dart # Preventive maintenance record
│   ├── recommended_item_model.dart     # Recommended values for apps
│   └── hive_model/
│       ├── task_model.dart             # Hive-annotated task model
│       └── task_model.g.dart           # Generated Hive adapter
├── newtork_repos/                     # Network/data layer
│   └── remote_repo/
│       ├── api_repos/                  # REST API clients (Dio-based, 11 files)
│       │   ├── dio_client.dart               # Singleton Dio HTTP client with JWT interceptor
│       │   ├── api_network_user_repos.dart           # Abstract user repo interface
│       │   ├── api_network_user_repos_impl.dart      # User API implementation
│       │   ├── api_network_daily_task_repos.dart      # Abstract task repo interface
│       │   ├── api_network_daily_task_repos_impl.dart # Task API implementation
│       │   ├── api_network_place_name_repos.dart      # Abstract place repo interface
│       │   ├── api_network_place_name_repos_impl.dart # Place API implementation
│       │   ├── api_network_preventive_repos.dart      # Abstract preventive repo interface
│       │   ├── api_network_preventive_repos_impl.dart # Preventive API implementation
│       │   ├── api_network_about_app_repos.dart       # Abstract about-app repo interface
│       │   └── api_network_about_app_repos_impl.dart  # About-app API implementation
│       └── firestore_services/         # Firebase services (stub/future use)
│           ├── firebase_email_password_services/
│           │   └── firebase_api_services.dart
│           └── social_auth/
│               ├── facebook_auth_service.dart
│               └── google_auth_service.dart
├── screens/                           # Screen/page widgets
│   ├── splash/
│   │   └── splash_screen.dart          # Animated splash with logo + loading
│   ├── auth/
│   │   └── auth_wrapper.dart           # Route guard: token check → role-based routing
│   ├── login/
│   │   └── login_screen.dart           # Username/password login with forgot password
│   ├── signup/
│   │   └── signup_screen.dart          # User registration
│   ├── task/
│   │   ├── task_screen.dart            # Admin task list (full CRUD, filters, sidebar)
│   │   ├── user_task_screen.dart       # Regular user task view (limited access)
│   │   └── manager_task_screen.dart    # Manager task view (read-only, bottom nav)
│   ├── report/
│   │   ├── report_screen.dart          # Daily task reports
│   │   ├── preventive_maintenance_report_screen.dart
│   │   └── widgets/
│   │       ├── generate_pdf.dart       # PDF report generation
│   │       └── preventive_maintenance_export_pdf.dart
│   ├── user/
│   │   ├── manage_users.dart           # User list management
│   │   └── manage_user_screen.dart     # Single user CRUD
│   ├── places/
│   │   └── manage_place_screen.dart    # Location management
│   ├── preventive/
│   │   ├── preventive_item_screen.dart          # Preventive items management
│   │   └── manage_preventive_maintenance_screen.dart
│   ├── about_app/
│   │   ├── manage_about_app_screen.dart          # App/device registry management
│   │   └── app_recommended_details_screen.dart   # Recommended values for apps
│   └── settings/
│       └── settings_screen.dart        # App settings (theme, profile, password)
├── services/                          # App services
│   ├── connectivity_service.dart       # Internet connectivity checking
│   └── connection_dialog_service.dart  # "No internet" dialog with retry
└── utils/                             # Utilities and constants
    ├── app_colors.dart                 # Comprehensive color palette
    ├── app_theme.dart                  # Light and dark ThemeData definitions
    ├── app_route.dart                  # Named route constants
    └── app_assets.dart                 # Asset path constants
```

## Roles and Access Control

The app defines 5 roles with hierarchical access:

| Role | Dashboard | Sidebar Items | Task Actions | Report Filtering |
|------|-----------|---------------|--------------|------------------|
| **GENERAL_MANAGER** | ManagerTaskScreen (bottom nav) | Home, Preventive Reports, Daily Reports, Settings | View only | All departments, all users |
| **SECTOR_MANAGER** | ManagerTaskScreen (bottom nav) | Home, Preventive Reports, Daily Reports, Settings | View only | All departments, all users |
| **ADMIN** | TaskScreen (full sidebar) | Users, Preventive Items, Apps, Places, Daily Reports, Preventive Reports, Settings | Create, delete, toggle status | Own department, users within department |
| **MANAGER** | TaskScreen (full sidebar) | Users, Preventive Items, Apps, Places, Daily Reports, Preventive Reports, Settings | Create, delete, toggle status | Own department, users within department |
| **USER** | UserTaskScreen (limited sidebar) | Preventive Items, Daily Reports, Preventive Reports, Add Maintenance, Settings, About Apps | Toggle status, toggle remote | Own tasks only (locked) |

### Role Routing (in `AuthWrapper`)

```
if (no token) → LoginScreen
else if (GENERAL_MANAGER or SECTOR_MANAGER) → ManagerTaskScreen
else if (ADMIN or MANAGER) → TaskScreen
else → UserTaskScreen
```

## Screens

### SplashScreen
Animated splash with 3 phases: logo fade-in + scale (1200ms), text slide-up + fade (800ms), pulsing loading indicator. Navigates to `AuthWrapper` after 3 seconds.

### LoginScreen
- Username and password fields with visibility toggle
- Gradient login button
- Social login buttons (Facebook, Google, Apple) — show "coming soon" toast
- Forgot password — resets to default password `100100123`
- Connectivity check before login
- Constrained to `maxWidth: 450` for responsive layout

### SignUpScreen
- Fields: Display name, username, password, confirm password
- Validation: all fields required, password min 6 chars, password match
- Default role: `USER`, default department: `ادراة البرامج وصيانتها`
- After signup, navigates back to login

### TaskScreen (Admin/Manager)
- Shows ALL tasks from the department
- Admin sidebar with 7 navigation items
- Filter panel: Employee dropdown, App/Device dropdown
- Task cards with: toggle status (green/grey), delete (red) with confirmation
- Task creation form: Task name, App, Assigned by/to, Main/sub location, Priority, Co-operators, Expected days, Notes

### UserTaskScreen
- Shows only tasks assigned to the current user
- Limited sidebar with 6 items
- Filter panel: Maintenance type (Remote/On-site/All), Priority, App/Device
- Task actions: toggle status, toggle remote, view notes

### ManagerTaskScreen
- Shows ALL tasks (read-only, no create/delete)
- Bottom navigation: Home, Preventive Reports, Daily Reports, Settings
- Filter panel: App/Device, Remote status, Department, Employee
- Department filter dynamically loads users for selected department

### ReportScreen (Daily Tasks)
- Collapsible filter card with: Date range, Assignee, Application, Department, Visit place, Status, Maintenance type
- Stats row: Total tasks, Completed, Pending
- Filtered task list with detailed cards
- PDF export button

### PreventiveMaintenanceReportScreen
- Collapsible filter card with: Date range, User, App, Department, Visit place, Remote type
- Stats row: Total tasks, Remote, On-site
- Debounced filter updates (300ms)
- PDF export button

### ManageUsersScreen
- Search bar filtering by display name, username, or department
- User cards: Avatar (initial), display name, username, role badge, status badge
- Enable/disable and delete actions with confirmation

### ManagePlaceScreen
- Location cards with add/edit/delete
- Teal color theme

### PreventiveItemScreen
- Horizontal scrollable app name filter chips
- When app selected, shows preventive actions
- Admin: add/edit/delete actions
- Regular user: view only

### ManagePreventiveMaintenanceScreen
- Form: Place name dropdown, App name dropdown
- When app selected, loads action items as selectable chips
- Remote/On-site toggle switch
- Sub-place text field

### ManageAboutAppScreen
- Apps grouped by app name
- Admin: add/edit/delete apps
- Tap to view recommended values

### AppRecommendedDetailsScreen
- Shows recommended values for a specific app
- Admin: add/edit/delete

### SettingsScreen
- Profile section: Avatar, display name, department
- Security: Change password dialog
- Appearance: Dark mode toggle (SwitchListTile)
- Logout with confirmation

## API Reference

### Base URL

```
http://41.33.226.211:8099/tasks-api/api
```

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/signup` | Register a new user |
| POST | `/auth/signin` | Sign in (returns JWT token + user data) |
| POST | `/auth/signout` | Sign out |
| POST | `/auth/forgot-password` | Reset password |

### Users

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users` | Get all users |
| GET | `/users/$id` | Get user by ID |
| GET | `/users/department/$department/all` | Get users by department |
| GET | `/users/role/$role` | Get users by role |
| GET | `/users/role/$role/enabled/$enabled` | Get enabled/disabled users by role |
| PUT | `/users/$id/enable?enabled=$enabled` | Enable/disable a user |
| DELETE | `/users/$id` | Delete a user |
| PUT | `/users/change-password` | Change password |

### Daily Tasks

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/daily-tasks` | Get all tasks |
| GET | `/daily-tasks/$id` | Get task by ID |
| GET | `/daily-tasks/assigned-to/$username` | Get tasks assigned to user |
| GET | `/daily-tasks/assigned-by/$username` | Get tasks assigned by user |
| GET | `/daily-tasks/app/$appName` | Get tasks by app name |
| GET | `/daily-tasks/status/$status` | Get tasks by status (bool) |
| GET | `/daily-tasks/priority/$priority` | Get tasks by priority |
| GET | `/daily-tasks/assigned-to/$username/remote/$isRemote` | Get tasks by assignee + remote flag |
| GET | `/daily-tasks/remote/$isRemote` | Get tasks by remote flag |
| POST | `/daily-tasks` | Create a task |
| PUT | `/daily-tasks/$id` | Update a task |
| DELETE | `/daily-tasks/$id` | Delete a task |

### Preventive Items

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/preventive-items` | Get all preventive items |
| GET | `/preventive-items/$id` | Get preventive item by ID |
| GET | `/preventive-items/app/$appName` | Get items by app name |
| GET | `/preventive-items/app/$appName/actions` | Get actions for an app |
| POST | `/preventive-items` | Create a preventive item |
| PUT | `/preventive-items/$id` | Update a preventive item |
| DELETE | `/preventive-items/$id` | Delete a preventive item |

### Preventive Maintenance

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/preventive-maintenance` | Get all maintenance records |
| GET | `/preventive-maintenance/$id` | Get by ID |
| GET | `/preventive-maintenance/app/$appName` | By app name |
| GET | `/preventive-maintenance/user/$username` | By username |
| GET | `/preventive-maintenance/place/$placeName` | By place name |
| GET | `/preventive-maintenance/sub-place/$subPlace` | By sub-place |
| GET | `/preventive-maintenance/remote/$isRemote` | By remote flag |
| GET | `/preventive-maintenance/app/$appName/user/$username` | By app + user |
| GET | `/preventive-maintenance/app/$appName/place/$placeName` | By app + place |
| GET | `/preventive-maintenance/user/$username/place/$placeName` | By user + place |
| GET | `/preventive-maintenance/app/$appName/remote/$isRemote` | By app + remote |
| GET | `/preventive-maintenance/user/$username/remote/$isRemote` | By user + remote |
| GET | `/preventive-maintenance/place/$placeName/remote/$isRemote` | By place + remote |
| POST | `/preventive-maintenance` | Create maintenance record |
| PUT | `/preventive-maintenance/$id` | Update record |
| DELETE | `/preventive-maintenance/$id` | Delete record |

### Place Names

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/place-items` | Get all places |
| GET | `/place-items/$id` | Get place by ID |
| GET | `/place-items/names` | Get all place name strings |
| POST | `/place-items` | Create a place |
| PUT | `/place-items/$id` | Update a place |
| DELETE | `/place-items/$id` | Delete a place |

### About Apps

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/about-apps` | Get all apps |
| GET | `/about-apps/department/$department` | By department |
| GET | `/about-apps/$id` | By ID |
| GET | `/about-apps/name/$appName` | By name |
| GET | `/about-apps/name/$appName/recommended` | Get recommended values (strings) |
| GET | `/about-apps/name/$appName/recommended/all` | Get recommended items (objects) |
| POST | `/about-apps/name/$appName/recommended` | Add a recommended value |
| DELETE | `/about-apps/recommended/$id` | Delete recommended value |
| POST | `/about-apps` | Create an app |
| PUT | `/about-apps/$id` | Update an app |
| DELETE | `/about-apps/$id` | Delete an app |

## Theme

### Font

**Cairo** font family (bundled as local assets) with weights: ExtraLight (200), Light (300), Medium (500), SemiBold (600), Bold (700), Regular (default).

### Light Theme

| Element | Value |
|---------|-------|
| Primary | `#769DAD` (muted blue) |
| Secondary | `#8CD6F7` (light blue) |
| Background | `#F5F5F5` |
| Surface/Card | `#FFFFFF` |
| Error | `#F44336` |

### Dark Theme

| Element | Value |
|---------|-------|
| Primary | `#8CD6F7` (light blue) |
| Secondary | `#769DAD` (muted blue) |
| Background | `#121212` |
| Surface/Card | `#1E1E1E` |

### Theme Persistence

Theme preference is stored via `SharedPreferences` (key: `theme_mode`) and restored on app start.

## Responsive Design

### Breakpoints

| Breakpoint | Range | Behavior |
|-----------|-------|----------|
| **MOBILE** | 0 - 600px | Standard scaffold with drawer |
| **TABLET** | 600px - 1024px | Intermediate layout, wider padding |
| **DESKTOP** | > 1024px | Persistent 280px sidebar + content |

### Responsive Widgets

- **`ResponsiveScaffold`**: Sidebar on desktop (≥1024px), drawer on mobile/tablet
- **`ResponsiveFormContainer`**: `showDialog()` on desktop (max-width 500px), `showModalBottomSheet()` on mobile
- **`ResponsiveContentContainer`**: Max-width 1200px on tablet/desktop, full width on mobile
- **Auth screens**: `ConstrainedBox(maxWidth: 450/500)` with `ResponsiveValue` padding (30px mobile, 40px tablet+)

## PDF Report Generation

### Daily Task Report

- **Page**: A4, 32px margins
- **Font**: Cairo (Regular + Bold) via `PdfGoogleFonts`
- **Direction**: RTL with bilingual cell detection (Arabic Unicode range `\u0600-\u06FF`)
- **Header**: "تقرير الأنشطة اليومية" (Daily Activities Report)
- **Table columns (11)**: Date, Task Name, App Name, Assigned To, Assigned By, Visit Place, Status, Priority, Remote Type, Co-Operators, Expected Completion Date
- **Output**: Opens system print/save dialog via `Printing.layoutPdf()`

### Preventive Maintenance Report

- **Header**: "تقرير الصيانة الوقائية - Preventive Maintenance Report"
- **Table columns (6)**: App Name, Action, User, Place, Sub-Place, Type
- **Filters shown**: Username, App name, Place name, Remote type, Date range

Both PDF generators use a `_containsArabic()` helper to auto-detect text direction per cell.

## Authentication Flow

1. User enters username + password on `LoginScreen`
2. Connectivity check via `ConnectivityService` (web: `navigator.onLine`; mobile: HTTP check to `httpbin.org/status/200`)
3. If offline, `ConnectionDialogService.showNoInternetDialog()` with retry
4. `UserProvider.signIn()` calls `POST /auth/signin`
5. Backend returns `{ token, displayName, username, role, department, ... }`
6. Token stored in `DioClient._token` (in-memory) + `SharedPreferences` (key: `auth_token`)
7. User data stored as JSON string (key: `current_user`)
8. On app start, `UserProvider._init()` restores token and user from cache
9. `DioClient` interceptor adds `Authorization: Bearer $token` to every request
10. Logout calls `POST /auth/signout` and clears all cached data

## Assets

- `assets/fonts/` — Cairo font family (Regular, Bold, SemiBold, Medium, Light, ExtraLight)
- `assets/icons/` — App icons
- `assets/images/` — Images and splash assets
- `assets/splash/` — Splash screen images (background, logo, branding)

## Testing

```bash
fvm flutter test
```

> Note: Tests are currently boilerplate and need to be updated to match the actual application.
