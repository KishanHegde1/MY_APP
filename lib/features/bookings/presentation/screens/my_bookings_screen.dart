import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../../config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/dependency_injection/service_locator.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../shared/models/location_model.dart';
import '../../data/models/booking_model.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/repositories/booking_repository.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({this.repository, super.key});

  final BookingRepository? repository;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late final BookingRepository _repository;
  List<BookingModel>? _bookings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? _createRepository();
    unawaited(_loadBookings());
  }

  BookingRepository _createRepository() {
    final config = sl.isRegistered<AppConfig>()
        ? sl.get<AppConfig>()
        : AppConfig.fromEnvironment();
    return BookingRepositoryImpl(
      config: config,
      accessTokenProvider: _backendToken,
    );
  }

  Future<String?> _backendToken() async {
    if (Firebase.apps.isNotEmpty) {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null && token.trim().isNotEmpty) return token;
    }
    if (!sl.isRegistered<SecureStorageService>()) return null;
    return sl.get<SecureStorageService>().read(StorageKeys.accessToken);
  }

  Future<void> _loadBookings() async {
    setState(() => _error = null);
    try {
      final bookings = await _repository.getBookings();
      if (!mounted) return;
      setState(() => _bookings = bookings);
    } on BookingRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _bookings = const <BookingModel>[];
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _bookings = const <BookingModel>[];
        _error = 'Your bookings could not be loaded. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _bookings;
    return Scaffold(
      key: const Key('my-bookings-screen'),
      appBar: AppBar(
        title: const Text('My bookings'),
        actions: [
          IconButton(
            key: const Key('refresh-bookings-button'),
            onPressed: _loadBookings,
            tooltip: 'Refresh bookings',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: bookings == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: _BookingsBody(bookings: bookings, error: _error, onRetry: _loadBookings),
            ),
    );
  }
}

class _BookingsBody extends StatelessWidget {
  const _BookingsBody({
    required this.bookings,
    required this.error,
    required this.onRetry,
  });

  final List<BookingModel> bookings;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _BookingsMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Bookings are unavailable',
            message: error!,
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        ],
      );
    }
    if (bookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _BookingsMessage(
            icon: Icons.receipt_long_outlined,
            title: 'No rides booked yet',
            message:
                'Your local ride bookings will appear here after you confirm a ride.',
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      itemCount: bookings.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) return _BookingsHeader(count: bookings.length);
        return _BookingCard(booking: bookings[index - 1]);
      },
    );
  }
}

class _BookingsHeader extends StatelessWidget {
  const _BookingsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 3, 4, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your ride activity',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count saved ${count == 1 ? 'ride' : 'rides'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = _statusPresentation(booking.status);

    return Container(
      key: Key('booking-card-${booking.id}'),
      padding: const EdgeInsets.all(16),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_vehicleIcon(booking.vehicleType), color: colors.primary),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_vehicleLabel(booking.vehicleType)} local ride',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dateLabel(booking.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(label: status.label, color: status.color),
            ],
          ),
          const SizedBox(height: 15),
          _RoutePoint(
            icon: Icons.trip_origin_rounded,
            color: AppColors.success,
            label: 'PICKUP',
            value: _locationLabel(booking.pickup),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9),
            child: Container(width: 2, height: 16, color: colors.outlineVariant),
          ),
          _RoutePoint(
            icon: Icons.location_on_rounded,
            color: AppColors.error,
            label: 'DROP',
            value: _locationLabel(booking.destination),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _BookingFact(icon: Icons.straighten_rounded, value: '${booking.distanceKm.toStringAsFixed(1)} km'),
                const SizedBox(width: 13),
                _BookingFact(icon: Icons.schedule_rounded, value: '${booking.durationMinutes} min'),
                const Spacer(),
                Text(
                  '₹${booking.estimatedFare.round()}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          _TrackingNotice(booking: booking),
        ],
      ),
    );
  }

  static IconData _vehicleIcon(String vehicle) => switch (vehicle.toUpperCase()) {
    'BIKE' => Icons.two_wheeler_rounded,
    'AUTO' => Icons.electric_rickshaw_rounded,
    _ => Icons.directions_car_filled_rounded,
  };

  static String _vehicleLabel(String vehicle) => switch (vehicle.toUpperCase()) {
    'AUTO' => 'Riksha',
    'BIKE' => 'Bike',
    'CAR' => 'Car',
    _ => 'Ride',
  };

  static String _locationLabel(LocationModel location) {
    final label = location.label?.trim();
    return label == null || label.isEmpty
        ? '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}'
        : label;
  }

  static String _dateLabel(DateTime date) {
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${date.day} ${months[date.month - 1]} ${date.year} • $hour:$minute $period';
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 20, child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w900)),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ],
  );
}

class _BookingFact extends StatelessWidget {
  const _BookingFact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 5),
      Text(value, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
    ],
  );
}

class _TrackingNotice extends StatelessWidget {
  const _TrackingNotice({required this.booking});

  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: booking.trackingAvailable
            ? AppColors.success.withValues(alpha: 0.1)
            : colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            booking.trackingAvailable
                ? Icons.location_searching_rounded
                : Icons.radar_outlined,
            color: booking.trackingAvailable ? AppColors.success : colors.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              booking.trackingMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );
}

class _BookingsMessage extends StatelessWidget {
  const _BookingsMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 105),
        child: Column(
          children: [
            Icon(icon, size: 56, color: colors.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => onAction!(),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

({String label, Color color}) _statusPresentation(BookingStatus status) =>
    switch (status) {
      BookingStatus.pending => (label: 'REQUESTED', color: AppColors.warning),
      BookingStatus.confirmed => (label: 'CONFIRMED', color: AppColors.success),
      BookingStatus.active => (label: 'ON THE WAY', color: AppColors.primary),
      BookingStatus.completed => (label: 'COMPLETED', color: AppColors.success),
      BookingStatus.cancelled => (label: 'CANCELLED', color: AppColors.error),
    };
