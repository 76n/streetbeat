# StreetBeat Cloud Functions

TypeScript Cloud Functions for Firestore triggers, scheduled jobs, and callable APIs.

## Requirements

- **Node.js 18** (LTS). Use `nvm install 18` or install from [nodejs.org](https://nodejs.org/).
- Firebase CLI: `npm install -g firebase-tools`
- Logged in: `firebase login`
- Project selected: `firebase use <your-project-id>`

## Install

From the repository root:

```bash
cd functions
npm install
```

## Build

```bash
npm run build
```

Compiled JavaScript is emitted to `functions/lib/`.

## Deploy

From the repository root (where `firebase.json` lives):

```bash
firebase deploy --only functions
```

Deploy Firestore rules and indexes together:

```bash
firebase deploy --only functions,firestore
```

## Local emulator (optional)

```bash
npm run serve
```

## Implemented functions

| Export | Type | Description |
|--------|------|-------------|
| `onRunCompleted` | `runs/{runId}` onCreate | Updates `leaderboardCache/weekly_{token}/entries/{uid}`, optional `clubs/{clubId}/weeklyStats/{weekToken}`, optional `segments/{segmentKey}` if run beats best duration |
| `weeklyReset` | Schedule (Mondays 00:00 UTC) | Writes archive marker doc on `leaderboardCache` (no-op; client derives boards from runs) |
| `sendFriendRequest` | Callable | Validates users, creates `friendRequests/{from}_{to}` or auto-accepts if reverse pending |
| `acceptFriendRequest` | Callable | Deletes request, unions `friends` on both users |
| `getUserStats` | Callable | Returns merged profile + weekly cache entry; caches response for 5 minutes in `leaderboardCache` |

### Client fields used by `onRunCompleted`

- **`segmentKey`** (optional on run): if set, segment bests are updated under `segments/{segmentKey}`.
- **`clubId`** (optional on user): if set, club weekly aggregates update under `clubs/{clubId}/weeklyStats/{weekToken}`.

Callable HTTPS endpoints use region **`us-central1`** (see `setGlobalOptions` in `src/index.ts`). Configure the Flutter app to use the same region for `FirebaseFunctions`.

## Firestore paths

- Friend requests: **`friendRequests`** (camelCase), document id `{fromUid}_{toUid}`.
- Weekly leaderboard cache: **`leaderboardCache/weekly_{ISO-week}/entries/{uid}`**.

If you previously used `friend_requests`, migrate documents or re-send requests after deploying rules that only allow deletes on `friendRequests` from participants (creates go through the callable).
