import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/workout_service.dart';
import '../theme.dart'; // AC helper available

class LiveWorkoutScreen extends StatefulWidget {
  final String activity;
  const LiveWorkoutScreen({super.key, required this.activity});

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _paused = false;

  StreamSubscription<StepCount>? _stepSub;
  int _startSteps = -1;
  int _workoutSteps = 0;
  int? _manualHeartRate; // null = use auto calculation

  double get _distanceKm => _workoutSteps * 0.000762;

  // Calories: only count when actually moving (steps > 0)
  // Average 0.04 kcal per step (realistic estimate)
  int get _calories => (_workoutSteps * 0.04).toInt();

  // Heart rate: manual entry takes priority, otherwise auto from steps
  int get _heartRate {
    if (_manualHeartRate != null) return _manualHeartRate!;
    if (_workoutSteps == 0) return 0;
    final rate = 72 + (_workoutSteps / 100).floor();
    return rate.clamp(72, 160);
  }

  String get _pace {
    if (_distanceKm < 0.01) return '--';
    final secPerKm = _seconds / _distanceKm;
    final m = secPerKm ~/ 60;
    final s = (secPerKm % 60).toInt();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String get _timeString {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _zoneLabel {
    if (_heartRate < 100) return 'Rest';
    if (_heartRate < 115) return 'Warm up';
    if (_heartRate < 130) return 'Fat burn';
    if (_heartRate < 150) return 'Cardio';
    return 'Peak';
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initSteps();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) setState(() => _seconds++);
    });
  }

  Future<void> _initSteps() async {
    // Request permission (may already be granted from home screen)
    final status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      await Permission.activityRecognition.request();
    }

    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (StepCount event) {
          if (event.steps == 0) return; // ignore zero readings
          if (_startSteps == -1) {
            _startSteps = event.steps; // set baseline
          }
          if (mounted && !_paused) {
            setState(() => _workoutSteps =
                (event.steps - _startSteps).clamp(0, 999999));
          }
        },
        onError: (e) => debugPrint('Workout step error: \$e'),
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Step init error: \$e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepSub?.cancel();
    super.dispose();
  }

  Future<void> _stopWorkout() async {
    _timer?.cancel();
    _stepSub?.cancel();

    if (_seconds < 30) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout too short — minimum 30 seconds'),
            duration: Duration(seconds: 2),
          ),
        );
        // Restart timer
        _startTimer();
        _initSteps();
      }
      return;
    }

    final record = WorkoutRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activity: widget.activity,
      startTime:
          DateTime.now().subtract(Duration(seconds: _seconds)),
      durationSeconds: _seconds,
      steps: _workoutSteps,
      distanceKm: _distanceKm,
      calories: _calories,
    );

    await WorkoutService().saveWorkout(record);

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SummarySheet(
          record: record,
          onDone: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildTimer(),
              const SizedBox(height: 16),
              _buildMap(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 12),
              _buildHRZone(),
              const SizedBox(height: 12),
              _buildMotivation(),
              const SizedBox(height: 20),
              _buildControls(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new),
        ),
        const SizedBox(width: 12),
        Text(widget.activity,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20)),
          child: const Row(
            children: [
              Icon(Icons.circle, color: Colors.white, size: 8),
              SizedBox(width: 6),
              Text('RECORDING',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text('DURATION',
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                color: AC.subtext(context))),
        const SizedBox(height: 4),
        Text(_timeString,
            style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w800,
                letterSpacing: -2)),
      ],
    );
  }

  Widget _buildMap() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
          color: AC.isDark(context) ? const Color(0xFF1A2A1A) : const Color(0xFFE8F0E4),
          borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Center(
            child: CustomPaint(
              size: const Size(double.infinity, 80),
              painter: _RoutePainter(),
            ),
          ),
          const Positioned(
            left: 16,
            bottom: 12,
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 16),
                SizedBox(width: 4),
                Text('Live location',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard('STEPS', '$_workoutSteps')),
            const SizedBox(width: 12),
            Expanded(
                child: _statCard('DISTANCE',
                    '${_distanceKm.toStringAsFixed(2)} km')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _statCard('PACE', '$_pace /km')),
            const SizedBox(width: 12),
            Expanded(child: _hrCard()),
          ],
        ),
        const SizedBox(height: 12),
        _statCard('CALORIES', '$_calories kcal'),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: AC.subtext(context),
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _hrCard() {
    final isManual = _manualHeartRate != null;
    final displayHR = _heartRate;

    return GestureDetector(
      onTap: _showHRInput,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isManual
                ? Border.all(color: Colors.red.shade200, width: 1.5)
                : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('HEART RATE',
                    style: TextStyle(
                        fontSize: 11,
                        color: AC.subtext(context),
                        letterSpacing: 0.5)),
                Icon(
                  isManual ? Icons.edit : Icons.add_circle_outline,
                  color: Colors.red,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 4),
            displayHR == 0
                ? Text(
                    'Tap to enter',
                    style: TextStyle(
                        fontSize: 14,
                        color: AC.subtext(context),
                        fontStyle: FontStyle.italic),
                  )
                : RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$displayHR',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AC.text(context)),
                        ),
                        TextSpan(
                          text: ' bpm',
                          style: TextStyle(
                              fontSize: 13,
                              color: AC.subtext(context)),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ── Manual HR input dialog ───────────────────────────────────────────────
  void _showHRInput() {
    final controller = TextEditingController(
        text: _manualHeartRate != null ? '$_manualHeartRate' : '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Enter Heart Rate'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 3,
              decoration: InputDecoration(
                hintText: 'e.g. 120',
                suffixText: 'bpm',
                counterText: '',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            // Quick select buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [60, 80, 100, 120, 140, 160].map((bpm) {
                return GestureDetector(
                  onTap: () {
                    controller.text = '$bpm';
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$bpm',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          if (_manualHeartRate != null)
            TextButton(
              onPressed: () {
                setState(() => _manualHeartRate = null);
                Navigator.pop(context);
              },
              child: const Text('Clear',
                  style: TextStyle(color: Colors.grey)),
            ),
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
              final val = int.tryParse(controller.text);
              if (val != null && val >= 40 && val <= 220) {
                setState(() => _manualHeartRate = val);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildHRZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Heart rate zone',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              Text(_zoneLabel,
                  style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _zoneBar(Colors.lightBlue.shade200, 'Rest'),
              _zoneBar(Colors.blue.shade300, 'Warm'),
              _zoneBar(Colors.yellow.shade300, 'Fat burn'),
              _zoneBar(Colors.orange, 'Cardio',
                  active: _zoneLabel == 'Cardio'),
              _zoneBar(Colors.pink.shade300, 'Peak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _zoneBar(Color color, String label,
      {bool active = false}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: active ? 10 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  color: active
                      ? AC.text(context)
                      : AC.subtext(context),
                  fontWeight: active
                      ? FontWeight.w600
                      : FontWeight.normal),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMotivation() {
    final msg = _workoutSteps > 500
        ? 'Faster than 78% of your runs this month.'
        : 'Just keep moving — every step counts!';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AC.cardPink(context),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Text('💪', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("You're flying today",
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(msg,
                    style: TextStyle(
                        fontSize: 13,
                        color: AC.subtext(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        GestureDetector(
          onTap: _stopWorkout,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle),
            child: const Icon(Icons.stop_rounded,
                color: Colors.red, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _paused = !_paused),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                  color: AppTheme.pink,
                  borderRadius: BorderRadius.circular(28)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _paused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _paused ? 'Resume' : 'Pause',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Route painter ─────────────────────────────────────────────────────────────

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pink
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.7)
      ..cubicTo(size.width * 0.2, size.height * 0.8,
          size.width * 0.3, size.height * 0.3,
          size.width * 0.45, size.height * 0.25)
      ..cubicTo(size.width * 0.55, size.height * 0.2,
          size.width * 0.65, size.height * 0.4,
          size.width * 0.75, size.height * 0.3)
      ..cubicTo(size.width * 0.85, size.height * 0.2,
          size.width * 0.9, size.height * 0.3,
          size.width * 0.95, size.height * 0.2);

    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.2),
      5,
      Paint()..color = AppTheme.pink,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Summary sheet ─────────────────────────────────────────────────────────────

class _SummarySheet extends StatelessWidget {
  final WorkoutRecord record;
  final VoidCallback onDone;

  const _SummarySheet(
      {required this.record, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration:  BoxDecoration(
        color: AC.card(context),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
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
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text('Workout Complete!',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
          Text(record.activity,
              style: TextStyle(
                  fontSize: 15, color: AC.subtext(context))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _item('⏱️', record.formattedDuration, 'Duration'),
              _item('👣', '${record.steps}', 'Steps'),
              _item('📍', record.formattedDistance, 'Distance'),
              _item('🔥', '${record.calories}', 'Calories'),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onDone,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: AppTheme.green,
                  borderRadius: BorderRadius.circular(24)),
              child: const Text('Done',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _item(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF9E9E9E))),
      ],
    );
  }
}