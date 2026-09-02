import 'package:dio/dio.dart';

import '../../domain/models/pickup_location_source.dart';
import '../../domain/repositories/pickup_location_repository.dart';

typedef PickupBearerTokenProvider = Future<String?> Function();

final class BackendPickupLocationRepository
    implements PickupLocationRepository {
  factory BackendPickupLocationRepository({
    required Uri apiBaseUri,
    required PickupBearerTokenProvider bearerTokenProvider,
    Dio? dio,
  }) {
    return BackendPickupLocationRepository._(
      apiBaseUri,
      bearerTokenProvider,
      dio ?? Dio(),
    );
  }

  BackendPickupLocationRepository._(
    this._apiBaseUri,
    this._bearerTokenProvider,
    this._dio,
  );

  final Uri _apiBaseUri;
  final PickupBearerTokenProvider _bearerTokenProvider;
  final Dio _dio;

  @override
  Future<void> savePickupLocation({
    required double latitude,
    required double longitude,
    required String formattedAddress,
    required PickupLocationSource source,
  }) async {
    final normalizedAddress = formattedAddress.trim();
    if (!_isValidCoordinate(latitude, longitude) || normalizedAddress.isEmpty) {
      throw const PickupLocationPersistenceException(
        PickupLocationPersistenceFailure.invalidLocation,
        'Choose a valid pickup point and address before saving.',
      );
    }

    final String? token;
    try {
      token = (await _bearerTokenProvider())?.trim();
    } catch (_) {
      throw const PickupLocationPersistenceException(
        PickupLocationPersistenceFailure.authenticationRequired,
        'Please sign in again to save your pickup location.',
      );
    }
    if (token == null || token.isEmpty) {
      throw const PickupLocationPersistenceException(
        PickupLocationPersistenceFailure.authenticationRequired,
        'Please sign in again to save your pickup location.',
      );
    }

    try {
      await _dio.put<Object?>(
        _endpoint('/users/me/pickup-location'),
        data: <String, Object>{
          'latitude': latitude,
          'longitude': longitude,
          'formattedAddress': normalizedAddress,
          'source': source.apiValue,
        },
        options: Options(
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        throw const PickupLocationPersistenceException(
          PickupLocationPersistenceFailure.authenticationRequired,
          'Your session expired. Please sign in again to save this location.',
        );
      }
      if (_isNetworkFailure(error)) {
        throw const PickupLocationPersistenceException(
          PickupLocationPersistenceFailure.networkUnavailable,
          'Could not reach the server. Check your connection and try again.',
        );
      }
      throw const PickupLocationPersistenceException(
        PickupLocationPersistenceFailure.saveRejected,
        'We could not save this pickup location. Please try again.',
      );
    }
  }

  String _endpoint(String path) {
    final base = _apiBaseUri.toString().replaceFirst(RegExp(r'/$'), '');
    final suffix = path.replaceFirst(RegExp(r'^/'), '');
    return '$base/$suffix';
  }

  static bool _isValidCoordinate(double latitude, double longitude) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static bool _isNetworkFailure(DioException error) {
    if (error.type == DioExceptionType.cancel) return false;
    if (error.response == null) return true;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.badCertificate ||
      DioExceptionType.badResponse ||
      DioExceptionType.cancel ||
      DioExceptionType.unknown => false,
    };
  }
}
