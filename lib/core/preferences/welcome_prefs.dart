import 'package:shared_preferences/shared_preferences.dart';

class WelcomePrefs {
  static const String _nameKey = 'user_display_name';
  static const String _lastWelcomeDateKey = 'last_welcome_date';

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey)?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
  }

  static Future<bool> shouldShowWelcomeToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final last = prefs.getString(_lastWelcomeDateKey);
    final name = prefs.getString(_nameKey)?.trim();

    final needsName = name == null || name.isEmpty;
    if (needsName) return true;

    return last != today;
  }

  static Future<void> markWelcomeShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastWelcomeDateKey, _todayString());
  }

  static String _todayString() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}

