# NuvioTV — APK Settings & Navigation Chrome Spec (for exact tvOS parity)

Authoritative, self-contained spec for making the tvOS SwiftUI app's **navigation
chrome + Settings** look and behave EXACTLY like the Android TV APK
(`~/Downloads/myapp.apk`, v0.7.15-beta). Compiled from (a) the real APK running
in the `Television_1080p` Android TV emulator and (b) the Android source at
`~/Downloads/NuvioTV`. Any LLM can implement from this doc alone.

Repo to change: `~/Downloads/NuvioTV-AppleTV` (SwiftUI, tvOS). Key files:
`NuvioTV/NuvioTVApp.swift` (nav), `NuvioTV/Screens/SettingsView.swift`,
`NuvioTV/Theme/NuvioTheme.swift`.

---

## 0. Ground truth: what the real APK looks like

Screenshots captured live (2026-07-06) — described precisely:

- **Home screen**: a slim **vertical icon sidebar pinned to the far LEFT edge**
  (Home, Search, Library, Settings-gear — icons only when unfocused). Content
  (hero + poster rows) fills the rest. No top tab bar anywhere.
- **Sidebar focused**: it **expands rightward** into a panel showing, top-to-
  bottom: **profile avatar + profile name** ("Profile 2"), then Home / Search /
  Library / Settings each as **icon-in-a-rounded-box + text label**. The
  focused item has a **light translucent rounded-rect fill** (FocusBackground)
  and a focus-ring border.
- **Settings screen**: everything sits inside ONE **big rounded "workspace"
  card** (rounded rect, faint 1px border), inset ~32px from screen edges, on
  near-black. The left nav sidebar icons stay visible at the far left, OUTSIDE
  the workspace card. Inside the card: **left category rail** + **right detail
  pane**.
- **Category rail**: vertical stack of **rounded pill buttons** (capsule shape),
  ~56dp tall, full rail width, **dark fill on every pill**. Each pill = leading
  **icon** + **title** + trailing **chevron ›**. The **focused** pill has a
  **bright accent/white outline** (see §6 note — it's the accent color, which
  was White because the user picked the "White" accent theme) + slightly
  lighter fill. Long titles truncate ("Content & Disco…").
- **Detail pane**: **grouped rounded cards**. Each group = a rounded-rect card
  (18dp radius, faint border) containing a **section title** + **subtitle** +
  rows. Examples seen under Appearance: "Color Theme" (row of colored-swatch
  cards, selected = check), "AMOLED Mode" (single row + toggle switch),
  "Settings Style" (3 option cards: Default ✓ / Minimal / Top Bar), "Font and
  Language" (rows: App Font → Inter ›, App Language → System default ›). The
  **focused row/card gets a bright accent/white border**. Selected option =
  border + checkmark.

---

## 1. The three Settings styles (the APK is themeable)

`SettingsUiStyle` enum, chosen in Settings → Appearance → "Settings Style":
- **CLASSIC** = **"Default — Standard layout with cards"** ← **THE DEFAULT**
  (`MainActivity.kt:196 settingsUiStyle = SettingsUiStyle.CLASSIC`). This is
  what to match. Vertical left rail + workspace card + grouped detail cards.
- **ZEN** = "Minimal — Simple, flat layout". Vertical rail, flat (no workspace
  card), a thin accent bar marks the selected item, focus = FocusBackground fill.
- **HORIZON** = "Top Bar — Navigation tabs at the top". Horizontal top tab bar +
  detail below. (This is the style I mistakenly built first — it is NOT default.)

Match CLASSIC. Optionally expose the 3 styles later; not required for parity.

---

## 2. App navigation = LEFT icon sidebar (replaces the tvOS top TabView)

Source: `ui/components/SidebarNavigation.kt`. **Current tvOS app uses a top
`TabView` pill bar — that is WRONG. Replace with a left sidebar.**

### Structure
- A `Column` pinned to the **left edge**, `width = sizes.sidebar.expandedWidth`,
  `fillMaxHeight`, `background = BackgroundElevated`, padding `vertical=xl(24),
  horizontal=lg(16)`, item spacing `md(12)`.
- **Collapsed vs expanded**: unfocused → icons only (narrow); on focus the
  whole sidebar `onFocusChanged{ hasFocus }` sets `isExpanded = hasFocus` and
  animates `alpha 0→1` / width to expanded, revealing labels. (In the tvOS port
  the simplest faithful approach: a narrow icon-only rail always visible that
  animates wider + fades in labels when any item is focused.)
- **Top of sidebar**: app brand / profile. Source shows the app name uppercased
  in `Primary` color; the live Modern-home sidebar shows the **profile avatar +
  profile name** at top. Use the profile avatar + name (matches screenshots).
