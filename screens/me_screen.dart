import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart'; // OK
import '../services/workout_service.dart';
import '../services/achievements_service.dart';
import '../services/sleep_service.dart';
import '../theme.dart'; // AC helper available

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final _profile  = ProfileService();
  final _theme    = ThemeService();
  final _workouts = WorkoutService();
  final _achieve  = AchievementsService();

  double _hydrationLitres = 0;

  @override
  void initState() {
    super.initState();
    _profile.addListener(_onUpdate);
    _workouts.addListener(_onUpdate);
    _theme.addListener(_onUpdate);
    _profile.init();
    _workouts.init();
    _loadHydration();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadHydration() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final saved = prefs.getString('hydration_date') ?? '';
    if (saved == today) {
      final ml = prefs.getDouble('hydration_ml') ?? 0;
      if (mounted) setState(() => _hydrationLitres = ml / 1000);
    }
  }

  @override
  void dispose() {
    _profile.removeListener(_onUpdate);
    _workouts.removeListener(_onUpdate);
    _theme.removeListener(_onUpdate);
    super.dispose();
  }

  // ── Computed stats ────────────────────────────────────────────────────────
  int get _totalWorkouts => _workouts.totalWorkouts;
  int get _totalSteps    => _workouts.totalSteps;

  int get _currentStreak {
    final streak = _workouts.weeklyStreak;
    int count = 0;
    final today = DateTime.now().weekday - 1;
    for (int i = today; i >= 0; i--) {
      if (streak[i]) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  int get _sleepScore =>
      SleepService().lastResult?.score ?? 0;

  List<HealthBadge> get _badges => _achieve.getBadges(
        totalSteps: _totalSteps,
        totalWorkouts: _totalWorkouts,
        streakDays: _currentStreak,
        hydrationLitres: _hydrationLitres,
        sleepScore: _sleepScore,
      );

  int get _unlockedCount =>
      _badges.where((b) => b.unlocked).length;

  String _formatSteps(int steps) {
    if (steps >= 1000000) {
      return '${(steps / 1000000).toStringAsFixed(1)}M';
    }
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return '$steps';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileCard(),
                  const SizedBox(height: 12),
                  _buildWeeklyChart(),
                  const SizedBox(height: 12),
                  _buildDarkModeToggle(),
                  const SizedBox(height: 12),
                  _buildAchievements(),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
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
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AC.isDark(context) ? const Color(0xFF1A2A1A) : const Color(0xFFF0F4EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      AppTheme.green.withValues(alpha: 0.3),
                  backgroundImage: _profile.photoPath != null
                      ? FileImage(File(_profile.photoPath!))
                      : null,
                  child: _profile.photoPath == null
                      ? Text(
                          _profile.initials,
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.green),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppTheme.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tappable name
          GestureDetector(
            onTap: _editName,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _profile.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 6),
                Icon(Icons.edit,
                    size: 16, color: AC.subtext(context)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _profile.joinDateStr,
                style: TextStyle(
                    fontSize: 13, color: AC.subtext(context)),
              ),
              if (_currentStreak > 0) ...[
                Text(' · ',
                    style: TextStyle(
                        color: AC.subtext(context))),
                Text('$_currentStreak-day streak',
                    style: TextStyle(
                        fontSize: 13,
                        color: AC.subtext(context))),
                const SizedBox(width: 4),
                const Text('🔥',
                    style: TextStyle(fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 20),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem('$_totalWorkouts', 'WORKOUTS'),
              Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300),
              _statItem(_formatSteps(_totalSteps), 'STEPS'),
              Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300),
              _statItem('$_unlockedCount', 'BADGES'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: AC.subtext(context),
                letterSpacing: 0.5)),
      ],
    );
  }

  // ── Edit name dialog ──────────────────────────────────────────────────────
  void _editName() {
    final controller =
        TextEditingController(text: _profile.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter your name',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              _profile.saveName(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Pick photo ────────────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 400,
    );
    if (picked != null) {
      await _profile.savePhoto(picked.path);
    }
  }

  // ── Dark mode toggle ─────────────────────────────────────────────────────────
  Widget _buildDarkModeToggle() {
    final isDark = _theme.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AC.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.amber : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dark Mode',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AC.text(context))),
                Text(isDark ? 'On' : 'Off',
                    style: TextStyle(
                        fontSize: 12, color: AC.subtext(context))),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => _theme.toggleTheme(),
            activeThumbColor: AppTheme.green,
            activeTrackColor: AppTheme.green.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  // ── Weekly bar chart (real step data) ─────────────────────────────────────
  Widget _buildWeeklyChart() {
    final weeklySteps = _getWeeklySteps();
    final maxSteps =
        weeklySteps.fold<double>(1000, (m, s) => s > m ? s : m);

    final barGroups = List.generate(7, (i) {
      final steps = weeklySteps[i];
      final opacity =
          steps > 0 ? (steps / maxSteps).clamp(0.3, 1.0) : 0.1;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: steps,
            color: AppTheme.green.withValues(alpha: opacity),
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AC.card(context),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('This week',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(_weekRangeStr(),
                  style: TextStyle(
                      fontSize: 13,
                      color: AC.subtext(context))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                maxY: maxSteps * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const days = [
                          'M', 'T', 'W', 'T', 'F', 'S', 'S'
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(days[v.toInt()],
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AC.subtext(context))),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get steps per day this week from workout history
  List<double> _getWeeklySteps() {
    final now = DateTime.now();
    final monday =
        now.subtract(Duration(days: now.weekday - 1));
    final mondayDay =
        DateTime(monday.year, monday.month, monday.day);

    return List.generate(7, (i) {
      final day = mondayDay.add(Duration(days: i));
      final dayWorkouts = _workouts.allWorkouts.where((w) {
        final wDay = DateTime(w.startTime.year,
            w.startTime.month, w.startTime.day);
        return wDay == day;
      });
      return dayWorkouts
          .fold<double>(0, (sum, w) => sum + w.steps);
    });
  }

  String _weekRangeStr() {
    final now = DateTime.now();
    final monday =
        now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${monday.day} ${months[monday.month - 1]} – ${sunday.day}';
  }

  // ── Achievements grid ─────────────────────────────────────────────────────
  Widget _buildAchievements() {
    final badges = _badges;
    final unlocked = badges.where((b) => b.unlocked).toList();
    final locked   = badges.where((b) => !b.unlocked).toList();
    final sorted   = [...unlocked, ...locked];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Achievements',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            Text('$_unlockedCount / ${badges.length}',
                style: const TextStyle(
                    color: AppTheme.green,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: sorted.length,
          itemBuilder: (_, i) {
            final b = sorted[i];
            return GestureDetector(
              onTap: () => _showBadgeInfo(b),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration( // ignore: prefer_const_constructors
                      color: b.unlocked
                          ? AC.card(context)
                          : AC.card(context),
                      borderRadius:
                          BorderRadius.circular(16),
                      boxShadow: b.unlocked
                          ? [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.06),
                                blurRadius: 4,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: b.unlocked
                          ? Text(b.emoji,
                              style: const TextStyle(
                                  fontSize: 26))
                          : Icon(Icons.lock_outline,
                              color: Colors.grey.shade400,
                              size: 24),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b.label,
                    style: TextStyle(
                        fontSize: 10,
                        color: b.unlocked
                            ? AC.text(context)
                            : AC.subtext(context),
                        fontWeight: b.unlocked
                            ? FontWeight.w600
                            : FontWeight.normal),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Badge info popup ──────────────────────────────────────────────────────
  void _showBadgeInfo(HealthBadge b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              b.unlocked ? b.emoji : '🔒',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(b.label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(b.description,
                style: TextStyle(
                    fontSize: 13,
                    color: AC.subtext(context)),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: b.unlocked
                    ? const Color(0xFFE8F5E9)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                b.unlocked ? '✅ Unlocked!' : '🔒 Not yet',
                style: TextStyle(
                    color: b.unlocked
                        ? AppTheme.green
                        : AC.subtext(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}