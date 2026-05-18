import 'workout_service.dart';

class HealthBadge {
  final String id;
  final String emoji;
  final String label;
  final String description;
  final bool unlocked;

  const HealthBadge({
    required this.id,
    required this.emoji,
    required this.label,
    required this.description,
    required this.unlocked,
  });
}

class AchievementsService {
  static final AchievementsService _instance =
      AchievementsService._internal();
  factory AchievementsService() => _instance;
  AchievementsService._internal();

  // ── Check all badges against real data ───────────────────────────────────
  List<HealthBadge> getBadges({
    required int totalSteps,
    required int totalWorkouts,
    required int streakDays,
    required double hydrationLitres,
    required int sleepScore,
  }) {
    final workouts = WorkoutService().allWorkouts;

    // Has run 5km in a single workout
    final hasRun5k =
        workouts.any((w) => w.activity == 'Running' && w.distanceKm >= 5);

    // Has cycled 20km total
    final cycleKm = workouts
        .where((w) => w.activity == 'Cycling')
        .fold<double>(0, (sum, w) => sum + w.distanceKm);

    // Has swum at least once
    final hasSwum =
        workouts.any((w) => w.activity == 'Swimming');

    return <HealthBadge>[
      HealthBadge(
        id: 'first_steps',
        emoji: '👟',
        label: 'First Steps',
        description: 'Take your first 1,000 steps',
        unlocked: totalSteps >= 1000,
      ),
      HealthBadge(
        id: 'step_5k',
        emoji: '🚶',
        label: '5K Steps',
        description: 'Walk 5,000 steps in a day',
        unlocked: totalSteps >= 5000,
      ),
      HealthBadge(
        id: 'step_10k',
        emoji: '🏆',
        label: '10K Steps',
        description: 'Reach 10,000 steps in a day',
        unlocked: totalSteps >= 10000,
      ),
      HealthBadge(
        id: 'first_run_5k',
        emoji: '🏃',
        label: 'First 5K',
        description: 'Run 5km in a single workout',
        unlocked: hasRun5k,
      ),
      HealthBadge(
        id: 'streak_3',
        emoji: '🔥',
        label: '3-Day Streak',
        description: 'Work out 3 days in a row',
        unlocked: streakDays >= 3,
      ),
      HealthBadge(
        id: 'streak_7',
        emoji: '⚡',
        label: '7-Day Streak',
        description: 'Work out 7 days in a row',
        unlocked: streakDays >= 7,
      ),
      HealthBadge(
        id: 'hydrated',
        emoji: '💧',
        label: 'Hydrated',
        description: 'Drink 2L of water in a day',
        unlocked: hydrationLitres >= 2.0,
      ),
      HealthBadge(
        id: 'good_sleep',
        emoji: '🌙',
        label: 'Deep Sleeper',
        description: 'Get a sleep score above 80',
        unlocked: sleepScore >= 80,
      ),
      HealthBadge(
        id: 'first_workout',
        emoji: '💪',
        label: 'First Workout',
        description: 'Complete your first workout',
        unlocked: totalWorkouts >= 1,
      ),
      HealthBadge(
        id: 'workout_10',
        emoji: '🥇',
        label: '10 Workouts',
        description: 'Complete 10 workouts',
        unlocked: totalWorkouts >= 10,
      ),
      HealthBadge(
        id: 'cyclist',
        emoji: '🚴',
        label: 'Cyclist',
        description: 'Cycle 20km total',
        unlocked: cycleKm >= 20,
      ),
      HealthBadge(
        id: 'swimmer',
        emoji: '🏊',
        label: 'Swimmer',
        description: 'Complete a swimming workout',
        unlocked: hasSwum,
      ),
    ];
  }

  // Count unlocked badges
  int unlockedCount({
    required int totalSteps,
    required int totalWorkouts,
    required int streakDays,
    required double hydrationLitres,
    required int sleepScore,
  }) {
    return getBadges(
      totalSteps: totalSteps,
      totalWorkouts: totalWorkouts,
      streakDays: streakDays,
      hydrationLitres: hydrationLitres,
      sleepScore: sleepScore,
    ).where((b) => b.unlocked).length;
  }
}