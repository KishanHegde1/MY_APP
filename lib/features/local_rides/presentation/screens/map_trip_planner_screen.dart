import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/location_model.dart';
import '../../domain/models/map_trip_selection.dart';
import '../../domain/models/ride_checkout_details.dart';
import '../../domain/models/ride_route_plan.dart';
import '../../domain/services/route_planning_service.dart';

typedef MapTripPlannerLauncher = Future<MapTripSelection?> Function(
  BuildContext context,
  LocationModel? initialPickup,
  RideRouteVehicle vehicle,
  RoutePlanningService routePlanningService,
);

enum _MapTripStep { pickup, destination, directions }

/// Selects both trip points using fixed map pins, displays route alternatives,
/// then returns only when the user explicitly confirms a route.
class MapTripPlannerScreen extends StatefulWidget {
  const MapTripPlannerScreen({
    required this.routePlanningService,
    required this.vehicle,
    this.initialPickup,
    super.key,
  });

  final RoutePlanningService routePlanningService;
  final RideRouteVehicle vehicle;
  final LocationModel? initialPickup;

  @override
  State<MapTripPlannerScreen> createState() => _MapTripPlannerScreenState();
}

class _MapTripPlannerScreenState extends State<MapTripPlannerScreen> {
  static const LatLng _indiaFallback = LatLng(20.5937, 78.9629);
  static const Duration _reverseGeocodeTimeout = Duration(seconds: 6);

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  late final CameraPosition _initialCamera;
  late LocationModel _candidate;
  late bool _hasCandidate;
  _MapTripStep _step = _MapTripStep.pickup;
  LocationModel? _pickup;
  LocationModel? _destination;
  RideRoutePlan? _plan;
  String? _selectedRouteId;
  String? _error;
  bool _cameraMoving = false;
  bool _resolvingAddress = false;
  bool _planningDirections = false;
  int _addressRequestId = 0;

  RideRouteOption? get _selectedRoute {
    final plan = _plan;
    if (plan == null) return null;
    return plan.routes
            .where((route) => route.id == _selectedRouteId)
            .firstOrNull ??
        plan.routes.first;
  }

  @override
  void initState() {
    super.initState();
    _pickup = widget.initialPickup;
    _step = _pickup == null ? _MapTripStep.pickup : _MapTripStep.destination;
    final initial = _pickup;
    final coordinate = initial == null
        ? _indiaFallback
        : LatLng(initial.latitude, initial.longitude);
    _initialCamera = CameraPosition(
      target: coordinate,
      zoom: initial == null ? 4.8 : 16,
    );
    _candidate = initial ?? _locationFrom(coordinate);
    _hasCandidate = initial != null;
  }

