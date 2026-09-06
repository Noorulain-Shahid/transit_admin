# TransitPro Admin — Fleet & Operations Management

> The **administrator application** for the TransitPro student transport system.
>
> The **mobile app** for parents, students, and drivers is a separate project:
> [`../transit_Pro/transit_pro`](../transit_Pro/transit_pro).
> Both apps share one Firebase backend (`transitpro-db`).

**Status:** Partially wired to the real backend. `transit_core` is now a real
path dependency (not "planned"); driver/parent/student management + detail
screens read and write live Firestore data through it, admin login calls real
Firebase Auth and requires `role: admin`, and there's a real "message this
user" action backed by the shared notification inbox. **Still mock**:
dashboard KPIs, fees, routes, vehicles, subscription/billing screens, and the
4 unreachable screens — none of that was in scope for this pass. **Still
missing:** a router `redirect` auth guard (`/admin` is still reachable without
signing in first — see §9).
**Document purpose:** single source of truth for the admin app. Read alongside the mobile app's README.

**Last updated:** 2026-09-02

---

## 1. Purpose

School transport operations are run on paper and phone calls. This app gives an administrator one place to:

- Monitor fleet KPIs, live trips, and revenue
- Manage students, parents, and drivers (approve, suspend, assign)
- Manage routes, vehicles, and stops
- Handle subscriptions, fees, and billing enforcement
- Approve driver documents and registration requests
- Receive and resolve safety incidents and SOS alerts

---

## 2. How This Relates to the Mobile App

```
D:\Noorulain FYP\
│
├── transit_Pro\transit_pro\   ← MOBILE APP (parent + student + driver)
│      own folder · own git repo · com.transitpro.transit_pro
│
├── transit_admin\             ← THIS APP
│      own folder · own git repo · com.transitpro.transit_admin
│
└── transit_core\              ← PLANNED shared package (not yet created)
                    │
                    ▼
        ┌───────────────────────────────────┐
        │  Firebase project: transitpro-db  │
        │  ONE shared cloud backend          │
        └───────────────────────────────────┘
```

**The folders are separate. These are two distinct programs, installed separately.**

They "share a backend" because both connect to the **same Firebase project** — one database, one user pool, one storage bucket. When an admin creates a route here, the mobile app reads that same document. They communicate **through the cloud**, never directly.

They must also "share a data model" — the same definition of `Student`, `Driver`, `Route`. **`transit_core` now exists and this app depends on it** (`pubspec.yaml` → `transit_core: {path: ../transit_core}`). It carries the domain models *and* the Firestore access layer: `Db` (typed collection refs) and `MessagingRepository` (notification inbox + chat) were moved out of the mobile app into `transit_core` on 2026-09-01 specifically so this app could read/write the exact same schema instead of a hand-maintained copy. `AdminRepository` (`lib/data/admin_repository.dart`) adds the admin-only queries (list every driver, list every user of a role) on top of that shared `Db`. Not yet unified: `admin_user_models.dart`'s presentation models are still used by the screens this pass didn't touch (dashboard, fees, routes, vehicles, subscription) — see §7.

Each app is a separate **Firebase App** inside the shared project. Android/iOS registrations are correct.

> 🐞 **Known bug:** the *web* `appId` is byte-identical in both apps (`1:231263449779:web:12e9bb6b22a9f0a52f76c6`) — they would collide as the same Firebase Web App. Re-run `flutterfire configure` for this app.

### Admin used to exist in two places — resolved

The mobile app previously contained its own `lib/screens/admin/` (10 screens, 7-tab nav) that shared no code with this app. **It was deleted on 2026-08-08.** This standalone app is now the only admin surface.

---

## 3. Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.38.10 (Dart ^3.10.9) |
| Navigation | `go_router` ^14.0.0 — 8 flat routes, **still no auth guard** (see §9) |
| State | `setState` + two singletons (`AuthService`, `ThemeProvider`) + `StreamBuilder` over live Firestore for the wired screens |
| Charts | **Hand-rolled `mini_chart.dart`** — zero dependencies |
| Storage | `shared_preferences` (theme + cached role only) + Firestore via `transit_core`'s `Db` |
| Auth | `firebase_auth` — **now used for real**: `AuthService.signInWithEmail` calls `signInWithEmailAndPassword` and requires `users/{uid}.role == admin` |
| Shared domain layer | `transit_core` (path dependency) — models, `Db`, `MessagingRepository` |

