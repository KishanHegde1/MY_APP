import 'dart:math';

import 'package:dio/dio.dart';

import '../../../../config/app_config.dart';
import '../../../../shared/models/location_model.dart';
import '../../domain/models/ride_booking_result.dart';
import '../../domain/models/ride_checkout_details.dart';
import '../../domain/models/ride_payment_method.dart';
import '../../domain/models/ride_route_plan.dart';
import '../../domain/models/razorpay_checkout_order.dart';
import '../../domain/repositories/ride_booking_repository.dart';

typedef RideBookingAccessTokenProvider = Future<String?> Function();

enum RideBookingFailure { authenticationRequired, unavailable, rejected }

final class RideBookingException implements Exception {
  const RideBookingException(this.message, this.failure);

  final String message;
  final RideBookingFailure failure;

  @override
  String toString() => message;
}

final class BackendRideBookingRepository implements RideBookingRepository {
  BackendRideBookingRepository({
    required AppConfig config,
    Dio? dio,
    this.accessTokenProvider,
  }) : _config = config,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: config.requestTimeout,
               receiveTimeout: config.requestTimeout,
               sendTimeout: config.requestTimeout,
               responseType: ResponseType.json,
             ),
           );

  final AppConfig _config;
  final Dio _dio;
  final RideBookingAccessTokenProvider? accessTokenProvider;

  @override
  Future<RideBookingResult> createBooking({
    required RideCheckoutDetails checkout,
    required RidePaymentMethod paymentMethod,
  }) async {
    final token = await accessTokenProvider?.call();
    if (token == null || token.trim().isEmpty) {
      throw const RideBookingException(
        'Sign in before booking this ride.',
        RideBookingFailure.authenticationRequired,
      );
    }
    try {
      final response = await _dio.post<Object?>(
        _endpoint('/local-rides/bookings'),
        data: _requestBody(checkout, paymentMethod),
        options: Options(
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Idempotency-Key': _uuidV4(),
          },
        ),
      );
      return _decode(response.data);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final message = _messageFrom(error.response?.data);
      if (status == 401 || status == 403) {
        throw RideBookingException(
          message ?? 'Sign in before booking this ride.',
          RideBookingFailure.authenticationRequired,
        );
      }
      if (status != null && status >= 400 && status < 500) {
        throw RideBookingException(
          message ?? 'This ride request could not be accepted.',
          RideBookingFailure.rejected,
        );
      }
      throw RideBookingException(
        message ?? 'Booking service is unavailable. Please try again.',
        RideBookingFailure.unavailable,
      );
    } on FormatException catch (error) {
      throw RideBookingException(error.message, RideBookingFailure.unavailable);
    }
  }

  @override
  Future<RazorpayCheckoutOrder> createRazorpayOrder({
    required String bookingId,
  }) async {
    final response = await _authorizedPost(
      '/local-rides/bookings/$bookingId/razorpay/order',
      data: const <String, Object?>{},
    );
    final data = _responseData(response);
    final orderId = data['razorpayOrderId']?.toString();
    final keyId = data['keyId']?.toString();
    final returnedBookingId = data['bookingId']?.toString();
    final amount = _integer(data['amount']);
    final currency = data['currency']?.toString();
    if (
        orderId == null ||
        keyId == null ||
        returnedBookingId == null ||
        amount == null ||
        currency == null) {
      throw const RideBookingException(
        'Invalid Razorpay order response.',
        RideBookingFailure.unavailable,
      );
    }
    return RazorpayCheckoutOrder(
      bookingId: returnedBookingId,
      razorpayOrderId: orderId,
      amountInPaise: amount,
      currency: currency,
      keyId: keyId,
    );
  }

  @override
  Future<RazorpayPaymentVerification> verifyRazorpayPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response = await _authorizedPost(
      '/local-rides/bookings/$bookingId/razorpay/verify',
      data: <String, String>{
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      },
    );
    final data = _responseData(response);
    final returnedBookingId = data['bookingId']?.toString();
    final rideId = data['rideId']?.toString();
    final paymentId = data['paymentId']?.toString();
    final paymentStatus = data['paymentStatus']?.toString();
    final bookingStatus = data['bookingStatus']?.toString();
    final fare = _number(data['estimatedFare']);
    final currency = data['currency']?.toString();
    if (
        returnedBookingId == null ||
        rideId == null ||
        paymentId == null ||
        paymentStatus == null ||
        bookingStatus == null ||
        fare == null ||
        currency == null) {
      throw const RideBookingException(
        'Invalid Razorpay verification response.',
        RideBookingFailure.unavailable,
      );
    }
    return RazorpayPaymentVerification(
      bookingId: returnedBookingId,
      rideId: rideId,
      paymentId: paymentId,
      paymentStatus: paymentStatus,
      bookingStatus: bookingStatus,
      estimatedFare: fare,
      currency: currency,
    );
  }

  Map<String, Object?> _requestBody(
    RideCheckoutDetails checkout,
    RidePaymentMethod paymentMethod,
  ) => <String, Object?>{
    'pickup': _location(checkout.pickup),
    'destination': _location(checkout.destination),
    'vehicleType': checkout.vehicle.apiValue,
    'routeId': checkout.route.id,
    'routeTitle': checkout.route.title,
    'routeSource': checkout.planSource == RideRouteSource.googleRoutes
        ? 'GOOGLE_ROUTES'
        : 'ESTIMATED_PREVIEW',
    'distanceKm': checkout.route.distanceKm,
    'durationMinutes': checkout.route.durationMinutes,
    'estimatedFare': checkout.estimatedFare,
    'paymentMethod': paymentMethod.apiValue,
    if (checkout.route.encodedPolyline != null)
      'encodedPolyline': checkout.route.encodedPolyline,
  };

  Map<String, Object?> _location(LocationModel location) => <String, Object?>{
    'latitude': location.latitude,
    'longitude': location.longitude,
    'label': _locationLabel(location),
  };

  String _locationLabel(LocationModel location) {
    final label = location.label?.trim();
    return label == null || label.isEmpty
        ? '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}'
        : label;
  }

  RideBookingResult _decode(Object? response) {
    final root = _asMap(response);
    final data = _asMap(root?['data']) ?? root;
    if (data == null) throw const FormatException('Invalid booking response.');
    final bookingId = data['bookingId']?.toString();
    final rideId = data['rideId']?.toString();
    final status = data['status']?.toString();
    final paymentMethod = data['paymentMethod']?.toString();
    final currency = data['currency']?.toString();
    final fare = _number(data['estimatedFare']);
    if (bookingId == null ||
        rideId == null ||
        status == null ||
        paymentMethod == null ||
        currency == null ||
        fare == null) {
      throw const FormatException('Invalid booking response.');
    }
    return RideBookingResult(
      bookingId: bookingId,
      rideId: rideId,
      status: status,
      paymentMethod: paymentMethod,
      estimatedFare: fare,
      currency: currency,
    );
  }

  String _endpoint(String path) {
    final base = _config.apiBaseUri.toString().replaceFirst(RegExp(r'/$'), '');
    return '$base/${path.replaceFirst(RegExp(r'^/'), '')}';
  }

  Future<Object?> _authorizedPost(
    String path, {
    required Object? data,
  }) async {
    final token = await accessTokenProvider?.call();
    if (token == null || token.trim().isEmpty) {
      throw const RideBookingException(
        'Sign in before continuing to payment.',
        RideBookingFailure.authenticationRequired,
      );
    }
    try {
      final response = await _dio.post<Object?>(
        _endpoint(path),
        data: data,
        options: Options(
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response.data;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final message = _messageFrom(error.response?.data);
      throw RideBookingException(
        message ??
            (status == 401 || status == 403
                ? 'Sign in before continuing to payment.'
                : 'Payment service is unavailable. Please try again.'),
        status == 401 || status == 403
            ? RideBookingFailure.authenticationRequired
            : RideBookingFailure.unavailable,
      );
    }
  }

  Map<String, Object?> _responseData(Object? response) {
    final root = _asMap(response);
    final data = _asMap(root?['data']) ?? root;
    if (data == null) {
      throw const RideBookingException(
        'Invalid payment service response.',
        RideBookingFailure.unavailable,
      );
    }
    return data;
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
    final value = root?['message']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