  @override
  void dispose() {
    _addressRequestId++;
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) _mapController.complete(controller);
  }

  void _onCameraMove(CameraPosition position) {
    if (_step == _MapTripStep.directions) return;
    _addressRequestId++;
    _cameraMoving = true;
    _hasCandidate = true;
    _candidate = _locationFrom(position.target);
    if (mounted && _resolvingAddress) {
      setState(() => _resolvingAddress = false);
    }
  }

  void _onCameraIdle() {
    if (_step == _MapTripStep.directions || !_hasCandidate) return;
    _cameraMoving = false;
    unawaited(_resolveCandidateAddress());
  }

  Future<void> _resolveCandidateAddress() async {
    final candidate = _candidate;
    final requestId = ++_addressRequestId;
    setState(() => _resolvingAddress = true);
    String? label;
    try {
      label = await _reverseGeocode(candidate).timeout(_reverseGeocodeTimeout);
    } on Exception {
      // Exact coordinates remain a safe fallback when geocoding is unavailable.
    }
    if (!mounted || requestId != _addressRequestId) return;
    final normalized = label?.trim();
    setState(() {
      _candidate = LocationModel(
        latitude: candidate.latitude,
        longitude: candidate.longitude,
        label: normalized == null || normalized.isEmpty
            ? _coordinateLabel(candidate)
            : normalized,
      );
      _resolvingAddress = false;
    });
  }

  Future<void> _setPinOrPlan() async {
    if (!_hasCandidate || _cameraMoving || _resolvingAddress) return;
    switch (_step) {
      case _MapTripStep.pickup:
        setState(() {
          _pickup = _candidate;
          _step = _MapTripStep.destination;
          _hasCandidate = false;
          _error = null;
        });
      case _MapTripStep.destination:
        setState(() {
          _destination = _candidate;
          _error = null;
        });
        await _showDirections();
      case _MapTripStep.directions:
        final plan = _plan;
        final route = _selectedRoute;
        if (plan == null || route == null) return;
        Navigator.of(
          context,
        ).pop(MapTripSelection(plan: plan, selectedRoute: route));
    }
  }

  Future<void> _showDirections() async {
    final pickup = _pickup;
    final destination = _destination;
    if (pickup == null || destination == null) return;
    setState(() {
      _planningDirections = true;
      _error = null;
    });
    try {
      final rawPlan = await widget.routePlanningService.planRoutes(
        pickup: pickup,
        destinationQuery:
            '${destination.latitude.toStringAsFixed(7)},${destination.longitude.toStringAsFixed(7)}',
        vehicle: widget.vehicle,
      );
      if (!mounted) return;
      final plan = RideRoutePlan(
        pickup: pickup,
        destination: destination,
        routes: rawPlan.routes,
        source: rawPlan.source,
        sourceNotice: rawPlan.sourceNotice,
      );
      final recommended = plan.routes.where((route) => route.isRecommended);
      setState(() {
        _plan = plan;
        _selectedRouteId = recommended.isEmpty
            ? plan.routes.first.id
            : recommended.first.id;
        _step = _MapTripStep.directions;
        _planningDirections = false;
      });
      await _fitRoute(plan.routes);
    } on RoutePlanningException catch (error) {
      if (!mounted) return;
      setState(() {
        _planningDirections = false;
        _error = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _planningDirections = false;
        _error =
            'Directions are unavailable right now. Move the destination and try again.';
      });
    }
  }

  Future<void> _fitRoute(List<RideRouteOption> routes) async {
    final points = routes.expand((route) => route.points).toList();
    if (points.isEmpty) return;
    final controller = await _mapController.future;
    var south = points.first.latitude;
    var north = south;
    var west = points.first.longitude;
    var east = west;
    for (final point in points.skip(1)) {
      south = point.latitude < south ? point.latitude : south;
      north = point.latitude > north ? point.latitude : north;
      west = point.longitude < west ? point.longitude : west;
      east = point.longitude > east ? point.longitude : east;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        56,
      ),
    );
  }

  void _edit(_MapTripStep step) {
    final current = step == _MapTripStep.pickup ? _pickup : _destination;
    setState(() {
      _step = step;
      _plan = null;
      _selectedRouteId = null;
      _candidate = current ?? _candidate;
      _hasCandidate = current != null;
      _error = null;
    });
  }

  Set<Marker> get _markers => <Marker>{
    if (_pickup != null)
      Marker(
        markerId: const MarkerId('map-trip-pickup'),
        position: LatLng(_pickup!.latitude, _pickup!.longitude),
        infoWindow: const InfoWindow(title: 'Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    if (_destination != null)
      Marker(
        markerId: const MarkerId('map-trip-destination'),
        position: LatLng(_destination!.latitude, _destination!.longitude),
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
  };

  Set<Polyline> get _polylines {
    final plan = _plan;
    if (plan == null) return const <Polyline>{};
    const colors = <Color>[
      AppColors.primary,
      AppColors.secondary,
      AppColors.warning,
    ];
    return <Polyline>{
      for (var index = 0; index < plan.routes.length; index++)
        Polyline(
          polylineId: PolylineId(plan.routes[index].id),
          points: plan.routes[index].points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          color: plan.routes[index].id == _selectedRouteId
              ? colors[index % colors.length]
              : colors[index % colors.length].withValues(alpha: 0.32),
          width: plan.routes[index].id == _selectedRouteId ? 7 : 4,
          zIndex: plan.routes[index].id == _selectedRouteId ? 2 : 1,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final route = _selectedRoute;
    final pinning = _step != _MapTripStep.directions;

    return Scaffold(
      key: const Key('map-trip-planner-screen'),
      appBar: AppBar(
        title: const Text('Plan ride on map'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            key: const Key('map-trip-planner-google-map'),
            initialCameraPosition: _initialCamera,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (pinning)
            const IgnorePointer(child: Center(child: _TripCenterPin())),
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: _StepCard(
              step: _step,
              pickup: _pickup,
              destination: _destination,
              onEditPickup: _pickup == null
                  ? null
                  : () => _edit(_MapTripStep.pickup),
              onEditDestination: _destination == null
                  ? null
                  : () => _edit(_MapTripStep.destination),
            ),
          ),
          if (route != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 248,
              child: _DirectionsCard(
                plan: _plan!,
                selectedRoute: route,
                vehicle: widget.vehicle,
                onSelected: (selected) =>
                    setState(() => _selectedRouteId = selected.id),
              ),
            ),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: route == null ? 220 : 430,
              child: _ErrorCard(message: _error!),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: colors.surface,
              elevation: 16,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _bottomDescription(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 11),
                      FilledButton.icon(
                        key: const Key('map-trip-confirm-button'),
                        onPressed:
                            _hasCandidate &&
                                !_cameraMoving &&
                                !_resolvingAddress &&
                                !_planningDirections
                            ? _setPinOrPlan
                            : _step == _MapTripStep.directions &&
                                  route != null &&
                                  !_planningDirections
                            ? _setPinOrPlan
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        icon: _planningDirections
                            ? const SizedBox.square(
                                dimension: 19,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Icon(_buttonIcon()),
                        label: Text(
                          _buttonLabel(),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _bottomDescription() => switch (_step) {
    _MapTripStep.pickup =>
      _resolvingAddress
          ? 'Finding the pickup address…'
          : 'Move the map so the pin marks your exact pickup.',
    _MapTripStep.destination =>
      _resolvingAddress
          ? 'Finding the destination address…'
          : 'Move the map so the pin marks your destination.',
    _MapTripStep.directions =>
      _plan?.source == RideRouteSource.googleRoutes
          ? 'Route directions are ready. Choose one, then confirm.'
          : 'Estimated route preview only. Google road directions are unavailable.',
  };

  String _buttonLabel() => switch (_step) {
    _MapTripStep.pickup => 'Set pickup pin',
    _MapTripStep.destination =>
      _planningDirections
          ? 'Finding directions…'
          : 'Set destination pin & show route',
    _MapTripStep.directions => 'Confirm map route',
  };

  IconData _buttonIcon() => switch (_step) {
    _MapTripStep.pickup => Icons.my_location_rounded,
    _MapTripStep.destination => Icons.alt_route_rounded,
    _MapTripStep.directions => Icons.check_circle_outline_rounded,
  };

  static LocationModel _locationFrom(LatLng point) => LocationModel(
    latitude: point.latitude,
    longitude: point.longitude,
    label:
        '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
  );

  static String _coordinateLabel(LocationModel location) =>
      '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';

  static Future<String?> _reverseGeocode(LocationModel location) async {
    final placemarks = await Geocoding().placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    if (placemarks.isEmpty) return null;
    final place = placemarks.first;
    final parts = <String>[];
    for (final value in <String?>[
      place.name,
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ]) {
      final normalized = value?.trim();
      if (normalized != null &&
          normalized.isNotEmpty &&
          !parts.contains(normalized)) {
        parts.add(normalized);
      }
    }
    return parts.isEmpty ? null : parts.join(', ');
  }
}

class _TripCenterPin extends StatelessWidget {
  const _TripCenterPin();

  @override
  Widget build(BuildContext context) {
    final pickup =
        context.findAncestorStateOfType<_MapTripPlannerScreenState>()?._step ==
        _MapTripStep.pickup;
    final color = pickup ? AppColors.success : AppColors.error;
    return Transform.translate(
      offset: const Offset(0, -25),
      child: Icon(Icons.location_on_rounded, color: color, size: 58),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.pickup,
    required this.destination,
    this.onEditPickup,
    this.onEditDestination,
  });

  final _MapTripStep step;
  final LocationModel? pickup;
  final LocationModel? destination;
  final VoidCallback? onEditPickup;
  final VoidCallback? onEditDestination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(20),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PointRow(
              color: AppColors.success,
              icon: Icons.trip_origin_rounded,
              label: 'FROM',
              value: pickup == null
                  ? step == _MapTripStep.pickup
                        ? 'Move map and set your pickup pin'
                        : 'Pickup pin needed'
                  : _label(pickup!),
              onEdit: onEditPickup,
            ),
            const SizedBox(height: 8),
            _PointRow(
              color: AppColors.error,
              icon: Icons.location_on_rounded,
              label: 'TO',
              value: destination == null
                  ? step == _MapTripStep.destination
                        ? 'Move map and set your destination pin'
                        : 'Destination pin needed'
                  : _label(destination!),
              onEdit: onEditDestination,
            ),
          ],
        ),
      ),
    );
  }

  static String _label(LocationModel location) {
    final label = location.label?.trim();
    return label == null || label.isEmpty
        ? '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}'
        : label;
  }
}

class _PointRow extends StatelessWidget {
  const _PointRow({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      if (onEdit != null)
        IconButton(
          onPressed: onEdit,
          tooltip: 'Change $label pin',
          icon: const Icon(Icons.edit_location_alt_outlined, size: 19),
        ),
    ],
  );
}

class _DirectionsCard extends StatelessWidget {
  const _DirectionsCard({
    required this.plan,
    required this.selectedRoute,
    required this.vehicle,
    required this.onSelected,
  });

  final RideRoutePlan plan;
  final RideRouteOption selectedRoute;
  final RideRouteVehicle vehicle;
  final ValueChanged<RideRouteOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 7,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${selectedRoute.distanceKm.toStringAsFixed(1)} km • ${selectedRoute.durationMinutes} min • ₹${calculateRideFare(selectedRoute, vehicle).round()}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final route in plan.routes) ...[
                    ChoiceChip(
                      label: Text(route.title),
                      selected: route.id == selectedRoute.id,
                      onSelected: (_) => onSelected(route),
                    ),
                    if (route != plan.routes.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.error,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
