# DukaanTak Firebase Android setup

- Firebase Android package name: `com.duakaantak.customer` (must remain exact).
- Firebase config is included at `android/app/google-services.json`.
- `ci_setup.sh` regenerates the Android Gradle scaffold using Flutter, applies Google Services plugin `4.4.2`, sets Android minSdk to 23, and runs `flutter pub get`.
- Firebase Flutter dependencies already declared in `pubspec.yaml`: `firebase_core`, `firebase_auth`, and `cloud_firestore`.
- `main.dart` initializes Firebase with `Firebase.initializeApp()` before `runApp`.

## Build

Run `bash ci_setup.sh`, then `flutter build apk --release`.

## Important verification

The supplied ZIP is a phone-friendly source bundle, not a complete generated Flutter platform project: its Dart files are at the archive root and it has no pre-existing `android/` Gradle scaffold. The setup script creates that scaffold with the installed Flutter SDK before applying Firebase configuration. A successful build still needs to be run in an environment with Flutter/Android SDK installed and Firebase Authentication (Phone provider) and Cloud Firestore enabled in the Firebase console.
