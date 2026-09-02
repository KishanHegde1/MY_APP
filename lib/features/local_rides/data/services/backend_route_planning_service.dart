import 'dart:math' as math;

import 'package:dio/dio.dart';

import '../../../../config/app_config.dart';
import '../../../../shared/models/location_model.dart';
import '../../domain/models/ride_route_plan.dart';
import '../../domain/services/route_planning_service.dart';

typedef RouteAccessTokenProvider = Future<String?> Function();

final class BackendRoutePlanningService implements RoutePlanningService {
  BackendRoutePlanningService({
    required AppConfig config,
    required this.destinationResolver,
    Dio? dio,
    this.accessTokenProvider,
  }) : _config = config,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: _routeTimeout(config.requestTimeout),
               receiveTimeout: _routeTimeout(config.requestTimeout),
               sendTimeout: _routeTimeout(config.requestTimeout),
               responseType: ResponseType.json,
             ),
           );

  final AppConfig _config;
  final DestinationResolver destinationResolver;
  final Dio _dio;
  final RouteAccessTokenProvider? accessTokenProvider;

  @override
  Future<RideRoutePlan> planRoutes({
    required LocationModel pickup,
    required String destinationQuery,
    required RideRouteVehicle vehicle,
  }) async {
    final query = destinationQuery.trim();
    if (query.length < 3) {
      throw const RoutePlanningException(
        'Enter a destination with at least 3 characters.',
      );
    }
    final destination = await destinationResolver.resolve(
      query: query,
      near: pickup,
    );
    if (destination == null) {
      throw const RoutePlanningException(
        'We could not find that destination. Add the city, area, or landmark '
        'and try again.',
      );
    }

    final token = await accessTokenProvider?.call();
    final response = await _dio.post<Object?>(
      _endpoint('/maps/routes'),
      data: <String, Object?>{
        'origin': <String, double>{
          'latitude': pickup.latitude,
          'longitude': pickup.longitude,
        },
        'destination': <String, double>{
          'latitude': destination.latitude,
          'longitude': destination.longitude,
        },
        'alternatives': true,
        'vehicleType': vehicle.apiValue,
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
    return _decode(response.data, pickup, destination);
  }

  RideRoutePlan _decode(
    Object? response,
    LocationModel pickup,
    LocationModel destination,
  ) {
    final root = _stringMap(response);
    final data = _stringMap(root?['data']) ?? root;
    final rawRoutes = data?['routes'];
    if (rawRoutes is! List<Object?> || rawRoutes.isEmpty) {
      throw const RoutePlanningException(
        'The route service returned no route alternatives.',
      );
    }

    final routes = <RideRouteOption>[];
    for (var index = 0; index < rawRoutes.length; index++) {
      final json = _stringMap(rawRoutes[index]);
      if (json == null) continue;
      final distanceKm =
          _number(json['distanceKilometers']) ??
          _number(json['distanceKm']) ??
          ((_number(json['distanceMeters']) ?? 0) / 1000);
      final durationMinutes =
          (_number(json['durationMinutes']) ??
                  ((_number(json['durationSeconds']) ?? 0) / 60))
              .ceil();
      if (distanceKm <= 0 || durationMinutes <= 0) continue;

      final encodedPolyline = json['encodedPolyline']?.toString();
      if (encodedPolyline == null || encodedPolyline.isEmpty) continue;
      final points = _decodePolyline(encodedPolyline);
      if (points.length < 2) continue;
      final label = json['label']?.toString().trim();
      routes.add(
        RideRouteOption(
          id: json['id']?.toString() ?? 'route-$index',
          title: label == null || label.isEmpty
              ? index == 0
                    ? 'Recommended'
                    : 'Alternative ${index + 1}'
              : label,
          description: json['description']?.toString() ?? 'Google road route',
          distanceKm: distanceKm,
          durationMinutes: math.max(1, durationMinutes),
          fareMultiplier: 1,
          points: points,
          encodedPolyline: encodedPolyline,
          fareEstimates: _fareEstimates(json['fareEstimates']),
          isRecommended: json['isRecommended'] == true || index == 0,
        ),
      );
    }
    if (routes.isEmpty) {
      throw const RoutePlanningException(
        'The route service returned invalid route alternatives.',
      );
    }

    return RideRoutePlan(
      pickup: pickup,
      destination: destination,
      routes: routes,
      source: RideRouteSource.googleRoutes,
      sourceNotice:
          'Road distances and route alternatives supplied by Google Routes '
          'through the Multi Service backend. Fares are indicative estimates '
          'and can change at booking.',
    );
  }

  String _endpoint(String path) {
    final base = _config.apiBaseUri.toString().replaceFirst(RegExp(r'/$'), '');
    final suffix = path.replaceFirst(RegExp(r'^/'), '');
    return '$base/$suffix';
  }

  static Duration _routeTimeout(Duration configured) {
    // The backend allows Google Routes up to eight seconds. Leave enough time
    // for the provider response plus mobile-network and JSON overhead.
    const maximum = Duration(seconds: 12);
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

  static Map<String, double> _fareEstimates(Object? value) {
    if (value is List<Object?>) {
      final fares = <String, double>{};
      for (final item in value) {
        final json = _stringMap(item);
        final vehicleType = json?['vehicleType']?.toString().trim();
        final amount =
            _number(json?['estimatedAmount']) ??
            _number(json?['amount']) ??
            _number(json?['estimatedFare']);
        if (vehicleType != null &&
            vehicleType.isNotEmpty &&
            amount != null &&
            amount >= 0) {
          fares[vehicleType.toUpperCase()] = amount;
        }
      }
      return fares;
    }
    final json = _stringMap(value);
    if (json == null) return const <String, double>{};
    final fares = <String, double>{};
    for (final entry in json.entries) {
      final nested = _stringMap(entry.value);
      final amount =
          _number(entry.value) ??
          _number(nested?['amount']) ??
          _number(nested?['estimatedFare']);
      if (amount != null && amount >= 0) {
        fares[entry.key.toUpperCase()] = amount;
      }
    }
    return fares;
  }

  static List<RideRoutePoint> _decodePolyline(String encoded) {
    const maximumEncodedLength = 100000;
    const maximumPoints = 10000;
    if (encoded.isEmpty || encoded.length > maximumEncodedLength) {
      return const <RideRoutePoint>[];
    }
    final points = <RideRoutePoint>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;
    while (index < encoded.length) {
      final latitudeResult = _decodeValue(encoded, index);
      if (latitudeResult == null) return const <RideRoutePoint>[];
      index = latitudeResult.nextIndex;
      latitude += latitudeResult.delta;
      final longitudeResult = _decodeValue(encoded, index);
      if (longitudeResult == null) return const <RideRoutePoint>[];
      index = longitudeResult.nextIndex;
      longitude += longitudeResult.delta;
      final decodedLatitude = latitude / 1e5;
      final decodedLongitude = longitude / 1e5;
      if (!decodedLatitude.isFinite ||
          !decodedLongitude.isFinite ||
          decodedLatitude < -90 ||
          decodedLatitude > 90 ||
          decodedLongitude < -180 ||
          decodedLongitude > 180) {
        return const <RideRoutePoint>[];
      }
      points.add(
        RideRoutePoint(latitude: decodedLatitude, longitude: decodedLongitude),
      );
      if (points.length > maximumPoints) return const <RideRoutePoint>[];
    }
    return points;
  }

  static _DecodedValue? _decodeValue(String encoded, int startIndex) {
    var index = startIndex;
    var result = 0;
    var shift = 0;
    var byte = 0;
    do {
      if (index >= encoded.length) return null;
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    final delta = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    return _DecodedValue(delta: delta, nextIndex: index);
  }
}

final class BackendFirstRoutePlanningService implements RoutePlanningService {
  const BackendFirstRoutePlanningService({
    required this.backend,
    required this.fallback,
  });

  final RoutePlanningService backend;
  final RoutePlanningService fallback;

  @override
  Future<RideRoutePlan> planRoutes({
    required LocationModel pickup,
    required String destinationQuery,
    required RideRouteVehicle vehicle,
  }) async {
    try {
      return await backend.planRoutes(
        pickup: pickup,
        destinationQuery: destinationQuery,
        vehicle: vehicle,
      );
    } on DioException {
      return _fallbackPlan(pickup, destinationQuery, vehicle);
    } on RoutePlanningException {
      return _fallbackPlan(pickup, destinationQuery, vehicle);
    } on FormatException {
      return _fallbackPlan(pickup, destinationQuery, vehicle);
    }
  }

  Future<RideRoutePlan> _fallbackPlan(
    LocationModel pickup,
    String destinationQuery,
    RideRouteVehicle vehicle,
  ) async {
    final plan = await fallback.planRoutes(
      pickup: pickup,
      destinationQuery: destinationQuery,
      vehicle: vehicle,
    );
    return RideRoutePlan(
      pickup: plan.pickup,
      destination: plan.destination,
      routes: plan.routes,
      source: RideRouteSource.estimatedPreview,
      sourceNotice:
          'Fallback estimate — the backend/Google Routes service is not '
          'available. Distances, route shapes, times, and fares are not live.',
    );
  }
}

final class _DecodedValue {
  const _DecodedValue({required this.delta, required this.nextIndex});

  final int delta;
  final int nextIndex;
}
