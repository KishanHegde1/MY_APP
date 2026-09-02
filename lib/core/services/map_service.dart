import '../../shared/models/location_model.dart';

abstract interface class MapService {
  Future<bool> openMap(LocationModel location, {String? label});
  Future<List<LocationModel>> route({
    required LocationModel origin,
    required LocationModel destination,
  });
}

final class PlaceholderMapService implements MapService {
  const PlaceholderMapService();

  @override
  Future<bool> openMap(LocationModel location, {String? label}) async => false;

  @override
  Future<List<LocationModel>> route({
    required LocationModel origin,
    required LocationModel destination,
  }) async => const <LocationModel>[];
}