### Declared but still not imported anywhere

`google_maps_flutter` · `geolocator` · `permission_handler` · `flutter_local_notifications` · `flutter_polyline_points` · `http` — unused dependencies in screens this pass didn't touch. `cloud_firestore` and `url_launcher` are now genuinely used (via `transit_core` and the driver document viewer respectively).

### Still planned

Firebase Storage · FCM · a router auth guard · Google Maps for a live dispatch view · unifying the remaining mock screens (dashboard, fees, routes, vehicles, subscription) onto `transit_core`

---

## 4. Architecture

### Honest assessment

This is a **plain Flutter app with an unused "enterprise" layer bolted on top.**

```
lib/core/     ← enums + DI        ─┐
lib/models/   ← domain models      ├── ZERO screens import ANY of this
lib/services/ ← audit, emergency,  │
                 smart alerts     ─┘

lib/screens/  ← what actually runs: hardcoded literals + setState
```

Two specifics worth knowing before you plan work:

1. **`ServiceLocator` is dead code.** `ServiceLocator.initialize()` is **never called**, and the class is never referenced outside its own file. Its fields are `late final`, so `ServiceLocator.instance.auditService` throws `LateInitializationError` today. It is not `get_it`, not injectable — it is an unwired stub.

2. **`main.dart` is explicitly designed to run without a backend:**
   ```dart
   try {
     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   } catch (e) {
     debugPrint('Firebase initialization skipped (front-end mode): $e');
   }
   ```

### Two conflicting model systems

| | `lib/models/*` | `lib/screens/admin/admin_user_models.dart` |
|---|---|---|
| Used by | **nothing** | every screen |
| Dates | `DateTime` ✅ | `String` — `'Jun 15'`, `'2m ago'` ❌ |
| Presentation | clean ✅ | embeds `Color` and `IconData` ❌ |
| Firestore-ready | needs `toJson` | **structurally blocked** |

There are also **two `SubscriptionStatus` enums** and **two `DriverStatus` enums** in the same package with different values. The domain layer and the UI layer cannot interoperate without a translation layer that does not exist.

### Folder structure

```
lib/
├── main.dart                    Entry; Firebase init in try/catch
├── firebase_options.dart        Project transitpro-db
├── app/
│   ├── router.dart                8 routes, no guard, no ShellRoute
│   └── auth_service.dart          SharedPreferences + unused Google sign-in
├── core/
│   ├── di/service_locator.dart    🗑️ Never initialized — dead
│   └── enums/enterprise_enums.dart  6 enums, used only by models/services
├── models/                      🗑️ Used by no screen
│   ├── driver_model.dart          DriverModel, ComplianceDocument
│   ├── student_model.dart         StudentModel, Guardian
│   ├── vehicle_model.dart · route_model.dart · incident_model.dart
├── services/                    🗑️ Zero callers
│   ├── audit_service.dart         In-memory list; TODO: sync to Firestore
│   ├── emergency_service.dart     Broadcast stream, no subscribers
│   └── smart_alert_service.dart   3 hardcoded `if`s (see §8)
├── screens/
│   ├── welcome_screen.dart · login_screen.dart · forgot_password_screen.dart
│   └── admin/                    17 screens (4 unreachable)
├── theme/    app_theme.dart · theme_provider.dart   (identical copies of the mobile app's)
└── widgets/
    ├── mini_chart.dart          ⭐ 357 LOC — the best code in either repo
    ├── glass_card.dart          82 lines BEHIND the mobile app's version
    └── image_source_sheet.dart  🗑️ Unused
```

### ⭐ `mini_chart.dart`

Four hand-rolled, zero-dependency chart widgets: `MiniBarChart` (animated, auto-highlights max), `MiniLineChart` (`CustomPainter`, cubic-Bézier smoothing, gradient fill, animated draw-on), `RingIndicator` (donut via `drawArc`), `AnimatedCounter` (unused).

**This is genuinely excellent original code.** Move it into `transit_core` — it is exactly what you need to visualize AI prediction accuracy in the demo and the report.

---

## 5. Roles & Permissions

Single role: **Admin**. No sub-roles, no permission tiers implemented (a "Role-Based Permissions" menu item exists but is a SnackBar stub).

