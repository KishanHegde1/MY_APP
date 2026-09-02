import '../../domain/repositories/booking_repository.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  @override
  Future<BookingModel?> getBooking(String id) async {
    // TODO: Request the booking from the backend API.
    return null;
  }

  @override
  Future<List<BookingModel>> getBookings() async {
    // TODO: Request bookings from the backend API.
    return const <BookingModel>[];
  }
}
