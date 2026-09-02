import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/location_model.dart';
import '../../../payments/presentation/screens/payment_screen.dart';
import '../../domain/models/ride_booking_result.dart';
import '../../domain/models/ride_checkout_details.dart';
import '../../domain/models/ride_payment_method.dart';
import '../../domain/models/razorpay_checkout_order.dart';
import '../../domain/models/ride_route_plan.dart';

class RideConfirmationScreen extends StatelessWidget {
  const RideConfirmationScreen({
    required this.checkout,
    this.onBookRide,
    this.onBookingSaved,
    this.onCreateRazorpayOrder,
    this.onVerifyRazorpayPayment,
    this.onPaymentVerified,
    super.key,
  });

  final RideCheckoutDetails checkout;
  final Future<RideBookingResult> Function(
    RideCheckoutDetails checkout,
    RidePaymentMethod paymentMethod,
  )?
  onBookRide;
  final Future<void> Function(BuildContext context, RideBookingResult booking)?
  onBookingSaved;
  final Future<RazorpayCheckoutOrder> Function(String bookingId)?
  onCreateRazorpayOrder;
  final Future<RazorpayPaymentVerification> Function({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  })?
  onVerifyRazorpayPayment;
  final Future<void> Function(
    BuildContext context,
    RazorpayPaymentVerification payment,
  )?
  onPaymentVerified;

  Future<void> _continueToPayment(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentScreen(
          checkout: checkout,
          onBookRide: onBookRide,
          onBookingSaved: onBookingSaved,
          onCreateRazorpayOrder: onCreateRazorpayOrder,
          onVerifyRazorpayPayment: onVerifyRazorpayPayment,
          onPaymentVerified: onPaymentVerified,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fare = checkout.estimatedFare.round();

    return Scaffold(
      key: const Key('ride-confirmation-screen'),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(title: const Text('Confirm your ride')),
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
                  _ConfirmationHero(checkout: checkout),
                  const SizedBox(height: 18),
                  _SectionCard(
                    title: 'Your journey',
                    icon: Icons.route_rounded,
                    child: _JourneySummary(checkout: checkout),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Ride details',
                    icon: _vehicleIcon(checkout.vehicle),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Ride',
                          value: checkout.vehicleLabel,
                        ),
                        const SizedBox(height: 13),
                        _SummaryRow(
                          label: 'Selected route',
                          value: checkout.route.title,
                        ),
                        const SizedBox(height: 13),
                        _SummaryRow(
                          label: 'Distance',
                          value:
                              '${checkout.route.distanceKm.toStringAsFixed(1)} km',
                        ),
                        const SizedBox(height: 13),
                        _SummaryRow(
                          label: 'Estimated time',
                          value: '${checkout.route.durationMinutes} min',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(
                        alpha: isDark ? 0.17 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated fare',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                checkout.hasBackendFare
                                    ? 'Based on the selected road route'
                                    : 'Sample estimate for this preview',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Semantics(
                          label: '$fare rupees estimated fare',
                          child: Text(
                            '₹$fare',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PreviewNotice(sourceNotice: checkout.sourceNotice),
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
              child: FilledButton.icon(
                key: const Key('continue-to-payment-button'),
                onPressed: () => _continueToPayment(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text(
                  'Continue to payment',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _vehicleIcon(RideRouteVehicle vehicle) => switch (vehicle) {
    RideRouteVehicle.bike => Icons.two_wheeler_rounded,
    RideRouteVehicle.auto => Icons.electric_rickshaw_rounded,
    RideRouteVehicle.car => Icons.directions_car_filled_rounded,
  };
}

class _ConfirmationHero extends StatelessWidget {
  const _ConfirmationHero({required this.checkout});

  final RideCheckoutDetails checkout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary,
            Color.lerp(colors.primary, AppColors.secondary, 0.55)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              RideConfirmationScreen._vehicleIcon(checkout.vehicle),
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Does everything look right?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${checkout.vehicleLabel} • ${checkout.route.durationMinutes} min • ${checkout.route.distanceKm.toStringAsFixed(1)} km',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: colors.primary),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _JourneySummary extends StatelessWidget {
  const _JourneySummary({required this.checkout});

  final RideCheckoutDetails checkout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LocationLine(
          color: AppColors.success,
          label: 'PICKUP',
          value: _locationLabel(checkout.pickup),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 7),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 2,
              height: 22,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        _LocationLine(
          color: AppColors.error,
          label: 'DROP-OFF',
          value: _locationLabel(checkout.destination),
        ),
      ],
    );
  }

  static String _locationLabel(LocationModel location) {
    final label = location.label?.trim();
    return label != null && label.isNotEmpty
        ? label
        : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({required this.sourceNotice});

  final String sourceNotice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
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
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review preview',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No ride is booked yet. $sourceNotice',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