| Capability | Status |
|---|---|
| View fleet KPIs | 🔶 UI only — hardcoded numbers (dashboard not in scope this pass) |
| Manage students / parents / drivers | ✅ Real Firestore lists (`Db.students`/`watchUsersByRole`/`watchDrivers`), search works; edit forms save for real |
| Approve / reject drivers | ✅ Writes `Driver.status`; document-level verify/reject writes `DriverDocument.status`+`rejectionReason` |
| Message a driver / parent / student about an issue | ✅ New — writes to `notifications/{uid}/items` via `MessagingRepository`, appears in the mobile app's inbox immediately |
| Edit a parent's or student's account details | ✅ New — inline edit form on each detail screen, writes `users/{uid}` / `students/{id}` |
| Manage routes / vehicles / fees | 🗑️ Screens exist but are unreachable — unchanged |
| Handle incidents & SOS | ❌ Service exists, no UI, no subscribers — unchanged |
| Audit logging | ❌ In-memory only; "Audit History" shows a SnackBar — unchanged |
| Subscription & billing | 🔶 UI only — unchanged. Note: `transit_core`'s `Student`/`AppUser` schema has no per-parent billing concept, so the old `ParentRecord` billing UI (plans, invoices, payment history) was **removed**, not wired, when `AdminParentDetail` was rewritten — it modeled data that doesn't exist in the real schema. A real payment history view would read the `payments` collection instead; not built here |

**Planned:** admin role must be a Firestore field + custom claim enforced by security rules, not a client-side string.

---

## 6. Screens

### Entry

| Screen | Route | Notes |
|---|---|---|
| `WelcomeScreen` | `/` | Animated splash; auto-navigates to `/login` after 4s |
| `LoginScreen` | `/login` | ⚠️ See §9 — fake auth with on-screen credentials |
| `ForgotPasswordScreen` | `/forgot-password` | ⚠️ Never calls `sendPasswordResetEmail` |

### Main shell — `AdminLayout` (`/admin`), 5 tabs

| # | Screen | Purpose | Data | Actions |
|---|---|---|---|---|
| 0 | `AdminDashboard` | Command center — 6 stat tiles, subscription bars, `MiniBarChart`, 3 `RingIndicator`s, 4 `MiniLineChart`s, alerts | **100% hardcoded**: `'486'` students, `'312'` parents, `'24'` drivers, `'₨4.2L'` MRR; chart arrays `[320,380,350,420,390,460]` — unchanged this pass | Bell → `/admin/notifications` is the only working action |
| 1 | `AdminStudentManagement` | Student list | ✅ Real: `AdminRepository.watchStudents()` | ✅ Search works (client-side). Tap → detail |
| 2 | `AdminParentManagement` | Parent list, children summary | ✅ Real: `watchUsersByRole(UserRole.parent)` + `watchStudents()` grouped by `parentId` | ✅ Search works |
| 3 | `AdminDriverManagement` | Driver list, ratings | ✅ Real: `AdminRepository.watchDrivers()` | ✅ Search + status filter (All/Pending/Online/Offline/On Trip/Suspended) |
| 4 | `AdminProfile` | Profile & settings | All literals — unchanged | ✅ Theme toggle persists. **9 SnackBar stubs** — unchanged |

### Detail & secondary

| Screen | Route | Notes |
|---|---|---|
| `AdminStudentDetail` | `/admin/student-detail` | ✅ Real: live `Student` doc via `watchStudent(id)`. Edit form (name/grade/school/medical notes) saves to Firestore. Suspend/re-enable and Message actions are real. The 4 history tabs (Attendance/Trip/Missed/Access) are still illustrative mock rows — no attendance/trip data source wired |
| `AdminParentDetail` | `/admin/parent-detail` | ✅ Rewritten as a real `StatefulWidget`: live `AppUser` doc, edit form (name/phone/email) saves, children list is real (`students` where `parentId == uid`, tap → student detail), Activate/Deactivate + Message actions are real. The old billing/subscription/payment-history UI was removed (no such schema exists — see §5) |
| `AdminDriverDetail` | `/admin/driver-detail` | ✅ Rewritten: live `Driver` doc, real Approve/Suspend (writes `status`), real Compliance Documents section (`watchDriverDocuments`, latest per `DocumentType`) with View/Verify/Reject — Reject prompts for a reason and messages the driver. Message Driver action is real. Performance bars now derive from real fields (`reliabilityScore`, `rating`, harsh-braking/over-speed counts) instead of hardcoded 92/88/95%. The 4 history tabs (Trip/Attendance/SOS/Earnings) are still illustrative mock rows |
| `AdminNotifications` | `/admin/notifications` | ⚠️ Review/Open/Approve chips are `Container`s with **no `onTap` at all** — unchanged |
| `AdminSubscription` | `/admin/subscription` | 3 buttons → SnackBars — unchanged |
| `AdminUserDetailPage` | `/admin/user-detail` | Legacy, unreachable, untouched this pass |

