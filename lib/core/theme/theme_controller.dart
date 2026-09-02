import 'package:flutter/material.dart';

import '../constants/storage_keys.dart';
import '../services/local_storage_service.dart';

/// Owns the app-wide appearance preference and persists it on the device.
class ThemeController extends ChangeNotifier {
  ThemeController({LocalStorageService? storage})
    : _storage = storage ?? InMemoryLocalStorageService();

  final LocalStorageService _storage;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      final savedMode = await _storage.getValue<String>(StorageKeys.themeMode);
      final restoredMode = _themeModeFromName(savedMode);
      if (restoredMode == _themeMode) return;
      _themeMode = restoredMode;
      notifyListeners();
    } on Object catch (error) {
      debugPrint('Could not restore the theme preference: $error');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      await _storage.setValue(StorageKeys.themeMode, mode.name);
    } on Object catch (error) {
      debugPrint('Could not save the theme preference: $error');
    }
  }

  static ThemeMode _themeModeFromName(String? name) {
    return ThemeMode.values.where((mode) => mode.name == name).firstOrNull ??
        ThemeMode.system;
  }
}

/// Makes the shared [ThemeController] available below [MultiServiceApp].
class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    required ThemeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'No ThemeControllerScope found in this context.');
    return scope!.notifier!;
  }
}
