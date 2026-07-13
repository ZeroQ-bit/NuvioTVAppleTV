# NuvioTV APK — Live Sweep & Exact Parity Diff (2026-07-07)

Captured from the **real APK v0.7.15-beta** running in the `Television_1080p` Android TV
emulator (`com.nuvio.tv`), driven screen-by-screen. This is the authoritative "what it
actually looks like and does" reference and the exact change list to make the tvOS port
(`~/Downloads/NuvioTV-AppleTV`) match. Screenshots in
`…/scratchpad/apk/` (01–27).

Legend: ✅ already matches · 🔧 change needed · ➕ missing, add · ❓ couldn't verify live.

---

## 0. Global: two experience modes

The whole settings surface has an **Experience mode: Essential ↔ Advanced** (Advanced
pane → "Switch to Advanced", with a confirm dialog). **Essential** = the simplified
surface most users see. **Advanced** = reveals full accordion settings (e.g. Playback
becomes General / Player & Stream Selection / Audio & Video / Subtitles / P2P sections).

➕ **The port has no experience-mode concept.** Add an Essential/Advanced toggle that
gates the depth of each settings pane. (Big structural item — can be phased.)

---

## 1. Sidebar navigation  🔧

APK (screens 02, 24): collapsed **icon-only** rail at the far left. On focus it
**expands rightward** to reveal **profile avatar + "Profile 2"** at top, then Home /
Search / Library / Settings as icon+label rows, and it **dims the content behind it**.
Focused item = translucent pill fill (rounded rect).

Port today: a **fixed-width always-labeled** column, no collapse, no dim.

🔧 Changes:
- Collapse to icons when unfocused; expand (labels + profile header) on focus.
- Dim/scrim the content while the sidebar is focused/expanded.
- Keep it reliable for tvOS focus (the earlier overlay attempt broke Right-into-content —
  do the expand without an overlay that steals focus).

---

## 2. Home screen  🔧

APK (screen 03), "Modern" layout:
- Hero: **logo** top-left, meta line **`Movie • Horror • 2026  [IMDb] 8.3`** (order:
  **type • genre • year • IMDb badge + rating**), then 3-line description.
- Row header format: **`Trending Movies - Movie`** = *catalog name* + ` - ` + *type*.
- The focused card is a large **landscape** card; there's a **"Landscape Posters"** toggle
  in Layout that switches Modern cards between portrait and landscape.
- Focus ring = accent (white here because White theme).

Port today: meta = `IMDb badge, year, runtime, genres`; row header = plain `Popular Movies`;
portrait cards only.

🔧 Changes:
- Meta line order/format → `Type • Genre • Year • IMDb badge rating`.
- Row header → `{Catalog Name} - {Type}`.
- ➕ Add the **Landscape Posters** option for Modern rows (portrait↔landscape).
- Verify hero backdrop gradient (APK darkens left ~45%, image on right).

---

## 3. Detail screen  🔧 (biggest visual gap after nav)

APK (screens 04, 06, 07): **full-bleed** backdrop, no sidebar.
- **Logo** large, vertically centered on the left.
- **Action row = circular icon buttons**: `▶ Play` (white **labeled** pill) · `+`
  (circular, add to library) · `⊘eye` (circular, mark watched) · `▶ YouTube` (circular,
  **trailer**). Port uses labeled "Add to Library"/"Mark Watched" and no trailer button.
- **`Director: <name>`** line under the buttons. Port has no director line.
- Description (3 lines).
- Meta line 1: **`Horror • Thriller • May 13, 2026 • [IMDb] 8.3`** (genres • **full release
  date** • IMDb). Meta line 2: **`1h 49m • United States • EN`** (runtime • **country** •
  **language**). Port shows none of country/language/full-date.
- **Auto-playing trailer**: scrolling/dwelling on the detail **plays the trailer as the
  background video** ("Press back to exit trailer"). Port opens trailers in a separate
  fullscreen player instead.
- Section header is a **tabbed** `Creator and Cast  |  Trailer`. Cast = circular headshots
  incl. **Director / Writer** entries plus actors with character names. Port has a "Cast"
  row (no Director/Writer, no tab).

