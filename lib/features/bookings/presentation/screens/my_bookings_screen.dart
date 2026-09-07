import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../data/repositories/customer_local_ride_bookings_api.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final CustomerLocalRideBookingsApi _api = CustomerLocalRideBookingsApi();
  Timer? _refreshTimer;
  List<CustomerLocalRideBooking> _bookings = const [];
  String? _error;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _loadBookings(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookings({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final bookings = await _api.listBookings();
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _error = null;
        _loading = false;
      });
    } on CustomerBookingsException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My bookings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _bookings.isEmpty
          ? _BookingLoadError(message: _error!, onRetry: _loadBookings)
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  Text(
                    'Your local rides',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Live driver updates refresh automatically while this screen is open.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _InlineWarning(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  if (_bookings.isEmpty)
                    const _NoBookings()
                  else
                    ..._bookings.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _BookingCard(booking: booking),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final CustomerLocalRideBooking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final live = booking.driver?.location;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _vehicleColor(booking.vehicleType).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(_vehicleIcon(booking.vehicleType), color: _vehicleColor(booking.vehicleType)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_vehicleName(booking.vehicleType)} ride',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${booking.distanceKm.toStringAsFixed(1)} km · ₹${booking.estimatedFare.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _StatusPill(status: booking.status, isLive: booking.trackingAvailable),
              ],
            ),
            const SizedBox(height: 18),
            _PlaceRow(icon: Icons.radio_button_checked_rounded, color: const Color(0xFF16A34A), label: booking.pickupLabel),
            const SizedBox(height: 10),
            _PlaceRow(icon: Icons.location_on_rounded, color: const Color(0xFFDC2626), label: booking.dropLabel),
            const SizedBox(height: 18),
            if (live != null) ...[
              _LiveTrackingPanel(booking: booking),
              const SizedBox(height: 14),
            ] else
              _TrackingMessage(message: booking.trackingMessage),
          ],
        ),
      ),
    );
  }
}

class _LiveTrackingPanel extends StatelessWidget {
  const _LiveTrackingPanel({required this.booking});
  final CustomerLocalRideBooking booking;

  @override
  Widget build(BuildContext context) {
    final location = booking.driver!.location!;
    final theme = Theme.of(context);
    final eta = booking.driver!.estimatedArrivalMinutes;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 178,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: 14.2,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('driver'),
                  position: LatLng(location.latitude, location.longitude),
                  infoWindow: const InfoWindow(title: 'Your driver'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: LatLng(booking.pickupLatitude, booking.pickupLongitude),
                  infoWindow: const InfoWindow(title: 'Pickup'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
              },
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              liteModeEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.near_me_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Driver is on the way', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(
                        eta == null ? 'Updating arrival time…' : 'Estimated arrival in $eta min',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  _lastUpdated(location.updatedAt),
                  style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF2563EB), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMessage extends StatelessWidget {
  const _TrackingMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 10),
      Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis)),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.isLive});
  final String status;
  final bool isLive;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: (isLive ? const Color(0xFF16A34A) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      isLive ? 'LIVE' : status,
      style: TextStyle(color: isLive ? const Color(0xFF15803D) : const Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w900),
    ),
  );
}

class _NoBookings extends StatelessWidget {
  const _NoBookings();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 86),
    child: Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFF94A3B8)),
        SizedBox(height: 16),
        Text('No local rides yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        SizedBox(height: 8),
        Text('When you confirm a ride, its driver and live-trip updates will appear here.', textAlign: TextAlign.center),
      ],
    ),
  );
}

class _BookingLoadError extends StatelessWidget {
  const _BookingLoadError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 62, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text('Bookings are unavailable', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [const Icon(Icons.wifi_off_rounded, color: Color(0xFFC2410C)), const SizedBox(width: 9), Expanded(child: Text(message))]),
  );
}

IconData _vehicleIcon(String vehicle) => switch (vehicle) {
  'BIKE' => Icons.two_wheeler_rounded,
  'AUTO' => Icons.electric_rickshaw_rounded,
  _ => Icons.directions_car_rounded,
};

Color _vehicleColor(String vehicle) => switch (vehicle) {
  'BIKE' => const Color(0xFF2563EB),
  'AUTO' => const Color(0xFF0F766E),
  _ => const Color(0xFFF59E0B),
};

String _vehicleName(String vehicle) => switch (vehicle) {
  'BIKE' => 'Bike',
  'AUTO' => 'Auto',
  _ => 'Car',
};

String _lastUpdated(DateTime updatedAt) {
  final seconds = DateTime.now().difference(updatedAt).inSeconds;
  return seconds <= 2 ? 'LIVE' : '${seconds}s ago';
}