> The 3 rewritten detail routes now take an id string via `extra` (e.g. `extra: driver.id`) and load their own data with a `StreamBuilder` — no more casting a whole mock object through navigation.

### 🗑️ Unreachable — imported by nothing (~2,084 LOC, ≈21% of `lib/`)

| Screen | LOC | Worth rescuing? |
|---|---|---|
| `admin_fees.dart` | 652 | ✅ Yes — fee management is core |
| `admin_students.dart` | 533 | ❌ Superseded by `AdminStudentManagement` |
| `admin_routes.dart` | 460 | ✅ Yes — route management is core |
| `admin_vehicles.dart` | 439 | ✅ Yes — fleet management is core |

---

## 7. Data Model / Schema

The shared Firestore schema is defined in the [mobile app README §8](../transit_Pro/transit_pro/README.md). This app is the **primary writer** for `routes`, `buses`, `drivers`, `students`, `incidents`, and `auditLogs`.

### Current model inventory

**`lib/models/`** — clean domain models, **no serialization on any of them**, used by no screen:

| Class | Key fields |
|---|---|
| `DriverModel` | `id, name, contactNumber, status, reliabilityScore, harshBrakingEvents, overSpeedEvents, documents[], incidentIds[], warnings[]` |
| `ComplianceDocument` | `documentType, expiryDate, fileUrl, isVerified` + `isExpired`, `expiresSoon` |
| `StudentModel` | `id, name, grade, assignedRouteId, assignedStopId, guardians[], subscriptionStatus, emergencyMedicalNotes, isTransportSuspended, consecutiveAbsences, missedBusHistory[]` + `canBoardBus` |
| `Guardian` | `id, name, relationship, contactNumber, photoUrl, isAuthorizedPickup` |
| `VehicleModel` | `id, licensePlate, capacity, status, nextMaintenanceDate, insuranceExpiryDate, currentMileage, isEngineIdle` |
| `RouteModel` | `id, routeName, stopIds[], currentState, activeVehicleId, activeDriverId, averageDurationMinutes, routeEfficiencyScore, estimatedFuelUsageLiters` — **no coordinates** |
| `IncidentModel` | `id, severity, title, description, timestamp, reportedByDriverId, associatedRouteId, isResolved, resolvedByAdminId, resolutionNotes` |

**`admin_user_models.dart`** (462 LOC) — presentation models the UI actually uses: `AdminUserRecord`, `StudentRecord`, `ParentRecord`, `ParentChildRecord`, `DriverRecord`, `AlertItem`, `SubscriptionPlanConfig`. All embed `Color`/`IconData` and string dates.

### Migration required (Phase 1, ~2 weeks)

1. Move domain models to `transit_core`; add `toJson`/`fromJson`.
2. Delete the duplicate enums; keep one definition per concept.
3. Convert string dates to `DateTime`, money to `int` paisa.
4. Split presentation: keep `Color`/`IconData` in a UI mapping layer, not the model.
5. Point every screen at the unified models.

---

## 8. `SmartAlertService` — Foundation for the AI Feature

**Today it is a rules engine with three hardcoded `if` statements and zero callers.** Not AI. No model, no inference, no statistics.

```dart
if (assignedStudentsCount > vehicle.capacity)   // → medium
if (vehicle.needsMaintenance)                   // → high
if (vehicle.needsInsuranceRenewal)              // → critical
if (overSpeedEvents > 3)                        // → safety warning
```

`analyzeDriverTelemetry()` accepts a `harshBrakes` parameter that is **never used**.

