# ShopSphere

A Flutter e-commerce catalogue app built on the public [DummyJSON](https://dummyjson.com) API,
created for the Prosessed Flutter Developer Intern assignment.

> **Status: source complete, not yet built or run.**
> The code and tests were written in an environment without the Flutter SDK or network access, so
> `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter build apk` have **not** been run.
> Treat everything below as "implemented, unverified" until you run the checks in
> [Getting started](#8-getting-started) and record the real results in
> [Testing](#9-testing).

## 1. Overview

Log in, browse a responsive product grid, search / filter / sort, open product details with
reviews, manage a persistent local cart, place a simulated order, and view your profile.

## 2. Screenshots

_Placeholders. Capture real screenshots from a device or emulator and add them here._

| Login | Home | Details | Cart | Profile |
|-------|------|---------|------|---------|
| _todo_ | _todo_ | _todo_ | _todo_ | _todo_ |

Demo video: _link to be added after recording_

## 3. Features

Implemented in code (unverified at runtime):

- Splash with session restore; login with validation, password toggle, loading state, inline invalid-credential error
- Tokens in `flutter_secure_storage`; **automatic access-token refresh + retry** (single shared in-flight refresh); failed refresh clears session and shows a session-expired message on login
- Product grid with skeleton loading, pull-to-refresh, infinite scroll (20/page, `limit`/`skip`), footer loader, duplicate guarding, stop at `total`
- Search (400 ms debounce, stale results ignored), horizontally scrolling category chips, sorting (price asc/desc, rating, title)
- Product details: image carousel + indicators, brand (nullable), price/discount, rating, stock status, reviews, quantity selector, add to cart, out-of-stock disabled, 404 "not found" state, hero animation
- Cart: add / remove / increment / decrement, subtotal / discount / total, live badge, persistence per user, empty state
- Checkout via `POST /carts/add`, loading state, success page, cart cleared **only** on success, preserved on failure, double-tap guard
- Profile via `GET /auth/me`, logout, route guard after logout
- Responsive: bottom nav (<600 dp), navigation rail (600–1024), master-detail home (>1024); text scale tolerant card heights

Not implemented (bonus): dark theme toggle, wishlist, offline cache, localization, golden/widget tests, CI workflow.

## 4. Technology stack

Versions in `pubspec.yaml` are minimum constraints written from memory; `flutter pub get` will resolve actual versions.

| Concern | Package |
|---|---|
| UI | Flutter + Material 3 |
| State / DI | `flutter_riverpod` |
| HTTP | `dio` |
| Routing | `go_router` |
| Secure tokens | `flutter_secure_storage` |
| Cart persistence | `shared_preferences` |
| Images | `cached_network_image` |
| Tests | `flutter_test`, `mocktail` |

Actual Flutter / Dart versions used: _fill in from `flutter --version` after your first run._

## 5. Architecture

Feature-first clean architecture. Data flows one way:

```
Widget → Notifier (Riverpod) → UseCase → Repository (interface, domain)
                                           ↑ implemented by
                                   RepositoryImpl (data) → DataSource → Dio
```

```
lib/
  core/        di, network (Dio, interceptors), error (Failure + mapper), storage, theme, utils, widgets
  features/
    auth/      data | domain | presentation
    products/  data | domain | presentation
    cart/      data | domain | presentation
    profile/   presentation
  shell/       responsive navigation shell
  app.dart  app_router.dart  main.dart
```

Rules followed: widgets never call Dio; domain has no Flutter/Dio imports; repositories are abstract in
domain; one configured Dio client; immutable state objects.

## 6. State management: Riverpod

Riverpod gives compile-safe dependency injection and testable state without `BuildContext`.
`Notifier`s hold immutable state objects with explicit statuses (initial / loading / success / empty /
failure / loading-more). Providers are trivially overridden with mocks in tests. It avoids the
boilerplate of Bloc while keeping logic out of widgets.

## 7. Error handling

All failures become a `Failure(type, message)` in `core/error/error_mapper.dart` (no internet, timeout,
400/401/403/404/5xx, parsing, unknown). Raw exception text is never shown. Every API screen has loading,
success, empty (where relevant) and failure states with a retry action.

- **401**: interceptor refreshes once and retries; concurrent 401s share one refresh; terminal refresh rejection clears tokens and routes to login with a message.
- **Load-more failure**: list stays; a footer retry button appears; no automatic retry loop.
- **Checkout failure**: cart untouched; snackbar with Retry.
- Logging is debug-only and prints method + path + status only (never headers, bodies, tokens).

Demonstrating errors (no permanent debug UI): server error — temporarily point a request at `/http/500`;
not found — open `/product/9999` (or edit the id in a tile); slow network — `GET /products?delay=3000`;
offline — enable airplane mode and pull to refresh.

## 8. Getting started

Prerequisites: Flutter stable (3.22+ recommended), Android SDK, a device/emulator on API 26+.

```bash
cd shopsphere
# 1) Generate the Android platform folder (not included in this source drop)
flutter create --platforms=android --project-name shopsphere /tmp/shopsphere_tmp
cp -r /tmp/shopsphere_tmp/android .
cp /tmp/shopsphere_tmp/.metadata . 2>/dev/null || true

# 2) Required Android edits
#    android/app/src/main/AndroidManifest.xml  → add inside <manifest>:
#        <uses-permission android:name="android.permission.INTERNET"/>
#    android/app/build.gradle(.kts)            → set minSdk to 26

flutter pub get
dart fix --apply        # resolves any const/lint suggestions
dart format .
flutter analyze
flutter test
flutter run
flutter build apk --release   # → build/app/outputs/flutter-apk/app-release.apk
```

No code generation is required.

## 9. Testing

```bash
flutter test
flutter test --coverage
```

49 test cases are written across 8 files (auth repository, product models and repository, product list
state, cart pricing, cart state/persistence, checkout, error mapping). **None have been run yet.**

Actual results: _fill in after running_ · Coverage: _fill in if measured_

## 10. Test credentials

```
Username: emilys
Password: emilyspass
```

## 11. Assumptions and trade-offs

- **Pricing**: `subtotal = Σ(price × qty)`, `discount = Σ(price × discount% × qty)` (each line rounded to cents), `total = subtotal − discount`. Product prices shown are the discounted unit price.
- **Search vs. category**: DummyJSON cannot combine them, so they are mutually exclusive (choosing one clears the other). Sorting applies to whichever is active.
- **Cart** is the source of truth locally, stored per user ID. Logout clears it from memory only; it returns when the same user logs in again.
- **Order** is simulated; DummyJSON does not persist it.
- Stale search results are ignored via a request counter rather than cancelling the HTTP request.
- A network failure during startup shows a retry screen instead of dropping the user to login.
- Cart items snapshot price/discount/stock at add time.

## 12. Author

_Your name · email · GitHub_

### AI assistance disclosure

The initial source and tests were generated with Claude (Anthropic) from a written specification. They
were not compiled or executed at generation time and must be reviewed, analysed and tested by the author
before submission.
