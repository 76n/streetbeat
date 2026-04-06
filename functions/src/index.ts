import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { setGlobalOptions } from "firebase-functions/v2/options";

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ region: "me-west1" });

function isoWeekToken(d: Date): string {
  const utc = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const day = utc.getUTCDay() || 7;
  const thursday = new Date(utc);
  thursday.setUTCDate(utc.getUTCDate() + 4 - day);
  const year = thursday.getUTCFullYear();
  const jan4 = new Date(Date.UTC(year, 0, 4));
  const jan4Day = jan4.getUTCDay() || 7;
  const week1Monday = new Date(jan4);
  week1Monday.setUTCDate(jan4.getUTCDate() - (jan4Day - 1));
  const diffMs = thursday.getTime() - week1Monday.getTime();
  const week = Math.floor(diffMs / (7 * 24 * 60 * 60 * 1000)) + 1;
  return `${year}-W${week.toString().padStart(2, "0")}`;
}

function weeklyScopeId(weekToken: string): string {
  return `weekly_${weekToken}`;
}

function collectedCoinPoints(coins: unknown): number {
  if (!Array.isArray(coins)) return 0;
  let sum = 0;
  for (const c of coins) {
    if (c && typeof c === "object" && (c as { isCollected?: boolean }).isCollected) {
      const p = (c as { points?: number }).points;
      sum += typeof p === "number" ? p : 0;
    }
  }
  return sum;
}

