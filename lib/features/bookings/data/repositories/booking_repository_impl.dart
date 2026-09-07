import 'package:dio/dio.dart';

import '../../../../config/app_config.dart';
import '../../../../shared/models/location_model.dart';
import '../../domain/repositories/booking_repository.dart';
import '../models/booking_model.dart';

typedef BookingAccessTokenProvider = Future<String?> Function();

final class BookingRepositoryException implements Exception {
  const BookingRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({
    required AppConfig config,
    this.accessTokenProvider,
    Dio? dio,
  }) : _config = config,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: config.requestTimeout,
               receiveTimeout: config.requestTimeout,
               responseType: ResponseType.json,
             ),
           );

  final AppConfig _config;
  final Dio _dio;
  final BookingAccessTokenProvider? accessTokenProvider;

  @override
  Future<BookingModel?> getBooking(String id) async {
    final bookings = await getBookings();
    for (final booking in bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  @override
  Future<List<BookingModel>> getBookings() async {
    final token = await accessTokenProvider?.call();
    if (token == null || token.trim().isEmpty) {
      throw const BookingRepositoryException(
        'Sign in to view your saved bookings.',
      );
    }
    try {
      final response = await _dio.get<Object?>(
        _endpoint('/local-rides/bookings'),
        options: Options(
          headers: <String, String>{
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      final root = _asMap(response.data);
      final data = root?['data'];
      if (data is! List<Object?>) {
        throw const FormatException('Invalid bookings response.');
      }
      return data
          .map(_asMap)
          .whereType<Map<String, Object?>>()
          .map(_bookingFromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      final message = _messageFrom(error.response?.data);
      throw BookingRepositoryException(
        message ?? 'Your bookings could not be loaded. Please try again.',
      );
    } on FormatException catch (error) {
      throw BookingRepositoryException(error.message);
    }
  }

  String _endpoint(String path) {
    final base = _config.apiBaseUri.toString().replaceFirst(RegExp(r'/$'), '');
    return '$base/${path.replaceFirst(RegExp(r'^/'), '')}';
  }

  static BookingModel _bookingFromJson(Map<String, Object?> json) {
    final bookingId = json['bookingId']?.toString().trim();
    final rideId = json['rideId']?.toString().trim();
    final pickup = _location(json['pickup']);
    final destination = _location(json['destination']);
    final distanceKm = _number(json['distanceKm']);
    final durationMinutes = _integer(json['durationMinutes']);
    final estimatedFare = _number(json['estimatedFare']);
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (bookingId == null ||
        bookingId.isEmpty ||
        rideId == null ||
        rideId.isEmpty ||
        pickup == null ||
        destination == null ||
        distanceKm == null ||
        durationMinutes == null ||
        estimatedFare == null ||
        createdAt == null) {
      throw const FormatException('A saved booking is missing required details.');
    }
    return BookingModel(
      id: bookingId,
      rideId: rideId,
      serviceType: json['serviceType']?.toString() ?? 'LOCAL_RIDE',
      status: _status(json['status']),
      createdAt: createdAt.toLocal(),
      vehicleType: json['vehicleType']?.toString() ?? 'RIDE',
      pickup: pickup,
      destination: destination,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      estimatedFare: estimatedFare,
      currency: json['currency']?.toString() ?? 'INR',
      paymentMethod: json['paymentMethod']?.toString() ?? 'CASH',
      paymentStatus: json['paymentStatus']?.toString(),
      trackingAvailable: json['trackingAvailable'] == true,
      trackingMessage:
          json['trackingMessage']?.toString() ??
          'Live tracking will appear when a driver accepts this ride.',
    );
  }

  static BookingStatus _status(Object? value) =>
      switch (value?.toString().toUpperCase()) {
        'CONFIRMED' => BookingStatus.confirmed,
        'ACTIVE' => BookingStatus.active,
        'COMPLETED' => BookingStatus.completed,
        'CANCELLED' => BookingStatus.cancelled,
        _ => BookingStatus.pending,
      };

  static LocationModel? _location(Object? value) {
    final json = _asMap(value);
    if (json == null) return null;
    final latitude = _number(json['latitude']);
    final longitude = _number(json['longitude']);
    if (latitude == null || longitude == null) return null;
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      label: json['label']?.toString(),
    );
  }

  static Map<String, Object?>? _asMap(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static double? _number(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');

  static int? _integer(Object? value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '');

  static String? _messageFrom(Object? response) {
    final root = _asMap(response);
    final message = root?['message']?.toString().trim();
    return message == null || message.isEmpty ? null : message;
  }
}
