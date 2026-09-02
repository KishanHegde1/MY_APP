import '../../data/models/booking_model.dart';

abstract interface class BookingRepository {
  Future<List<BookingModel>> getBookings();

  Future<BookingModel?> getBooking(String id);
}
