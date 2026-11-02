import 'package:flutter/cupertino.dart';

class ThemeSettingsController extends ChangeNotifier {
  static final ThemeSettingsController instance = ThemeSettingsController._internal();
  ThemeSettingsController._internal();

  bool _isLiquidGlassEnabled = false;

  bool get isLiquidGlassEnabled => _isLiquidGlassEnabled;

  void toggleLiquidGlass(bool value) {
    _isLiquidGlassEnabled = value;
    notifyListeners();
  }
}