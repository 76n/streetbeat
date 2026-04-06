# StreetBeat — Release Builds

## Android (`streetbeat-android.apk`)

Install on any Android device:

- Enable "Install from unknown sources" in Settings
- Transfer APK to device and tap to install
- Or via adb: `adb install releases/streetbeat-android.apk`

## iOS (`streetbeat-ios-unsigned.ipa`)

Unsigned builds require **full Xcode** (not only Command Line Tools) on macOS. From the repo root:

```bash
flutter build ios --release --no-codesign
mkdir -p releases/ios_payload/Payload
cp -r build/ios/iphoneos/Runner.app releases/ios_payload/Payload/
cd releases/ios_payload && zip -r ../streetbeat-ios-unsigned.ipa Payload/
cd ../.. && rm -rf releases/ios_payload
```

Then sideload:

- **AltStore:** import the IPA via AltStore on your device
- **Xcode:** Window → Devices → install package
- **Mac only:** drag `.ipa` to Xcode Devices panel

If `streetbeat-ios-unsigned.ipa` is missing from this folder, it was not built in the current environment (Xcode required).

## Firebase setup required

Before first launch, ensure Firebase project `streetbeatrun` has:

- Authentication enabled (Email/Password + Google)
- Firestore database created (region: `europe-west1`)
- Firestore rules deployed: `firebase deploy --only firestore:rules`
