import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/utils/week_utils.dart';
import '../../../shared/repositories/social_repository.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final SocialRepository _social = sl<SocialRepository>();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final weekTok = WeekUtils.isoWeekToken(DateTime.now().toUtc());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Weekly'),
            Tab(text: 'All Time'),
          ],
        ),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final friends = List<String>.from(
                  userSnap.data!.data()?['friends'] ?? [],
                );
                final pool = {...friends, uid}.toList();
                return TabBarView(
                  controller: _tabs,
                  children: [
                    _FriendsScopedBoard(
                      myUid: uid,
                      uids: pool,
                      social: _social,
                      weekTok: weekTok,
                      allTime: false,
                    ),
                    _GlobalWeekBoard(myUid: uid, weekTok: weekTok),
                    _FriendsScopedBoard(
                      myUid: uid,
                      uids: pool,
                      social: _social,
                      weekTok: weekTok,
                      allTime: true,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _FriendsScopedBoard extends StatefulWidget {
  const _FriendsScopedBoard({
    required this.myUid,
    required this.uids,
    required this.social,
    required this.weekTok,
    required this.allTime,
  });

  final String myUid;
  final List<String> uids;
  final SocialRepository social;
  final String weekTok;
  final bool allTime;

  @override
  State<_FriendsScopedBoard> createState() => _FriendsScopedBoardState();
}

class _FriendsScopedBoardState extends State<_FriendsScopedBoard> {
  List<LeaderboardRow> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant _FriendsScopedBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uids.length != widget.uids.length ||
        oldWidget.allTime != widget.allTime ||
        oldWidget.weekTok != widget.weekTok ||
        !_setEq(oldWidget.uids.toSet(), widget.uids.toSet())) {
      _reload();
    }
  }

  bool _setEq(Set<String> a, Set<String> b) {
    return a.length == b.length && a.containsAll(b);
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final rows = await widget.social.leaderboardForUids(
      uids: widget.uids,
      scoreFor: widget.allTime
          ? (m) => (m['totalCoins'] as num?)?.toInt() ?? 0
          : (m) {
              final t = m['weeklyCoinsWeekToken'] as String? ?? '';
              if (t != widget.weekTok) {
                return 0;
              }
              return (m['weeklyCoins'] as num?)?.toInt() ?? 0;
            },
    );
    if (mounted) {
      setState(() {
        _rows = rows;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_rows.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const [
          SizedBox(height: 48),
          StreetBeatEmptyState(
            title: 'Add friends to compete',
            message:
                'See how you stack up on coins each week. Open the bell on the '
                'Feed tab to find friends and send requests.',
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _rows.length,
      itemBuilder: (context, i) {
        final row = _rows[i];
        return _RankRow(
          key: ValueKey('f-${row.uid}-${row.rank}-${row.score}'),
          row: row,
          highlight: row.uid == widget.myUid,
        );
      },
    );
  }
}

class _GlobalWeekBoard extends StatelessWidget {
  const _GlobalWeekBoard({
    required this.myUid,
    required this.weekTok,
  });

  final String myUid;
  final String weekTok;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('weeklyCoinsWeekToken', isEqualTo: weekTok)
          .orderBy('weeklyCoins', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text(
              'Could not load leaderboard.',
              style: TextStyle(color: Color(0xFFE57373)),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: const [
              SizedBox(height: 48),
              StreetBeatEmptyState(
                title: 'Weekly board is open',
                message:
                    'No scores for this week yet. Go for a run — your coins '
                    'land here automatically.',
              ),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final m = d.data();
            final row = LeaderboardRow(
              uid: d.id,
              name: m['name'] as String? ?? 'Runner',
              score: (m['weeklyCoins'] as num?)?.toInt() ?? 0,
              rank: i + 1,
            );
            return _RankRow(
              key: ValueKey('g-${row.uid}-${row.rank}-${row.score}'),
              row: row,
              highlight: row.uid == myUid,
            );
          },
        );
      },
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    super.key,
    required this.row,
    required this.highlight,
  });

  final LeaderboardRow row;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final podium = row.rank <= 3;
    final podiumBorder = switch (row.rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => null,
    };
    final bg =
        highlight ? AppColors.primary.withValues(alpha: 0.22) : AppColors.card;
    final accent = highlight ? AppColors.primary : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: podium && podiumBorder != null
              ? BorderSide(
                  color: podiumBorder.withValues(alpha: 0.85),
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: TweenAnimationBuilder<int>(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  tween: IntTween(begin: row.rank, end: row.rank),
                  builder: (context, value, child) {
                    return Text(
                      '$value',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: accent,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 20,
                backgroundColor: podium
                    ? (podiumBorder ?? AppColors.surface).withValues(alpha: 0.2)
                    : AppColors.surface,
                child: Text(
                  _initials(row.name),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  row.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '${row.score}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
