import 'package:flutter/cupertino.dart';

class AppIosTheme {
  static const Color f1Red = Color(0xFFE10600);

  static const CupertinoThemeData theme = CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: f1Red,
    barBackgroundColor: CupertinoColors.systemBackground,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    textTheme: CupertinoTextThemeData(
      navTitleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        color: CupertinoColors.black,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.8,
        color: CupertinoColors.black,
      ),
    ),
  );
}