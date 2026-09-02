import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'core/dependency_injection/service_locator.dart';
import 'core/services/image_picker_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/location_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/theme/theme_controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  }
  if (!sl.isRegistered<AppConfig>()) {
    sl.registerSingleton(AppConfig.fromEnvironment());
  }
  if (!sl.isRegistered<SecureStorageService>()) {
    sl.registerSingleton<SecureStorageService>(DeviceSecureStorageService());
    sl.registerSingleton<LocalStorageService>(DeviceLocalStorageService());
    sl.registerSingleton<LocationService>(const DeviceLocationService());
    sl.registerSingleton<ImagePickerService>(DeviceImagePickerService());
  }
  final themeController = ThemeController(
    storage: sl.get<LocalStorageService>(),
  );
  await themeController.load();
  // Notification permission and channel setup remains a separate feature.
  runApp(
    ProviderScope(child: MultiServiceApp(themeController: themeController)),
  );
}
