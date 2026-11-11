project_root: f:\resonance
last_brain_review: 2026-11-11

# Master Memory

## What this project is
An offline-first music player app for Android. Organizes local audio files into a Spotify-like library — fully on-device with no cloud required.
(source: README.md)

## Key Details
- **App Name (pubspec)**: appresonance  (source: pubspec.yaml `name:`)
- **App Display Title**: Resonance  (source: lib/main.dart `title:`)
- **Android namespace / applicationId**: com.mxbn.appresonance  (source: android/app/build.gradle.kts)
- **Dart SDK**: `>=3.3.0 <4.0.0`  (source: pubspec.yaml)
- **Flutter**: stable channel, build runs as debug APK for dev  (source: terminal observation)
- **State Management**: flutter_riverpod, riverpod_annotation  (source: pubspec.yaml)
- **Local DB**: isar, isar_flutter_libs  (source: pubspec.yaml)
- **Playback**: just_audio, audio_service, audio_session  (source: pubspec.yaml)
- **Metadata**: audio_metadata_reader, flutter_colorpicker  (source: pubspec.yaml)
- **Other deps**: dio, cached_network_image, palette_generator, image, permission_handler, workmanager, crypto, just_waveform, file_picker, path_provider  (source: pubspec.yaml)

## Current State (as of 2026-08-09)
- **UI**: Fully built. Home, Library (tabs: Songs/Artists/Albums/Folders/Favourites), Playlists, Player, Settings screens all present and functional.
- **Player**: Cinematic full-screen player. Transport controls (play/pause/skip), speed, sleep timer, queue sheet, EQ button (stub), mini-player on every screen.
- **Library Health**: Implemented with history tracking in Isar.
- **Metadata**: MusicBrainz → iTunes fallback chain with ID3 local fallback. Metadata cleaner strips garbage tags. Artwork extraction and compression per quality setting.
- **Scanning**: Folder-based scan with included/excluded folder lists. On-demand rescan from Library AppBar.
- **Playlists**: Manual playlists with cover mosaic widget. Auto-playlists and AI playlists are stubbed.
- **Favourites**: Toggle per song (heart icon on SongTile and mini-player). Favourites tab in Library.
- **Equalizer**: Stub screen at `lib/presentation/player/equalizer/equalizer_screen.dart` — wired into secondary player controls; full implementation is a future item.

## Component Structure (presentation layer — 230-line rule enforced)
All screens have been split into `components/` sub-files. Current extracted components:

| Screen | Components |
|---|---|
| `player/` | `components/player_controls.dart`, `components/player_secondary_controls.dart`, `components/queue_sheet.dart` |
| `playlists/` | `components/playlist_header.dart` |
| `library/` | `components/group_header.dart`, `components/library_tabs.dart` (SongsTab, ArtistsTab, AlbumsTab, FoldersTab, FavouritesTab) |
| `home/` | `components/home_recent_section.dart`, `components/home_empty_prompt.dart`, `components/home_playlists_section.dart` |
| `settings/` | `components/settings_library_section.dart`, `components/settings_metadata_section.dart`, `components/settings_theme_section.dart`, `components/settings_health_section.dart` |

## Active Work / Pending Features
- Favourite heart on mini-player *(partially: toggle exists, heart icon in mini-player pending confirmation)*
- Moving/animated equalizer logo when playing
- Queue songs re-orderable and auto-playing song highlighted
- Filter in folder tab
- Equalizer full implementation
- AI mood rails on Home screen (TODO comment left in home_screen.dart)
