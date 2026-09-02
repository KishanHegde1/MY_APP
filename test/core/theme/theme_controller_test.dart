import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/core/services/local_storage_service.dart';
import 'package:my_app_flutter/core/theme/theme_controller.dart';

void main() {
  test('persists and restores the selected theme mode', () async {
    final storage = InMemoryLocalStorageService();
    final controller = ThemeController(storage: storage);

    await controller.setThemeMode(ThemeMode.dark);

    final restoredController = ThemeController(storage: storage);
    await restoredController.load();

    expect(restoredController.themeMode, ThemeMode.dark);
  });
}
