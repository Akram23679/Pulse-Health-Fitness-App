import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/sleep_service.dart';
import '../theme.dart';
import 'sleep_detail_screen.dart';

class SleepTrackingScreen extends StatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  State<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends State<SleepTrackingScreen>
    with SingleTickerProviderStateMixin {
  final _service = SleepService();
  bool _loading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChange);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onServiceChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChange);
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startSleep() async {
    await WakelockPlus.enable();
    _service.startTracking();
  }

  Future<void> _stopSleep() async {
    setState(() => _loading = true);
    await WakelockPlus.disable();
    final result = await _service.stopTracking();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SleepDetailScreen(result: result),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _service.isTracking
        ? _buildTrackingScreen()
        : _buildStartScreen();
  }

  // ── Start screen ─────────────────────────────────────────────────────────
  Widget _buildStartScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1035),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  const Text('Sleep Tracking',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              const Spacer(),
              // Moon icon
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.purple.withValues(alpha: 0.25),
                ),
                child: const Icon(Icons.bedtime,
                    color: Colors.white70, size: 64),
              ),
              const SizedBox(height: 28),
              const Text('Ready to sleep?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              const Text(
                'Place your phone on your bedside table.\nThe app tracks sleep using the motion sensor.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Sleep window info
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.schedule,
                        color: Colors.white54, size: 16),
                    SizedBox(width: 8),
                    Text('Your sleep window: 11 PM → 6 AM',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    _TipRow(
                      icon: Icons.phone_android,
                      text: 'Keep app open on bedside table',
                    ),
                    SizedBox(height: 10),
                    _TipRow(
                      icon: Icons.brightness_low,
                      text: 'Screen stays on (very dim)',
                    ),
                    SizedBox(height: 10),
                    _TipRow(
                      icon: Icons.do_not_disturb_on_outlined,
                      text: 'Put phone on silent / Do Not Disturb',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Start button
              GestureDetector(
                onTap: _startSleep,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.purple,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bedtime, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Start Sleep Tracking',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tracking screen (shown all night) ────────────────────────────────────
  Widget _buildTrackingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A1F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Pulsing moon
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: child,
                ),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.purple.withValues(alpha: 0.18),
                  ),
                  child: const Icon(Icons.bedtime,
                      color: Colors.white70, size: 70),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Tracking your sleep...',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                'Started at ${_service.bedTimeStr}',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Good night 🌙',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 14)),
              ),
              const Spacer(),
              // Wake up button
              if (_loading)
                const CircularProgressIndicator(color: Colors.white70)
              else
                GestureDetector(
                  onTap: _stopSleep,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wb_sunny_outlined,
                            color: Colors.white70),
                        SizedBox(width: 10),
                        Text('Good Morning — Stop Tracking',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}