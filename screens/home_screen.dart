import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../widgets/ring_chart.dart';
import 'sleep_detail_screen.dart';
import 'sleep_tracking_screen.dart';
import '../services/sleep_service.dart';
import 'hydration_screen.dart';
import 'daily_stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _hydrationMl = 0;

  int _steps = 0;
  int _stepOffset = -1;
  String _walkStatus = 'stopped';
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  static const int _stepGoal    = 10000;
  static const int _activeGoal  = 60;
  int _calorieGoal = 600;

  int get _activeMinutes => (_steps / 100).floor().clamp(0, _activeGoal + 30);
  int get _calories      => (_steps * 0.04).floor();

  @override
  void initState() {
    super.initState();
    _initPedometer();
    SleepService().init();
    SleepService().addListener(_onSleepChange);
    _loadHydration();
    _loadCalorieGoal();
  }

  void _onSleepChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('calorie_goal');
    if (saved != null && mounted) setState(() => _calorieGoal = saved);
  }

  Future<void> _loadHydration() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final saved = prefs.getString('hydration_date') ?? '';
    if (saved == today) {
      final ml = prefs.getDouble('hydration_ml') ?? 0;
      if (mounted) setState(() => _hydrationMl = ml);
    } else {
      if (mounted) setState(() => _hydrationMl = 0);
    }
  }

  Future<void> _initPedometer() async {
    // Request permission
    final status = await Permission.activityRecognition.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Enable Physical Activity permission in Settings → Apps → Pulse → Permissions'),
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    try {
      // Pedestrian status
      _statusSub = Pedometer.pedestrianStatusStream.listen(
        (e) { if (mounted) setState(() => _walkStatus = e.status); },
        onError: (_) {},
      );

      // Step count stream
      _stepSub = Pedometer.stepCountStream.listen(
        (StepCount event) async {
          // Ignore if device returns 0 (sensor not ready)
          if (event.steps == 0) return;

          final prefs = await SharedPreferences.getInstance();
          final today = DateTime.now().toIso8601String().substring(0, 10);
          final saved = prefs.getString('step_date') ?? '';

          if (saved != today) {
            // New day — reset offset to current steps
            _stepOffset = event.steps;
            await prefs.setString('step_date', today);
            await prefs.setInt('step_offset', _stepOffset);
          } else if (_stepOffset == -1) {
            // Same day, first reading — load saved offset
            final savedOffset = prefs.getInt('step_offset');
            if (savedOffset != null && savedOffset <= event.steps) {
              _stepOffset = savedOffset;
            } else {
              // No valid offset — save current as offset
              _stepOffset = event.steps;
              await prefs.setString('step_date', today);
              await prefs.setInt('step_offset', _stepOffset);
            }
          }

          if (mounted && _stepOffset >= 0) {
            setState(() {
              _steps = (event.steps - _stepOffset).clamp(0, 999999);
            });
          }
        },
        onError: (error) {
          // Silently handle sensor errors
          debugPrint('Pedometer error: $error');
        },
      );
    } catch (e) {
      debugPrint('Pedometer init error: $e');
    }
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    SleepService().removeListener(_onSleepChange);
    super.dispose();
  }

  double get _stepsProgress   => (_steps / _stepGoal).clamp(0.0, 1.0);
  double get _activeProgress  => (_activeMinutes / _activeGoal).clamp(0.0, 1.0);
  double get _calorieProgress => (_calories / _calorieGoal).clamp(0.0, 1.0);
  int    get _overallPct      =>
      (((_stepsProgress + _activeProgress + _calorieProgress) / 3) * 100).round();

  String _fmt(int n) => n >= 1000
      ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k'
      : n.toString();

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── TEMP DEBUG CARD — remove after testing ──────────────────────────────
  Widget _buildDebugCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔧 Pedometer Debug',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.orange)),
          const SizedBox(height: 6),
          Text('Raw steps from sensor: $_steps',
              style: const TextStyle(fontSize: 13)),
          Text('Step offset saved: $_stepOffset',
              style: const TextStyle(fontSize: 13)),
          Text('Walk status: $_walkStatus',
              style: const TextStyle(fontSize: 13)),
          const Text('Permission: tap Start Walk to test',
              style:  TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _initPedometer,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Re-request Permission',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AC.isDark(context);
    return Scaffold(
      backgroundColor: AC.bg(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(isDark)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeroCard(isDark),
                const SizedBox(height: 12),
                _buildDebugCard(),
                const SizedBox(height: 16),
                _buildBentoGrid(isDark),
                const SizedBox(height: 16),
                _buildSleepHydrationRow(isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: TextStyle(
                    fontSize: 14,
                    color: AC.subtext(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _walkStatus == 'walking'
                      ? 'Keep going! 🚶' : 'Stay active today',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AC.text(context),
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Notification bell
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AC.card(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: AC.text(context),
                      size: 22,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.pink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero card with ring chart ──────────────────────────────────────────────
  Widget _buildHeroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0E2A1E), const Color(0xFF0A1F2E)]
              : [const Color(0xFFE6FDF5), const Color(0xFFE0F4FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? AppTheme.green.withValues(alpha: 0.15)
              : AppTheme.green.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Goal',
                    style: TextStyle(
                      fontSize: 13,
                      color: AC.subtext(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_overallPct',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.green,
                          ),
                        ),
                        TextSpan(
                          text: '%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.green.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'completed today',
                    style: TextStyle(
                      fontSize: 13,
                      color: AC.subtext(context),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 110,
                height: 110,
                child: RingChart(
                  stepsProgress: _stepsProgress,
                  activeProgress: _activeProgress,
                  caloriesProgress: _calorieProgress,
                  centerText: '',
                  centerSubText: '',
                  size: 110,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Steps progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_fmt(_steps)} steps',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AC.text(context),
                    ),
                  ),
                  Text(
                    'Goal: ${_fmt(_stepGoal)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AC.subtext(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _stepsProgress,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? const Color(0xFF1A3020)
                      : const Color(0xFFCCF5E7),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bento grid ────────────────────────────────────────────────────────────
  Widget _buildBentoGrid(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                icon: Icons.directions_walk,
                label: 'Steps',
                value: _fmt(_steps),
                sub: 'of ${_fmt(_stepGoal)}',
                color: AppTheme.green,
                bg: AC.cardGreen(context),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DailyStatsScreen(
                    type: 'steps', current: _steps, goal: _stepGoal))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bentoCard(
                icon: Icons.timer_outlined,
                label: 'Active',
                value: '$_activeMinutes',
                sub: 'of ${_fmt(_activeGoal)} min',
                color: AppTheme.blue,
                bg: AC.cardBlue(context),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DailyStatsScreen(
                    type: 'active', current: _activeMinutes, goal: _activeGoal))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Calories',
                value: '$_calories',
                sub: 'of ${_fmt(_calorieGoal)} kcal',
                color: AppTheme.pink,
                bg: AC.cardPink(context),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DailyStatsScreen(
                    type: 'calories', current: _calories, goal: _calorieGoal))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bentoCard(
                icon: Icons.water_drop_outlined,
                label: 'Hydration',
                value: (_hydrationMl / 1000).toStringAsFixed(1),
                sub: 'of 2.0 L',
                color: AppTheme.blue,
                bg: AC.cardBlue(context),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HydrationScreen()),
                ).then((_) => _loadHydration()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bentoCard({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    required Color color,
    required Color bg,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: AC.subtext(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AC.text(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sleep + Hydration row ─────────────────────────────────────────────────
  Widget _buildSleepHydrationRow(bool isDark) {
    final sleepScore = SleepService().lastResult?.score;
    final isTracking = SleepService().isTracking;

    return Column(
      children: [
        // Sleep card
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SleepDetailScreen())),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AC.card(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AC.divider(context)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.bedtime_rounded,
                      color: AppTheme.purple, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last night',
                        style: TextStyle(
                            fontSize: 12, color: AC.subtext(context))),
                    Row(
                      children: [
                        Text(
                          sleepScore != null ? '$sleepScore' : '--',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.purple,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('sleep score',
                            style: TextStyle(
                                fontSize: 13, color: AC.subtext(context))),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AC.subtext(context)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Sleep tracking button
        GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SleepTrackingScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: isTracking
                  ? AppTheme.purple
                  : AppTheme.purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.purple.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isTracking ? Icons.bedtime : Icons.bedtime_outlined,
                  color: isTracking ? Colors.white : AppTheme.purple,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isTracking
                      ? 'Tracking sleep...'
                      : 'Start sleep tracking tonight',
                  style: TextStyle(
                    color: isTracking ? Colors.white : AppTheme.purple,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}