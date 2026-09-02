import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../local_rides/domain/models/ride_booking_result.dart';
import '../../../local_rides/domain/models/ride_checkout_details.dart';
import '../../../local_rides/domain/models/ride_payment_method.dart';
import '../../../local_rides/domain/models/razorpay_checkout_order.dart';
import 'payment_failed_screen.dart';

typedef RazorpayOrderCreator = Future<RazorpayCheckoutOrder> Function(
  String bookingId,
);
typedef RazorpayPaymentVerifier = Future<RazorpayPaymentVerification> Function({
  required String bookingId,
  required String razorpayOrderId,
  required String razorpayPaymentId,
  required String razorpaySignature,
});
typedef RazorpayPaymentSuccessHandler = Future<void> Function(
  BuildContext context,
  RazorpayPaymentVerification payment,
);

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    this.bookingId,
    this.checkout,
    this.onBookRide,
    this.onBookingSaved,
    this.onCreateRazorpayOrder,
    this.onVerifyRazorpayPayment,
    this.onPaymentVerified,
    super.key,
  });

  final String? bookingId;
  final RideCheckoutDetails? checkout;
  final Future<RideBookingResult> Function(
    RideCheckoutDetails checkout,
    RidePaymentMethod paymentMethod,
  )?
  onBookRide;
  final Future<void> Function(BuildContext context, RideBookingResult booking)?
  onBookingSaved;
  final RazorpayOrderCreator? onCreateRazorpayOrder;
  final RazorpayPaymentVerifier? onVerifyRazorpayPayment;
  final RazorpayPaymentSuccessHandler? onPaymentVerified;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  RidePaymentMethod _selectedMethod = RidePaymentMethod.upi;
  bool _isBooking = false;
  late final Razorpay _razorpay;
  RazorpayCheckoutOrder? _activeRazorpayOrder;
  RideBookingResult? _pendingOnlineBooking;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _showIntegrationPending() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Payment gateway is not connected yet. No payment was made and no ride was booked.',
          ),
        ),
      );
  }

  Future<void> _confirmPaymentChoice() async {
    final checkout = widget.checkout;
    final bookRide = widget.onBookRide;
    if (checkout == null || bookRide == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Cash booking is not connected yet. No ride was booked.',
            ),
          ),
        );
      return;
    }
    if (_selectedMethod != RidePaymentMethod.cash &&
        (widget.onCreateRazorpayOrder == null ||
            widget.onVerifyRazorpayPayment == null)) {
      _showIntegrationPending();
      return;
    }
    setState(() => _isBooking = true);
    try {
      final booking = _selectedMethod == RidePaymentMethod.cash
          ? await bookRide(checkout, _selectedMethod)
          : _pendingOnlineBooking ??
                await bookRide(checkout, _selectedMethod);
      if (!mounted) return;
      if (_selectedMethod != RidePaymentMethod.cash) {
        _pendingOnlineBooking = booking;
        final order = await widget.onCreateRazorpayOrder!(booking.bookingId);
        if (!mounted) return;
        _activeRazorpayOrder = order;
        _razorpay.open(<String, Object>{
          'key': order.keyId,
          'amount': order.amountInPaise,
          'currency': order.currency,
          'name': 'Multi Service',
          'description': 'Local ride booking',
          'order_id': order.razorpayOrderId,
          'retry': <String, Object>{'enabled': true, 'max_count': 2},
          'theme': <String, String>{'color': '#2563EB'},
        });
        return;
      }
      final onBookingSaved = widget.onBookingSaved;
      if (onBookingSaved != null) {
        await onBookingSaved(context, booking);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request saved.')),
        );
      }
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    final order = _activeRazorpayOrder;
    final verify = widget.onVerifyRazorpayPayment;
    if (order == null || verify == null || response.paymentId == null || response.signature == null) {
      _showRazorpayMessage('Payment verification details were incomplete.');
      return;
    }
    setState(() => _isBooking = true);
    try {
      final payment = await verify(
        bookingId: order.bookingId,
        razorpayOrderId: response.orderId ?? order.razorpayOrderId,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );
      if (!mounted) return;
      _pendingOnlineBooking = null;
      _activeRazorpayOrder = null;
      final onPaymentVerified = widget.onPaymentVerified;
      if (onPaymentVerified != null) {
        await onPaymentVerified(context, payment);
      } else if (mounted) {
        _showRazorpayMessage('Payment verified. Your ride is confirmed.');
      }
    } on Object catch (error) {
      if (mounted) {
        _showRazorpayMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    _activeRazorpayOrder = null;
    final message = response.message?.trim().isNotEmpty == true
        ? 'Payment was not completed: ${response.message}'
        : 'Payment was cancelled or could not be completed.';
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentFailedScreen(message: message),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showRazorpayMessage('Continue payment in ${response.walletName ?? 'your wallet'}.');
  }

  void _showRazorpayMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final checkout = widget.checkout;

    return Scaffold(
      key: const Key('ride-payment-screen'),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Choose payment')),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AmountCard(checkout: checkout),
                  const SizedBox(height: 22),
                  Text(
                    'PAYMENT METHOD',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'How would you like to pay?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _PaymentMethodTile(
                    key: const Key('payment-method-upi'),
                    icon: Icons.account_balance_rounded,
                    title: 'UPI',
                    subtitle: 'Google Pay, PhonePe or any UPI app',
                    badge: 'Razorpay checkout',
                    selected: _selectedMethod == RidePaymentMethod.upi,
                    onTap: () =>
                        setState(() => _selectedMethod = RidePaymentMethod.upi),
                  ),
                  const SizedBox(height: 11),
                  _PaymentMethodTile(
                    key: const Key('payment-method-card'),
                    icon: Icons.credit_card_rounded,
                    title: 'Credit or debit card',
                    subtitle: 'Visa, Mastercard and RuPay',
                    badge: 'Razorpay checkout',
                    selected: _selectedMethod == RidePaymentMethod.card,
                    onTap: () => setState(
                      () => _selectedMethod = RidePaymentMethod.card,
                    ),
                  ),
                  const SizedBox(height: 11),
                  _PaymentMethodTile(
                    key: const Key('payment-method-cash'),
                    icon: Icons.payments_outlined,
                    title: 'Cash',
                    subtitle: 'Pay the driver after your ride',
                    badge: 'Pay after ride',
                    selected: _selectedMethod == RidePaymentMethod.cash,
                    onTap: () => setState(
                      () => _selectedMethod = RidePaymentMethod.cash,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SecurityNotice(
                    message: checkout == null
                        ? 'Payment providers are not connected yet. This screen '
                              'does not collect or store payment information.'
                        : _selectedMethod == RidePaymentMethod.cash
                        ? 'Cash payment is collected only after your ride. This saves '
                              'a pending ride request and does not charge you now.'
                        : 'Razorpay opens a secure checkout. The app verifies the '
                              'payment on the backend before confirming your ride.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.outlineVariant)),
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    key: const Key('pay-and-confirm-button'),
                    onPressed: _isBooking ? null : _confirmPaymentChoice,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _isBooking
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _selectedMethod == RidePaymentMethod.cash
                                ? Icons.event_available_rounded
                                : Icons.lock_outline_rounded,
                          ),
                    label: Text(
                      _isBooking
                          ? 'Saving your ride…'
                          : _selectedMethod == RidePaymentMethod.cash
                          ? 'Book cash ride'
                          : 'Pay securely with Razorpay',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedMethod == RidePaymentMethod.cash
                        ? 'No payment is taken now. Pay the driver after the ride.'
                        : 'Razorpay checkout. Your payment is verified by the backend.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.checkout});

  final RideCheckoutDetails? checkout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fare = checkout?.estimatedFare.round();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: colors.primary,
              size: 25,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Estimated ride total',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fare == null ? 'Not calculated' : '₹$fare',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          if (checkout != null) ...[
            const SizedBox(height: 8),
            Text(
              '${checkout!.vehicleLabel} • ${checkout!.route.title} • '
              '${checkout!.route.distanceKm.toStringAsFixed(1)} km',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle, $badge',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.16 : 0.07,
                )
              : colors.surface,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(21),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: colors.primary),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          badge.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? colors.primary : colors.outline,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            color: colors.onPrimary,
                            size: 15,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.warning, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
