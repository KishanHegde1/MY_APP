final class LocationModel {
  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.label,
  }) : assert(latitude >= -90 && latitude <= 90),
       assert(longitude >= -180 && longitude <= 180);

  factory LocationModel.fromJson(Map<String, Object?> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      label: json['label'] as String?,
    );
  }

  final double latitude;
  final double longitude;
  final String? label;

  Map<String, Object?> toJson() => <String, Object?>{
    'latitude': latitude,
    'longitude': longitude,
    if (label != null) 'label': label,
  };
}
