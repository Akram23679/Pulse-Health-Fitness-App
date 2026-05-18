import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Data models ──────────────────────────────────────────────────────────────

class SleepSample {
  final int timestamp;
  final double movement;

  const SleepSample({required this.timestamp, required this.movement});

  Map<String, dynamic> toJson() => {'t': timestamp, 'm': movement};

  factory SleepSample.fromJson(Map<String, dynamic> j) => SleepSample(
        timestamp: j['t'] as int,
        movement: (j['m'] as num).toDouble(),
      );
}

class SleepResult {
  final int score;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int awakenMinutes;
  final int remMinutes;
  final int lightMinutes;
  final int deepMinutes;
  final List<SleepSample> samples;

  const SleepResult({
    required this.score,
    required this.bedTime,
    required this.wakeTime,
    required this.awakenMinutes,
    required this.remMinutes,
    required this.lightMinutes,
    required this.deepMinutes,
    required this.samples,
  });

  int get totalMinutes => wakeTime.difference(bedTime).inMinutes;

  String get durationStr {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }

  String get restorationLabel {
    if (score >= 85) return 'Restoration excellent';
    if (score >= 70) return 'Good recovery';
    if (score >= 55) return 'Fair sleep';
    return 'Needs improvement';
  }

  String get bedTimeStr {
    final h = bedTime.hour > 12 ? bedTime.hour - 12 : bedTime.hour;
    final m = bedTime.minute.toString().padLeft(2, '0');
    final period = bedTime.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String get wakeTimeStr {
    final h = wakeTime.hour > 12 ? wakeTime.hour - 12 : wakeTime.hour;
    final m = wakeTime.minute.toString().padLeft(2, '0');
    final period = wakeTime.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'bedTime': bedTime.millisecondsSinceEpoch,
        'wakeTime': wakeTime.millisecondsSinceEpoch,
        'awaken': awakenMinutes,
        'rem': remMinutes,
        'light': lightMinutes,
        'deep': deepMinutes,
        'samples': samples.map((s) => s.toJson()).toList(),
      };

  factory SleepResult.fromJson(Map<String, dynamic> j) => SleepResult(
        score: j['score'] as int,
        bedTime:
            DateTime.fromMillisecondsSinceEpoch(j['bedTime'] as int),
        wakeTime:
            DateTime.fromMillisecondsSinceEpoch(j['wakeTime'] as int),
        awakenMinutes: j['awaken'] as int,
        remMinutes: j['rem'] as int,
        lightMinutes: j['light'] as int,
        deepMinutes: j['deep'] as int,
        samples: (j['samples'] as List)
            .map((s) =>
                SleepSample.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

// ── Service ──────────────────────────────────────────────────────────────────

class SleepService extends ChangeNotifier {
  static final SleepService _instance = SleepService._internal();
  factory SleepService() => _instance;
  SleepService._internal();

  bool _isTracking = false;
  DateTime? _bedTime;
  final List<SleepSample> _samples = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Timer? _sampleTimer;

  // Live accelerometer values
  double _ax = 0, _ay = 0, _az = 9.81;

  SleepResult? _lastResult;

  bool get isTracking => _isTracking;
  SleepResult? get lastResult => _lastResult;

  String get bedTimeStr {
    if (_bedTime == null) return '';
    final h = _bedTime!.hour > 12 ? _bedTime!.hour - 12 : _bedTime!.hour;
    final m = _bedTime!.minute.toString().padLeft(2, '0');
    final period = _bedTime!.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  // ── Load saved result on startup ─────────────────────────────────────────
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('sleep_result');
      if (json != null) {
        _lastResult = SleepResult.fromJson(
            jsonDecode(json) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Start tracking ────────────────────────────────────────────────────────
  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;
    _bedTime = DateTime.now();
    _samples.clear();

    // Read accelerometer at 2Hz
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 500),
    ).listen(
      (e) {
        _ax = e.x;
        _ay = e.y;
        _az = e.z;
      },
      onError: (_) {},
    );

    // Store a sample every 30 seconds
    _sampleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final magnitude = sqrt(_ax * _ax + _ay * _ay + _az * _az);
      // Subtract gravity to isolate actual movement
      final movement = (magnitude - 9.81).abs();
      _samples.add(SleepSample(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        movement: movement,
      ));
    });

    notifyListeners();
  }

  // ── Stop tracking & calculate ─────────────────────────────────────────────
  Future<SleepResult> stopTracking() async {
    _isTracking = false;
    _accelSub?.cancel();
    _sampleTimer?.cancel();

    final wakeTime = DateTime.now();
    final result = _calculate(_bedTime ?? wakeTime, wakeTime);
    _lastResult = result;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sleep_result', jsonEncode(result.toJson()));

    notifyListeners();
    return result;
  }

  // ── Score & stage calculation ─────────────────────────────────────────────
  // Calibrated for BEDSIDE TABLE placement (lower sensitivity than on-bed)
  SleepResult _calculate(DateTime bedTime, DateTime wakeTime) {
    final totalMin = wakeTime.difference(bedTime).inMinutes;

    if (_samples.isEmpty) {
      return _estimateFromDuration(bedTime, wakeTime, totalMin);
    }

    int awakeSamples = 0;
    int lightSamples = 0;
    int remSamples   = 0;
    int deepSamples  = 0;

    for (final s in _samples) {
      // Bedside thresholds — lower than on-bed because phone picks up less
      if (s.movement > 1.2) {
        awakeSamples++;
      } else if (s.movement > 0.35) {
        lightSamples++;
      } else if (s.movement > 0.08) {
        remSamples++;
      } else {
        deepSamples++;
      }
    }

    final total = _samples.length;
    final awakenMin =
        (awakeSamples / total * totalMin).round().clamp(0, totalMin);
    final lightMin =
        (lightSamples / total * totalMin).round().clamp(0, totalMin);
    final remMin =
        (remSamples / total * totalMin).round().clamp(0, totalMin);
    final deepMin =
        (totalMin - awakenMin - lightMin - remMin).clamp(0, totalMin);

    // Score: start at 100, apply penalties and bonuses
    int score = 100;

    // Duration scoring (ideal: 7–9 hours)
    final hours = totalMin / 60.0;
    if (hours < 5) {
  score -= 25;
  } else if (hours < 6) {
  score -= 15;
  } else if (hours < 7) {
  score -= 8;
  } else if (hours > 9) {
  score -= 5;
  }

    // Awake time penalty
    score -= ((awakeSamples / total) * 35).round();

    // Deep sleep bonus
    final deepRatio = deepSamples / total;
    if (deepRatio > 0.15) score += 5;
    if (deepRatio > 0.25) score += 5;

    // REM bonus
    final remRatio = remSamples / total;
    if (remRatio > 0.18) score += 3;

    score = score.clamp(20, 100);

    return SleepResult(
      score: score,
      bedTime: bedTime,
      wakeTime: wakeTime,
      awakenMinutes: awakenMin,
      remMinutes: remMin,
      lightMinutes: lightMin,
      deepMinutes: deepMin,
      samples: List.from(_samples),
    );
  }

  // Fallback when sensor has no data (app was in background briefly)
  SleepResult _estimateFromDuration(
      DateTime bedTime, DateTime wakeTime, int totalMin) {
    final deepMin  = (totalMin * 0.20).round();
    final remMin   = (totalMin * 0.22).round();
    final lightMin = (totalMin * 0.50).round();
    final awakeMin = totalMin - deepMin - remMin - lightMin;

    final hours = totalMin / 60.0;
    int score = 72;
    if (hours >= 7 && hours <= 9) score = 80;
    if (hours >= 7.5 && hours <= 8.5) score = 85;
    if (hours < 6) score = 58;
    if (hours < 5) score = 45;

    return SleepResult(
      score: score,
      bedTime: bedTime,
      wakeTime: wakeTime,
      awakenMinutes: awakeMin.clamp(0, totalMin),
      remMinutes: remMin,
      lightMinutes: lightMin,
      deepMinutes: deepMin,
      samples: const [],
    );
  }
}