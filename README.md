# StreetBeat

StreetBeat is a running and walking companion app: live tracking, run summaries, social feed, friends, leaderboards, badges, and Firebase-backed sync. It targets Android (and can be extended for iOS).

## Screenshots

Add images under `docs/screenshots/` and reference them here, for example:

- `docs/screenshots/feed.png` — activity feed  
- `docs/screenshots/run.png` — active run  
- `docs/screenshots/profile.png` — profile and stats  

## Tech stack

- **Flutter** — UI and client app  
- **Firebase** — Auth (email/password, Google), Firestore, Storage, Cloud Functions  
- **Bloc** — state management (`flutter_bloc`)  
- **Maps** — `flutter_map` + OpenStreetMap-style tiles  
- **Routing** — `go_router`  
- **DI** — `get_it`  

## Quick start

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd streetbeat
   ```

2. **Configure Firebase** — Follow [SETUP.md](SETUP.md): create a Firebase project, add the Android app with package `com.streetbeat.app`, download `google-services.json`, and place it at `android/app/google-services.json`.

   Optional validation:

   ```bash
   chmod +x scripts/setup_firebase.sh
   ./scripts/setup_firebase.sh
   ```

3. **Run or build**

   ```bash
   flutter pub get
   flutter run
   ```

   Release APK:

   ```bash
   chmod +x scripts/build_apk.sh
   ./scripts/build_apk.sh
   ```

   Output: `streetbeat-release.apk` at the repo root (and under `build/app/outputs/flutter-apk/`).

If Firebase is missing or still uses placeholder values, the app opens an in-app setup screen with steps so you can still launch the build while finishing configuration.

## Features

- GPS run tracking with pace, distance, and map replay  
- Run summary with stats and optional coin/segment gameplay hooks  
- Firebase Authentication and Firestore-backed data  
- Social feed, kudos, friend requests, and search  
- Profile with recent activity and Strava-style layout  
- Leaderboards  
- Badges and celebrations  
- Push-ready structure (local notifications, Cloud Functions)  

## Documentation

- **[SETUP.md](SETUP.md)** — Firebase, Firestore rules, Cloud Functions, and APK install  

## Contributing

Contribution guidelines (branching, PR process, code style) will be documented here. Until then, open a PR with a clear description of the change and any setup steps; match existing patterns in `lib/` and run `dart format` on touched Dart files.

## License

See the repository license file if present.
