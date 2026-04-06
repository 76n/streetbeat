#!/bin/bash
# StreetBeat APK Build Script
echo "Building StreetBeat APK..."
flutter clean
flutter pub get
flutter build apk --release --target-platform android-arm64
echo "APK built at build/app/outputs/flutter-apk/app-release.apk"
cp build/app/outputs/flutter-apk/app-release.apk ./streetbeat-release.apk
echo "Copied to ./streetbeat-release.apk"
