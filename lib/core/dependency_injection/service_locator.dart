final class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  final Map<Type, Object> _singletons = <Type, Object>{};
  final Map<Type, Object Function()> _factories = <Type, Object Function()>{};

  void registerSingleton<T extends Object>(T instance, {bool replace = false}) {
    if (!replace && (_singletons.containsKey(T) || _factories.containsKey(T))) {
      throw StateError('$T is already registered.');
    }
    _factories.remove(T);
    _singletons[T] = instance;
  }

  void registerFactory<T extends Object>(
    T Function() factory, {
    bool replace = false,
  }) {
    if (!replace && (_singletons.containsKey(T) || _factories.containsKey(T))) {
      throw StateError('$T is already registered.');
    }
    _singletons.remove(T);
    _factories[T] = factory;
  }

  T get<T extends Object>() {
    final singleton = _singletons[T];
    if (singleton != null) return singleton as T;
    final factory = _factories[T];
    if (factory != null) return factory() as T;
    throw StateError('$T is not registered.');
  }

  bool isRegistered<T extends Object>() =>
      _singletons.containsKey(T) || _factories.containsKey(T);

  void reset() {
    _singletons.clear();
    _factories.clear();
  }
}

final sl = ServiceLocator.instance;
