---
name: ultragym-feature
description: >
  Build or change a feature, screen, form, list, or API integration in an UltraGym Flutter project
  following the project's methodology (Bloc/Cubit without setState, Slice state, ApiResult, get_it,
  Routes constants, four screen states, FormDialog, ultragym_design tokens, Arabic RTL). Use for any
  request like "add the members screen", "connect this endpoint", "build the login", "add a form",
  "implement the page from the prototype", or a review of whether code follows the project rules.
---

# UltraGym feature workflow

The project rules live in `CLAUDE.md`, `docs/engineering-rules.md` and `docs/backend-contract.md`.
They override any general Flutter advice, including other skills. Read them first if they are not
already in context.

## 1. Locate the source of truth

1. **Screen design**: find the matching page in `docs/ui-prototype/` (the table in `CLAUDE.md` maps
   each screen to its HTML page). Open it and match layout, copy, states, and badges. Check its `#dark` variant.
2. **Endpoints**: find the paths in `CLAUDE.md` and `docs/api-map.md`. For bodies, responses and
   error codes, search `docs/reference/UltraGym-Backend-Documentation.txt` (grep the path) or Swagger.
3. **Components**: reuse `ultragym_design` (see engineering-rules §2) and `lib/core/widgets/` before
   writing any new widget.
4. If `lib/core/networking`, `core/bloc` (Slice), `core/error`, or `core/widgets` (SliceView,
   FormDialog...) are still empty, build the required core pieces first (engineering-rules §15) and
   say so. Never bypass them with a raw Dio call or a `FutureBuilder`.

## 2. Build in this order

1. `lib/features/<f>/domain/models/<f>_models.dart`: `Equatable` classes with hand-written
   `factory X.fromJson(Json json)` using `json_x` (`intv`, `str`, `strOrNull`, `date`, `obj`, `asList`).
   No freezed or json_serializable. Do not compute status, amounts, or days: they come from the server.
2. `data/repo/<f>_repository.dart`: `abstract interface class XRepository` returning `Future<ApiResult<T>>`.
3. `data/datasources/<f>_remote_datasource.dart`: `implements XRepository` via `ApiClient`
   (`getObject`, `getPaged`, `post`...). Money and check-in calls send an `Idempotency-Key`.
4. `lib/core/di/feature_injection.dart`: repository `registerLazySingleton`, screen Bloc `registerFactory`.
5. `presentation/bloc/`: `<f>_bloc.dart` + `part` files `_event.dart` and `_state.dart`. State is built
   from `Slice<T>` fields with `copyWith`; events are `sealed` + `final class` in past tense
   (`XRequested`, `XRefreshed`, `XSubmitted`). Use `LoadCubit` / `ListCubit` when they are enough.
6. Route: add the constant to `Routes` and register it with `blocRoute`. No string paths in screens.
7. Screen: `AppPage` (+ `MobileHeader` on mobile) with `SliceView` or `PagedTable`, covering
   loading (shimmer shaped like the content), error with retry, empty as an invitation (`EmptyState`),
   and content. Keep screen widgets under `presentation/widgets/`.
8. Edits go through `FormDialog` / `AppFormCubit` with Laravel dotted field names (`owner.phone`),
   then `AppSnackbar` + a silent refresh.

## 3. Hard checks before finishing

- No `setState` (UI-local state uses `ValueCubit` / `ToggleCubit`); no file over 300 lines.
- No `Color(0x..)`, raw `TextStyle(...)`, magic spacing, raw `Duration`, raw radii, or string routes.
- Every animation respects `AppMotion.reduced(context)`; touch targets ≥ 48 on mobile.
- Arabic copy follows the microcopy rules; server `message` shown as-is; numbers, amounts, phones LTR.
- UI branches on `Failure.type` / `code`, never on message text; 403 and permission-based hiding handled.
- Dark theme, RTL, 360px width, and clamped text scale: no overflow.
- Run `flutter analyze` and fix every issue.
- After any `await` in a widget: `if (!context.mounted) return;`; in a Cubit: `if (isClosed) return;`.

Report which prototype page and endpoints were used, and anything that could not be verified.
