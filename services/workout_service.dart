import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class WorkoutRecord {
  final String id;
  final String activity;
  final DateTime startTime;
  final int durationSeconds;
  final int steps;
  final double distanceKm;
  final int calories;

  const WorkoutRecord({
    required this.id,
    required this.activity,
    required this.startTime,
    required this.durationSeconds,
    required this.steps,
    required this.distanceKm,
    required this.calories,
  });

  // ── Formatted getters ────────────────────────────────────────────────────

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final rm = m % 60;
      return '${h}h ${rm}m';
    }
    return '${m}m ${s}s';
  }

  String get formattedDistance =>
      '${distanceKm.toStringAsFixed(2)} km';

  String get formattedPace {
    if (distanceKm < 0.01) return '--';
    final secPerKm = durationSeconds / distanceKm;
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).toInt();
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDay = DateTime(
        startTime.year, startTime.month, startTime.day);
    final diff = today.difference(workoutDay).inDays;

    final h = startTime.hour > 12
        ? startTime.hour - 12
        : startTime.hour == 0
            ? 12
            : startTime.hour;
    final m = startTime.minute.toString().padLeft(2, '0');
    final period = startTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$h:$m $period';

    if (diff == 0) return 'Today, $timeStr';
    if (diff == 1) return 'Yesterday, $timeStr';
    return '${startTime.day}/${startTime.month}, $timeStr';
  }

  // ── Serialization ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'activity': activity,
        'startTime': startTime.millisecondsSinceEpoch,
        'durationSeconds': durationSeconds,
        'steps': steps,
        'distanceKm': distanceKm,
        'calories': calories,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> j) =>
      WorkoutRecord(
        id: j['id'] as String,
        activity: j['activity'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(
            j['startTime'] as int),
        durationSeconds: j['durationSeconds'] as int,
        steps: j['steps'] as int,
        distanceKm: (j['distanceKm'] as num).toDouble(),
        calories: j['calories'] as int,
      );
}

// ── Service ───────────────────────────────────────────────────────────────────

class WorkoutService extends ChangeNotifier {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  List<WorkoutRecord> _workouts = [];
  bool _loaded = false;

  List<WorkoutRecord> get allWorkouts => _workouts;

  // Recent 10 workouts
  List<WorkoutRecord> get recentWorkouts =>
      _workouts.take(10).toList();

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('workout_history');
      if (json != null) {
        final List<dynamic> decoded =
            jsonDecode(json) as List<dynamic>;
        _workouts = decoded
            .map((e) =>
                WorkoutRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        // Sort newest first
        _workouts.sort(
            (a, b) => b.startTime.compareTo(a.startTime));
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  // ── Save new workout ──────────────────────────────────────────────────────
  Future<void> saveWorkout(WorkoutRecord record) async {
    _workouts.insert(0, record);
    notifyListeners();
    await _persist();
  }

  // ── Delete workout ────────────────────────────────────────────────────────
  Future<void> deleteWorkout(String id) async {
    _workouts.removeWhere((w) => w.id == id);
    notifyListeners();
    await _persist();
  }

  // ── Weekly streak (Mon–Sun this week) ────────────────────────────────────
  List<bool> get weeklyStreak {
    final now = DateTime.now();
    // Find Monday of this week
    final monday =
        now.subtract(Duration(days: now.weekday - 1));
    final mondayDay =
        DateTime(monday.year, monday.month, monday.day);

    return List.generate(7, (i) {
      final day = mondayDay.add(Duration(days: i));
      return _workouts.any((w) {
        final wDay = DateTime(
            w.startTime.year, w.startTime.month, w.startTime.day);
        return wDay == day;
      });
    });
  }

  // ── Stats per activity ────────────────────────────────────────────────────
  String statFor(String activity) {
    final matching = _workouts
        .where((w) => w.activity == activity)
        .toList();

    if (matching.isEmpty) return _defaultStat(activity);

    final last = matching.first;

    switch (activity) {
      case 'Walking':
        if (last.durationSeconds > 0 && last.distanceKm > 0) {
          final kmh =
              last.distanceKm / (last.durationSeconds / 3600);
          return 'Last avg ${kmh.toStringAsFixed(1)} km/h';
        }
        return 'Last: ${last.formattedDistance}';
      case 'Running':
        return 'Last pace ${last.formattedPace}';
      case 'Cycling':
        final totalKm = matching.fold<double>(
            0, (sum, w) => sum + w.distanceKm);
        return 'Total ${totalKm.toStringAsFixed(1)} km';
      case 'Swimming':
        return 'Last: ${last.formattedDuration}';
      default:
        return 'Last: ${last.formattedDistance}';
    }
  }

  String _defaultStat(String activity) {
    switch (activity) {
      case 'Walking':   return 'No walks yet';
      case 'Running':   return 'No runs yet';
      case 'Cycling':   return 'No rides yet';
      case 'Swimming':  return 'No swims yet';
      default:          return 'Not started';
    }
  }

  // Total workouts count
  int get totalWorkouts => _workouts.length;

  // Total steps across all workouts
  int get totalSteps =>
      _workouts.fold(0, (sum, w) => sum + w.steps);

  // ── Persist ───────────────────────────────────────────────────────────────
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json =
        jsonEncode(_workouts.map((w) => w.toJson()).toList());
    await prefs.setString('workout_history', json);
  }
}