The UI oversells it further: `admin_routes.dart` shows a "🤖 AI Route Optimization — 3 routes can be optimized to save 22 min total" card whose "Optimize" button is a `Container` with no `onTap`.

**But the shape is right** — a broadcast `Stream<SmartAlert>` with `IncidentSeverity` levels is exactly the right plumbing. Phase 3 fills it in:

- Route-deviation detection (distance from route polyline beyond threshold)
- Unscheduled stop detection
- Harsh speed-change detection from the real GPS stream
- Predicted late arrival → proactive parent alert
- Then: a small regression on real pilot trip data for ETA prediction

Pair with `mini_chart.dart` to visualize accuracy in the demo and the report.

---

## 9. ⚠️ Security — Must Fix Before the Pilot

**Updated 2026-09-01 — login is real, the route guard still isn't.**

| Issue | Detail |
|---|---|
| **No route guard** | ⚠️ Still true — `router.dart` has no `redirect`. Navigating straight to `/admin` (or any `/admin/*` route) still bypasses login entirely; login only gates *how you'd normally get there*. This is the one security item from this list not fixed this pass — add a `redirect` mirroring the mobile app's `router.dart` guard (`transit_pro/lib/app/router.dart`), checking `FirebaseAuth.instance.currentUser` |
| **Fake login** | ✅ Fixed — `AuthService.signInWithEmail` calls `signInWithEmailAndPassword`, then requires `Db.users.doc(uid).get()` to have `role == UserRole.admin` (throws `NotAnAdminException` and signs back out otherwise). The old `Future.delayed` + unconditional `saveRole('admin')` is gone |
| **Credentials on screen** | ✅ Fixed — the "📋 USE DEMO ACCOUNT" tile and `_fillDemo()` are removed |
| **Logout doesn't log out** | Not touched this pass — verify `AuthService.signOut()` (which does call `_firebaseAuth.signOut()` + `clearRole()`) is actually wired to the logout button before relying on it |
| **Broken role mapping** | Not touched this pass — `routeForRole()` still has no `'admin'` case; irrelevant today since login always lands on `/admin` directly, but worth fixing if that ever changes |
| **Fake password reset** | Not touched this pass — still no `sendPasswordResetEmail` call |
| **No security rules** | Not this app's rules to add — `firestore.rules` lives in `transit_pro/` and already has full `isAdmin()` support for every collection this app now reads/writes (`users`, `drivers`, `documents`, `students`); verified before wiring, no rule changes were needed |

**Required before pilot:** the router `redirect` guard (only remaining item above), an actual `role: admin` Firebase Auth account + Firestore doc for real login to be testable at all (nobody here can create one — needs the project owner, via Firebase console), logout wiring, password reset.

---

## 10. Setup & Run

```bash
cd transit_admin
flutter pub get
flutter run
```

No API keys required today — the app has **no maps and no network calls**. Firebase init failure is caught and ignored.

Firebase project **`transitpro-db`**, sender `231263449779`, already configured for all platforms.

### Repo hygiene

Root-level one-off codemod scripts left behind: `fix_icons.dart`, `fix_all_icons.dart`, `fix_icons.py` — delete them.

`test/widget_test.dart` contains one boilerplate smoke test asserting `find.text('Admin Login')`.

---

## 11. Roadmap

