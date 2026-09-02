enum Flavor {
  development,
  staging,
  production;

  static Flavor fromName(String value) {
    return switch (value.trim().toLowerCase()) {
      'production' || 'prod' => Flavor.production,
      'staging' || 'stage' => Flavor.staging,
      _ => Flavor.development,
    };
  }

  bool get isProduction => this == Flavor.production;
}
