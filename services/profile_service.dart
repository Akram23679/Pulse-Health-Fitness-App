import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  String _name = 'Your Name';
  String? _photoPath; // local file path
  DateTime _joinDate = DateTime.now();

  String get name => _name;
  String? get photoPath => _photoPath;
  DateTime get joinDate => _joinDate;

  String get initials {
    final parts = _name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _name.isNotEmpty ? _name[0].toUpperCase() : '?';
  }

  String get joinDateStr {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Joined ${months[_joinDate.month - 1]} ${_joinDate.year}';
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString('profile_name') ?? 'Your Name';
      _photoPath = prefs.getString('profile_photo');

      final joinMs = prefs.getInt('profile_join_date');
      if (joinMs != null) {
        _joinDate = DateTime.fromMillisecondsSinceEpoch(joinMs);
      } else {
        // First time — save today as join date
        _joinDate = DateTime.now();
        await prefs.setInt(
            'profile_join_date', _joinDate.millisecondsSinceEpoch);
      }
      notifyListeners();
    } catch (_) {}
  }

  // ── Save name ─────────────────────────────────────────────────────────────
  Future<void> saveName(String name) async {
    _name = name.trim().isEmpty ? 'Your Name' : name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _name);
    notifyListeners();
  }

  // ── Save photo path ───────────────────────────────────────────────────────
  Future<void> savePhoto(String path) async {
    _photoPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo', path);
    notifyListeners();
  }
}