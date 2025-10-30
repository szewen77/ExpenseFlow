import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2A9D8F); // teal
  static const secondary = Color(0xFFE9C46A); // warm yellow accent
  static const background = Color(0xFFF7F8FA); // off-white
  static const card = Colors.white;
  static const income = Color(0xFF22C55E);
  static const expense = Color(0xFFEF4444);
}

class AppStrings {
  static const appName = 'ExpenseFlow';
  static const currencyPrefix = 'RM';
}

class AppDurations {
  static const splashDelay = Duration(seconds: 2);
}

class AppConstants {
  static const categories = <String>[
    'Food',
    'Travel',
    'Bills',
    'Shopping',
    'Entertainment',
    'Health',
    'Work',
    'Other',
  ];
}
