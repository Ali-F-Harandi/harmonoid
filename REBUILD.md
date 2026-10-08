# Community Rebuild — Status & Roadmap

This fork builds **without any of the original private upstream packages**.
The eight previously-private dependencies have been replaced with fresh,
API-compatible implementations vendored directly inside this repository:

| Path | Package | Status |
| --- | --- | --- |
| `external/adaptive_layouts` | `adaptive_layouts` | ✅ Functional reimplementation (widgets, themes, carousel, file explorer) |
| `external/identity` | `identity` | ✅ Offline reimplementation — no backend, all "Plus" features unlocked locally |
| `external/lastfm` | `lastfm` | ✅ Functional Last.fm API 2.0 client (MD5 signing, token auth, scrobbling) |
| `external/media_library` | `media_library` | ⚠️ Type-complete **engine stub** — models/playlists/lookups work; file indexing TODO |
| `external/tag_reader` | `tag_reader` | ⚠️ Stub — derives title from the file name only; real tag parsing TODO |
| `external/taglib/taglib` | `taglib` | ⚠️ Stub — tag *writing* throws `UnsupportedError` (tag editor shows its error state) |
| `external/taglib/taglib_libs` | `taglib_libs` | ⚠️ Placeholder FFI plugin — bundles no native library yet |
| `external/smtc-win32/bindings/system_media_transport_controls` | `system_media_transport_controls` | ⚠️ Stub — Windows media-overlay (SMTC) integration is inert |
| `lib/private/crossfade_player.dart` | (in-app) | ⚠️ Playback fully works via `NativePlayer`; the crossfade *fade* itself is not implemented — the duration is only stored |
| `assets/localizations` | (vendored data) | ✅ Real upstream content (public repo), fa_IR included |

## What works today

- The application **compiles & runs** on Windows (and other desktop targets) with a completely public dependency tree.
- Full UI: adaptive layouts, theming (M2/M3), navigation, settings, now-playing screens, lyrics display, file explorer (folders browsing works over the real file system).
- Playback through `media_kit` (mpv), playlists (in-memory), Last.fm scrobbling (with API keys), window management.
- `flutter pub get` / `flutter analyze` / `flutter build windows` succeed from a plain checkout — no tokens, no submodules.

## What is missing (the phased roadmap)

1. **Phase 1 — tag reading.** Implement real tag parsing in `tag_reader`.
   Options: FFI bindings to the open-source [taglib](https://github.com/taglib/taglib)
   C++ library (bundled through `taglib_libs`), or a pure-Dart parser for
   ID3v2/FLAC/MP4/Vorbis metadata. This unlocks `updateCurrent` metadata
   (titles/artists/albums in the now-playing bar) and the file-info screen.
2. **Phase 2 — indexing engine.** Implement `FileSystemMediaLibrary.refresh/populate`
   for real: directory scanning, tag parsing through the `parse` hook, SQLite
   persistence (drift or sqlite3), grouping (albums/artists/genres), cover-art
   extraction & caching, incremental diffing.
3. **Phase 3 — tag writing.** Bundle the real taglib library via `taglib_libs`
   (Windows + Linux) and implement `TagLibFile` FFI bindings to restore the
   tag editor.
4. **Phase 4 — SMTC.** Write a fresh WinRT `smtc-win32.dll`
   (`ISystemMediaTransportControls`) + bindings to restore the Windows
   media-overlay integration.
5. **Phase 5 — crossfade.** Implement the dual-deck volume ramp in
   `CrossfadePlayer` for real gapless crossfades.

## Notes

- `identity` is intentionally offline: login always fails with a clear
  message, `Supabase`-shimmed edge functions (remote config, lyrics
  translation) report unavailability gracefully, and every Plus feature is
  unlocked. Remote-config falls back to compiled defaults.
- The upstream `harmonoid/localizations` content is vendored under
  `assets/localizations` (its public repository still exists).
- `License`: the repository is licensed CC0 (see `LICENSE`) for the original
  contributions of this fork; the app code itself derives from the
  PolyForm-Strict-licensed upstream — see the LICENSE file for details.