🔧/➕ Changes:
- Rework action buttons to circular icon-only for +/watched; add the YouTube **trailer
  button**; keep Play as a labeled pill.
- Add **Director** line; add **country + language + full release date** to meta.
- ➕ **Auto-play trailer as the detail background** (major feature).
- Rename cast section to **"Creator and Cast"** with a **"Trailer"** tab; include
  Director/Writer in the cast row.
- Layout: center the logo vertically, buttons directly under it.

*(Note: this particular movie had no More-Like-This row; verify on a TMDB-rich title.)*

---

## 4. Streams / source selection  🔧

APK (screen 10): **split layout** — dimmed backdrop with **logo + meta on the LEFT**, a
**source panel on the RIGHT** (here: "No installed addon supports streams for 'movie'." +
**Retry**, because the emulator has no stream addons). Port uses a full-screen grouped
list.

🔧 Change: adopt the split layout (content info left, source list panel right).
❓ Couldn't see populated stream rows or the Player (no stream addons on the emulator).

---

## 5. Search + Discover  🔧 / ➕

APK Search (screen 11): a **top bar** = `[compass/Discover button] [mic/voice button]
[search field "Search movies & series"]`, empty state **"Start Searching / Enter at least
2 characters"**. Port uses native tvOS `.searchable` with no Discover/voice.

APK **Discover** (screen 12, opened from the compass): **Type / Catalog / Genre** dropdown
selectors + a source label (`Nuvio Catalog Addon • Movie`) + a **portrait-poster grid**
(paginated). Port has **no Discover screen** (deferred).

🔧/➕ Changes:
- Rebuild Search with the custom top bar + **Discover** button (+ voice if feasible) +
  the "Start Searching" empty state.
- ➕ Build the **Discover** screen: Type/Catalog/Genre dropdowns + paginated poster grid.

---

## 6. Library  🔧

APK (screen 13): title "Library" + **"NUVIO"** wordmark top-right; **`Saved` / `Cloud`
tabs**; **`Type` (All) / `Sort` (Added ↓)** dropdowns; empty state "No {type} yet / Start
saving your favorites to see them here". Port = plain poster grid, no tabs/filters.

🔧/➕ Changes: add Saved/Cloud tabs, Type + Sort dropdowns, the empty state, and the
wordmark.

---

## 7. Settings — rail & structure  🔧 (important)

APK rail (Essential), top→bottom: **Appearance, Layout, Content & Discovery, Integrations,
Playback, Trakt, About, Advanced**. **There is NO Account and NO Profiles category.**
(Profiles/account are handled via the sidebar profile avatar, not settings.)

Port rail today: Account, Profiles, Appearance, Layout, …. 🔧 **Remove Account + Profiles
categories; add Advanced (experience mode). Match the APK order.**

Rail pill styling ✅ largely matches (capsule, icon + title + chevron, accent focus). The
detail does **not** live-preview on focus — it opens on **click** (Center). Left from the
detail returns to the rail (anti-lockup) ✅.

### 7a. Appearance  🔧 (screens 01, 14 — Essential)
Sections: **Color Theme** (row of **swatch cards**: White ✓/Crimson/Ocean/Violet/Emerald/…
horizontally scrollable) · **AMOLED Mode** (toggle, "Use pure black for app backgrounds") ·
**Settings Style** (3 cards: **Default ✓ / Minimal / Top Bar**) · **Font and Language**
(App Font → **Inter ›**, App Language → **System default ›**).
Port has **only Color Theme** (as list rows).
➕ Add AMOLED Mode, Settings Style, Font, Language; render Color Theme as **swatch cards**.

### 7b. Layout  🔧 (screen 15)
"Layout Settings / Choose your home screen layout":
- **Home Layout** collapsible ("Open ▼") → 3 **visual wireframe preview cards**:
  **Modern ✓ / Grid / Classic** (mock diagrams, not text rows).
- **Landscape Posters** toggle ("Switch between portrait and landscape cards for Modern").
- **Fullscreen Hero Backdrop** toggle.
Port: text rows for layout + "Hide unreleased" + "Home Rows" reorder.
🔧 Make the layout picker **visual preview cards**; ➕ add Landscape Posters + Fullscreen
Hero toggles. (Home-rows reorder lives under Content & Discovery → Addons here, not Layout.)

