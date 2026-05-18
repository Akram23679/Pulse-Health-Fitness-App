import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class DailyStatsScreen extends StatefulWidget {
  final String type;
  final int current;
  final int goal;

  const DailyStatsScreen({
    super.key,
    required this.type,
    required this.current,
    required this.goal,
  });

  @override
  State<DailyStatsScreen> createState() => _DailyStatsScreenState();
}

class _DailyStatsScreenState extends State<DailyStatsScreen> {
  late int _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    if (widget.type == 'calories') _loadCalorieGoal();
  }

  Future<void> _loadCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('calorie_goal');
    if (saved != null && mounted) setState(() => _goal = saved);
  }

  Future<void> _saveCalorieGoal(int newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calorie_goal', newGoal);
    if (mounted) setState(() => _goal = newGoal);
  }

  void _editGoal() {
    final controller = TextEditingController(text: '$_goal');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🔥', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('Daily Calorie Goal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 5,
              decoration: InputDecoration(
                hintText: 'e.g. 600',
                suffixText: 'kcal',
                counterText: '',
                filled: true,
                fillColor: AC.card(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            // Quick presets
            Wrap(
              spacing: 8,
              children: [300, 400, 500, 600, 800, 1000].map((v) {
                return GestureDetector(
                  onTap: () => controller.text = '$v',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AC.card(context),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$v',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 100 && val <= 5000) {
                _saveCalorieGoal(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Config per type ────────────────────────────────────────────────────────
  // ignore: unused_element
  String get _title {
    switch (widget.type) {
      case 'steps':    return 'Steps';
      case 'active':   return 'Active Time';
      default:         return 'Calories';
    }
  }

  // ignore: unused_element
  String get _emoji {
    switch (widget.type) {
      case 'steps':    return '👟';
      case 'active':   return '⏱️';
      default:         return '🔥';
    }
  }

  Color get _color {
    switch (widget.type) {
      case 'steps':    return AppTheme.green;
      case 'active':   return AppTheme.blue;
      default:         return AppTheme.pink;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case 'steps':    return Icons.directions_walk;
      case 'active':   return Icons.timer_outlined;
      default:         return Icons.local_fire_department_outlined;
    }
  }

  // ignore: unused_element
  String get _unit {
    switch (widget.type) {
      case 'steps':    return 'steps';
      case 'active':   return 'min';
      default:         return 'kcal';
    }
  }

  // ignore: unused_element
  String get _goalLabel {
    // ignore unused
    switch (widget.type) {
      case 'steps':    return '10,000 steps / day';
      case 'active':   return '60 minutes / day';
      default:         return '600 kcal / day';
    }
  }

  // ignore: unused_element
  String get _tip {
    switch (widget.type) {
      case 'steps':
        return 'Walking 10,000 steps burns around 400 kcal and improves heart health. Try a 30 min walk after dinner.';
      case 'active':
        return 'Even 30 minutes of moderate activity reduces risk of heart disease by 35%. Every minute counts!';
      default:
        return 'Your calorie burn is calculated from your step count. More steps = more calories burned.';
    }
  }

  String _formatValue(int v) {
    if (widget.type == 'steps' && v >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    return v.toString();
  }

  List<Map<String, String>> get _insights {
    final current = widget.current;
    final goal = _goal;
    final pct = goal > 0 ? (current / goal * 100).round() : 0;
    final remaining = (goal - current).clamp(0, goal);

    switch (widget.type) {
      case 'steps':
        return [
          {'label': 'Steps taken',     'value': current.toString()},
          {'label': 'Steps remaining', 'value': remaining.toString()},
          {'label': 'Goal',            'value': '${goal ~/ 1000}k steps'},
          {'label': 'Progress',        'value': '$pct%'},
          {'label': 'Est. distance',   'value': '${(current * 0.000762).toStringAsFixed(2)} km'},
          {'label': 'Est. calories',   'value': '${(current * 0.04).toInt()} kcal'},
        ];
      case 'active':
        return [
          {'label': 'Active minutes',   'value': '$current min'},
          {'label': 'Remaining',        'value': '$remaining min'},
          {'label': 'Daily goal',       'value': '$_goal min'},
          {'label': 'Progress',         'value': '$pct%'},
          {'label': 'Est. calories',    'value': '${(current * 5).toInt()} kcal'},
          {'label': 'Heart health',     'value': pct >= 50 ? '✅ Good' : '⚠️ Keep going'},
        ];
      default:
        return [
          {'label': 'Calories burned',  'value': '$current kcal'},
          {'label': 'Remaining',        'value': '$remaining kcal'},
          {'label': 'Daily goal',       'value': '$_goal kcal'},
          {'label': 'Progress',         'value': '$pct%'},
          {'label': 'Est. from steps',  'value': 'Based on activity'},
          {'label': 'Deficit',          'value': pct >= 100 ? '✅ Goal met!' : '$remaining kcal to go'},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AC.isDark(context);
    final progress = _goal > 0 ? (widget.current / _goal).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();

    return Scaffold(
      backgroundColor: AC.bg(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AC.card(context),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back_ios_new,
                                size: 16, color: AC.text(context)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(_title,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AC.text(context))),
                        const Spacer(),
                        if (widget.type == 'calories')
                          GestureDetector(
                            onTap: _editGoal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.pink.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppTheme.pink.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 13, color: AppTheme.pink),
                                  SizedBox(width: 4),
                                  Text('Edit Goal',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.pink,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          )
                        else
                          Text('Today',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AC.subtext(context))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Hero card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  _color.withValues(alpha: 0.2),
                                  _color.withValues(alpha: 0.05),
                                ]
                              : [
                                  _color.withValues(alpha: 0.12),
                                  _color.withValues(alpha: 0.03),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: _color.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(_icon, color: _color, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_emoji,
                                      style: const TextStyle(fontSize: 24)),
                                  Text(_title,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: AC.subtext(context))),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: pct >= 100
                                      ? _color.withValues(alpha: 0.2)
                                      : AC.card(context),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$pct%',
                                  style: TextStyle(
                                      color: _color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _formatValue(widget.current),
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w900,
                              color: _color,
                              height: 1,
                            ),
                          ),
                          Text(
                            _unit,
                            style: TextStyle(
                                fontSize: 18,
                                color: _color.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor:
                                  _color.withValues(alpha: 0.15),
                              valueColor:
                                  AlwaysStoppedAnimation(_color),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${widget.current} $_unit',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AC.subtext(context)),
                              ),
                              Text(
                                'Goal: $_goal $_unit',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AC.subtext(context)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats grid
                    Text('Details',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AC.text(context))),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: _insights.length,
                      itemBuilder: (_, i) {
                        final item = _insights[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AC.card(context),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: AC.divider(context)),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item['label']!,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AC.subtext(context),
                                    letterSpacing: 0.3),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['value']!,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AC.text(context)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tip card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AC.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡',
                              style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Tip',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AC.text(context))),
                                const SizedBox(height: 4),
                                Text(_tip,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AC.subtext(context),
                                        height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Goal card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: _color.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(_icon, color: _color, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Daily Goal',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AC.subtext(context))),
                              Text(_goalLabel,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _color)),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            pct >= 100 ? '🎉 Done!' : '$pct%',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}