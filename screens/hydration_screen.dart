import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart'; // AC helper available

// ── Data model ───────────────────────────────────────────────────────────────

class WaterEntry {
  final String label;
  final int amount; // ml
  final DateTime time;

  const WaterEntry({
    required this.label,
    required this.amount,
    required this.time,
  });

  String get timeStr {
    final h = time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'time': time.millisecondsSinceEpoch,
      };

  factory WaterEntry.fromJson(Map<String, dynamic> j) => WaterEntry(
        label: j['label'] as String,
        amount: j['amount'] as int,
        time: DateTime.fromMillisecondsSinceEpoch(j['time'] as int),
      );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen>
    with SingleTickerProviderStateMixin {
  static const double _goal = 2000; // ml

  double _current = 0;
  List<WaterEntry> _log = [];
  bool _loading = true;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadData();
  }

  // ── Load saved data ───────────────────────────────────────────────────────
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final savedDate = prefs.getString('hydration_date') ?? '';

    if (savedDate != today) {
      // New day — reset everything
      await prefs.setString('hydration_date', today);
      await prefs.setDouble('hydration_ml', 0);
      await prefs.remove('hydration_log');
      if (mounted) {
        setState(() {
          _current = 0;
          _log = [];
          _loading = false;
        });
      }
    } else {
      // Same day — restore data
      final ml = prefs.getDouble('hydration_ml') ?? 0;
      final logJson = prefs.getString('hydration_log');
      List<WaterEntry> entries = [];
      if (logJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(logJson) as List<dynamic>;
          entries = decoded
              .map((e) => WaterEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _current = ml;
          _log = entries;
          _loading = false;
        });
      }
    }
  }

  // ── Save data ─────────────────────────────────────────────────────────────
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hydration_ml', _current);
    final logJson =
        jsonEncode(_log.map((e) => e.toJson()).toList());
    await prefs.setString('hydration_log', logJson);
  }

  // ── Add water ─────────────────────────────────────────────────────────────
  Future<void> _addWater(int ml) async {
    final entry = WaterEntry(
      label: ml >= 500
          ? 'Water bottle'
          : ml >= 250
              ? 'Glass'
              : 'Small glass',
      amount: ml,
      time: DateTime.now(),
    );

    setState(() {
      _current = (_current + ml).clamp(0, _goal + 500);
      _log.insert(0, entry);
    });

    await _saveData();
  }

  // ── Remove last entry ─────────────────────────────────────────────────────
  Future<void> _removeEntry(int index) async {
    final entry = _log[index];
    setState(() {
      _current = (_current - entry.amount).clamp(0, _goal + 500);
      _log.removeAt(index);
    });
    await _saveData();
  }

  // ── Reset today ───────────────────────────────────────────────────────────
  Future<void> _resetDay() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset today?'),
        content: const Text(
            'This will clear all water entries for today.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _current = 0;
        _log = [];
      });
      await _saveData();
    }
  }

  String _todayKey() =>
      DateTime.now().toIso8601String().substring(0, 10);

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_current / _goal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AC.bg(context),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildBottleCard(progress),
                    const SizedBox(height: 16),
                    _buildQuickAdd(),
                    const SizedBox(height: 16),
                    _buildLog(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new),
          ),
          const SizedBox(width: 12),
          const Text('Hydration',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          // Reset button
          GestureDetector(
            onTap: _resetDay,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Reset',
                  style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated bottle ───────────────────────────────────────────────────────
  Widget _buildBottleCard(double progress) {
    final remaining = (_goal - _current).clamp(0, _goal).toInt();
    final pct = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AC.card(context),
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) => CustomPaint(
              size: const Size(120, 180),
              painter: _BottlePainter(
                progress: progress,
                wavePhase: _waveController.value,
              ),
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: (_current / 1000).toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AC.text(context)),
                ),
                TextSpan(
                  text: ' / 2.0 L',
                  style: TextStyle(
                      fontSize: 18, color: AC.subtext(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pct >= 100
                ? '🎉 Daily goal reached!'
                : '$pct% of daily goal · ${remaining}ml to go',
            style: TextStyle(
                fontSize: 13,
                color: pct >= 100
                    ? AppTheme.green
                    : AC.subtext(context),
                fontWeight: pct >= 100
                    ? FontWeight.w600
                    : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  // ── Quick add ─────────────────────────────────────────────────────────────
  Widget _buildQuickAdd() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AC.card(context),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick add',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickBtn('🥃', '100ml', 100),
              _quickBtn('🥛', '250ml', 250),
              _quickBtn('🍶', '500ml', 500),
              _quickBtn('🧴', '750ml', 750),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickBtn(String emoji, String label, int ml) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _addWater(ml),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AC.cardBlue(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.blue)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Log ───────────────────────────────────────────────────────────────────
  Widget _buildLog() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AC.card(context),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's log",
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              Text(
                _log.isEmpty
                    ? 'No entries yet'
                    : '${_log.length} ${_log.length == 1 ? 'entry' : 'entries'}',
                style: TextStyle(
                    color: AC.subtext(context), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_log.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    const Text('💧',
                        style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text('No water logged yet today',
                        style: TextStyle(
                            fontSize: 13,
                            color: AC.subtext(context))),
                    Text('Tap a quick add button above',
                        style: TextStyle(
                            fontSize: 12,
                            color: AC.subtext(context))),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_log.length, (i) {
              final e = _log[i];
              return Dismissible(
                key: Key('${e.time.millisecondsSinceEpoch}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.red),
                ),
                onDismissed: (_) => _removeEntry(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('💧',
                              style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(e.timeStr,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AC.subtext(context))),
                        ],
                      ),
                      const Spacer(),
                      Text('${e.amount}ml',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Bottle painter ────────────────────────────────────────────────────────────

class _BottlePainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  const _BottlePainter(
      {required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final bottlePath = Path()
      ..moveTo(size.width * 0.38, 0)
      ..lineTo(size.width * 0.62, 0)
      ..lineTo(size.width * 0.68, size.height * 0.1)
      ..lineTo(size.width * 0.85, size.height * 0.12)
      ..lineTo(size.width * 0.85, size.height * 0.95)
      ..quadraticBezierTo(size.width * 0.85, size.height,
          size.width * 0.75, size.height)
      ..lineTo(size.width * 0.25, size.height)
      ..quadraticBezierTo(size.width * 0.15, size.height,
          size.width * 0.15, size.height * 0.95)
      ..lineTo(size.width * 0.15, size.height * 0.12)
      ..lineTo(size.width * 0.32, size.height * 0.1)
      ..close();

    canvas.save();
    canvas.clipPath(bottlePath);

    final waterTop =
        size.height * (1 - progress.clamp(0.0, 1.0) * 0.86 - 0.06);

    // Base water fill
    canvas.drawRect(
      Rect.fromLTWH(0, waterTop, size.width, size.height),
      Paint()..color = const Color(0xFF90CAF9),
    );

    // Wave on top
    final wavePath = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = waterTop +
          5 * sin(x / size.width * 2 * pi + wavePhase * 2 * pi);
      if (x == 0) {
        wavePath.moveTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    wavePath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
        wavePath, Paint()..color = const Color(0xFF64B5F6));
    canvas.restore();

    // Bottle outline
    canvas.drawPath(
      bottlePath,
      Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BottlePainter old) =>
      old.progress != progress || old.wavePhase != wavePhase;
}