### 7c. Content & Discovery  🔧 (screen 15b)
Single drill-in row: **Addons** — "Manage add-ons, catalog order, and collections" (→ opens
a sub-screen). Port inlines Collections + add-on install. 🔧 Make it a single **Addons**
drill-in that contains add-ons + catalog order + collections.

### 7d. Integrations  🔧 (screen 17)
Drill-in rows: **Connected Services** ("Experimental cloud account sources") · **TMDB**
("Metadata enrichment controls") · **MDBList** ("External ratings providers") ·
**Anime-Skip** ("Anime intro/outro skip timestamps"). **No Debrid here** and **no Trakt
here** (Trakt is its own rail item). Port has TMDB/MDBList/**Debrid** inline.
➕ Add **Connected Services** + **Anime-Skip**; make each a drill-in sub-screen;
❓ find where Debrid lives (likely Advanced-mode Playback → Player & Stream Selection, or
Connected Services).

### 7e. Playback  🔧 (screens 18 Essential, 26 Advanced)
Essential: **Playback basics** (Stream selection: Manual/auto · Auto-play next episode ·
P2P streams) + **Subtitles and audio** (Subtitle language "en" + audio…).
Advanced: full accordion — **General** · **Player & Stream Selection** (player pref,
auto-play, source filtering) · **Audio & Video** · **Subtitles** (language, style, render
mode) · **P2P Streaming**.
Port Playback = auto-play detail only (next-episode/still-watching/countdown/threshold).
🔧 Restructure to match: add **Stream selection**, **P2P**, **Subtitle language/style/
render**, **Audio** sections; fold existing auto-play controls under Player & Stream
Selection; gate the deep set behind Advanced mode.

### 7f. Trakt  🔧 (screen 19)
Opens as a **full-screen** page (not inside the workspace card): Trakt logo + description
on the left, **"Account Login"** card (Login / Back) on the right. Port renders Trakt as an
in-card pane. 🔧 Make Trakt a full-screen page.

### 7g. About  🔧 (screen 20)
NUVIO **logo** + "Made with ❤️ by Tapframe and friends" + **Version 0.7.15-beta** + rows:
**Check for updates** (external), **Privacy Policy** (external), **Supporters &
Contributors** (drill-in), + Licenses below. Port = version text only.
➕ Add logo, tagline, Privacy Policy, Supporters & Contributors, Licenses. (Check-for-
updates is N/A on the App Store.)

### 7h. Advanced  🔧 (screens 21, 24)
"Advanced / Performance, navigation, cache, and diagnostics": **Experience mode** (Switch
to Essential/Advanced) + **Performance & navigation** (Fast Horizontal Navigation, **Nuvio
Focus Scrolling**, Remember Last Profile, …) + cache + diagnostics. Port has none of this.
➕ Add an Advanced pane + the experience-mode toggle.

---

## 8. Dialogs  ✅ reference
Confirm dialogs (screen 23) = centered modal, title + body + two pill buttons (Cancel
focused white / action). Match this style for any confirmations.

---

## Priority order (highest visible impact first)
1. **Sidebar**: collapse-to-icons + expand-on-focus + dim (§1).
2. **Detail**: circular buttons + trailer button + Director + country/language + auto-play
   trailer background + "Creator and Cast/Trailer" tabs (§3).
3. **Settings rail**: drop Account/Profiles, add Advanced, match order (§7).
4. **Appearance**: AMOLED + Settings Style + Font/Language + swatch cards (§7a).
5. **Library**: Saved/Cloud tabs + Type/Sort (§6).
6. **Search + Discover**: custom bar + Discover screen (§5).
7. **Home**: meta/row-header format + Landscape Posters (§2).
8. **Streams** split layout (§4); **Trakt** full-screen (§7f); **About** contents (§7g).
9. **Playback** restructure + **experience modes** (§0, §7e) — largest, phase last.

## Not verifiable on this emulator
- Populated **Streams** list + the **Player** UI (no stream addons installed).
- **Debrid** location in settings.
- **More Like This** on Detail (test a TMDB-rich title).
- **Profiles** management screen (reached via the sidebar avatar — not captured).
