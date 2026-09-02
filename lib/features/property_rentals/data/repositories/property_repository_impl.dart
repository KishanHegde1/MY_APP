import '../../domain/repositories/property_repository.dart';
import '../models/property_model.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  const PropertyRepositoryImpl();

  @override
  Future<List<PropertyModel>> searchProperties({
    String? query,
    String? type,
  }) async {
    // TODO: Search property listings through the backend API.
    return const <PropertyModel>[];
  }
}
