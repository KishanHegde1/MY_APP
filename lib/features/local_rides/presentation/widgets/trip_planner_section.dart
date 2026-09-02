import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/location_model.dart';
import '../../domain/models/map_trip_selection.dart';
import '../../domain/models/pickup_location_source.dart';
import '../../domain/models/ride_booking_result.dart';
import '../../domain/models/ride_checkout_details.dart';
import '../../domain/models/ride_payment_method.dart';
import '../../domain/models/razorpay_checkout_order.dart';
import '../../domain/models/ride_route_plan.dart';
import '../../domain/services/route_planning_service.dart';
import '../controllers/local_ride_controller.dart';
import '../screens/map_trip_planner_screen.dart';
import '../screens/ride_confirmation_screen.dart';

class TripPlannerSection extends StatefulWidget {
  const TripPlannerSection({
    required this.pickup,
    required this.locationStatus,
    required this.selectedVehicle,
    required this.routePlanningService,
    required this.pickupResolver,
    required this.onRequestPickup,
    required this.onPickupSelected,
    this.onBookRide,
    this.onBookingSaved,
    this.onCreateRazorpayOrder,
    this.onVerifyRazorpayPayment,
    this.onPaymentVerified,
    this.mapTripPlanner,
    this.enableGoogleMap = true,
    super.key,
  });

  final LocationModel? pickup;
  final RideLocationStatus locationStatus;
  final RideVehicleType? selectedVehicle;
  final RoutePlanningService routePlanningService;
  final DestinationResolver pickupResolver;
  final Future<void> Function() onRequestPickup;
  final Future<void> Function(
    LocationModel location,
    PickupLocationSource source,
  )
  onPickupSelected;
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
  final MapTripPlannerLauncher? mapTripPlanner;
  final bool enableGoogleMap;

  @override
  State<TripPlannerSection> createState() => _TripPlannerSectionState();
}

class _TripPlannerSectionState extends State<TripPlannerSection> {
  final TextEditingController _pickupController = TextEditingController();
  final FocusNode _pickupFocus = FocusNode();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destinationFocus = FocusNode();
  RideRoutePlan? _plan;
  String? _selectedRouteId;
  String? _error;
  bool _isPlanning = false;
  bool _isResolvingPickup = false;
  bool _pickupTextChanged = false;
  int _requestId = 0;
  int _pickupRequestId = 0;

  @override
  void initState() {
    super.initState();
    _writePickupLabel(widget.pickup);
  }

  RideRouteOption? get _selectedRoute {
    final plan = _plan;
    if (plan == null) return null;
    for (final route in plan.routes) {
      if (route.id == _selectedRouteId) return route;
    }
    return plan.routes.first;
  }

  @override
  void didUpdateWidget(covariant TripPlannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameLocation(oldWidget.pickup, widget.pickup) ||
        oldWidget.selectedVehicle != widget.selectedVehicle) {
      _plan = null;
      _selectedRouteId = null;
      _error = null;
      _requestId++;
    }
    if (!_sameLocation(oldWidget.pickup, widget.pickup)) {
      _writePickupLabel(widget.pickup);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _pickupFocus.dispose();
    _destinationController.dispose();
    _destinationFocus.dispose();
    super.dispose();
  }

