import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/badges.dart';
import '../../core/theme/colors.dart';
import '../models/badge_model.dart';
import '../models/user_model.dart';

String? badgeProgressHint(String badgeId, UserModel u) {
  switch (badgeId) {
    case 'three_runs':
      return '${u.totalRuns.clamp(0, 3)}/3 runs';
    case 'week_streak_1':
      return '${u.currentStreakWeeks.clamp(0, 1)}/1 week streak';
    case 'week_streak_3':
      return '${u.currentStreakWeeks.clamp(0, 3)}/3 week streak';
    case 'week_streak_6':
      return '${u.currentStreakWeeks.clamp(0, 6)}/6 week streak';
    case 'week_streak_10':
      return '${u.currentStreakWeeks.clamp(0, 10)}/10 week streak';
    case 'week_streak_20':
      return '${u.currentStreakWeeks.clamp(0, 20)}/20 week streak';
    case 'early_bird':
      return '${u.earlyBirdRuns.clamp(0, 5)}/5 runs before 7am';
    case 'night_owl':
      return '${u.nightOwlRuns.clamp(0, 5)}/5 runs after 9pm';
    case 'rain_warrior':
      return '${u.rainRuns.clamp(0, 3)}/3 runs in rain';
    case 'explorer_1':
      return '${u.explorerCoinsLifetime.clamp(0, 10)}/10 explorer coins';
    case 'explorer_2':
      return '${u.uniqueStreetCells.length.clamp(0, 20)}/20 unique streets';
    case 'explorer_3':
      return '${u.uniqueStreetCells.length.clamp(0, 50)}/50 unique streets';
    case 'five_neighborhoods':
      return '${u.neighborhoodCells.length.clamp(0, 5)}/5 neighborhoods';
    case 'elevation_hunter':
      return '${u.elevationCoinsLifetime.clamp(0, 20)}/20 elevation coins';
    case 'streetbeat_master':
      return '${u.streetbeatSessionsLifetime.clamp(0, 10)}/10 STREETBEATs';
    case 'gate_master':
      return '${u.gatesCapturedLifetime.clamp(0, 100)}/100 gates';
    case 'coin_collector':
      return '${u.totalCoins.clamp(0, 1000)}/1000 coins';
    case 'ghost_beater':
      return '${u.ghostBeatsLifetime.clamp(0, 5)}/5 ghost wins';
    case 'phantom_hunter':
      return '${u.phantomGoldLifetime.clamp(0, 5)}/5 phantom coins';
    case 'distance_5k':
    case 'distance_10k':
    case 'distance_half':
      return 'Complete in a single run';
    case 'first_streetbeat':
      return u.streetbeatSessionsLifetime >= 1
          ? null
          : 'Reach STREETBEAT multiplier';
    case 'new_neighborhood':
      return 'Run in a new neighborhood tile';
    default:
      return null;
  }
}

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.user});

  final UserModel user;

  static String _categoryTitle(BadgeCategory c) {
    return switch (c) {
      BadgeCategory.consistency => 'Consistency',
      BadgeCategory.adventurousness => 'Adventurousness',
      BadgeCategory.performance => 'Performance',
    };
  }

  @override
  Widget build(BuildContext context) {
    final byCategory = <BadgeCategory, List<BadgeDefinition>>{};
    for (final c in BadgeCategory.values) {
      byCategory[c] =
          kAllBadgeDefinitions.where((d) => d.category == c).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: EdgeInsets.only(
              top: entry.key == BadgeCategory.consistency ? 0 : 20,
              bottom: 10,
            ),
            child: Text(
              _categoryTitle(entry.key),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemCount: entry.value.length,
            itemBuilder: (context, i) {
              return _BadgeGridCell(
                def: entry.value[i],
                user: user,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _BadgeGridCell extends StatelessWidget {
  const _BadgeGridCell({
    required this.def,
    required this.user,
  });

  final BadgeDefinition def;
  final UserModel user;

  @override
  Widget build(BuildContext context) {
    BadgeModel? earned;
    for (final b in user.badges) {
      if (b.id == def.id) {
        earned = b;
        break;
      }
    }
    final earnedAt = earned?.earnedAt;
    final locked = earned == null;

    Widget tile = Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openSheet(context, earned),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                def.icon,
                style: TextStyle(
                  fontSize: locked ? 30 : 34,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                def.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: locked
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (!locked && earnedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().format(earnedAt.toLocal()),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (locked) {
      tile = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: tile,
      );
    }

    return tile;
  }

  void _openSheet(BuildContext context, BadgeModel? earned) {
    final hint = badgeProgressHint(def.id, user);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(def.icon, style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          def.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _categoryLabel(def.category),
                          style: TextStyle(
                            color: Theme.of(ctx).hintColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                def.description,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              if (earned != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Earned ${DateFormat.yMMMd().add_jm().format(earned.earnedAt.toLocal())}',
                  style: TextStyle(
                    color: Theme.of(ctx).hintColor,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Tier: ${earned.tier.name}',
                  style: TextStyle(
                    color: Theme.of(ctx).hintColor,
                    fontSize: 13,
                  ),
                ),
              ] else if (hint != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Progress: $hint',
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _categoryLabel(BadgeCategory c) {
    return switch (c) {
      BadgeCategory.consistency => 'Consistency badge',
      BadgeCategory.adventurousness => 'Adventurousness badge',
      BadgeCategory.performance => 'Performance badge',
    };
  }
}
