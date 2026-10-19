# ShopSphere requirements audit

Project: `D:\ShopSphere`. All entries below describe source implementation,
not device or CI verification. Final analysis and tests are pending because
their execution requests were declined. No commit has been made.

| Section | Implementation |
| --- | --- |
| 3.1 Splash/auth | Session restoration and routing, validated username/password, visibility toggle, submit loading, POST /auth/login, secure access/refresh tokens, invalid-credentials message. Interceptor refreshes and retries once; terminal 401/refresh 403 clears session. |
| 3.2 Catalogue | Responsive cards, limit 20/skip pagination, footer loading/retry, pull-to-refresh, API categories, 400ms search debounce, price/rating/title sorting, loading skeletons and empty state. Preserves loaded products and rejects stale responses. |
| 3.3 Details | Carousel/indicator, optional brand, discounted price, rating, stock, description/reviews, quantity, out-of-stock disabling, dedicated 404 view, Hero animation. |
| 3.4 Cart | Add/remove/quantity, subtotal/discount/total, user-scoped persistence, live badges, POST /carts/add, success view and clear-on-success. Orders are simulated by DummyJSON. |
| 3.5 Profile | GET /auth/me, avatar/name/email/phone, logout clears tokens and cached user profile, expiration message. |
| 3.6 Themes | Persisted light/dark choice. |
| 3.6 Wishlist | Hearts on catalogue cards, Wishlist page via shop header and Profile, per-user local persistence. |
| 3.6 Offline | Bounded cache of 30 pages keyed by query/category/sort/offset/limit; network/timeout fallback, offline banner and retry. Cached categories/product details and user profile support browsing after restart with an existing stored session. A first login and checkout require connectivity. |
| 3.6 Localization | Persisted English/Hindi choice via translate icon on Login and Profile. App controls translated; DummyJSON product/category/review content remains as supplied. Hindi Material labels for common app controls. |
| 3.6 Tests | Existing widget/unit tests plus auth refresh, pagination, scroll preservation, cache, wishlist, and localization tests. New tests await execution. |
| 3.6 CI | GitHub Actions workflow for flutter analyze and flutter test, Flutter 3.44.4. Workflow has not run remotely. |

## Verification remaining

Run from this folder:

```powershell
flutter analyze
flutter test
flutter build apk --release
```

Verify release startup, Hindi layouts, online/offline recovery, wishlist persistence,
and expiry/logout on a device. Review changes and obtain approval before committing.
