import '../models/ride_booking_result.dart';
import '../models/ride_checkout_details.dart';
import '../models/ride_payment_method.dart';
import '../models/razorpay_checkout_order.dart';

abstract interface class RideBookingRepository {
  Future<RideBookingResult> createBooking({
    required RideCheckoutDetails checkout,
    required RidePaymentMethod paymentMethod,
  });

  Future<RazorpayCheckoutOrder> createRazorpayOrder({
    required String bookingId,
  });

  Future<RazorpayPaymentVerification> verifyRazorpayPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });
}
