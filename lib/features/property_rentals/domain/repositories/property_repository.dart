import '../../data/models/property_model.dart';

abstract interface class PropertyRepository {
  Future<List<PropertyModel>> searchProperties({String? query, String? type});
}