- Then the nav items.

### Nav items (`SidebarItem { route, label, icon }`), in order
1. **Home** — house icon
2. **Search** — magnifying-glass icon
3. **Library** — box/stack icon
4. **Settings** — gear icon

### Nav item styling (`SidebarNavItem`)
- `Card`, `fillMaxWidth`, `height = sizes.settings.railItemHeight` (56dp),
  shape = `RoundedCornerShape(sidebar.panelRadius/2)` (rounded rect, NOT full
  capsule).
- Content `Row`, `padding horizontal md(12)`, spacing `md(12)`:
  - **icon box**: `size = icons.xl - xs`, `clip(RoundedCornerShape(panelRadius/3))`,
    `background = SurfaceVariant`, centered `Icon` tinted `TextPrimary`,
    `size = icons.sm`.
  - **label**: `titleMedium`, color `TextPrimary` when focused/selected else
    `TextSecondary`.
- **Colors**: `containerColor` = `FocusBackground` when focused OR selected,
  else `Transparent`. **Border**: none normally; **focused → FocusRing border**
  (`strokes.focus` width), shape = NavItemShape.
- No scale on focus.

### tvOS wiring
- Replace `TabView { NavigationStack per tab }` in `NuvioTVApp.content` with
  `HStack(spacing:0) { Sidebar | selectedContent }`.
- `selectedContent` switches on the selected route (Home/Search/Library/Settings),
  each wrapped in its own `NavigationStack(path:)`.
- Sidebar is a `.focusSection()`; content is a `.focusSection()`. Left → sidebar,
  Right → content. Keep the per-tab `homePath/searchPath/libraryPath` from the
  current build.

---

## 3. Settings screen layout (CLASSIC)

Source: `SettingsScreen.kt` (the `else`/non-Horizon branch, ~L545-665) +
`SettingsDesignSystem.kt`.

```
Box(padding horizontal=xxl(32), vertical=xl(24)) {          // outer inset
  SettingsWorkspaceSurface {                                // the rounded card
    Row(spacing = lg(16)) {
      Box(width = 220.dp, fillMaxHeight) { RAIL }           // left category rail
      Box(weight = 1f, fillMaxHeight) { DETAIL }            // right detail pane
    }
  }
}
```

### 3a. Workspace surface (`SettingsWorkspaceSurface`, CLASSIC branch)
- `clip(RoundedCornerShape(containerRadius = 28dp))`
- `background = BackgroundElevated`
- `border(width = hairline(1dp), color = Border, shape = 28dp)`
- `padding(20dp)`
- (ZEN/flat styles skip the card and just pad md/sm.)

### 3b. Rail (left, `width = 220dp`)
- `LazyColumn`, `verticalArrangement = spacedBy(10.dp, CenterVertically)` (items
  vertically CENTERED in the rail).
- Vertical scroll indicators at the bottom edge.
- Focus: rail is a focus container; on gaining focus → focus the SELECTED
  category's button. Pressing **Right** (`onPreviewKeyEvent DirectionRight`) sets
  `allowDetailAutofocus = true` and lets focus move into the detail.
- Each item = `SettingsRailButton` (§4).

### 3c. Detail pane (right, `weight 1f`, `widthIn(max = 880dp)`, TopCenter)
- `AnimatedContent(targetState = selectedCategory)` with a horizontal slide
  (¼ width) + fade transition (in ~220ms, out ~180ms), direction = forward/back
  by category index.
- **Left key** in the detail (`onKeyEvent DirectionLeft`) → moveFocus(Left); if
  nothing there, set `allowDetailAutofocus = false` and **return focus to the
  selected rail button**. THIS is the anti-lockup guarantee: Left from the
  detail always goes back to the rail.
- Content = the selected category's pane, built from **grouped cards** (§5).

---

## 4. Rail button (`SettingsRailButton`) — exact spec

- `Card`, `fillMaxWidth`, `heightIn(min = railItemHeight = 56dp)`, vertical
  padding `xxs(2)` top+bottom (so ~10dp gaps overall with the column spacing).
- **Shape**: CLASSIC → `RoundedCornerShape(SettingsPillRadius = 999dp)` = full
  **capsule**.
- **Fill (`containerColor`)**: selected → `BackgroundCard`; unselected →
  `Background`. **`focusedContainerColor` = `BackgroundCard`.** (So every pill
  has a dark fill; focused/selected slightly lighter.)
- **Border**: selected (not focused) → `Border(hairline(1dp), FocusRing)`.
  Focused → `Border(xxs(2dp), FocusRing)`, pill shape. Unselected+unfocused →
  none.