  Future<void> _compareRoutes() async {
    FocusManager.instance.primaryFocus?.unfocus();
    var pickup = widget.pickup;
    final destination = _destinationController.text.trim();
    if (pickup == null || _pickupTextChanged) {
      pickup = await _confirmTypedPickup();
    }
    if (pickup == null) {
      if (mounted) {
        setState(
          () => _error =
              'Enter a pickup, use current GPS, or choose an exact map pin.',
        );
        _pickupFocus.requestFocus();
      }
      return;
    }
    if (widget.selectedVehicle == null) {
      setState(() => _error = 'Choose Bike, Auto, or Car to see route prices.');
      return;
    }
    if (destination.length < 3) {
      setState(() => _error = 'Enter an area, landmark, or destination.');
      _destinationFocus.requestFocus();
      return;
    }

    final requestId = ++_requestId;
    setState(() {
      _isPlanning = true;
      _error = null;
    });
    try {
      final plan = await widget.routePlanningService.planRoutes(
        pickup: pickup,
        destinationQuery: destination,
        vehicle: switch (widget.selectedVehicle!) {
          RideVehicleType.bike => RideRouteVehicle.bike,
          RideVehicleType.auto => RideRouteVehicle.auto,
          RideVehicleType.car => RideRouteVehicle.car,
        },
      );
      if (!mounted || requestId != _requestId) return;
      final recommended = plan.routes.where((route) => route.isRecommended);
      setState(() {
        _plan = plan;
        _selectedRouteId = recommended.isEmpty
            ? plan.routes.first.id
            : recommended.first.id;
        _isPlanning = false;
      });
    } on RoutePlanningException catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error.message;
        _isPlanning = false;
      });
    } on Object {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error =
            'Routes are unavailable right now. Check the destination and try again.';
        _isPlanning = false;
      });
    }
  }

  Future<LocationModel?> _confirmTypedPickup() async {
    final query = _pickupController.text.trim();
    if (query.length < 3) {
      setState(() => _error = 'Enter at least 3 characters for your pickup.');
      _pickupFocus.requestFocus();
      return null;
    }

    final requestId = ++_pickupRequestId;
    setState(() {
      _isResolvingPickup = true;
      _error = null;
    });
    try {
      final resolved = await widget.pickupResolver.resolve(
        query: query,
        near: widget.pickup,
      );
      if (!mounted || requestId != _pickupRequestId) return null;
      if (resolved == null) {
        setState(() {
          _isResolvingPickup = false;
          _error =
              'We could not find that pickup. Add the area, city, or landmark.';
        });
        return null;
      }
      await widget.onPickupSelected(resolved, PickupLocationSource.manual);
      if (!mounted) return resolved;
      _writePickupLabel(resolved);
      setState(() {
        _isResolvingPickup = false;
        _error = null;
      });
      return resolved;
    } on Object {
      if (!mounted || requestId != _pickupRequestId) return null;
      setState(() {
        _isResolvingPickup = false;
        _error = 'Pickup search is unavailable. Check the address and retry.';
      });
      return null;
    }
  }

  Future<void> _planTripOnMap() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final vehicle = widget.selectedVehicle;
    if (vehicle == null) {
      setState(
        () => _error = 'Choose Bike, Auto, or Car before planning on the map.',
      );
      return;
    }
    if (!widget.enableGoogleMap && widget.mapTripPlanner == null) {
      setState(() {
        _error =
            'Add the Android Maps API key before planning a trip on the map.';
      });
      return;
    }
    final selection = widget.mapTripPlanner == null
        ? await Navigator.of(context).push<MapTripSelection>(
            MaterialPageRoute<MapTripSelection>(
              fullscreenDialog: true,
              builder: (_) => MapTripPlannerScreen(
                initialPickup: widget.pickup,
                vehicle: _routeVehicle(vehicle),
                routePlanningService: widget.routePlanningService,
              ),
            ),
          )
        : await widget.mapTripPlanner!(
            context,
            widget.pickup,
            _routeVehicle(vehicle),
            widget.routePlanningService,
          );
    if (selection == null || !mounted) return;
    await widget.onPickupSelected(
      selection.plan.pickup,
      PickupLocationSource.mapPin,
    );
    if (!mounted) return;
    _writePickupLabel(selection.plan.pickup);
    final destinationLabel = selection.plan.destination.label?.trim();
    final destinationText = destinationLabel == null || destinationLabel.isEmpty
        ? '${selection.plan.destination.latitude.toStringAsFixed(6)}, ${selection.plan.destination.longitude.toStringAsFixed(6)}'
        : destinationLabel;
    _destinationController
      ..text = destinationText
      ..selection = TextSelection.collapsed(offset: destinationText.length);
    setState(() {
      _plan = selection.plan;
      _selectedRouteId = selection.selectedRoute.id;
      _pickupTextChanged = false;
      _error = null;
    });
  }

  Future<void> _useCurrentGps() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _pickupRequestId++;
    await widget.onRequestPickup();
  }

  void _writePickupLabel(LocationModel? location) {
    if (location == null) return;
    final label = location.label?.trim();
    final value = label != null && label.isNotEmpty
        ? label
        : '${location.latitude.toStringAsFixed(6)}, '
              '${location.longitude.toStringAsFixed(6)}';
    _pickupController
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    _pickupTextChanged = false;
  }

  void _useSuggestion(String suggestion) {
    _destinationController
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
    setState(() => _error = null);
  }

  void _selectRoute(RideRouteOption route) {
    setState(() => _selectedRouteId = route.id);
  }

  Future<void> _reviewRide() async {
    final plan = _plan;
    final route = _selectedRoute;
    final selectedVehicle = widget.selectedVehicle;
    if (plan == null || route == null || selectedVehicle == null) return;

    final checkout = RideCheckoutDetails(
      pickup: plan.pickup,
      destination: plan.destination,
      route: route,
      vehicle: _routeVehicle(selectedVehicle),
      planSource: plan.source,
      sourceNotice: plan.sourceNotice,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => RideConfirmationScreen(
          checkout: checkout,
          onBookRide: widget.onBookRide,
          onBookingSaved: widget.onBookingSaved,
          onCreateRazorpayOrder: widget.onCreateRazorpayOrder,
          onVerifyRazorpayPayment: widget.onVerifyRazorpayPayment,
          onPaymentVerified: widget.onPaymentVerified,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pickup = widget.pickup;
    final plan = _plan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlannerHeading(hasPlan: plan != null),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.75),
            ),
            boxShadow: theme.brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _JourneyFields(
                pickup: pickup,
                locationStatus: widget.locationStatus,
                pickupController: _pickupController,
                pickupFocus: _pickupFocus,
                destinationController: _destinationController,
                destinationFocus: _destinationFocus,
                isResolvingPickup: _isResolvingPickup,
                onPickupChanged: (_) {
                  _pickupRequestId++;
                  _pickupTextChanged = true;
                  if (_error != null) setState(() => _error = null);
                },
                onConfirmPickup: _confirmTypedPickup,
                onRequestPickup: _useCurrentGps,
                onPlanTripOnMap: _planTripOnMap,
                onSubmitted: (_) => unawaited(_compareRoutes()),
              ),
              const SizedBox(height: 16),
              Text(
                'Quick destinations',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final suggestion in const <String>[
                    'Airport',
                    'Railway station',
                    'City centre',
                  ])
                    ActionChip(
                      avatar: Icon(
                        _suggestionIcon(suggestion),
                        size: 17,
                        color: colors.primary,
                      ),
                      label: Text(suggestion),
                      onPressed: () => _useSuggestion(suggestion),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _InlineMessage(
                  icon: Icons.info_outline_rounded,
                  message: _error!,
                  color: AppColors.error,
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('compare-routes-button'),
                onPressed: _isPlanning ? null : _compareRoutes,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                icon: _isPlanning
                    ? const SizedBox.square(
                        dimension: 19,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Icon(Icons.route_rounded),
                label: Text(
                  _isPlanning
                      ? 'Finding route alternatives…'
                      : 'View routes & fares',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Fares come from the selected route. You can still pin start and '
                'drop on the map if you want an exact location.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          child: plan == null
              ? const _RoutesEmptyState(key: ValueKey('route-empty'))
              : _RouteResults(
                  key: ValueKey('${plan.source}-${plan.destination.latitude}'),
                  plan: plan,
                  selectedRoute: _selectedRoute!,
                  selectedVehicle: widget.selectedVehicle!,
                  onSelected: _selectRoute,
                ),
        ),
        if (plan != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('confirm-ride-button'),
            onPressed: _reviewRide,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text(
              'Review & confirm ride',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can review every detail before choosing a payment method.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _FutureTrackingPanel(route: _selectedRoute, planSource: plan?.source),
      ],
    );
  }

  static bool _sameLocation(LocationModel? first, LocationModel? second) =>
      first?.latitude == second?.latitude &&
      first?.longitude == second?.longitude;

  static IconData _suggestionIcon(String suggestion) => switch (suggestion) {
    'Airport' => Icons.flight_takeoff_rounded,
    'Railway station' => Icons.train_rounded,
    _ => Icons.location_city_rounded,
  };

  static RideRouteVehicle _routeVehicle(RideVehicleType vehicle) =>
      switch (vehicle) {
        RideVehicleType.bike => RideRouteVehicle.bike,
        RideVehicleType.auto => RideRouteVehicle.auto,
        RideVehicleType.car => RideRouteVehicle.car,
      };
}

class _PlannerHeading extends StatelessWidget {
  const _PlannerHeading({required this.hasPlan});

  final bool hasPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLAN YOUR TRIP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Where do you want to go?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Add your starting point and drop location, then compare the '
                'best routes and fares.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (hasPlan)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 16,
                ),
                SizedBox(width: 5),
                Text(
                  'ROUTES READY',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _JourneyFields extends StatelessWidget {
  const _JourneyFields({
    required this.pickup,
    required this.locationStatus,
    required this.pickupController,
    required this.pickupFocus,
    required this.destinationController,
    required this.destinationFocus,
    required this.isResolvingPickup,
    required this.onPickupChanged,
    required this.onConfirmPickup,
    required this.onRequestPickup,
    required this.onPlanTripOnMap,
    required this.onSubmitted,
  });

  final LocationModel? pickup;
  final RideLocationStatus locationStatus;
  final TextEditingController pickupController;
  final FocusNode pickupFocus;
  final TextEditingController destinationController;
  final FocusNode destinationFocus;
  final bool isResolvingPickup;
  final ValueChanged<String> onPickupChanged;
  final Future<LocationModel?> Function() onConfirmPickup;
  final Future<void> Function() onRequestPickup;
  final Future<void> Function() onPlanTripOnMap;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLocating = locationStatus == RideLocationStatus.locating;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _LocationInputShell(
            markerColor: AppColors.success,
            markerIcon: Icons.my_location_rounded,
            label: 'START',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('pickup-address-field'),
                        controller: pickupController,
                        focusNode: pickupFocus,
                        textInputAction: TextInputAction.search,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.fullStreetAddress],
                        onChanged: onPickupChanged,
                        onSubmitted: (_) => unawaited(onConfirmPickup()),
                        decoration: const InputDecoration(
                          hintText: 'Enter pickup area, landmark, or address',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      key: const Key('confirm-pickup-address'),
                      onPressed: isResolvingPickup
                          ? null
                          : () => unawaited(onConfirmPickup()),
                      tooltip: 'Confirm entered pickup',
                      icon: isResolvingPickup
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      key: const Key('pickup-use-gps'),
                      avatar: isLocating
                          ? const SizedBox.square(
                              dimension: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.gps_fixed_rounded,
                              size: 17,
                              color: colors.primary,
                            ),
                      label: Text(isLocating ? 'Locating…' : 'Use my location'),
                      onPressed: isLocating
                          ? null
                          : () => unawaited(onRequestPickup()),
                    ),
                    ActionChip(
                      key: const Key('pickup-pin-map'),
                      avatar: Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: colors.primary,
                      ),
                      label: const Text('Pin on map'),
                      onPressed: () => unawaited(onPlanTripOnMap()),
                    ),
                    if (pickup != null)
                      Chip(
                        avatar: const Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color: AppColors.success,
                        ),
                        label: const Text('Exact pickup set'),
                        side: BorderSide.none,
                        backgroundColor: AppColors.success.withValues(
                          alpha: 0.09,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Divider(height: 1, color: colors.outlineVariant),
          ),
          _LocationInputShell(
            markerColor: AppColors.error,
            markerIcon: Icons.location_on_rounded,
            label: 'DROP',
            child: TextField(
              key: const Key('destination-field'),
              controller: destinationController,
              focusNode: destinationFocus,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.fullStreetAddress],
              onSubmitted: onSubmitted,
              decoration: const InputDecoration(
                hintText: 'Area, landmark, or full address',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationInputShell extends StatelessWidget {
  const _LocationInputShell({
    required this.markerColor,
    required this.markerIcon,
    required this.label,
    required this.child,
  });

  final Color markerColor;
  final IconData markerIcon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: markerColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(markerIcon, color: markerColor, size: 20),
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
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutesEmptyState extends StatelessWidget {
  const _RoutesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.alt_route_rounded, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route choices will appear here',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'You’ll see every returned alternative with distance, time, and price.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
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

class _RouteResults extends StatelessWidget {
  const _RouteResults({
    required this.plan,
    required this.selectedRoute,
    required this.selectedVehicle,
    required this.onSelected,
    super.key,
  });

  final RideRoutePlan plan;
  final RideRouteOption selectedRoute;
  final RideVehicleType selectedVehicle;
  final ValueChanged<RideRouteOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return _RouteAlternatives(
      plan: plan,
      selectedRoute: selectedRoute,
      selectedVehicle: selectedVehicle,
      onSelected: onSelected,
    );
  }
}

class _RouteAlternatives extends StatelessWidget {
  const _RouteAlternatives({
    required this.plan,
    required this.selectedRoute,
    required this.selectedVehicle,
    required this.onSelected,
  });

  final RideRoutePlan plan;
  final RideRouteOption selectedRoute;
  final RideVehicleType selectedVehicle;
  final ValueChanged<RideRouteOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${plan.routes.length} route choices',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap one to select fare, time, and distance.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                selectedVehicle.name.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        for (final route in plan.routes) ...[
          _RouteChoiceCard(
            route: route,
            vehicle: selectedVehicle,
            source: plan.source,
            isSelected: route.id == selectedRoute.id,
            onTap: () => onSelected(route),
          ),
          if (route != plan.routes.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RouteChoiceCard extends StatelessWidget {
  const _RouteChoiceCard({
    required this.route,
    required this.vehicle,
    required this.source,
    required this.isSelected,
    required this.onTap,
  });

  final RideRouteOption route;
  final RideVehicleType vehicle;
  final RideRouteSource source;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = isSelected ? colors.primary : colors.onSurfaceVariant;
    final backendFare = route.fareFor(vehicle.name);
    final fare = calculateRideFare(route, switch (vehicle) {
      RideVehicleType.bike => RideRouteVehicle.bike,
      RideVehicleType.auto => RideRouteVehicle.auto,
      RideVehicleType.car => RideRouteVehicle.car,
    });
    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${route.title}, ${route.distanceKm.toStringAsFixed(1)} kilometres, '
          '${route.durationMinutes} minutes, ${fare.round()} rupees',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.16 : 0.07,
                )
              : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 1.7 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('route-choice-${route.id}'),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 21,
                        height: 21,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colors.primary
                              : Colors.transparent,
                          border: Border.all(color: accent, width: 2),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check_rounded,
                                color: colors.onPrimary,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          route.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (route.isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'BEST',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    route.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _RouteFact(
                        icon: Icons.straighten_rounded,
                        value: '${route.distanceKm.toStringAsFixed(1)} km',
                      ),
                      const SizedBox(width: 12),
                      _RouteFact(
                        icon: Icons.schedule_rounded,
                        value: '${route.durationMinutes} min',
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${fare.round()}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            source == RideRouteSource.googleRoutes &&
                                    backendFare != null
                                ? 'fare estimate'
                                : 'sample fare',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _RouteFact extends StatelessWidget {
  const _RouteFact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _FutureTrackingPanel extends StatelessWidget {
  const _FutureTrackingPanel({required this.route, required this.planSource});

  final RideRouteOption? route;
  final RideRouteSource? planSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.brightness == Brightness.dark
              ? const [Color(0xFF111E38), Color(0xFF152445)]
              : const [Color(0xFFF3F7FF), Color(0xFFEAF1FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.navigation_rounded, color: colors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Live trip safety panel',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PLANNED',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'After booking and driver GPS are connected, this will '
                      'verify progress and warn when the ride leaves your selected route.',
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
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = <Widget>[
                const _TrackingMetric(
                  icon: Icons.route_rounded,
                  label: 'DISTANCE COVERED',
                  value: '—',
                  supporting: 'Waiting for live GPS',
                ),
                _TrackingMetric(
                  icon: Icons.flag_rounded,
                  label: 'DISTANCE REMAINING',
                  value: route == null
                      ? '—'
                      : '${route!.distanceKm.toStringAsFixed(1)} km',
                  supporting: route == null
                      ? 'Choose a route first'
                      : 'Planned distance',
                ),
                const _TrackingMetric(
                  icon: Icons.shield_outlined,
                  label: 'ROUTE STATUS',
                  value: 'Not tracking',
                  supporting: 'Off-route alerts inactive',
                ),
              ];
              if (constraints.maxWidth >= 700) {
                return Row(
                  children: [
                    for (var index = 0; index < metrics.length; index++) ...[
                      Expanded(child: metrics[index]),
                      if (index < metrics.length - 1) const SizedBox(width: 10),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < metrics.length; index++) ...[
                    metrics[index],
                    if (index < metrics.length - 1) const SizedBox(height: 9),
                  ],
                ],
              );
            },
          ),
          if (route != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    planSource == RideRouteSource.googleRoutes
                        ? 'Selected road route saved for the future booking/tracking hand-off.'
                        : 'Fallback geometry is only a preview and will not be used for live safety checks.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingMetric extends StatelessWidget {
  const _TrackingMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.supporting,
  });

  final IconData icon;
  final String label;
  final String value;
  final String supporting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  supporting,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
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
