import 'dart:math';
import 'package:flutter/material.dart';

class RingChart extends StatefulWidget {
  final double stepsProgress;
  final double activeProgress;
  final double caloriesProgress;
  final String centerText;
  final String centerSubText;
  final double size;

  const RingChart({
    super.key,
    required this.stepsProgress,
    required this.activeProgress,
    required this.caloriesProgress,
    required this.centerText,
    required this.centerSubText,
    this.size = 200,
  });

  @override
  State<RingChart> createState() => _RingChartState();
}

class _RingChartState extends State<RingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(RingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stepsProgress != widget.stepsProgress) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read text colors from theme — auto-switches in dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subTextColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RingPainter(
            size: widget.size,
            stepsProgress: widget.stepsProgress * _animation.value,
            activeProgress: widget.activeProgress * _animation.value,
            caloriesProgress: widget.caloriesProgress * _animation.value,
            isDark: isDark,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.centerText,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    widget.centerSubText,
                    style: TextStyle(
                      fontSize: 11,
                      color: subTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double stepsProgress;
  final double activeProgress;
  final double caloriesProgress;
  final bool isDark;
  final double size;

  const _RingPainter({
    required this.stepsProgress,
    required this.activeProgress,
    required this.caloriesProgress,
    this.isDark = false,
    this.size = 200,
  });

  void _drawRing(Canvas canvas, Offset center, double radius,
      double progress, Color color, Color bgColor, double strokeWidth) {
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Scale radii and stroke proportionally to widget size
    final r1 = size.width * 0.42;
    final r2 = size.width * 0.33;
    final r3 = size.width * 0.24;
    final sw = size.width * 0.08;
    // Track colors
    final greenTrack  = isDark ? const Color(0xFF1A4A2A) : const Color(0xFFE8F5E9);
    final blueTrack   = isDark ? const Color(0xFF1A2E4A) : const Color(0xFFE3F2FD);
    final pinkTrack   = isDark ? const Color(0xFF4A1A2E) : const Color(0xFFFCE4EC);
    _drawRing(canvas, center, r1, stepsProgress,
        const Color(0xFF00E5A0), greenTrack, sw);
    _drawRing(canvas, center, r2, activeProgress,
        const Color(0xFF4D9FFF), blueTrack, sw);
    _drawRing(canvas, center, r3, caloriesProgress,
        const Color(0xFFFF4D8B), pinkTrack, sw);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.stepsProgress != stepsProgress ||
      old.activeProgress != activeProgress ||
      old.caloriesProgress != caloriesProgress ||
      old.isDark != isDark;
}