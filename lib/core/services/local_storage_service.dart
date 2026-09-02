import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalStorageService {
  Future<void> setValue(String key, Object? value);
  Future<T?> getValue<T>(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

final class InMemoryLocalStorageService implements LocalStorageService {
  final Map<String, Object?> _values = <String, Object?>{};

  @override
  Future<void> setValue(String key, Object? value) async =>
      _values[key] = value;

  @override
  Future<T?> getValue<T>(String key) async => _values[key] as T?;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();
}

final class DeviceLocalStorageService implements LocalStorageService {
  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<void> setValue(String key, Object? value) async {
    final preferences = await _preferences;
    if (value == null) {
      await preferences.remove(key);
      return;
    }
    switch (value) {
      case String value:
        await preferences.setString(key, value);
      case bool value:
        await preferences.setBool(key, value);
      case int value:
        await preferences.setInt(key, value);
      case double value:
        await preferences.setDouble(key, value);
      case List<String> value:
        await preferences.setStringList(key, value);
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Unsupported local-storage value type.',
        );
    }
  }

  @override
  Future<T?> getValue<T>(String key) async =>
      (await _preferences).get(key) as T?;
  @override
  Future<void> remove(String key) async {
    await (await _preferences).remove(key);
  }

  @override
  Future<void> clear() async {
    await (await _preferences).clear();
  }
}
