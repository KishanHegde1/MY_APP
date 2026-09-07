import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dependency_injection/service_locator.dart';
import '../../../../core/services/location_service.dart';
import '../../../../routes/app_routes.dart';
import '../../data/driver_local_rides_api.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final DriverLocalRidesApi _api = DriverLocalRidesApi();
  final LocationService _locationService = sl.get<LocationService>();
  Timer? _tickTimer;
  List<DriverRideRequest> _requests = const [];
  DriverActiveRide? _activeRide;
  String? _error;
  bool _loading = true;
  bool _refreshing = false;
  bool _accepting = false;
  bool _sharing = false;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _onTick() async {
    _ticks += 1;
    if (_activeRide != null) {
      await _shareLiveLocation();
    }
    if (_ticks == 1 || _ticks % 8 == 0) {
      await _refresh(silent: true);
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final activeRide = await _api.activeRide();
      final requests = activeRide == null
          ? await _api.listRequests()
          : const <DriverRideRequest>[];
      if (!mounted) return;
      setState(() {
        _activeRide = activeRide;
        _requests = requests;
        _error = null;
        _loading = false;
      });
    } on DriverRidesException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _acceptRide(DriverRideRequest request) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    try {
      final activeRide = await _api.acceptRide(request.rideId);
      if (!mounted) return;
      setState(() {
        _activeRide = activeRide;
        _requests = const [];
        _error = null;
      });
      await _shareLiveLocation();
    } on DriverRidesException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _shareLiveLocation() async {
    final activeRide = _activeRide;
    if (activeRide == null || _sharing) return;
    _sharing = true;
    try {
      final result = await _locationService.requestCurrentLocation();
      final location = result.location;
      if (location == null) {
        if (mounted && _ticks % 12 == 1) {
          _showMessage(_locationMessage(result.issue));
        }
        return;
      }
      final updatedRide = await _api.updateLocation(
        rideId: activeRide.rideId,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (!mounted) return;
      setState(() {
        _activeRide = updatedRide;
        _error = null;
      });
    } on DriverRidesException catch (error) {
      if (mounted && _ticks % 12 == 1) _showMessage(error.message);
    } finally {
      _sharing = false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver workspace'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.localRides),
            tooltip: 'Book a ride',
            icon: const Icon(Icons.add_road_rounded),
          ),
          IconButton(onPressed: _refresh, tooltip: 'Refresh rides', icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _DriverHeader(isActive: _activeRide != null),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _DriverError(message: _error!, onRetry: _refresh),
                  ],
                  const SizedBox(height: 22),
                  if (_activeRide != null)
                    _ActiveRideCard(
                      ride: _activeRide!,
                      isSharing: _sharing,
                      onShareNow: _shareLiveLocation,
                    )
                  else ...[
                    Text('Nearby ride requests', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text('Accept one ride to start sharing your live foreground location.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 14),
                    if (_requests.isEmpty)
                      const _NoDriverRequests()
                    else
                      ..._requests.map(
                        (request) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _DriverRequestCard(
                            request: request,
                            accepting: _accepting,
                            onAccept: () => _acceptRide(request),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DriverHeader extends StatelessWidget {
  const _DriverHeader({required this.isActive});
  final bool isActive;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF14B8A6)]),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(17)),
          child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 29),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isActive ? 'You are on a ride' : 'You are ready for rides', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(isActive ? 'GPS sharing updates the customer every second.' : 'Incoming local rides appear below.', style: TextStyle(color: Colors.white.withValues(alpha: 0.88), height: 1.35)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActiveRideCard extends StatelessWidget {
  const _ActiveRideCard({required this.ride, required this.isSharing, required this.onShareNow});
  final DriverActiveRide ride;
  final bool isSharing;
  final VoidCallback onShareNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: const Color(0xFF14B8A6).withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.navigation_rounded, color: Color(0xFF0F766E)),
              const SizedBox(width: 9),
              Text('Active ${_vehicleName(ride.vehicleType)} ride', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 18),
            _Stop(label: 'Pickup', value: ride.pickupLabel, color: const Color(0xFF16A34A)),
            const SizedBox(height: 12),
            _Stop(label: 'Drop', value: ride.dropLabel, color: const Color(0xFFDC2626)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                SizedBox(width: 20, height: 20, child: isSharing ? const CircularProgressIndicator(strokeWidth: 2) : const Icon(Icons.my_location_rounded, color: Color(0xFF0F766E))),
                const SizedBox(width: 10),
                Expanded(child: Text(ride.locationSharedAt == null ? 'Getting your precise GPS location…' : 'Live location shared ${_age(ride.locationSharedAt!)}', style: const TextStyle(fontWeight: FontWeight.w700))),
              ]),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(onPressed: isSharing ? null : onShareNow, icon: const Icon(Icons.refresh_rounded), label: const Text('Share location now')),
          ],
        ),
      ),
    );
  }
}

class _DriverRequestCard extends StatelessWidget {
  const _DriverRequestCard({required this.request, required this.accepting, required this.onAccept});
  final DriverRideRequest request;
  final bool accepting;
  final VoidCallback onAccept;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(_vehicleIcon(request.vehicleType), color: const Color(0xFF2563EB)), const SizedBox(width: 8), Text('${_vehicleName(request.vehicleType)} · ${request.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.w900)), const Spacer(), Text('₹${request.estimatedFare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))]),
        const SizedBox(height: 14),
        _Stop(label: 'Pickup', value: request.pickupLabel, color: const Color(0xFF16A34A)),
        const SizedBox(height: 8),
        _Stop(label: 'Drop', value: request.dropLabel, color: const Color(0xFFDC2626)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: accepting ? null : onAccept, icon: accepting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline_rounded), label: const Text('Accept ride'))),
      ]),
    ),
  );
}

class _Stop extends StatelessWidget {
  const _Stop({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.circle, color: color, size: 15), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis)]))]);
}

class _NoDriverRequests extends StatelessWidget {
  const _NoDriverRequests();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Column(children: [Icon(Icons.hourglass_empty_rounded, size: 60, color: Color(0xFF94A3B8)), SizedBox(height: 14), Text('No nearby rides right now', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), SizedBox(height: 7), Text('Keep this page open. New local-ride requests refresh automatically.', textAlign: TextAlign.center)]));
}

class _DriverError extends StatelessWidget {
  const _DriverError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Driver access needs attention', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF9A3412))), const SizedBox(height: 5), Text(message), const SizedBox(height: 8), TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again'))]));
}

String _locationMessage(LocationAccessIssue? issue) => switch (issue) {
  LocationAccessIssue.serviceDisabled => 'Turn on device location to share your live position.',
  LocationAccessIssue.permissionDenied => 'Allow location permission to share your live position.',
  LocationAccessIssue.permissionPermanentlyDenied => 'Allow location permission in Settings to share your live position.',
  _ => 'Your precise location is not available right now.',
};

IconData _vehicleIcon(String vehicle) => switch (vehicle) {
  'BIKE' => Icons.two_wheeler_rounded,
  'AUTO' => Icons.electric_rickshaw_rounded,
  _ => Icons.directions_car_rounded,
};

String _vehicleName(String vehicle) => switch (vehicle) {
  'BIKE' => 'Bike',
  'AUTO' => 'Auto',
  _ => 'Car',
};

String _age(DateTime time) {
  final seconds = DateTime.now().difference(time).inSeconds;
  return seconds <= 2 ? 'just now' : '${seconds}s ago';
}
