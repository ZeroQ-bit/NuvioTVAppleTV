# NuvioTV Apple TV — Parity Roadmap

Goal: make the tvOS SwiftUI port (`~/Downloads/NuvioTV-AppleTV`) behave the same as the
Android APK (`myapp.apk`, source in `~/Downloads/NuvioTV`, `com.nuvio.tv`, 615 Kotlin files).

This file is the durable plan. It replaces the lost "sections 3-4" numbering from the
earlier LLM session — instead of guessing that numbering, this is a fresh, complete
audit + roadmap. Keep it updated as sections land (check the boxes).

> **See also `APK_SETTINGS_SPEC.md`** (root) — a separate spec (from an emulator-driven
> session) for **navigation chrome + Settings** parity. Tracked here as **Section 11**.

---

## Section 11 — Navigation chrome & Settings (from APK_SETTINGS_SPEC.md) 🟡

The APK uses a **left icon sidebar** (not a top tab bar) and a **Settings workspace card**
with a 220px capsule rail + grouped detail cards. Priority-ordered fixes:
- [x] **Left sidebar nav** — `Screens/SidebarNav.swift` replaces the top `TabView`.
      Collapsed icon rail that expands rightward on focus (overlay, no content reflow),
      profile avatar+name header, focus-driven tab selection, accent `focusRing` border.
      Verified in sim. NOTE: required a `clean build` after xcodegen (incremental build
      silently reused stale objects — top tab bar kept showing until clean).
- [x] **Settings workspace card** — rail+detail now sit in a 28dp `backgroundElevated`
      card w/ 1px `neutral750` border, inset. Verified in sim.
- [x] **Rail restyle** — 220px wide, 56dp capsule pills, `backgroundCard` fill (active) /
      `background` (inactive), no scale, icon+title+chevron, "Content &…" truncates. Verified.
- [x] **Focus color** — all rail/pill focus outlines now use `theme.palette.focusRing`
      (accent), not hardcoded white. Verified (crimson ring in sim).
- [x] **AccountView** — dropped its opaque full-bleed background + top-aligned so the
      workspace card shows through.
- [x] **Detail panes as grouped cards** — `SettingsGroupCard` (18dp rounded, title+subtitle
      + rows). Applied to Layout, Appearance, Integrations, Playback, Content & Discovery.
      (Account/Profiles/Trakt/About are single-purpose panes, left ungrouped.)
- [x] Category list/order/icons corrected (done in an earlier session).
- [x] **Fit fixes** — Home sidebar rebuilt as a clean fixed-width 2-column `HStack` of
      focus sections (the overlay approach broke tvOS Right-into-content; now the poster
      rows are reachable). Settings content clips to the workspace card (28dp `clipShape` +
      removed `scrollClipDisabled`) so scrolled rows no longer spill outside it; proportions
      tuned. Verified in sim.

**Section 11 DONE** (2026-07-07): sidebar nav, workspace card, 220 rail, accent focus,
account bg, grouped detail cards, and the Home/Settings fit fixes — all verified in sim.

---

## Audit result — what the port already has (baseline, DONE)

- **Home** — hero backdrop follows focus, addon catalog rows, Continue Watching row. *(one
  layout only)*
- **Search** — native tvOS search across search-capable catalogs.
- **Detail** — backdrop, logo, meta badges, **cast as a plain text line**, season picker,
  episode rows with progress.
- **Streams** — parallel fan-out to stream addons, grouped by addon, quality badges,
  torrent/`infoHash` streams filtered out.
- **Player** — dual engine (KSAVPlayer + KSMEPlayer/FFmpeg) with auto-failover, custom
  Nuvio controls, Infuse-style touchpad scrubbing, pause info overlay, ±10s skips,
  episodes/sources side panels, audio & subtitle **embedded** track selection, speed,
  aspect (fit/zoom/stretch), Continue Watching persistence.
- **Settings** — 10 categories: Account, Profiles, Appearance (7 themes), Layout,
  Collections, Add-ons, Playback, Integrations (Debrid/TMDB/MDBList label), Trakt, About.
- **Add-ons** — Cinemeta preinstalled, add by manifest URL / `stremio://`.
- **Collections** — custom catalog grouping (CollectionsStore, CollectionView).
- **Library** + **Watched** + **Progress** stores.
- **Profiles** — multiple profiles, PIN locks, avatars.
- **Trakt** — scrobble + sync. **Debrid** — HTTP link resolution. **TMDB** — Discover
  resolution for collection sources.
- **Nuvio Account** — device/OAuth login, QR login, cross-device sync manager.

## Audit result — the "section 3-4" question (RESOLVED)

There is no section doc or VCS history in the folder, but cross-referencing the build
history shows the earlier numbering was:
- **#1** core app + dual-engine player + Nuvio account/QR login
- **#2** profiles + PIN + avatars
- **#3** Collections + catalog/home-layout customization
- **#4** Integrations (TMDB + Debrid + Trakt)

