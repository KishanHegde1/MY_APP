import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/features/bookings/data/models/booking_model.dart';
import 'package:my_app_flutter/features/bookings/domain/repositories/booking_repository.dart';
import 'package:my_app_flutter/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:my_app_flutter/shared/models/location_model.dart';

void main() {
  testWidgets('shows the customer saved ride and tracking hand-off state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyBookingsScreen(
          repository: _FakeBookingRepository(<BookingModel>[_booking]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('my-bookings-screen')), findsOneWidget);
    expect(find.byKey(const Key('booking-card-booking-001')), findsOneWidget);
    expect(find.text('Bike local ride'), findsOneWidget);
    expect(find.text('Honnāvar Bus Stand'), findsOneWidget);
    expect(find.text('Apsarakonda Beach'), findsOneWidget);
    expect(find.text('₹84'), findsOneWidget);
    expect(
      find.textContaining('Driver assignment and live tracking'),
      findsOneWidget,
    );
  });
}

const _booking = BookingModel(
  id: 'booking-001',
  rideId: 'ride-001',
  serviceType: 'LOCAL_BIKE_RIDE',
  status: BookingStatus.pending,
  createdAt: DateTime(2026, 9, 4, 10, 30),
  vehicleType: 'BIKE',
  pickup: LocationModel(
    latitude: 14.2802,
    longitude: 74.4439,
    label: 'Honnāvar Bus Stand',
  ),
  destination: LocationModel(
    latitude: 14.3043,
    longitude: 74.4301,
    label: 'Apsarakonda Beach',
  ),
  distanceKm: 4.2,
  durationMinutes: 15,
  estimatedFare: 84,
  currency: 'INR',
  paymentMethod: 'CASH',
  paymentStatus: null,
  trackingAvailable: false,
  trackingMessage:
      'Your ride request is saved. Driver assignment and live tracking will appear here once available.',
);

final class _FakeBookingRepository implements BookingRepository {
  const _FakeBookingRepository(this.bookings);

  final List<BookingModel> bookings;

  @override
  Future<BookingModel?> getBooking(String id) async {
    for (final booking in bookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  @override
  Future<List<BookingModel>> getBookings() async => bookings;
}
