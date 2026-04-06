enum BadgeCategory {
  consistency,
  adventurousness,
  performance,
}

enum BadgeTier {
  bronze,
  silver,
  gold,
}

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.tier,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeCategory category;
  final BadgeTier tier;
}

const List<BadgeDefinition> kAllBadgeDefinitions = [
  BadgeDefinition(
    id: 'first_run',
    name: 'First Step',
    description: 'Complete your first run.',
    icon: '🏃',
    category: BadgeCategory.consistency,
    tier: BadgeTier.bronze,
  ),
  BadgeDefinition(
    id: 'three_runs',
    name: 'Getting Started',
    description: 'Complete 3 runs.',
    icon: '🔥',
    category: BadgeCategory.consistency,
    tier: BadgeTier.bronze,
  ),
  BadgeDefinition(
    id: 'week_streak_1',
    name: 'Spark',
    description: 'Maintain a 1-week streak (3+ runs).',
    icon: '🔥',
    category: BadgeCategory.consistency,
    tier: BadgeTier.bronze,
  ),
  BadgeDefinition(
    id: 'week_streak_3',
    name: 'Burning',
    description: 'Maintain a 3-week streak.',
    icon: '🔥🔥',
    category: BadgeCategory.consistency,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'week_streak_6',
    name: 'Blazing',
    description: 'Maintain a 6-week streak.',
    icon: '🔥🔥🔥',
    category: BadgeCategory.consistency,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'week_streak_10',
    name: 'Inferno',
    description: 'Maintain a 10-week streak.',
    icon: '👑',
    category: BadgeCategory.consistency,
    tier: BadgeTier.gold,
  ),
  BadgeDefinition(
    id: 'week_streak_20',
    name: 'Eternal',
    description: 'Maintain a 20-week streak.',
    icon: '🌌',
    category: BadgeCategory.consistency,
    tier: BadgeTier.gold,
  ),
  BadgeDefinition(
    id: 'early_bird',
    name: 'Early Bird',
    description: 'Complete 5 runs before 7am.',
    icon: '🌅',
    category: BadgeCategory.consistency,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'night_owl',
    name: 'Night Owl',
    description: 'Complete 5 runs after 9pm.',
    icon: '🌙',
    category: BadgeCategory.consistency,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'rain_warrior',
    name: 'Rain Warrior',
    description: 'Complete 3 runs in rain.',
    icon: '🌧️',
    category: BadgeCategory.consistency,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'explorer_1',
    name: 'Pathfinder',
    description: 'Collect 10 explorer coins (side streets).',
    icon: '🗺️',
    category: BadgeCategory.adventurousness,
    tier: BadgeTier.bronze,
  ),
  BadgeDefinition(
    id: 'explorer_2',
    name: 'Wanderer',
    description: 'Run on 20 unique streets.',
    icon: '🧭',
    category: BadgeCategory.adventurousness,
    tier: BadgeTier.bronze,
  ),
  BadgeDefinition(
    id: 'explorer_3',
    name: 'Cartographer',
    description: 'Run on 50 unique streets.',
    icon: '🗺️✨',
    category: BadgeCategory.adventurousness,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'new_neighborhood',
    name: 'New Territory',
    description: "Run in a neighborhood you've never run in before.",
    icon: '📍',
    category: BadgeCategory.adventurousness,
    tier: BadgeTier.bronze,
  ),
  BadgeDefinition(
    id: 'five_neighborhoods',
    name: 'City Rover',
    description: 'Run in 5 different neighborhoods.',
    icon: '🏙️',
    category: BadgeCategory.adventurousness,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'elevation_hunter',
    name: 'Hill Climber',
    description: 'Collect 20 elevation coins.',
    icon: '⛰️',
    category: BadgeCategory.adventurousness,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'distance_5k',
    name: '5K Club',
    description: 'Complete a single run of 5km or more.',
    icon: '🏅',
    category: BadgeCategory.adventurousness,
    tier: BadgeTier.bronze,
  ),
  BadgeDefinition(
    id: 'distance_10k',
    name: '10K Club',
    description: 'Complete a single run of 10km or more.',
    icon: '🏅🏅',
    category: BadgeCategory.adventurousness,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'distance_half',
    name: 'Half Marathon Club',
    description: 'Complete 21.1km in one run.',
    icon: '🏆',
    category: BadgeCategory.adventurousness,
    tier: BadgeTier.gold,
  ),
  BadgeDefinition(
    id: 'first_streetbeat',
    name: 'Streetbeat',
    description: 'Reach STREETBEAT multiplier for the first time.',
    icon: '⚡',
    category: BadgeCategory.performance,
    tier: BadgeTier.bronze,
  ),
  BadgeDefinition(
    id: 'streetbeat_master',
    name: 'Streetbeat Master',
    description: 'Reach STREETBEAT 10 times total.',
    icon: '⚡⚡',
    category: BadgeCategory.performance,
    tier: BadgeTier.gold,
  ),
  BadgeDefinition(
    id: 'gate_master',
    name: 'Gate Keeper',
    description: 'Capture 100 gates total.',
    icon: '🚪',
    category: BadgeCategory.performance,
    tier: BadgeTier.gold,
  ),
  BadgeDefinition(
    id: 'coin_collector',
    name: 'Coin Collector',
    description: 'Collect 1000 coins total.',
    icon: '🪙',
    category: BadgeCategory.performance,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'ghost_beater',
    name: 'Ghost Buster',
    description: 'Beat your personal best ghost 5 times.',
    icon: '👻',
    category: BadgeCategory.performance,
    tier: BadgeTier.silver,
  ),
  BadgeDefinition(
    id: 'phantom_hunter',
    name: 'Phantom Hunter',
    description: 'Collect 5 phantom gold coins.',
    icon: '⭐',
    category: BadgeCategory.performance,
    tier: BadgeTier.gold,
  ),
];

final Map<String, BadgeDefinition> kBadgeById = {
  for (final b in kAllBadgeDefinitions) b.id: b,
};