**Sections 3-4 DID land in this folder** — confirmed present and functional:
`Core/CollectionsStore.swift`, `Core/HomeCatalogSettingsStore.swift`,
`Screens/CollectionView.swift`, `Screens/SettingsLayoutView.swift` (§3) and
`Core/TMDBService.swift`, `Core/DebridService.swift`, `Core/TraktService.swift`,
`Screens/SettingsIntegrationsView.swift`, `Screens/SettingsTraktView.swift` (§4).

So nothing from your other-LLM session was lost. The "baseline DONE" list above =
old sections 1-4. Everything below is the *remaining* work to reach APK parity.

Caveat carried over from build notes: §3/§4 compile but are **not runtime-verified**
(sync/TMDB/Debrid/Trakt need a real login + your own Debrid keys + the unresolved Trakt
`client_secret`). Verifying these live is folded into the relevant sections below.

---

## Missing vs the APK — the roadmap

Ordered by user-visible impact. Each section is independently shippable.

### Section 1 — Detail screen depth ✅ (COMPLETE 2026-07-06)
The single biggest visible gap — now at parity with the APK.
- [x] **Cast → Cast Detail**: cast row of circular headshots (TMDB), tappable through to
      a person filmography screen (`Screens/CastDetailView.swift`, `Route.person`).