export const onRunCompleted = onDocumentCreated(
  "runs/{runId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data() as Record<string, unknown>;
    const uid = data.uid as string | undefined;
    if (!uid) return;

    const startedRaw = data.startedAt as string | undefined;
    const started = startedRaw ? new Date(startedRaw) : new Date();
    const weekToken =
      typeof data.weekToken === "string" && data.weekToken.length > 0
        ? data.weekToken
        : isoWeekToken(started);

    const distance = typeof data.distance === "number" ? data.distance : 0;
    const durationSeconds =
      typeof data.durationSeconds === "number" ? data.durationSeconds : 0;
    const totalScore = typeof data.totalScore === "number" ? data.totalScore : 0;
    const coinPoints = collectedCoinPoints(data.coins);

    const scopeDoc = db.collection("leaderboardCache").doc(weeklyScopeId(weekToken));
    const userEntry = scopeDoc.collection("entries").doc(uid);

    await userEntry.set(
      {
        uid,
        coins: FieldValue.increment(coinPoints),
        distance: FieldValue.increment(distance),
        runs: FieldValue.increment(1),
        score: FieldValue.increment(totalScore),
        lastRunId: snap.id,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const userSnap = await db.collection("users").doc(uid).get();
    const userData = userSnap.data();
    const clubId = userData?.clubId as string | undefined;
    if (clubId) {
      const clubWeekly = db
        .collection("clubs")
        .doc(clubId)
        .collection("weeklyStats")
        .doc(weekToken);
      await clubWeekly.set(
        {
          clubId,
          weekToken,
          totalCoins: FieldValue.increment(coinPoints),
          totalDistance: FieldValue.increment(distance),
          runCount: FieldValue.increment(1),
          totalScore: FieldValue.increment(totalScore),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    }

    const segmentKey = data.segmentKey as string | undefined;
    if (segmentKey && durationSeconds > 0) {
      const segRef = db.collection("segments").doc(segmentKey);
      await db.runTransaction(async (tx) => {
        const segSnap = await tx.get(segRef);
        const prev = segSnap.data()?.bestDurationSeconds as number | undefined;
        if (prev === undefined || durationSeconds < prev) {
          tx.set(
            segRef,
            {
              segmentId: segmentKey,
              bestDurationSeconds: durationSeconds,
              bestByUid: uid,
              bestRunId: snap.id,
              bestDistance:
                typeof data.distance === "number" ? data.distance : null,
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }
      });
    }
  }
);

function previousIsoWeekToken(now: Date): string {
  const prev = new Date(now);
  prev.setUTCDate(prev.getUTCDate() - 7);
  return isoWeekToken(prev);
}

export const weeklyReset = onSchedule(
  {
    schedule: "0 0 * * 1",
    timeZone: "UTC",
  },
  async () => {
    const now = new Date();
    const prevWeek = previousIsoWeekToken(now);
    await db
      .collection("leaderboardCache")
      .doc(`archive_${prevWeek}`)
      .set(
        {
          type: "weekly_archive",
          weekToken: prevWeek,
          archivedAt: FieldValue.serverTimestamp(),
          note:
            "No-op archive marker. Weekly leaderboards are derived client-side from runs filtered by weekToken.",
        },
        { merge: true }
      );
  }
);

function friendRequestDocId(fromUid: string, toUid: string): string {
  return `${fromUid}_${toUid}`;
}

export const sendFriendRequest = onCall(async (request) => {
  const fromUid = request.auth?.uid;
  if (!fromUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const toUid = request.data?.toUid as string | undefined;
  if (!toUid || typeof toUid !== "string") {
    throw new HttpsError("invalid-argument", "toUid is required.");
  }
  if (fromUid === toUid) {
    throw new HttpsError("invalid-argument", "Cannot add yourself.");
  }

  const [fromSnap, toSnap] = await Promise.all([
    db.collection("users").doc(fromUid).get(),
    db.collection("users").doc(toUid).get(),
  ]);
  if (!fromSnap.exists || !toSnap.exists) {
    throw new HttpsError("not-found", "Both users must exist.");
  }

  const friends = (fromSnap.data()?.friends as string[] | undefined) ?? [];
  if (friends.includes(toUid)) {
    throw new HttpsError("already-exists", "Already friends.");
  }

  const forwardId = friendRequestDocId(fromUid, toUid);
  const reverseId = friendRequestDocId(toUid, fromUid);
  const forwardRef = db.collection("friendRequests").doc(forwardId);
  const reverseRef = db.collection("friendRequests").doc(reverseId);

  const [forward, reverse] = await Promise.all([forwardRef.get(), reverseRef.get()]);

  if (forward.exists) {
    throw new HttpsError("already-exists", "Request already sent.");
  }

  if (reverse.exists && reverse.data()?.status === "pending") {
    await db.runTransaction(async (tx) => {
      const rev = await tx.get(reverseRef);
      if (!rev.exists || rev.data()?.status !== "pending") return;
      tx.delete(reverseRef);
      tx.update(db.collection("users").doc(toUid), {
        friends: FieldValue.arrayUnion(fromUid),
      });
      tx.update(db.collection("users").doc(fromUid), {
        friends: FieldValue.arrayUnion(toUid),
      });
    });
    return { status: "accepted_mutual", requestId: reverseId };
  }

  await forwardRef.set({
    fromUid,
    toUid,
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
  });

  return { status: "sent", requestId: forwardId };
});

export const acceptFriendRequest = onCall(async (request) => {
  const accepterUid = request.auth?.uid;
  if (!accepterUid) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const requesterUid = request.data?.requesterUid as string | undefined;
  if (!requesterUid || typeof requesterUid !== "string") {
    throw new HttpsError("invalid-argument", "requesterUid is required.");
  }

  const id = friendRequestDocId(requesterUid, accepterUid);
  const ref = db.collection("friendRequests").doc(id);
  const pre = await ref.get();
  if (!pre.exists) {
    throw new HttpsError("not-found", "Request not found.");
  }
  const m = pre.data()!;
  if (m.toUid !== accepterUid || m.fromUid !== requesterUid) {
    throw new HttpsError("permission-denied", "Not your request to accept.");
  }

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    tx.delete(ref);
    tx.update(db.collection("users").doc(requesterUid), {
      friends: FieldValue.arrayUnion(accepterUid),
    });
    tx.update(db.collection("users").doc(accepterUid), {
      friends: FieldValue.arrayUnion(requesterUid),
    });
  });

  return { status: "accepted", requestId: id };
});

const CACHE_TTL_MS = 5 * 60 * 1000;

export const getUserStats = onCall(async (request) => {
  const caller = request.auth?.uid;
  if (!caller) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const targetUid = (request.data?.uid as string | undefined) ?? caller;
  if (targetUid !== caller) {
    throw new HttpsError(
      "permission-denied",
      "Only your own stats can be requested (MVP)."
    );
  }

  const cacheRef = db.collection("leaderboardCache").doc(`userStatsCache_${targetUid}`);
  const cacheSnap = await cacheRef.get();
  const now = Date.now();
  const cached = cacheSnap.data();
  const expiresAt = cached?.expiresAt as Timestamp | undefined;
  if (expiresAt && expiresAt.toMillis() > now && cached?.stats) {
    return { stats: cached.stats, cached: true, expiresAt: expiresAt.toMillis() };
  }

  const userSnap = await db.collection("users").doc(targetUid).get();
  if (!userSnap.exists) {
    throw new HttpsError("not-found", "User not found.");
  }
  const u = userSnap.data()!;

  const weekToken = isoWeekToken(new Date());
  const weeklyEntrySnap = await db
    .collection("leaderboardCache")
    .doc(weeklyScopeId(weekToken))
    .collection("entries")
    .doc(targetUid)
    .get();

  const stats = {
    uid: targetUid,
    name: u.name ?? "",
    city: u.city ?? "",
    totalRuns: u.totalRuns ?? 0,
    totalDistance: u.totalDistance ?? 0,
    totalCoins: u.totalCoins ?? 0,
    currentStreakWeeks: u.currentStreakWeeks ?? 0,
    weeklyCoins: u.weeklyCoins ?? 0,
    weeklyCoinsWeekToken: u.weeklyCoinsWeekToken ?? "",
    weeklyLeaderboardEntry: weeklyEntrySnap.exists ? weeklyEntrySnap.data() : null,
    weekToken,
  };

  await cacheRef.set({
    stats,
    expiresAt: Timestamp.fromMillis(now + CACHE_TTL_MS),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { stats, cached: false, expiresAt: now + CACHE_TTL_MS };
});
