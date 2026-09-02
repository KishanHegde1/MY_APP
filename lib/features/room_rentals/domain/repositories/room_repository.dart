import '../../data/models/room_model.dart';

abstract interface class RoomRepository {
  Future<List<RoomModel>> searchRooms({String? query});
}