- **`focusedScale = 1f` (NO scale on focus).**
- **Content** `Row`, `padding horizontal 18dp`, space-between:
  - leading group: `Icon` size 18dp, tint `TextPrimary` if selected||focused else
    `TextSecondary`; `Spacer 10dp`; **title** `titleMedium`, weight SemiBold if
    selected||focused else Medium, color `TextPrimary` if selected||focused else
    `TextSecondary`, marquee-on-focus, truncates otherwise.
  - trailing: `Icon(ChevronRight)` size 18dp, tint `TextTertiary`.
- **Behavior**: focusing a rail button DOES live-preview its detail (the live
  APK shows the focused category's detail). Clicking also opens + moves focus in.

---

## 5. Detail pane = grouped rounded cards

Every settings pane is a vertical scroll of **section groups**. A section group
is a rounded-rect **card** (radius `secondaryCardRadius = 18dp`, faint `Border`,
`BackgroundCard`-ish fill) containing:
- **Section title** (e.g. "Color Theme") — titleMedium/large, `TextPrimary`.
- **Section subtitle** (e.g. "Pick the accent color used across the app") —
  `TextSecondary`.
- **Rows** inside the card. Row types seen:
  - **Navigation row**: title + subtitle (left) + value + `ChevronRight`
    (right). e.g. "App Font … Inter ›".
  - **Toggle row**: title + subtitle (left) + **pill switch** (right). e.g.
    "AMOLED Mode".
  - **Slider row**: title + subtitle + a value stepper.
  - **Single-choice cards**: a `Row`/grid of selectable rounded cards, each with
    a title + description; selected shows an accent **border + checkmark** (e.g.
    Settings Style: Default/Minimal/Top Bar; Color Theme swatches).
- **Focus** on any row/card = **FocusRing border** (accent; thick), rounded to
  the row shape (`settingsRowShape()` = pill for CLASSIC). Fill →
  `settingsFocusFillColor()` = `FocusBackground` for CLASSIC.
- Up/down chevron affordances at top/bottom indicate vertical scroll.

Each pane's exact sections come from its `SettingsDetailPane` sub-composable —
e.g. Appearance = Color Theme + AMOLED Mode + Settings Style + Font & Language;
Playback = the autoplay/subtitle/etc. sections (already spec'd in the
post-play work). Rebuild each tvOS pane to use the grouped-card pattern.

---

## 6. Focus behavior & colors (CRITICAL)

- **Focus indicator = `FocusRing` border** (a colored outline), applied to rail
  pills, nav items, and detail rows/cards. `FocusRing = palette.focusRing`.
  **NOTE**: in the captured screenshots it looked WHITE because the user has the
  **"White" accent theme** selected (Color Theme → White), so `focusRing` ≈
  white. With other accents (Crimson/Ocean/Violet/Emerald) the focus outline is
  that accent color. So: **focus outline color = current accent's focusRing**,
  NOT hardcoded white. (The tvOS app already has per-theme `focusRing` in
  `NuvioTheme.swift` — use it.)
- Focus fill = `FocusBackground` (a dark tinted fill of the accent).
- **No scale** on focus for rail/nav items.
- **Anti-lockup**: rail and detail are separate focus regions. Right enters
  detail; **Left from detail always returns to the selected rail button**
  (explicit in APK; on tvOS use `.focusSection()` on both + it works).

---

## 7. Exact category list (rail order, titles, icons, subtitles)

From `SettingsScreen.kt` `SettingsSectionSpec` list. Order shown top-to-bottom.
(Experience/Advanced/Debug are mode-gated — omit unless building those features.)

| # | Category | Title (string) | Material icon | SF Symbol equiv | Subtitle |
|---|----------|----------------|---------------|-----------------|----------|
| — | EXPERIENCE | "Experience" | Tune | slider.horizontal.3 | "Essential or Advanced" *(gated)* |
| 1 | ACCOUNT | "Account" | Person | person.crop.circle | "Account and sync status" |
| 2 | PROFILES | "Profiles" | People | person.2.fill | *(profiles subtitle)* |
| 3 | APPEARANCE | "Appearance" | Palette | paintpalette.fill | *(appearance subtitle)* |
| 4 | LAYOUT | "Layout" | GridView | square.grid.2x2.fill | "Home structure and poster styles" |
| 5 | CONTENT_DISCOVERY | "Content & Discovery" | Explore | safari.fill | "Add-ons, plugins, catalogs, and discovery sources" |
| 6 | INTEGRATION | "Integrations" | Link | link | *(empty)* |
| 7 | PLAYBACK | "Playback" | PlayArrow | play.fill | "Player, subtitles, and auto-play" |
| 8 | TRAKT | "Trakt" | (trakt glyph svg) | checkmark.seal.fill | *(trakt subtitle)* |
| 9 | ABOUT | "About" | Info | info.circle.fill | "Version and policies" |
| — | ADVANCED | "Advanced" | Build | wrench.and.screwdriver.fill | *(gated)* |
| — | DEBUG | "Debug" | BugReport | ant.fill | *(gated)* |

The APK folds Add-ons + Catalogs + **Collections** into the single
**"Content & Discovery"** section (not separate top-level items).

---

## 8. Design tokens (exact values)

**Spacing** (dp): hairline=1, xxs=2, xs=4, sm=8, md=12, lg=16, xl=24, xxl=32,
xxxl=48, huge=56.

**Radii** (dp): full=999 (capsule), containerRadius=28 (workspace card),
secondaryCardRadius=18 (detail group cards). ZEN row=12, HORIZON row=10,
HORIZON group=16.

**Sizes** (dp): railItemHeight=56 (rail pill + nav item height).

**Colors** (default/dark; from `Color.kt`):
- `Background` = palette.background (near-black; AMOLED → pure black)
- `BackgroundElevated` = palette.backgroundElevated (workspace card + sidebar bg)
- `BackgroundCard` = palette.backgroundCard (rail pill fill, detail cards)
- `SurfaceVariant` = (nav icon box bg)
- `Border` = neutral750 (faint 1px borders)
- `TextPrimary` = white; `TextSecondary` = neutral400; `TextTertiary` = neutral600
- `Primary` = neutral500 (brand text); `Secondary`/accent = palette.secondary
- `FocusRing` = palette.focusRing (focus outline — accent-tinted; white for
  White theme); `FocusBackground` = palette.focusBackground (focus fill)
- **Accent themes** (Color Theme picker): White, Crimson, Ocean, Violet,
  Emerald (+ more, horizontally scrollable). Each sets secondary/focusRing/
  focusBackground. tvOS already has these palettes in `NuvioTheme.swift`.

**Typography**: Inter (default "App Font"; user-selectable). titleLarge (brand),
titleMedium (rail titles, nav labels), bodyLarge/Medium (rows).

---

## 9. Current tvOS build — what's WRONG and the fix list

Current `NuvioTV-AppleTV` state vs APK:

1. **App nav** — currently a floating top `TabView` pill bar. **FIX**: replace
   with the left icon sidebar (§2). Biggest single visual difference.
2. **Settings workspace card** — missing/too subtle. **FIX**: wrap rail+detail
   in a `RoundedRectangle(28)` filled `BackgroundElevated` + 1px `Border`, inset
   xxl/xl (§3a). NOTE: `AccountView` paints its own full-bleed background that
   hides the card — give panes transparent backgrounds so the card shows.
3. **Rail** — width was 340 (should be **220**), pills too short/tall variants.
   **FIX**: 220 width, 56dp pills, capsule, `BackgroundCard` fill always,
   `FocusRing` border (2dp focus / 1dp selected), no scale, icon18+title+chevron.
4. **Focus color** — was using accent inconsistently / white hardcoded. **FIX**:
   use `theme.palette.focusRing` (accent) for all focus outlines; fill
   `focusBackground`.
5. **Detail panes** — currently flat rows. **FIX**: rebuild each pane as grouped
   rounded cards (§5): a card per section with title+subtitle+rows.
6. **AccountView** — content centered. **FIX**: top-align inside a grouped card
   ("Account and sync status") like other panes.
7. Categories already corrected to §7 order/titles/icons (done 2026-07-06).

Implementation order (highest impact first): #1 sidebar → #2 workspace card →
#3/#4 rail+focus → #5 detail cards → #6 account.

---

## 10. How to drive the real APK for pixel comparison

- Emulator: `~/Library/Android/sdk/emulator/emulator -avd Television_1080p
  -no-snapshot -no-audio -gpu swiftshader_indirect &`
- adb: `~/Library/Android/sdk/platform-tools/adb`
- Install: `adb install -r -g ~/Downloads/myapp.apk`; launch:
  `adb shell monkey -p com.nuvio.tv -c android.intent.category.LAUNCHER 1`
- **Screenshot (reliable)**: `adb shell screencap -p /sdcard/s.png && adb pull
  /sdcard/s.png out.png` (`adb exec-out screencap` HANGS — don't use it).
- **Dpad keyevents**: 19=up 20=down 21=left 22=right 23=center. e.g. to reach
  Settings from home: Left (into sidebar) → Down×3 → Center.
- Skip login: on the QR screen, focus "Continue without account" (bottom-right)
  and Center. (Touch `input tap` does NOT work — TV apps are dpad-only.)
- tvOS sim CANNOT be driven by CLI (no remote input) — use `-settingsDemo`
  launch arg to jump straight to Settings for resting-state screenshots; focus
  states can't be scripted there.