- [x] **More Like This** row — TMDB recommendations/similar, opens nested Detail.
- [x] **Collection / "belongs to"** section — TMDB `belongs_to_collection`, shows the
      collection's other parts as a poster row.
      *(All three via new `TMDBService.detail(imdbID:type:)` enrichment; graceful Cinemeta
      fallback when TMDB can't map the id. Build + launch verified in tvOS sim.)*
- [x] **Trailers** section + playback — TMDB `videos` → "Trailers & More" row
      (`TrailerCard`, YouTube thumbnails). tvOS has no WebKit, so playback goes through
      **YouTubeKit** (SPM, `exactVersion: 0.4.8`): `TrailerResolver` extracts a
      natively-playable stream URL from the YouTube key → `TrailerPlayerView` (AVKit
      `VideoPlayer`, Menu to dismiss). Falls back to a "Trailer unavailable" state if
      extraction fails (YouTube can change and break the extractor).
- [x] **Comments** (Trakt comments) — public Trakt comments row (`CommentCard`, spoilers
      hidden until focus); no auth needed (api-key header). `TraktService.comments()`.
- [x] **Company logos** — TMDB `production_companies` logo row (`CompanyLogo`).
- [x] **Episode ratings** — per-episode TMDB rating badge on episode cards
      (`TMDBService.seasonEpisodes()`, `RatingBadge`, loaded per selected season).
- [x] **Release-date formatting** — localized long-date helper (`DateFormat.releaseDate`),
      shown as the episode caption when no overview; better TMDB stills used as fallback.

**Section 1 is complete.** Verified via `-detailDemo` launch arg (jumps to a Detail
screen for tt0111161): backdrop/logo/rating/description, Trailers row, Cast row all render
in the tvOS sim. Trailer *playback* (YouTubeKit extraction) isn't CLI-clickable — verify by
hand on device/sim once. Dev arg: launch with `-detailDemo`.

### Section 2 — Ratings & metadata integrations ✅ (COMPLETE 2026-07-06)
- [x] **MDBList ratings** — real ratings via `Core/MDBListService.swift`
      (POST `/rating/{movie|show}/{source}?apikey=`, 7 sources fanned out in parallel,
      30-min cache). `MDBListSettingsStore` + Settings → Integrations MDBList section
      (enable, API-key editor w/ live `validate`, per-source show toggles). Detail header
      shows `MDBListRatingsRow` (IMDb/TMDB/Trakt/Letterboxd/RT/Metacritic chips).
      Needs the user's own MDBList key (no shared key exists — per-account).
- [x] **IMDb rating source label** + rating source selection — the `ImdbBadge` already
      labels the IMDb score; MDBList entries carry their own source labels, and the
      per-source show toggles are the rating-source selection.
- [x] **TMDB entity browse** — company logos on Detail are now tappable →
      `Screens/TMDBBrowseView.swift` (`Route.tmdbCompany`) shows that studio's catalog
      (`TMDBService.browseCompany`, movies+TV by popularity).

**Section 2 complete.** Build verified; Detail screen renders with no regression (MDBList
row correctly hidden until a key is set). Not runtime-verified: MDBList row population
(needs a real MDBList API key) and the company-browse grid (no CLI remote to click it).

### Section 3 — Home layouts & discovery 🟡 (core done 2026-07-06)
- [x] **Multiple home layouts**: Classic / Modern / Grid — `HomeLayout` enum +
      `homeLayout` on `HomeCatalogSettingsStore` (device-local, persisted). HomeView
      renders all three (modern = hero-follows-focus + rows; classic = rows, no hero
      panel, focus backdrop; grid = wrapped poster grids). Picker in Settings → Layout
      (`HomeLayoutOptionRow`). Verified modern in sim.
- [x] **Catalog "See All"** — `StremioAPI.catalog(skip:)` pagination +
      `Screens/CatalogSeeAllView.swift` (infinite-scroll grid, prefetch on tail) +
      "See All ›" header button on every catalog row (`SeeAllLabel`, `Route.catalogSeeAll`).
      Verified: buttons render on Home rows.
- [x] **Catalog Order** — already covered by Settings → Layout (reorder/rename/hide rows,
      synced). No separate screen needed.
- [ ] **Experience modes** (simple/advanced) — deferred: it's an onboarding density
      preset with low standalone value on tvOS; the layout picker covers the visible part.
- [ ] **Discover** screen — deferred: per-catalog browsing is now served by See-All +
      Search; a dedicated Discover grid is lower priority.

**Section 3 core complete** (layouts + See-All + catalog order). Deferred: experience
modes, Discover (both low-value / already partially served).

### Section 4 — Player: post-play & auto-next ⬜
- [ ] **Post-play overlay** + **next-episode end prompt** (`PostPlayOverlay`,
      `NextEpisodeEndPromptOverlay`, `PlayerNextEpisodeRules`).
- [ ] **Autoplay session rules** + count (`PlayerAutoplaySessionRules`).
- [ ] **Still-watching gating** ("Are you still watching?", `StillWatching*`).
- [ ] **Stream info overlay** + **display mode overlay** (`StreamInfoOverlay`,
      `DisplayModeOverlay`).

### Section 5 — Player: subtitles subsystem ⬜
- [ ] **External subtitle addons** (OpenSubtitles etc.) — fetch, list, select. README
      notes this is unwired.
- [ ] **Subtitle style panel** (font/size/color/background) (`SubtitleStyleSidePanel`).
- [ ] **Subtitle timing/delay** UI (`SubtitleTimingDialog`, `SubtitleDelayConfig`).
- [ ] **ASS/libass rendering** parity (`PlayerLibass*`, `NuvioAssMatroskaExtractor`) —
      KSPlayer covers embedded PGS/text; verify ASS styling matches.

### Section 6 — Player: audio & advanced playback ⬜
- [ ] **Audio delay** + **audio output route** handling (`AudioDelayMediaSource`,
      `AudioOutputRouteDetector`, `PlaybackSpeedAwareAudio*`, `GainAudioProcessor`).
- [ ] **Frame-rate matching / AFR preflight** (`PlayerRuntimeControllerAfrPreflight`,
      `PlayerFrameRateHeuristics`) — tvOS displayManager AVDisplayCriteria.
- [ ] **Dolby Vision** base-layer policy / codec fallback (`DolbyVision*`).
- [ ] **Parental guide overlay** (`ParentalGuideOverlay`).
- [ ] **Skip intro / anime skip** (AniSkip) (`SkipIntroButton`, `AnimeSkipSettings*`).

### Section 6 note — not portable
- **Torrent/`infoHash`** streams (`TorrentOverlay`, `PlayerRuntimeControllerTorrent`): no
  torrent engine on tvOS — keep filtered (already done). Debrid-resolved HTTP works.
- **In-app APK updater** (`updater/ApkDownloader`): N/A on the App Store.
- **Sentry** analytics settings: skip unless requested.

### Section 7 — Settings parity ⬜
- [ ] **Playback settings** full depth: buffer/network, autoplay, audio, subtitle sub-pages
      (`PlaybackSettingsSections`, `PlaybackBufferNetworkSettings`,
      `PlaybackAutoPlaySettings`, `PlaybackAudioSettings`, `PlaybackSubtitleSettings`).
- [ ] **Network settings** (`NetworkSettingsScreen`).
- [ ] **Anime skip settings** (`AnimeSkipSettingsScreen`).
- [ ] **Debug / diagnostics** (`DebugSettingsScreen`, `DiagnosticsCard`).
- [ ] **Licenses/Attributions**, **Supporters/Contributors** screens
      (`LicensesAttributionsScreen`, `SupportersContributorsScreen`).
- [ ] **Plugins** screen (`plugin/PluginScreen`).

### Section 8 — Collections & Library editor parity ⬜
- [ ] **Collection editor** with TMDB/Trakt/genre-emoji pickers, folders, folder detail
      (`collection/CollectionEditor*`, `FolderDetailScreen`,
      `CollectionManagementScreen`).

### Section 9 — Account / sync parity ⬜
- [ ] **Email/password auth sign-in** (`account/AuthSignInScreen`) — port has QR/device.
- [ ] **Sync code generate / claim** (`SyncCodeGenerateScreen`, `SyncCodeClaimScreen`).
- [ ] **Essential addon setup** onboarding (`EssentialAddonSetupScreen`).

### Section 10 — Localization ⬜
- [ ] String catalog for the ~30 locales the Android app ships (`res/values-*`). Lower
      priority; English-only is functional.

---

## Working method
- Compare against Kotlin source in `~/Downloads/NuvioTV/app/src/main/java/com/nuvio/tv`
  (not the APK bytecode) — behavior is the spec.
- Apply schema/model additions additively; keep the 7-theme design system.
- Build with `xcodegen generate` then `xcodebuild ... -destination 'generic/platform=tvOS Simulator'`.
