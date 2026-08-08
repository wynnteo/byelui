# ByeLui

Daily expense tracker for you and your family — sibling app to MyLui, same
design system, coral/amber accent instead of cyan.

## Getting started

This scaffold was built without a Flutter SDK available, so the Hive
adapter files (`*.g.dart`) referenced by the models are not generated yet.
Run these steps locally:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

This generates `category.g.dart` and `transaction.g.dart` from the
`@HiveType`/`@HiveField` annotations in `lib/models/`.

## Latest update

- **Delete a transaction** — open it from any list, tap the trash icon in
  the top-right of the edit screen, confirm. Also deletes its attached
  receipt photo from disk.
- **Categories can be edited and deleted** — tap any category in
  Categories (or the edit pencil) to rename it / change its icon / change
  its color, including default categories (defaults still can't be
  deleted, only edited). Deleting a category that has existing
  transactions asks for confirmation first; those transactions aren't
  deleted, they just show without a category icon afterward.
- **All transactions now pages by month** (prev/next arrows, same pattern
  as Analytics) instead of one long scrolling list, with an income/expense
  total for the visible month. Typing in the search box switches to an
  all-time search across every month instead.
- **Tags weren't saving** — almost certainly a stale generated Hive
  adapter. Any time a model file changes (like adding `tags` to
  `Transaction`), you must rerun:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
  Tags are also now shown directly on each transaction card so you get
  visual confirmation they saved.

## What's included (MVP + updates)

- `lib/theme/app_theme.dart` — coral/amber design system matching MyLui's structure
- `lib/models/` — `Transaction` (with `tags`), `Category`, `RecurringTransaction`, `Budget` Hive models
- `lib/services/data_service.dart` — CRUD, currency conversion, monthly + yearly
  totals/trend, category breakdown, recurring-transaction generation, smart tag
  suggestions, tag spend breakdown, budgets, month-over-month/year comparison
- `lib/services/photo_service.dart` — camera/gallery capture
- `lib/widgets/` — `GlassCard`, `TransactionCard`, `ScopeToggle`, `BannerAdWidget`,
  `category_picker_dialog.dart` (name + icon + color picker, reused by the
  category quick-add and the Categories screen)
- `lib/screens/`
  - `home_screen.dart` — monthly summary, scope filter, recent transactions
    with a **See all** link, bottom banner ad, links to Recurring and Settings
  - `transaction_form_screen.dart` — add/edit with category picker (+ inline
    **New category** with icon/color), scope toggle, date picker, photo
    capture, **tags** (manual entry + auto-suggested from the description,
    e.g. typing "Shopee" or "kopi" suggests a tag)
  - `all_transactions_screen.dart` — full transaction list, **search** across
    description/note/tags/category/amount, category + scope filters, grouped
    by month
  - `analytics_screen.dart` — This month / This year toggle, **month
    navigation** (prev/next arrows), **month-over-month or vs-last-year
    comparison** with % change, income/expense chart, category pie chart
  - `categories_screen.dart` — manage categories with icon/color
  - `recurring_screen.dart` — add/edit/pause recurring transactions
  - `budgets_screen.dart` — set a monthly limit per expense category,
    progress bar, over-budget highlighted in red
  - `tag_insights_screen.dart` — spend breakdown by tag, This month / This
    year / All time
  - `settings_screen.dart` — base currency, links to Recurring, Budgets,
    Tag insights, Categories

## Smart tag suggestions

`DataService.suggestTags()` matches the transaction description against a
keyword → tag map (`shopee`→Shopee, `kopi`/`teh`/`coffee`→Coffee/Tea,
`boba`/`bubble tea`→Bubble tea, `netflix`/`spotify`→Subscriptions, etc.),
shown as tappable chips on the add/edit screen. Extend the list by calling
`DataService().addTagKeyword('keyword', 'Tag Name')`, or add a settings UI
for it later — it's stored under the `tagKeywords` settings key so it
already persists.

## Not yet done — next steps

- **Multi-language (EN/中文)** — MyLui's `l10n/` ARB + `AppLocalizations`
  approach needs proper Flutter l10n codegen (`flutter gen-l10n`), which is
  a bigger lift than a quick copy-paste since every hardcoded string in
  ByeLui's screens needs to be extracted into ARB keys first. Worth doing
  as its own pass — happy to do it next if you want.
- PIN lock / biometric screens (copy from MyLui's `security_service.dart` /
  `biometric_service.dart`)
- In-app purchase / premium unlock flow (the `isPremium` flag exists in
  `DataService` to hide the banner ad, but nothing sets it yet)
- Data export (CSV/PDF)
- Home-screen widget
- App icon / launcher icon assets are still MyLui's placeholders —
  replace `assets/icons/app_icon.png` and `android/app/src/main/res/mipmap-*/`

Renamed from MyLui's `com.cloudfullstack.mylui` to
**`com.cloudfullstack.byelui`** (namespace + applicationId in
`android/app/build.gradle.kts`, Java package under
`android/app/src/main/java/com/cloudfullstack/byelui/`). `MainActivity`
was simplified — MyLui's home-screen net-worth-widget channel code
(`AccountUpdateWidgetReceiver`, `WidgetActionReceiver`, widget layouts/drawables)
was stripped since it's specific to that app; add ByeLui's own widget later
if you want one.

## iOS bundle identifier

`ios/Runner.xcodeproj` still has MyLui's bundle identifier
(`com.cloudfullstack.mylui` or similar) baked into the Xcode project file,
which is risky to hand-edit as raw text. Open the project in Xcode and
change **Runner target → Signing & Capabilities → Bundle Identifier** to
something like `com.cloudfullstack.byelui` before building for iOS —
`Info.plist`'s camera/photo usage strings are already added for you.

The AdMob app ID in `AndroidManifest.xml` is currently Google's **public
test ID** (`ca-app-pub-3940256099942544~3347511713`) — replace it with
ByeLui's real AdMob app ID once you register the app in AdMob, and swap
the placeholder ad unit ID in `lib/widgets/banner_ad.dart` too.

**Signing**: the release `signingConfig` was left as a TODO — do not reuse
MyLui's keystore/credentials for ByeLui. Set up a separate release
keystore before publishing.

## Not yet ported from MyLui (copy over when ready)

- PIN lock / biometric screens (`pin_lock_screen.dart`, `biometric_screen.dart`,
  `security_service.dart`, `biometric_service.dart`)
- EN/中文 localization (`l10n/` ARB files + `AppLocalizations` delegate)
- In-app purchase / premium unlock flow (the `isPremium` flag exists in
  `DataService` to hide the banner ad, but nothing sets it yet)
- Data export (CSV/PDF)
- Home-screen widget
- App icon / launcher icon assets are currently copied from MyLui as
  placeholders — replace `assets/icons/app_icon.png` and the
  `android/app/src/main/res/mipmap-*/ic_launcher.png` files

## Notes

- Exchange rates are static (matching MyLui's fallback table). Swap in
  MyLui's live-rate fetching from `DataService` if you want ByeLui's
  totals to use live rates too.
- Recurring transactions are materialized into real `Transaction` records
  by `DataService.generateDueRecurringTransactions()`, called once on
  every app start (`main.dart`). If you add app-resume handling later,
  call it there too so overdue items catch up while the app is backgrounded.
