import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PodcastPreferences extends ChangeNotifier {
  static const _enabledKey = 'podcasts_enabled';
  bool _enabled = false;

  bool get enabled => _enabled;

  PodcastPreferences() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }
}
