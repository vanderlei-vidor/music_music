import 'package:flutter/material.dart';

class PlayerPanelController extends ChangeNotifier {
  double _progress = 0.0; // 0 = mini | 1 = player full

  double get progress => _progress;

  bool get isOpen => _progress > 0.5;

  void open() {
    _progress = 1.0;
    notifyListeners();
  }

  void close() {
    _progress = 0.0;
    notifyListeners();
  }

  void update(double value) {
    _progress = value.clamp(0.0, 1.0);
    notifyListeners();
  }
}
