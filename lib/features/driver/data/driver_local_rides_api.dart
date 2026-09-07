import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../config/app_config.dart';

final class DriverRideRequest {
  const DriverRideRequest({
    required this.rideId,
    required this.bookingId,
    required this.vehicleType,
    required this.pickupLabel,
    required this.dropLabel,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedFare,
    required this.currency,
  });

  final String rideId;
  final String bookingId;
  final String vehicleType;
  final String pickupLabel;
  final String dropLabel;
  final double distanceKm;
  final int durationMinutes;
  final double estimatedFare;
  final String currency;

  factory DriverRideRequest.fromJson(Map<String, Object?> json) {
    final pickup = _map(json['pickup']);
    final destination = _map(json['destination']);
    return DriverRideRequest(
      rideId: _string(json['rideId']),
      bookingId: _string(json['bookingId']),
      vehicleType: _string(json['vehicleType']),
      pickupLabel: _string(pickup['label']),
      dropLabel: _string(destination['label']),
      distanceKm: _number(json['distanceKm']),
      durationMinutes: _number(json['durationMinutes']).round(),
      estimatedFare: _number(json['estimatedFare']),
      currency: _string(json['currency'], fallback: 'INR'),
    );
  }
}

final class DriverActiveRide extends DriverRideRequest {
  const DriverActiveRide({
    required super.rideId,
    required super.bookingId,
    required super.vehicleType,
    required super.pickupLabel,
    required super.dropLabel,
    required super.distanceKm,
    required super.durationMinutes,
    required super.estimatedFare,
    required super.currency,
    required this.driverAcceptedAt,
    required this.locationSharedAt,
  });

  final DateTime driverAcceptedAt;
  final DateTime? locationSharedAt;

  factory DriverActiveRide.fromJson(Map<String, Object?> json) =>
      DriverActiveRide(
        rideId: _string(json['rideId']),
        bookingId: _string(json['bookingId']),
        vehicleType: _string(json['vehicleType']),
        pickupLabel: _string(_map(json['pickup'])['label']),
        dropLabel: _string(_map(json['destination'])['label']),
        distanceKm: _number(json['distanceKm']),
        durationMinutes: _number(json['durationMinutes']).round(),
        estimatedFare: _number(json['estimatedFare']),
        currency: _string(json['currency'], fallback: 'INR'),
        driverAcceptedAt:
            DateTime.tryParse(_string(json['driverAcceptedAt'])) ?? DateTime.now(),
        locationSharedAt: DateTime.tryParse(_string(json['locationSharedAt'])),
      );
}

final class DriverLocalRidesApi {
  DriverLocalRidesApi({AppConfig? config, Dio? dio})
    : _config = config ?? AppConfig.fromEnvironment(),
      _dio = dio ?? Dio();

  final AppConfig _config;
  final Dio _dio;

  Future<void> activateDriverAccess() async {
    await _write('/driver/activate');
  }

  Future<List<DriverRideRequest>> listRequests() async {
    final body = await _get('/driver/local-rides/requests');
    if (body is! List<Object?>) {
      throw const DriverRidesException('The ride request response was invalid.');
    }
    return body
        .whereType<Map<Object?, Object?>>()
        .map((item) => DriverRideRequest.fromJson(_map(item)))
        .toList(growable: false);
  }

  Future<DriverActiveRide?> activeRide() async {
    final body = await _get('/driver/local-rides/active');
    if (body == null) return null;
    final data = _map(body);
    return data.isEmpty ? null : DriverActiveRide.fromJson(data);
  }

  Future<DriverActiveRide> acceptRide(String rideId) async {
    final body = await _write('/driver/local-rides/$rideId/accept');
    return DriverActiveRide.fromJson(_map(body));
  }

  Future<DriverActiveRide> updateLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    final body = await _write(
      '/driver/local-rides/$rideId/location',
      method: 'PUT',
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return DriverActiveRide.fromJson(_map(body));
  }

  Future<Object?> _get(String path) async {
    try {
      final response = await _dio.get<Object?>(
        _endpoint(path),
        options: Options(headers: {'Authorization': 'Bearer ${await _token()}'}),
      );
      final root = _map(response.data);
      return root['data'] ?? response.data;
    } on DioException catch (error) {
      throw DriverRidesException(_message(error.response?.data));
    }
  }

  Future<Object?> _write(
    String path, {
    String method = 'POST',
    Object? data,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        _endpoint(path),
        data: data,
        options: Options(
          method: method,
          headers: {
            'Authorization': 'Bearer ${await _token()}',
            'Content-Type': 'application/json',
          },
        ),
      );
      final root = _map(response.data);
      return root['data'] ?? response.data;
    } on DioException catch (error) {
      throw DriverRidesException(_message(error.response?.data));
    }
  }

  Future<String> _token() async {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw const DriverRidesException('Sign in with a driver account first.');
    }
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    if (token == null || token.isEmpty) {
      throw const DriverRidesException('Your sign-in session has expired.');
    }
    return token;
  }

  String _endpoint(String path) {
    final base = _config.apiBaseUri.toString().replaceFirst(RegExp(r'/$'), '');
    return '$base/${path.replaceFirst(RegExp(r'^/'), '')}';
  }
}

final class DriverRidesException implements Exception {
  const DriverRidesException(this.message);
  final String message;
  @override
  String toString() => message;
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map<Object?, Object?>) return const <String, Object?>{};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _string(Object? value, {String fallback = ''}) =>
    value?.toString() ?? fallback;

double _number(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

String _message(Object? value) {
  final message = _map(value)['message']?.toString().trim();
  return message == null || message.isEmpty
      ? 'Driver service is unavailable. Please try again.'
      : message;
}
