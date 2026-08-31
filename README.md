# ByeLui

Daily expense tracker for you and your family — sibling app to MyLui, same
design system, coral/amber accent instead of cyan.

## Getting started

## Latest update — All Transactions filter redesign

The filter bar had grown cluttered (search + scope toggle + category chips
+ Today chip + month pager, all stacked). Reworked into:

- **Search bar** stays visible at top (spans all time when you type).
- **One "Filters" pill** opens a bottom sheet with everything: Type
  (All/Income/Expense), Who (All/Personal/Family), Period (Today/This
  week/This month/This year/All time/Custom range), and Category — Apply
  commits them all at once, Reset clears the sheet.
- **Compact summary row** underneath instead of a wall of controls: the
  Filters pill (highlighted when anything's active, with an X to clear),
  the current period label (with prev/next arrows only when "This month"
  is selected, since that's the only period where paging makes sense),
  and the income/expense totals for whatever's currently filtered.
- Income/Expense **type filter is new** — previously there was no way to
  see just income or just expense in this list.
- "This week" is Monday–Sunday of the current week.

`DataService.getTransactions()` gained a `type` parameter to support the
new Income/Expense filter.


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

## Latest update — 3 fixes

- **Tag autocomplete** — typing in the tag field on Add/Edit Transaction
  now shows a dropdown of existing tags that match what you've typed
  (separate from the description-based smart suggestions), tap to add.
- **Budget false-alarm bug fixed** — `budgetProgress` was comparing every
  budget's spend using whatever scope filter the *calling screen* had
  selected (e.g. Home's "All"), instead of that budget's own Personal/
  Family scope. A Personal-only budget could get flagged as over limit by
  combined Personal+Family spending. Now each budget is always evaluated
  against spend filtered by its own scope.
- **Biometric toggle now visible** — after creating a PIN for the first
  time, the screen used to pop straight back to Settings, so the
  biometric toggle (which only shows once a PIN exists) was never seen.
  `Settings → App lock` now stays on a management view after PIN
  creation, showing "PIN lock is on", the biometric toggle (or an
  explanation if biometrics aren't available on the device/emulator),
  Change PIN, and Remove PIN lock.

- **PIN + biometric lock** — `Settings → App lock` to set a 4–6 digit PIN;
  if the device supports biometrics, a toggle appears to also allow
  fingerprint/Face ID. The app shows a lock screen at cold start whenever
  a PIN is set (tries biometric first if enabled, falls back to PIN).
  Ported `security_service.dart` (PIN hashing, salted SHA-256, constant-time
  compare) and `biometric_service.dart` straight from MyLui since they're
  app-agnostic; `lock_screen.dart` and `pin_setup_screen.dart` are new,
  written for ByeLui's theme (MyLui's versions depend on its l10n system,
  which ByeLui doesn't have yet — see below).
  **Note:** currently only locks at cold start, not on app resume from
  background — see the comment on `AppLockGate` in `main.dart` for how to
  extend it with a `WidgetsBindingObserver` if you want lock-on-resume too.
- **Export to CSV/PDF** — `Settings → Export transactions`. Pick Personal/
  Family/All, a range (this month/year/all time/custom), and export —
  opens the native share sheet (`share_plus`) so you can save to Files,
  email it, AirDrop it, etc. CSV via the `csv` package, PDF via `pdf`
  (title, income/expense/net summary, then a full table).
- **Swipe gestures** on every transaction list (Home, All transactions) —
  swipe right to edit, swipe left to delete (with confirmation). New
  `widgets/swipeable_transaction_card.dart` wraps `TransactionCard`.
- **Inline recurring** — the Add Transaction screen now has a "Make this
  recurring" toggle (new transactions only) with a frequency picker right
  there, instead of requiring a separate trip to Settings → Recurring.
  The transaction you're saving becomes the first occurrence; the
  recurring rule's next due date is set one cycle ahead so it won't
  duplicate today's entry.
- **Budget insights** — Budgets screen now has a summary header (total
  spent vs. total budgeted this month, "On track"/"X close"/"X over"
  pill). Home screen shows a dismissive-free alert card when any budget
  is ≥80% or over its limit, linking straight to Budgets.

## Latest update — 5 fixes/features

- **PIN and biometric are now independent** (matches MyLui's actual
  pattern) — `Settings → Security` shows a biometric toggle and a PIN
  entry as two separate rows. Turn on biometric alone, set a PIN alone,
  or both — no more "must create a PIN before biometric appears."
  `PinSetupScreen` is back to a single combined form (current/new/confirm
  fields, Remove PIN button) instead of a multi-step wizard.
- **Backup & restore** — `Settings → Backup & restore`. Exports everything
  (transactions, categories, recurring rules, budgets, settings) as one
  JSON file via the share sheet; Import picks a file and replaces all
  local data after confirmation. This is what to use when switching
  phones. Receipt photo *files* aren't included, only the transaction
  data — noted on-screen.
- **Tag insights moved out of Settings** — it's still there, just
  reachable from Analytics → Top tags → See all instead, since it's more
  of an analysis view than a settings item.
- **Budgets screen now sorts categories with a budget set to the top**
  (highest % spent first), unbudgeted categories below alphabetically —
  no more scrolling past everything without a budget to find the ones
  that matter.
- **Recurring can now be set when editing, not just when creating** — the
  "Make this recurring" toggle appears on both Add and Edit. Editing an
  existing transaction and turning it on creates a new recurring rule
  starting from that transaction's date (there's no link back to "this
  transaction already came from a recurring rule," so it always creates
  a fresh one — worth knowing if you toggle it on repeatedly while
  editing the same transaction multiple times).

## Multi-language status

Still not built — this needs proper Flutter l10n codegen (`flutter gen-l10n`)
and every hardcoded string across ~15 screens pulled into `.arb` files. It's
a distinct, sizeable pass on its own (not something to bolt on alongside
other features without risking half-translated screens). Say the word and
I'll do it as a dedicated pass next.

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