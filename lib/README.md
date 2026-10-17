# ShopSphere source structure

`main.dart` remains the existing application entry point. This scaffold adds no
runtime behavior. Empty folders contain `.gitkeep` files so Git preserves them;
remove each placeholder when real source files are added to its folder.

## Shared infrastructure

| Folder | Purpose |
| --- | --- |
| `core/networking/` | Shared HTTP client configuration, interceptors, and transport helpers. |
| `core/di/` | Dependency composition and provider wiring for infrastructure and features. |
| `core/errors/` | Shared failure types, exceptions, and error mapping conventions. |
| `core/theme/` | App themes, colors, typography, and design tokens. |
| `core/utils/` | Small reusable, feature-independent helpers. |
| `core/widgets/` | Reusable UI components shared across features. |

## Features

| Folder | Responsibility |
| --- | --- |
| `features/auth/` | Authentication and session flows. |
| `features/products/` | Product catalog and product details. |
| `features/cart/` | Cart items and cart operations. |
| `features/profile/` | User profile and account preferences. |

Each feature contains these layers:

| Layer | Purpose |
| --- | --- |
| `data/` | Data sources, serialization models, mappings, and implementations of domain repository contracts. |
| `domain/` | Plain Dart entities, repository contracts, and use cases when needed. |
| `presentation/` | Screens, feature-specific widgets, and UI state/controllers. |

Keep dependency direction inward: data and presentation may depend on domain;
domain must not depend on either layer, Flutter, or storage/network packages.
Presentation accesses data through domain contracts wired in `core/di/`.
The composition folder may import concrete implementations to connect them.
Other core folders should remain independent of individual features.
Keep feature-specific code within its feature; share through explicit contracts
rather than importing another feature's data or presentation internals.

Add deeper folders such as `models/`, `repositories/`, or `screens/` only when
implementation needs them. No placeholder Dart classes or extra packages are
required for this structure.
