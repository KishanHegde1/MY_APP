import '../../domain/repositories/room_repository.dart';
import '../models/room_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  const RoomRepositoryImpl();

  @override
  Future<List<RoomModel>> searchRooms({String? query}) async {
    // TODO: Search available rooms through the backend API.
    return const <RoomModel>[];
  }
}
