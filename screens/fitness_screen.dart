import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import '../theme.dart'; // AC helper available
import 'live_workout_screen.dart';

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  final _service = WorkoutService();

  static const List<Map<String, dynamic>> _activities = [
    {
      'icon': Icons.directions_walk,
      'label': 'Walking',
      'color': AppTheme.green,
      'bg': Color(0xFFE8F5E9),
      'btnColor': AppTheme.green,
    },
    {
      'icon': Icons.directions_run,
      'label': 'Running',
      'color': AppTheme.pink,
      'bg': Color(0xFFFCE4EC),
      'btnColor': AppTheme.pink,
    },
    {
      'icon': Icons.directions_bike,
      'label': 'Cycling',
      'color': AppTheme.blue,
      'bg': Color(0xFFE3F2FD),
      'btnColor': AppTheme.blue,
    },
    {
      'icon': Icons.pool,
      'label': 'Swimming',
      'color': Color(0xFF26A69A),
      'bg': Color(0xFFE0F2F1),
      'btnColor': Color(0xFF26A69A),
    },
  ];

  static const List<String> _days = [
    'M', 'T', 'W', 'T', 'F', 'S', 'S'
  ];

  @override
  void initState() {
    super.initState();
    _service.addListener(_onUpdate);
    _service.init();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = _service.weeklyStreak;
    final recents = _service.recentWorkouts;

    return Scaffold(
      backgroundColor: AC.bg(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStreakRow(streak),
                  const SizedBox(height: 16),
                  ..._activities.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildActivityCard(context, a),
                      )),
                  const SizedBox(height: 8),
                  _buildRecentWorkouts(recents),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppTheme.green,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.monitor_heart,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('Pulse',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Move your body',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            "Pick an activity and we'll track every step, beat, and breath in real time.",
            style: TextStyle(
                fontSize: 14, color: AC.subtext(context)),
          ),
        ],
      )
    );
  }

  // ── Real streak row ───────────────────────────────────────────────────────
  Widget _buildStreakRow(List<bool> streak) {
    final today = DateTime.now().weekday - 1; // 0=Mon, 6=Sun

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
          color: AC.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AC.divider(context))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final done = streak[i];
              final isToday = i == today;
              return Column(
                children: [
                  Text(_days[i],
                      style: TextStyle(
                          fontSize: 12,
                          color: isToday
                              ? AppTheme.green
                              : AC.subtext(context),
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w500)),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? AppTheme.green
                          : isToday
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF5F5F5),
                      border: isToday && !done
                          ? Border.all(
                              color: AppTheme.green, width: 1.5)
                          : null,
                    ),
                    child: done
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          // Streak count
          Text(
            _streakMessage(streak),
            style: TextStyle(
                fontSize: 12,
                color: AC.subtext(context)),
          ),
        ],
      ),
    );
  }

  String _streakMessage(List<bool> streak) {
    int count = 0;
    final today = DateTime.now().weekday - 1;
    for (int i = today; i >= 0; i--) {
      if (streak[i]) {
        count++;
      } else {
        break;
      }
    }
    if (count == 0) return 'Start your streak today! 💪';
    if (count == 1) return '1 day streak — keep going! 🔥';
    return '$count day streak this week! 🔥';
  }

  // ── Activity card with real stats ─────────────────────────────────────────
  Widget _buildActivityCard(
      BuildContext context, Map<String, dynamic> a) {
    final stat = _service.statFor(a['label'] as String);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
          color: AC.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AC.divider(context))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: a['bg'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(a['icon'] as IconData,
                color: a['color'] as Color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['label'] as String,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                Text(stat,
                    style: TextStyle(
                        fontSize: 13,
                        color: AC.subtext(context))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveWorkoutScreen(
                    activity: a['label'] as String),
              ),
            ).then((_) => setState(() {})),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: a['btnColor'] as Color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('Start',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Real recent workouts ──────────────────────────────────────────────────
  Widget _buildRecentWorkouts(List<WorkoutRecord> workouts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent workouts',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            if (workouts.isNotEmpty)
              Text('${workouts.length} total',
                  style: const TextStyle(
                      color: AppTheme.green,
                      fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        if (workouts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: AC.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AC.divider(context))),
            child:  Center(
              child: Column(
                children: [
                  const Text('🏃',
                      style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  const Text('No workouts yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text('Start an activity above!',
                      style: TextStyle(
                          fontSize: 13,
                          color: AC.subtext(context))),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
                color: AC.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AC.divider(context))),
            child: Column(
              children: workouts
                  .asMap()
                  .entries
                  .map((e) {
                final i = e.key;
                final w = e.value;
                return Column(
                  children: [
                    _workoutRow(w),
                    if (i < workouts.length - 1)
                      Divider(height: 1, indent: 16, color: AC.divider(context)),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // Get icon/color directly by activity name — no lookup needed
  IconData _activityIcon(String activity) {
    switch (activity) {
      case 'Running':  return Icons.directions_run;
      case 'Cycling':  return Icons.directions_bike;
      case 'Swimming': return Icons.pool;
      default:         return Icons.directions_walk;
    }
  }

  Color _activityColor(String activity) {
    switch (activity) {
      case 'Running':  return AppTheme.pink;
      case 'Cycling':  return AppTheme.blue;
      case 'Swimming': return const Color(0xFF26A69A);
      default:         return AppTheme.green;
    }
  }

  Color _activityBg(String activity) {
    switch (activity) {
      case 'Running':  return const Color(0xFFFCE4EC);
      case 'Cycling':  return const Color(0xFFE3F2FD);
      case 'Swimming': return const Color(0xFFE0F2F1);
      default:         return const Color(0xFFE8F5E9);
    }
  }

  Widget _workoutRow(WorkoutRecord w) {
    return GestureDetector(
      onTap: () => _showWorkoutSummary(w),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _activityBg(w.activity),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _activityIcon(w.activity),
                color: _activityColor(w.activity),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.activity,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700)),
                  Text(w.formattedDate,
                      style: TextStyle(
                          fontSize: 12,
                          color: AC.subtext(context))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(w.formattedDistance,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(w.formattedDuration,
                    style: TextStyle(
                        fontSize: 12,
                        color: AC.subtext(context))),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                color: AC.subtext(context), size: 18),
          ],
        ),
      ),
    );
  }

  // ── Workout summary bottom sheet ──────────────────────────────────────────
  void _showWorkoutSummary(WorkoutRecord w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AC.card(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AC.divider(context),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _activityBg(w.activity),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(_activityIcon(w.activity),
                      color: _activityColor(w.activity), size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.activity,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AC.text(context))),
                    Text(w.formattedDate,
                        style: TextStyle(
                            fontSize: 13,
                            color: AC.subtext(context))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _summaryStatCard('⏱️', 'Duration', w.formattedDuration),
                const SizedBox(width: 10),
                _summaryStatCard('👣', 'Steps', '\${w.steps}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _summaryStatCard('📍', 'Distance', w.formattedDistance),
                const SizedBox(width: 10),
                _summaryStatCard('🔥', 'Calories', '\${w.calories} kcal'),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AC.card(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text('🏃', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Avg Pace',
                          style: TextStyle(
                              fontSize: 11,
                              color: AC.subtext(context),
                              letterSpacing: 0.5)),
                      Text(w.formattedPace,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _deleteWorkout(w);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 6),
                          Text('Delete',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('Close',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _summaryStatCard(
      String emoji, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AC.card(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: AC.subtext(context),
                    letterSpacing: 0.5)),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AC.text(context))),
          ],
        ),
      ),
    );
  }

  void _deleteWorkout(WorkoutRecord w) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete workout?'),
        content: const Text(
            'Delete \${w.activity} on \${w.formattedDate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              WorkoutService().deleteWorkout(w.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}