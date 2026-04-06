import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/badges.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/utils/week_utils.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../shared/widgets/badge_grid.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../run/models/run_model.dart';
import '../../run/models/run_summary_payload.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr is AuthError,
      listener: (context, state) {
        final msg = (state as AuthError).message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.card,
            content: Text(msg),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: 'Edit profile',
              icon: const Icon(Icons.edit_outlined),
              color: AppColors.textPrimary,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.card,
                    content: Text('Profile editing is coming soon.'),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final loading = state is AuthLoading;
            final fbUser = FirebaseAuth.instance.currentUser;
            final uid = switch (state) {
              AuthAuthenticated u => u.user.uid,
              _ => fbUser?.uid,
            };
            if (uid == null) {
              return const Center(child: Text('Sign in'));
            }
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final user = UserModel.fromFirestore(snap.data!.data() ?? {});
                final weekTok = WeekUtils.isoWeekToken(DateTime.now().toUtc());
                final runsWeek = user.runsCountForWeekToken(weekTok);
                final kmWeek = user.weeklyDistanceMeters / 1000;
                final earnedMvp = user.badges
                    .where((b) => kBadgeById.containsKey(b.id))
                    .length;
                final displayName = user.name.isNotEmpty
                    ? user.name
                    : (fbUser?.displayName != null &&
                            fbUser!.displayName!.trim().isNotEmpty)
                        ? fbUser.displayName!.trim()
                        : 'Runner';
                final email = fbUser?.email?.trim() ?? '';

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AvatarWidget(
                                  radius: 48,
                                  name: displayName,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 24,
                                        ),
                                      ),
                                      if (email.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        user.city.isNotEmpty
                                            ? user.city
                                            : 'Set your city in settings',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 30,
                                  color: user.currentStreakWeeks > 0
                                      ? AppColors.primary
                                      : AppColors.textSecondary
                                          .withValues(alpha: 0.35),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.currentStreakWeeks > 0
                                      ? '${user.currentStreakWeeks} week streak'
                                      : '0 week streak',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This week · $runsWeek runs · ${kmWeek.toStringAsFixed(kmWeek >= 10 ? 0 : 1)} km · ${user.weeklyCoins} coins',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Totals',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _StatsGrid(user: user),
                            const SizedBox(height: 24),
                            const Text(
                              'Bests',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _BestsRow(user: user),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Badges',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  '$earnedMvp / ${kAllBadgeDefinitions.length}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            BadgeGrid(user: user),
                            const SizedBox(height: 28),
                            const Text(
                              'Recent runs',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    _RecentRunsSliver(uid: uid),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () => context.read<AuthBloc>().add(
                                    const AuthSignOut(),
                                  ),
                          child: loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Text('Sign out'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, IconData)>[
      ('Runs', '${user.totalRuns}', Icons.directions_run_rounded),
      (
        'Distance',
        LocationUtils.formatDistance(user.totalDistance),
        Icons.straighten_rounded,
      ),
      ('Coins', '${user.totalCoins}', Icons.stars_rounded),
      (
        'Gates',
        '${user.gatesCapturedLifetime}',
        Icons.flag_rounded,
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.75,
      children: items
          .map(
            (e) => StatCard(
              title: e.$1,
              value: e.$2,
              icon: e.$3,
            ),
          )
          .toList(),
    );
  }
}

class _BestsRow extends StatelessWidget {
  const _BestsRow({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final pace = user.bestPaceSecPerKm;
    final paceStr = pace != null && pace > 0
        ? LocationUtils.formatPace(1000.0 / pace)
        : '—';
    return Row(
      children: [
        Expanded(
          child: _BestCell(
            label: 'Best pace',
            value: paceStr,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BestCell(
            label: 'Longest run',
            value: LocationUtils.formatDistance(user.longestRunMeters),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BestCell(
            label: 'Most coins (1 run)',
            value: '${user.mostCoinsSingleRun}',
          ),
        ),
      ],
    );
  }
}

class _BestCell extends StatelessWidget {
  const _BestCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRunsSliver extends StatelessWidget {
  const _RecentRunsSliver({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('runs')
          .where('uid', isEqualTo: uid)
          .orderBy('startedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.route_rounded,
                      size: 40,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No runs yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Start a run from the center button — your recent '
                      'activities show up here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final docs = snap.data!.docs;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final d = docs[i];
              final run = RunModel.fromFirestore(d.id, d.data());
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    onTap: () => context.push(
                      '/run-summary',
                      extra: RunSummaryPayload(run: run),
                    ),
                    title: Text(
                      LocationUtils.formatDistance(run.distance),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${run.averagePace ?? '—'} · ${run.totalScore} pts',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }
}
