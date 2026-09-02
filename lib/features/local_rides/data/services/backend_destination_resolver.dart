import 'package:dio/dio.dart';

import '../../../../config/app_config.dart';
import '../../../../shared/models/location_model.dart';
import '../../domain/services/route_planning_service.dart';

typedef DestinationAccessTokenProvider = Future<String?> Function();

/// Resolves typed destinations through the backend so the Places API key never
/// ships in the Android app. When the backend or Google Places is unavailable,
/// the supplied device resolver keeps destination entry usable.
final class BackendDestinationResolver implements DestinationResolver {
  BackendDestinationResolver({
    required AppConfig config,
    required this.fallback,
    Dio? dio,
    this.accessTokenProvider,
  }) : _config = config,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: _destinationTimeout(config.requestTimeout),
               receiveTimeout: _destinationTimeout(config.requestTimeout),
               sendTimeout: _destinationTimeout(config.requestTimeout),
               responseType: ResponseType.json,
             ),
           );

  final AppConfig _config;
  final DestinationResolver fallback;
  final Dio _dio;
  final DestinationAccessTokenProvider? accessTokenProvider;

  @override
  Future<LocationModel?> resolve({
    required String query,
    LocationModel? near,
  }) async {
    final normalizedQuery = query.trim();
    final coordinate = _coordinateFrom(normalizedQuery);
    if (coordinate != null) return coordinate;

    try {
      final token = await accessTokenProvider?.call();
      final response = await _dio.post<Object?>(
        _endpoint('/maps/places/resolve'),
        data: <String, Object?>{
          'query': normalizedQuery,
          if (near != null)
            'near': <String, double>{
              'latitude': near.latitude,
              'longitude': near.longitude,
            },
        },
        options: Options(
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      final place = _placeFrom(response.data);
      if (place != null) return place;
    } on DioException {
      // A missing key, unreachable local backend, or provider issue should not
      // make the form unusable while the app has a device-geocoder fallback.
    } on FormatException {
      // Treat malformed provider data as unavailable and use the fallback.
    }

    return fallback.resolve(query: normalizedQuery, near: near);
  }

  LocationModel? _placeFrom(Object? response) {
    final root = _stringMap(response);
    final data = _stringMap(root?['data']) ?? root;
    final rawPlace = data?['place'];
    if (rawPlace == null) return null;
    final place = _stringMap(rawPlace);
    if (place == null) {
      throw const FormatException('Invalid place response.');
    }
    final latitude = _number(place['latitude']);
    final longitude = _number(place['longitude']);
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const FormatException('Invalid place coordinates.');
    }
    final name = place['name']?.toString().trim();
    final address = place['formattedAddress']?.toString().trim();
    final label = address != null && address.isNotEmpty
        ? address
        : name != null && name.isNotEmpty
        ? name
        : null;
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
  }

  String _endpoint(String path) {
    final base = _config.apiBaseUri.toString().replaceFirst(RegExp(r'/$'), '');
    final suffix = path.replaceFirst(RegExp(r'^/'), '');
    return '$base/$suffix';
  }

  static Duration _destinationTimeout(Duration configured) {
    const maximum = Duration(seconds: 8);
    return configured > maximum ? maximum : configured;
  }

  static Map<String, Object?>? _stringMap(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static LocationModel? _coordinateFrom(String value) {
    final parts = value.split(',');
    if (parts.length != 2) return null;
    final latitude = double.tryParse(parts.first.trim());
    final longitude = double.tryParse(parts.last.trim());
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90) return null;
    if (longitude < -180 || longitude > 180) return null;
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      label: value,
    );
  }
}
