import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ProfileViewModel extends ChangeNotifier {
  String _userName = 'Usuário';
  String get userName => _userName;

  ProfileViewModel() {
    _initUserName();
  }

  Future<void> _initUserName() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'Usuário';
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    if (_userName == name) return;
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    notifyListeners();
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }
}
