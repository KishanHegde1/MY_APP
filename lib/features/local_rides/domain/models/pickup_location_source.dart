enum PickupLocationSource {
  gps('GPS'),
  manual('MANUAL'),
  mapPin('MAP_PIN');

  const PickupLocationSource(this.apiValue);

  final String apiValue;
}
