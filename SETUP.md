# StreetBeat — Firebase Setup Guide

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com
2. Create a new project called "streetbeat"
3. Enable Google Analytics (optional)

## Step 2: Add Android App

1. In Firebase console → Project Settings → Add App → Android
2. Package name: `com.streetbeat.app`
3. Download `google-services.json`
4. Place it at: `android/app/google-services.json`

Optional: run `./scripts/setup_firebase.sh` to verify the file before building.

## Step 3: Enable Authentication

1. Firebase Console → Authentication → Sign-in method
2. Enable: Email/Password
3. Enable: Google

## Step 4: Enable Firestore

1. Firebase Console → Firestore Database → Create database
2. Start in production mode
3. Choose your region (recommend: `europe-west1` for Israel)

## Step 5: Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

## Step 6: Deploy Cloud Functions

```bash
cd functions && npm install
cd ..
firebase deploy --only functions
```

## Step 7: Build APK

```bash
chmod +x scripts/build_apk.sh
./scripts/build_apk.sh
```

## Step 8: Install on Device

```bash
adb install streetbeat-release.apk
```

Or transfer `streetbeat-release.apk` to your phone and install directly.
