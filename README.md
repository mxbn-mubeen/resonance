# 🎵 Resonance — Offline Music Platform

> A personal, offline-first music platform that turns your messy local audio files into a clean, Spotify-like library — fully on-device, no cloud required.

Built with **Flutter** · Clean Architecture · Riverpod · Isar · just_audio

---

## 🚀 Getting a build on your phone — two ways

### Option A: Just want the app, no dev setup

Every push to `main` builds a real APK automatically via GitHub Actions.

1. Go to the **Actions** tab on this repo.
2. Click the latest successful **Build APK** run.
3. Download the **resonance-apk** artifact, unzip it, and install the `.apk` on your phone (enable "install from unknown sources" if prompted).

No Flutter, no Android Studio, nothing installed locally. This is the fastest way to try a build.

### Option B: Full dev setup (to actually edit code)

#### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.3.0, on your `PATH`
- Android Studio **or** VS Code with the Flutter extension
- An Android device with USB debugging on, **or** a running emulator

Check your environment first — every checkmark should be green before continuing:
```bash
flutter doctor
```

#### Step 1 — Clone and install dependencies

```bash
git clone https://github.com/mxbn-mubeen/resonance.git
cd resonance
flutter pub get
```

The `android/` folder, permissions, and Gradle config are **already committed** in this repo — you do not need to run `flutter create` or manually edit `AndroidManifest.xml`/`build.gradle`. That was true early on but isn't anymore; skip straight to codegen.

#### Step 2 — Generate Isar database code (required, not optional)

The Isar schemas use code generation. Without this step the project **will not compile** — `isar_schemas.dart` references a generated file that doesn't exist until you run this:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Re-run this any time you change a file under `lib/data/local/isar_schemas.dart`.

#### Step 3 — Run it

Plug in your device (or start an emulator), then:

```bash
flutter run
```

Or open the folder in **Android Studio**, pick your device from the dropdown, hit ▶ Run.

#### Step 4 — Grant permissions on first launch

The app will prompt for audio/storage access the first time it tries to scan. Accept it, then use **Settings → Folders** to pick which folders to scan (Telegram/WhatsApp/Recorder/Podcasts are excluded by default).

---

## 🩺 If something doesn't compile

Run this locally before assuming something's broken:
```bash
flutter analyze
```
The GitHub Actions workflow (`.github/workflows/build.yml`) runs this same check on every push and uploads the results even if the build fails — check the **Actions** tab for the exact error and file/line before digging further.

---

## 🗂️ Project structure

```
resonance/
├── .github/workflows/build.yml     # CI: builds a real APK on every push
├── android/                        # Native Android shell (already committed)
├── assets/                         # App icon, static assets
│
├── lib/
│   ├── main.dart                   # Entry point, AudioService.init()
│   ├── app.dart                    # Root widget + bottom nav shell
│   │
│   ├── core/
│   │   ├── constants/              # App-wide constants, website blacklist
│   │   ├── di/providers.dart       # Riverpod dependency injection graph
│   │   └── theme/                  # Color scheme, typography
│   │
│   ├── domain/entities/            # Pure Dart models (Song, Artist, Album...)
│   │
│   ├── data/
│   │   ├── local/                  # Isar schemas + DatabaseService
│   │   ├── remote/                 # iTunes (multi-storefront) + MusicBrainz clients
│   │   └── repositories/           # Library, Playlist, Metadata, History
│   │
│   ├── application/
│   │   ├── scanner/                # Folder scanner - incremental diff, skips unchanged files
│   │   ├── metadata/                # Metadata cleaner + song matcher
│   │   ├── artwork/                # Download → resize → compress → cache + palette extraction
│   │   ├── lyrics/                 # Lyrics priority chain
│   │   ├── duplicates/             # Hash + perceptual-fingerprint duplicate detection
│   │   ├── playback/               # just_audio + audio_service controller
│   │   ├── playlist/               # Manual, smart (auto), and genre-matched AI playlists
│   │   └── recommendation/         # Artist/genre affinity "Recommended for you"
│   │
│   └── presentation/
│       ├── home/                   # Home screen + components/ (recent, recommended, playlists rails)
│       ├── library/                # Library screen + components/
│       ├── search/                 # Search screen
│       ├── player/                 # Cinematic full-screen player + components/
│       ├── playlists/              # Playlists screen + shared smart-playlist definitions
│       ├── equalizer/              # Equalizer screen
│       ├── settings/               # Settings screen + components/
│       └── widgets/                # MiniPlayer, SongTile, PlaylistCoverWidget (shared)
│
└── pubspec.yaml                    # Dependencies
```

---

## ✅ What's implemented vs. still open

| Module | Status |
|---|---|
| Folder scanning | **Done** — diffs by (mtime, size), skips unchanged files |
| Metadata Cleaner | **Done** — website blacklist, regex normalization, tested against real MP3s |
| Song Matcher (MusicBrainz → iTunes) | **Done** — multi-storefront iTunes fallback (`in`/`us`/`jp`/`ru`/`ae`) for regional/niche coverage |
| Artwork Manager | **Done** — download → decode → resize → JPEG compress → cache; quality presets in Settings |
| Lyrics Manager | Priority chain stubbed (embedded → `.lrc` → online → cache) |
| Duplicate Detector | **Done** — exact hash + perceptual energy-envelope fingerprint (catches different-bitrate re-encodes) |
| Playlist Engine | **Done** — manual CRUD, Most/Recently Played/Added/Never Played, genre-matched mood playlists |
| Recommendation Engine | **Done** — artist/genre affinity heuristic, excludes recently-played |
| Playback Controller | **Done** — full `just_audio` + `audio_service`, real OS media notification |
| Cinematic player screen | **Done** — blurred art backdrop, dominant-color tint, 3D-tilted card, animated transitions |
| Home rails | **Done** — Recent, Recommended, and combined Manual+Smart playlists |
| Equalizer | **Placeholder** — band sliders exist but aren't wired to real audio effects (needs a native platform channel) |
| CI build | **Done** — `.github/workflows/build.yml` builds and uploads an installable APK on every push |

Every open item has a `// TODO(module):` comment in the code pointing to exactly what's needed.

---

## 🛠️ Tech stack

| Concern | Package |
|---|---|
| State management | `flutter_riverpod` |
| Local database | `isar` + `isar_flutter_libs` |
| Playback | `just_audio` + `audio_service` + `audio_session` |
| Media scanning | `on_audio_query` |
| Networking | `dio` (iTunes + MusicBrainz — both free, keyless APIs) |
| Metadata reading | `audio_metadata_reader` |
| Artwork | `image` (resize/compress) + `palette_generator` (dominant color) |
| Duplicate detection | `crypto` (hash) + `just_waveform` (perceptual fingerprint) |
| Permissions / connectivity | `permission_handler` + `connectivity_plus` |
| Settings persistence | `shared_preferences` + `file_picker` + `flutter_colorpicker` |