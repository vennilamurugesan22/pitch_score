import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_colors.dart';

// Holds the user's theme choice (dark / light / system), saved in Hive.
// Dark is the default — easiest to read outdoors and saves battery.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.dark);

  static final instance = ThemeController._();

  static const String _boxName = 'settings';
  static const String _key = 'theme_mode';

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final saved = box.get(_key) as String?;
    value = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.dark,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    try {
      await Hive.box(_boxName).put(_key, mode.name);
    } catch (e) {
      debugPrint('ThemeController save error: $e');
    }
  }

  // Palette for the current choice; 'system' follows the phone setting
  AppPalette resolve(Brightness platform) {
    final dark = switch (value) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platform == Brightness.dark,
    };
    return dark ? AppPalette.dark : AppPalette.light;
  }
}
