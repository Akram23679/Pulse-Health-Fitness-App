import 'package:flutter/material.dart';
import '../services/sleep_service.dart';
import '../theme.dart'; // AC helper available

class SleepDetailScreen extends StatefulWidget {
  final SleepResult? result;
  const SleepDetailScreen({super.key, this.result});

  @override
  State<SleepDetailScreen> createState() => _SleepDetailScreenState();
}

class _SleepDetailScreenState extends State<SleepDetailScreen> {
  SleepResult? _result;

  static const Color _awakeColor = Color(0xFFEF9A9A);
  static const Color _remColor   = Color(0xFFCE93D8);
  static const Color _lightColor = Color(0xFF9575CD);
  static const Color _deepColor  = Color(0xFF4527A0);

  @override
  void initState() {
    super.initState();
    _result = widget.result ?? SleepService().lastResult;
    SleepService().addListener(_onServiceChange);
  }

  void _onServiceChange() {
    if (mounted) setState(() => _result = SleepService().lastResult);
  }

  @override
  void dispose() {
    SleepService().removeListener(_onServiceChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _result == null
        ? _buildNoData(context)
        : _buildResult(context, _result!);
  }

  Widget _buildNoData(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.isDark(context) ? const Color(0xFF0F0E1A) : const Color(0xFFF0EEF8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new),
                  ),
                  const SizedBox(width: 12),
                  const Text('Sleep',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Spacer(),
            const Icon(Icons.bedtime_outlined,
                size: 72, color: AppTheme.purple),
            const SizedBox(height: 16),
            const Text('No sleep data yet',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Start sleep tracking tonight\nto see your real sleep score.',
              style: TextStyle(
                  fontSize: 14, color: AC.subtext(context)),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, SleepResult r) {
    return Scaffold(
      backgroundColor: AC.isDark(context) ? const Color(0xFF0F0E1A) : const Color(0xFFF0EEF8),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back_ios_new),
                          ),
                          const SizedBox(width: 12),
                          const Text('Sleep',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    _scoreCard(r),
                    const SizedBox(height: 12),
                    _stagesCard(r),
                    const SizedBox(height: 12),
                    _vitalsRow(r),
                    const SizedBox(height: 12),
                    _insightCard(r),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard(SleepResult r) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AC.card(context), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bedtime,
                    color: AppTheme.purple, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAST NIGHT',
                      style: TextStyle(
                          fontSize: 11,
                          color: AC.subtext(context),
                          letterSpacing: 1)),
                  Text('${r.bedTimeStr} → ${r.wakeTimeStr}',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('${r.score}',
                  style: const TextStyle(
                      fontSize: 52, fontWeight: FontWeight.w800)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.durationStr,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: AC.cardGreen(context),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(r.restorationLabel,
                        style: const TextStyle(
                            color: AppTheme.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Sleep score',
              style:
                  TextStyle(fontSize: 13, color: AC.subtext(context))),
        ],
      ),
    );
  }

  Widget _stagesCard(SleepResult r) {
    final awake = r.awakenMinutes.clamp(1, r.totalMinutes);
    final rem   = r.remMinutes.clamp(1, r.totalMinutes);
    final light = r.lightMinutes.clamp(1, r.totalMinutes);
    final deep  = r.deepMinutes.clamp(1, r.totalMinutes);

    String fmt(int min) {
      final h = min ~/ 60;
      final m = min % 60;
      return h > 0 ? '${h}h ${m}m' : '${m}m';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AC.card(context), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sleep stages',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              Text(r.durationStr,
                  style: TextStyle(
                      fontSize: 13, color: AC.subtext(context))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(flex: awake, child: Container(height: 10, color: _awakeColor)),
                Expanded(flex: rem,   child: Container(height: 10, color: _remColor)),
                Expanded(flex: light, child: Container(height: 10, color: _lightColor)),
                Expanded(flex: deep,  child: Container(height: 10, color: _deepColor)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stageLbl(_awakeColor, 'Awake', fmt(r.awakenMinutes)),
              _stageLbl(_remColor, 'REM', fmt(r.remMinutes)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _stageLbl(_lightColor, 'Light', fmt(r.lightMinutes)),
              _stageLbl(_deepColor, 'Deep', fmt(r.deepMinutes)),
            ],
          ),
          // Real movement chart if data available
          if (r.samples.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('MOVEMENT TIMELINE',
                style: TextStyle(
                    fontSize: 11,
                    color: AC.subtext(context),
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: CustomPaint(
                size: const Size(double.infinity, 80),
                painter: _MovementPainter(samples: r.samples),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.bedTimeStr,
                    style: TextStyle(
                        fontSize: 11, color: AC.subtext(context))),
                Text(r.wakeTimeStr,
                    style: TextStyle(
                        fontSize: 11, color: AC.subtext(context))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stageLbl(Color color, String stage, String time) {
    return Expanded(
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(stage, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(time,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _vitalsRow(SleepResult r) {
    final deepPct = r.totalMinutes > 0
        ? (r.deepMinutes / r.totalMinutes * 100).round()
        : 0;
    return Row(
      children: [
        Expanded(
          child: _vitalCard(
            'DEEP SLEEP',
            '$deepPct%',
            deepPct >= 20 ? '↑ Great' : '↓ Below avg',
            deepPct >= 20 ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _vitalCard(
            'SLEEP SCORE',
            '${r.score}',
            r.score >= 80
                ? '↑ Excellent'
                : r.score >= 65
                    ? '→ Good'
                    : '↓ Needs rest',
            r.score >= 80
                ? Colors.green
                : r.score >= 65
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _vitalCard(
      String label, String value, String sub, Color subColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AC.card(context), borderRadius: BorderRadius.circular(16)),
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
                  fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub,
              style: TextStyle(
                  fontSize: 12,
                  color: subColor,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _insightCard(SleepResult r) {
    final deepPct = r.totalMinutes > 0
        ? (r.deepMinutes / r.totalMinutes * 100).round()
        : 0;
    final String emoji;
    final String message;

    if (r.score >= 85) {
      emoji = '🌙';
      message =
          'Deep sleep was $deepPct% of total — excellent recovery. Keep the same bedtime tonight.';
    } else if (r.score >= 70) {
      emoji = '😴';
      message =
          'Good night! Deep sleep was $deepPct%. Try sleeping 30 min earlier for better recovery.';
    } else {
      emoji = '☁️';
      message =
          'Sleep was lighter than usual. Only $deepPct% deep sleep. Reduce screen time before bed.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AC.cardPurple(context),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.score >= 80 ? "You're well rested" : 'Sleep insight',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(message,
                    style: TextStyle(
                        fontSize: 13, color: AC.subtext(context))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementPainter extends CustomPainter {
  final List<SleepSample> samples;
  const _MovementPainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final maxM = samples.fold<double>(
        0.01, (m, s) => s.movement > m ? s.movement : m);

    final paint = Paint()
      ..color = AppTheme.purple
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final step = size.width / (samples.length - 1);

    for (int i = 0; i < samples.length; i++) {
      final norm = (samples[i].movement / maxM).clamp(0.0, 1.0);
      final x = i * step;
      final y = size.height * (1 - norm * 0.85 - 0.05);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevNorm =
            (samples[i - 1].movement / maxM).clamp(0.0, 1.0);
        final prevY = size.height * (1 - prevNorm * 0.85 - 0.05);
        path.lineTo(x, prevY);
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}