Aligned with the [mobile app roadmap](../transit_Pro/transit_pro/README.md#10-roadmap). 12 weeks, solo.

### Phase 0 — Unblock (Week 1)
- [ ] Regenerate the colliding web `appId`
- [x] Create `transit_core`; depend on it from this app — **done 2026-09-01**. `mini_chart.dart` and `glass_card`/theme are **not yet** moved into it (still admin-local copies)
- [ ] Sync `glass_card.dart` forward (this copy is 82 lines behind — missing `GradientButton.isEnabled`)
- [ ] Decide fate of the 4 unreachable screens (recommend rescuing fees, routes, vehicles)
- [ ] Remove the remaining unused dependencies and the 3 codemod scripts
- [ ] Delete or wire `ServiceLocator`

### Phase 1 — Real identity & real data (Weeks 2–5)
- [x] Real Firebase email/password auth — **done 2026-09-01**; demo tile removed
- [ ] Router auth guard — **still open**, see §9. Admin role is enforced at login (`role == UserRole.admin` check) but not by a route guard
- [ ] Unify the two model systems into `transit_core` (see §7) — **done for driver/parent/student screens only**; dashboard/fees/routes/vehicles/subscription still use `admin_user_models.dart`
- [x] Replace hardcoded lists with Firestore `snapshots()` — **done for driver/parent/student management + detail**; dashboard/fees/routes/vehicles/subscription still hardcoded
- [x] Make writes real: approve/reject driver, suspend student — **done 2026-09-01**, plus a new "message user" action neither this list nor the original scope anticipated. Assign route/vehicle — **not done**, out of scope this pass
- [ ] Wire `AuditService` to a Firestore `auditLogs` collection

### Phase 2 — Operations (Weeks 6–8)
- [ ] Live dispatch map — all active buses from RTDB
- [ ] Wire `EmergencyService` to real SOS events from the driver app
- [ ] Route/stop editor writing real coordinates (`RouteModel` has none today)
- [ ] Document verification with Firebase Storage

### Phase 3 — AI (Weeks 9–10)
- [ ] Implement `SmartAlertService` for real (see §8)
- [ ] Admin-facing alert feed with severity triage
- [ ] Visualize prediction accuracy with `mini_chart.dart`

### Phase 4 — Pilot hardening (Weeks 11–12)
- [ ] Security-rules audit · Crashlytics · seed real school data · widget tests

---

## 12. Open Decisions

| # | Decision | Status |
|---|---|---|
| 1 | Rescue or delete the 4 unreachable screens | ⏳ Open — recommend rescuing fees, routes, vehicles; delete `admin_students` |
| 2 | Sub-roles / permission tiers (super-admin vs operator) | ⏳ Open — UI hints at it, nothing implemented |
| 3 | Admin as mobile-only, or also Flutter Web? | ⏳ Open — a fleet dashboard is more natural on a large screen, and web deploy is free on Firebase Hosting |
| 4 | Keep `core/di`, or drop it for plain singletons matching the mobile app? | ⏳ Open — consistency across the two apps matters more than the pattern |
| 5 | Standalone admin app is the only admin surface | ✅ **Decided 2026-08-08** |

---

## 13. Project Facts

| Metric | Value |
|---|---|
| Dart files in `lib/` | 37 |
| Lines of Dart | ~12,200 |
| Screens | 20 (4 unreachable) |
| **Dead code** | **≈21% of `lib/`** — 2,084 LOC screens + 346 LOC services + 203 LOC models/enums/DI |
| Unused dependencies | 8 |
| Things that persist across restart | **2** — role string, theme boolean |
| Tests | 1 boilerplate smoke test |
| Firebase project | `transitpro-db` (shared with the mobile app) |

---

## 14. For a Fresh AI Session — Start Here

1. This is the **admin app**, one of **two** Flutter apps. The mobile app is at `../transit_Pro/transit_pro`. Separate folders, separate repos, **one shared Firebase project** (`transitpro-db`), and now a **shared `transit_core` package** both depend on.
2. **No longer a pure UI mock.** Driver/parent/student management + detail screens, and admin login, are real — live Firestore reads/writes through `transit_core`'s `Db`, real `firebase_auth`. Everything else (dashboard, fees, routes, vehicles, subscription, the 4 unreachable screens) is still hardcoded literals — check the tables in §6 for which is which before assuming either way.
3. **`core/`, `models/`, and `services/` are imported by zero screens.** Do not assume the "enterprise" layer does anything — `ServiceLocator` is never initialized and would throw.
4. `admin_user_models.dart`'s presentation models are **still used by the untouched screens** (dashboard/fees/routes/vehicles/subscription) — leave them alone unless you're migrating those screens too. The driver/parent/student screens no longer import it at all; they use `transit_core`'s `AppUser`/`Driver`/`Student` directly. Read §7 before touching either.
5. **Security is improved but not complete** (§9): login is real and role-checked, but `router.dart` still has no auth guard — `/admin` is reachable by URL/deep-link without signing in. Fix that before the pilot; this app manages real children's data.
6. The best assets here are **`mini_chart.dart`** (still not moved into `transit_core` — only `Db`/`MessagingRepository`/models are there so far) and the **`SmartAlertService` stream shape** (foundation for the AI feature).
7. Constraints: **solo developer, ~12 weeks, no budget beyond essentials, real pilot at a confirmed school.**
