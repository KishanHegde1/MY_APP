import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../config/app_config.dart';

final class CustomerLocalRideBooking {
  const CustomerLocalRideBooking({
    required this.bookingId,
    required this.rideId,
    required this.status,
    required this.vehicleType,
    required this.pickupLabel,
    required this.dropLabel,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropLatitude,
    required this.dropLongitude,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedFare,
    required this.currency,
    required this.createdAt,
    required this.trackingAvailable,
    required this.trackingMessage,
    required this.driver,
  });

  final String bookingId;
  final String rideId;
  final String status;
  final String vehicleType;
  final String pickupLabel;
  final String dropLabel;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropLatitude;
  final double dropLongitude;
  final double distanceKm;
  final int durationMinutes;
  final double estimatedFare;
  final String currency;
  final DateTime createdAt;
  final bool trackingAvailable;
  final String trackingMessage;
  final DriverLiveTracking? driver;

  factory CustomerLocalRideBooking.fromJson(Map<String, Object?> json) {
    final pickup = _map(json['pickup']);
    final destination = _map(json['destination']);
    final driver = _map(json['driver']);
    return CustomerLocalRideBooking(
      bookingId: _string(json['bookingId']),
      rideId: _string(json['rideId']),
      status: _string(json['status']),
      vehicleType: _string(json['vehicleType']),
      pickupLabel: _string(pickup['label']),
      dropLabel: _string(destination['label']),
      pickupLatitude: _number(pickup['latitude']),
      pickupLongitude: _number(pickup['longitude']),
      dropLatitude: _number(destination['latitude']),
      dropLongitude: _number(destination['longitude']),
      distanceKm: _number(json['distanceKm']),
      durationMinutes: _number(json['durationMinutes']).round(),
      estimatedFare: _number(json['estimatedFare']),
      currency: _string(json['currency'], fallback: 'INR'),
      createdAt: DateTime.tryParse(_string(json['createdAt'])) ?? DateTime.now(),
      trackingAvailable: json['trackingAvailable'] == true,
      trackingMessage: _string(json['trackingMessage']),
      driver: driver.isEmpty ? null : DriverLiveTracking.fromJson(driver),
    );
  }
}

final class DriverLiveTracking {
  const DriverLiveTracking({
    required this.acceptedAt,
    required this.location,
    required this.estimatedArrivalMinutes,
  });

  final DateTime acceptedAt;
  final DriverLocation? location;
  final int? estimatedArrivalMinutes;

  factory DriverLiveTracking.fromJson(Map<String, Object?> json) {
    final location = _map(json['location']);
    return DriverLiveTracking(
      acceptedAt: DateTime.tryParse(_string(json['acceptedAt'])) ?? DateTime.now(),
      location: location.isEmpty ? null : DriverLocation.fromJson(location),
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'] == null
          ? null
          : _number(json['estimatedArrivalMinutes']).round(),
    );
  }
}

final class DriverLocation {
  const DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  factory DriverLocation.fromJson(Map<String, Object?> json) => DriverLocation(
    latitude: _number(json['latitude']),
    longitude: _number(json['longitude']),
    updatedAt: DateTime.tryParse(_string(json['updatedAt'])) ?? DateTime.now(),
  );
}

final class CustomerLocalRideBookingsApi {
  CustomerLocalRideBookingsApi({AppConfig? config, Dio? dio})
    : _config = config ?? AppConfig.fromEnvironment(),
      _dio = dio ?? Dio();

  final AppConfig _config;
  final Dio _dio;

  Future<List<CustomerLocalRideBooking>> listBookings() async {
    final token = await _token();
    try {
      final response = await _dio.get<Object?>(
        _endpoint('/local-rides/bookings'),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final body = _map(response.data);
      final raw = body['data'] ?? response.data;
      if (raw is! List<Object?>) {
        throw const CustomerBookingsException('The booking response was invalid.');
      }
      return raw
          .whereType<Map<Object?, Object?>>()
          .map((item) => CustomerLocalRideBooking.fromJson(_map(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw CustomerBookingsException(_message(error.response?.data));
    }
  }

  Future<String> _token() async {
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      throw const CustomerBookingsException('Sign in to see your bookings.');
    }
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    if (token == null || token.isEmpty) {
      throw const CustomerBookingsException('Your sign-in session has expired.');
    }
    return token;
  }

  String _endpoint(String path) {
    final base = _config.apiBaseUri.toString().replaceFirst(RegExp(r'/$'), '');
    return '$base/${path.replaceFirst(RegExp(r'^/'), '')}';
  }
}

final class CustomerBookingsException implements Exception {
  const CustomerBookingsException(this.message);
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
      ? 'Bookings are unavailable. Please try again.'
      : message;
}
