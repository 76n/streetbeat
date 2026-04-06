import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/badges.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/location_utils.dart';
import '../../../core/utils/time_format_utils.dart';
import '../../../shared/repositories/social_repository.dart'
    show FriendRequestDoc, SocialRepository, UserSearchHit;
import '../../run/models/run_model.dart';
import '../../run/models/run_summary_payload.dart';
import '../widgets/feed_route_thumbnail.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final SocialRepository _social = sl<SocialRepository>();
  List<RunModel> _runs = [];
  void Function()? _disposeFeed;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    final u = _uid;
    if (u != null) {
      _disposeFeed = _social.watchActivityFeed(
        myUid: u,
        onRuns: (runs) {
          if (mounted) {
            setState(() => _runs = runs);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _disposeFeed?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'StreetBeat',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Friends & requests',
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textPrimary,
            onPressed:
                uid == null ? null : () => _openFriendsSheet(context, uid),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to see your feed.'))
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              displacement: 48,
              strokeWidth: 3,
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 450));
                if (mounted) {
                  setState(() {});
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  if (_runs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '🏃',
                              style: TextStyle(
                                fontSize: 56,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No runs yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Complete your first run to see it here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.95,
                                ),
                                height: 1.4,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 28),
                            FilledButton(
                              onPressed: () => context.push('/run'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Start your first run →'),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => _openFriendsSheet(context, uid),
                              child: const Text('Find friends'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final run = _runs[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ActivityCard(
                                run: run,
                                viewerUid: uid,
                                onKudosChanged: () => setState(() {}),
                                onOpenRun: () => context.push(
                                  '/run-summary',
                                  extra: RunSummaryPayload(
                                    run: run,
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _runs.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  void _openFriendsSheet(BuildContext context, String myUid) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scroll) {
            return _FriendsSheetContent(
              scrollController: scroll,
              myUid: myUid,
              social: _social,
            );
          },
        );
      },
    );
  }
}

class _FriendsSheetContent extends StatefulWidget {
  const _FriendsSheetContent({
    required this.scrollController,
    required this.myUid,
    required this.social,
  });

  final ScrollController scrollController;
  final String myUid;
  final SocialRepository social;

  @override
  State<_FriendsSheetContent> createState() => _FriendsSheetContentState();
}

class _FriendsSheetContentState extends State<_FriendsSheetContent> {
  final _search = TextEditingController();
  List<UserSearchHit> _hits = [];
  bool _searching = false;
  String _searchError = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _search.text.trim();
    setState(() {
      _searching = true;
      _searchError = '';
      _hits = [];
    });
    try {
      final r = await widget.social.searchUsers(
        myUid: widget.myUid,
        query: q,
      );
      if (mounted) {
        setState(() => _hits = r);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searchError = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const Text(
          'Friend requests',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<FriendRequestDoc>>(
          stream: widget.social.incomingRequestsStream(widget.myUid),
          builder: (context, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return const Text(
                'No pending requests.',
                style: TextStyle(color: AppColors.textSecondary),
              );
            }
            return Column(
              children: snap.data!
                  .map(
                    (r) => _IncomingRequestTile(
                      doc: r,
                      social: widget.social,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 28),
        const Text(
          'Add friends',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 6),
        const Text(
          'Search by name or email',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Name or email',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _runSearch(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _searching ? null : _runSearch,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
              child: _searching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : const Text('Search'),
            ),
          ],
        ),
        if (_searchError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _searchError,
            style: const TextStyle(color: Color(0xFFE57373)),
          ),
        ],
        const SizedBox(height: 12),
        ..._hits.map(
          (h) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(h.name),
            subtitle: Text(
              h.city.isNotEmpty ? '${h.email} · ${h.city}' : h.email,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: FilledButton.tonal(
              onPressed: () async {
                try {
                  await widget.social.sendFriendRequest(toUid: h.uid);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Friend request sent'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$e'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ),
        ),
      ],
    );
  }
}

class _IncomingRequestTile extends StatelessWidget {
  const _IncomingRequestTile({
    required this.doc,
    required this.social,
  });

  final FriendRequestDoc doc;
  final SocialRepository social;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          FirebaseFirestore.instance.collection('users').doc(doc.fromUid).get(),
      builder: (context, snap) {
        final name = snap.data?.data()?['name'] as String? ?? 'Runner';
        return Card(
          color: AppColors.card,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(name),
            subtitle: const Text('Wants to connect'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => social.declineFriendRequest(
                    requesterUid: doc.fromUid,
                  ),
                  child: const Text('Decline'),
                ),
                FilledButton(
                  onPressed: () async {
                    await social.acceptFriendRequest(
                      requesterUid: doc.fromUid,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({
    required this.run,
    required this.viewerUid,
    required this.onKudosChanged,
    required this.onOpenRun,
  });

  final RunModel run;
  final String viewerUid;
  final VoidCallback onKudosChanged;
  final VoidCallback onOpenRun;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard>
    with SingleTickerProviderStateMixin {
  bool _kudosBusy = false;
  int? _kudosCountOverride;
  bool? _iGaveKudosOverride;
  late final AnimationController _kudosBurst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _kudosBurst.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.run.id != widget.run.id ||
        oldWidget.run.kudosCount != widget.run.kudosCount ||
        oldWidget.run.kudosUserIds.length != widget.run.kudosUserIds.length) {
      _kudosCountOverride = null;
      _iGaveKudosOverride = null;
    }
  }

  Future<void> _toggleKudos() async {
    if (_kudosBusy) {
      return;
    }
    final r = widget.run;
    final had = r.kudosUserIds.contains(widget.viewerUid);
    setState(() {
      _kudosBusy = true;
      _iGaveKudosOverride = !had;
      _kudosCountOverride = r.kudosCount + (had ? -1 : 1);
    });
    try {
      await sl<SocialRepository>().toggleKudos(
        runId: widget.run.id,
        uid: widget.viewerUid,
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        unawaited(_kudosBurst.forward(from: 0).then((_) {
          if (mounted) {
            _kudosBurst.reverse();
          }
        }));
      }
      widget.onKudosChanged();
    } catch (_) {
      if (mounted) {
        setState(() {
          _kudosCountOverride = null;
          _iGaveKudosOverride = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _kudosBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.run;
    final name = r.runnerName.isNotEmpty ? r.runnerName : 'Runner';
    final iGaveKudos =
        _iGaveKudosOverride ?? r.kudosUserIds.contains(widget.viewerUid);
    final kudosCount = _kudosCountOverride ?? r.kudosCount;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onOpenRun,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.22),
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          formatRelativeTime(r.startedAt),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FeedRouteThumbnail(route: r.route),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatChip(
                    icon: Icons.straighten_rounded,
                    text: LocationUtils.formatDistance(r.distance),
                  ),
                  _StatChip(
                    icon: Icons.speed_rounded,
                    text: r.averagePace ?? '—',
                  ),
                  _StatChip(
                    icon: Icons.timer_outlined,
                    text: formatDurationHms(r.durationSeconds),
                  ),
                  _StatChip(
                    icon: Icons.stars_rounded,
                    text: '${r.totalScore}',
                  ),
                ],
              ),
              if (r.earnedBadgeIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: r.earnedBadgeIds
                      .map(
                        (id) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            kBadgeById[id]?.icon ?? '🏅',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _kudosBusy ? null : _toggleKudos,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: Tween<double>(begin: 1, end: 1.35).animate(
                                CurvedAnimation(
                                  parent: _kudosBurst,
                                  curve: Curves.elasticOut,
                                ),
                              ),
                              child: Text(
                                '👊',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: iGaveKudos
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$kudosCount',
                              style: TextStyle(
                                color: iGaveKudos
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${r.commentCount}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
