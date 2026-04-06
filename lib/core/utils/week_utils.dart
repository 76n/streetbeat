abstract final class WeekUtils {
  static DateTime utcDate(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static DateTime mondayUtc(DateTime date) {
    final d = utcDate(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static String isoWeekToken(DateTime date) {
    final d = utcDate(date);
    final weekday = d.weekday;
    final monday = d.subtract(Duration(days: weekday - 1));
    final thursday = monday.add(const Duration(days: 3));
    final year = thursday.year;
    final jan4 = DateTime.utc(year, 1, 4);
    final jan4Monday = jan4.subtract(Duration(days: jan4.weekday - 1));
    final weekIndex = thursday.difference(jan4Monday).inDays ~/ 7;
    final week = weekIndex + 1;
    return '$year-W${week.toString().padLeft(2, '0')}';
  }

  static int streakWeeksMeetingGoal({
    required List<String> weeklyRuns,
    required int weeklyGoalRuns,
    required DateTime now,
    int lookbackWeeks = 8,
  }) {
    final counts = <String, int>{};
    for (final w in weeklyRuns) {
      counts[w] = (counts[w] ?? 0) + 1;
    }
    final baseMonday = mondayUtc(now.toUtc());
    var streak = 0;
    for (var i = 0; i < lookbackWeeks; i++) {
      final monday = baseMonday.subtract(Duration(days: 7 * i));
      final token = isoWeekToken(monday);
      if ((counts[token] ?? 0) >= weeklyGoalRuns) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
