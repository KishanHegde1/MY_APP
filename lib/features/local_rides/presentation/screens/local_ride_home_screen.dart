import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/dependency_injection/service_locator.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../shared/models/location_model.dart';
import '../../data/repositories/backend_pickup_location_repository.dart';
import '../../data/repositories/backend_ride_booking_repository.dart';
import '../../data/services/backend_destination_resolver.dart';
import '../../data/services/backend_route_planning_service.dart';
import '../../data/services/estimated_route_planning_service.dart';
import '../../domain/services/route_planning_service.dart';
import '../../domain/models/pickup_location_source.dart';
import '../../domain/models/ride_booking_result.dart';
import '../../domain/models/ride_checkout_details.dart';
import '../../domain/models/ride_payment_method.dart';
import '../../domain/models/razorpay_checkout_order.dart';
import '../../domain/repositories/pickup_location_repository.dart';
import '../../domain/repositories/ride_booking_repository.dart';
import '../controllers/local_ride_controller.dart';
import 'ride_request_saved_screen.dart';
import 'map_trip_planner_screen.dart';
import '../../../payments/presentation/screens/payment_success_screen.dart';
import '../widgets/ride_option_card.dart';
import '../widgets/trip_planner_section.dart';

class LocalRideHomeScreen extends StatefulWidget {
  const LocalRideHomeScreen({
    this.locationService,
    this.routePlanningService,
    this.pickupResolver,
    this.pickupLocationRepository,
    this.rideBookingRepository,
    this.mapTripPlanner,
    this.enableGoogleMap,
    super.key,
  });

  final LocationService? locationService;
  final RoutePlanningService? routePlanningService;
  final DestinationResolver? pickupResolver;
  final PickupLocationRepository? pickupLocationRepository;
  final RideBookingRepository? rideBookingRepository;
  final MapTripPlannerLauncher? mapTripPlanner;

  /// Overrides native Maps availability when supplied, primarily for tests.
  /// When omitted, Android reports whether a real local Maps key is present.
  final bool? enableGoogleMap;

  @override
  State<LocalRideHomeScreen> createState() => _LocalRideHomeScreenState();
}

class _LocalRideHomeScreenState extends State<LocalRideHomeScreen>
    with WidgetsBindingObserver {
  late final LocalRideController _controller;
  late final RoutePlanningService _routePlanningService;
  late final DestinationResolver _pickupResolver;
  late final PickupLocationRepository _pickupLocationRepository;
  late final RideBookingRepository _rideBookingRepository;
  bool _enableGoogleMap = false;
  bool _retryWhenResumed = false;
  bool _dialogIsOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final locationService =
        widget.locationService ??
        (sl.isRegistered<LocationService>()
            ? sl.get<LocationService>()
            : const DeviceLocationService());
    _controller = LocalRideController(locationService);
    _pickupResolver =
        widget.pickupResolver ?? _createDefaultDestinationResolver();
    _routePlanningService =
        widget.routePlanningService ??
        _createDefaultRoutePlanningService(_pickupResolver);
    _pickupLocationRepository =
        widget.pickupLocationRepository ??
        _createDefaultPickupLocationRepository();
    _rideBookingRepository =
        widget.rideBookingRepository ?? _createDefaultRideBookingRepository();
    final mapOverride = widget.enableGoogleMap;
    if (mapOverride != null) {
      _enableGoogleMap = mapOverride;
    } else {
      unawaited(_loadGoogleMapAvailability());
    }
  }

  Future<void> _loadGoogleMapAvailability() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final configured =
          await const MethodChannel(
            'com.kisha.multiservice/app_configuration',
          ).invokeMethod<bool>('isGoogleMapsConfigured') ??
          false;
      if (mounted && configured != _enableGoogleMap) {
        setState(() => _enableGoogleMap = configured);
      }
    } on MissingPluginException {
      // Tests and unsupported platforms use the code-drawn route preview.
    } on PlatformException {
      // A configuration lookup must never block the trip planner.
    }
  }

  DestinationResolver _createDefaultDestinationResolver() {
    final config = sl.isRegistered<AppConfig>()
        ? sl.get<AppConfig>()
        : AppConfig.fromEnvironment();
    const deviceDestinationResolver = DeviceDestinationResolver();
    return BackendDestinationResolver(
      config: config,
      fallback: deviceDestinationResolver,
      accessTokenProvider: _backendToken,
    );
  }

  RoutePlanningService _createDefaultRoutePlanningService(
    DestinationResolver destinationResolver,
  ) {
    final config = sl.isRegistered<AppConfig>()
        ? sl.get<AppConfig>()
        : AppConfig.fromEnvironment();
    return BackendFirstRoutePlanningService(
      backend: BackendRoutePlanningService(
        config: config,
        destinationResolver: destinationResolver,
        accessTokenProvider: _backendToken,
      ),
      fallback: const EstimatedRoutePlanningService(
        destinationResolver: DeviceDestinationResolver(),
      ),
    );
  }

  PickupLocationRepository _createDefaultPickupLocationRepository() {
    final config = sl.isRegistered<AppConfig>()
        ? sl.get<AppConfig>()
        : AppConfig.fromEnvironment();
    return BackendPickupLocationRepository(
      apiBaseUri: config.apiBaseUri,
      bearerTokenProvider: _backendToken,
    );
  }

  RideBookingRepository _createDefaultRideBookingRepository() {
    final config = sl.isRegistered<AppConfig>()
        ? sl.get<AppConfig>()
        : AppConfig.fromEnvironment();
    return BackendRideBookingRepository(
      config: config,
      accessTokenProvider: _backendToken,
    );
  }

  Future<String?> _backendToken() async {
    if (Firebase.apps.isNotEmpty) {
      final firebaseToken = await FirebaseAuth.instance.currentUser
          ?.getIdToken();
      if (firebaseToken != null && firebaseToken.trim().isNotEmpty) {
        return firebaseToken;
      }
    }
    if (!sl.isRegistered<SecureStorageService>()) return null;
    return sl.get<SecureStorageService>().read(StorageKeys.accessToken);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_retryWhenResumed) return;
    _retryWhenResumed = false;
    unawaited(_retryLocation(showFollowUpDialog: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseVehicle(RideVehicleType vehicle) async {
    await _controller.chooseVehicle(vehicle);
  }

  Future<void> _retryLocation({bool showFollowUpDialog = true}) async {
    final status = await _controller.refreshLocation();
    if (!mounted) return;
    if (status == RideLocationStatus.ready &&
        _controller.pickupLocation != null) {
      await _persistPickup(
        _controller.pickupLocation!,
        PickupLocationSource.gps,
      );
    }
    if (!mounted || !showFollowUpDialog) return;
    await _handleLocationStatus(status);
  }

  Future<void> _selectPickup(
    LocationModel location,
    PickupLocationSource source,
  ) async {
    _controller.setPickupLocation(location, source: source);
    unawaited(_persistPickup(location, source));
  }

  Future<void> _persistPickup(
    LocationModel location,
    PickupLocationSource source,
  ) async {
    final label = location.label?.trim();
    final formattedAddress = label != null && label.isNotEmpty
        ? label
        : '${location.latitude.toStringAsFixed(7)}, '
              '${location.longitude.toStringAsFixed(7)}';
    try {
      await _pickupLocationRepository.savePickupLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        formattedAddress: formattedAddress,
        source: source,
      );
      if (!mounted) return;
      _showPickupMessage('Pickup confirmed and saved to your account.');
    } on PickupLocationPersistenceException catch (error) {
      if (!mounted) return;
      _showPickupMessage(
        error.failure == PickupLocationPersistenceFailure.authenticationRequired
            ? 'Pickup confirmed for this ride. Sign in to save it to your account.'
            : 'Pickup confirmed, but cloud save failed. You can retry later.',
      );
    }
  }

  void _showPickupMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<RideBookingResult> _bookRide(
    RideCheckoutDetails checkout,
    RidePaymentMethod paymentMethod,
  ) => _rideBookingRepository.createBooking(
    checkout: checkout,
    paymentMethod: paymentMethod,
  );

  Future<RazorpayCheckoutOrder> _createRazorpayOrder(String bookingId) =>
      _rideBookingRepository.createRazorpayOrder(bookingId: bookingId);

  Future<RazorpayPaymentVerification> _verifyRazorpayPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) => _rideBookingRepository.verifyRazorpayPayment(
    bookingId: bookingId,
    razorpayOrderId: razorpayOrderId,
    razorpayPaymentId: razorpayPaymentId,
    razorpaySignature: razorpaySignature,
  );

  Future<void> _showSavedRideRequest(
    BuildContext currentContext,
    RideBookingResult booking,
  ) => Navigator.of(currentContext).pushReplacement<void, void>(
    MaterialPageRoute<void>(
      builder: (_) => RideRequestSavedScreen(booking: booking),
    ),
  );

  Future<void> _showPaymentSuccess(
    BuildContext currentContext,
    RazorpayPaymentVerification payment,
  ) => Navigator.of(currentContext).pushReplacement<void, void>(
    MaterialPageRoute<void>(
      builder: (_) => PaymentSuccessScreen(payment: payment),
    ),
  );

  Future<void> _handleLocationStatus(RideLocationStatus status) async {
    switch (status) {
      case RideLocationStatus.serviceDisabled:
        await _showGpsDialog();
      case RideLocationStatus.permissionPermanentlyDenied:
        await _showPermissionSettingsDialog();
      case RideLocationStatus.idle:
      case RideLocationStatus.locating:
      case RideLocationStatus.ready:
      case RideLocationStatus.permissionDenied:
      case RideLocationStatus.unavailable:
        return;
    }
  }

  Future<void> _showGpsDialog() async {
    if (_dialogIsOpen || !mounted) return;
    _dialogIsOpen = true;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => _LocationDialog(
        icon: Icons.gps_off_rounded,
        accent: AppColors.warning,
        title: 'Turn on GPS',
        message:
            'Your pickup is based on your current position. Turn on location '
            'services, then return here to see ride estimates nearby.',
        actionLabel: 'Turn on GPS',
      ),
    );
    _dialogIsOpen = false;
    if (!mounted || shouldOpen != true) return;
    await _openSettings(appSettings: false);
  }

  Future<void> _showPermissionSettingsDialog() async {
    if (_dialogIsOpen || !mounted) return;
    _dialogIsOpen = true;
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => const _LocationDialog(
        icon: Icons.location_disabled_rounded,
        accent: AppColors.error,
        title: 'Allow location access',
        message:
            'Location permission is turned off for Multi Service. Open app '
            'settings and allow location while using the app.',
        actionLabel: 'Open settings',
      ),
    );
    _dialogIsOpen = false;
    if (!mounted || shouldOpen != true) return;
    await _openSettings(appSettings: true);
  }

  Future<void> _openSettings({required bool appSettings}) async {
    _retryWhenResumed = true;
    final opened = appSettings
        ? await _controller.openAppSettings()
        : await _controller.openLocationSettings();
    if (!mounted) return;
    if (!opened) {
      _retryWhenResumed = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appSettings
                ? 'Could not open app settings. Please open them from your device.'
                : 'Could not open GPS settings. Please turn on location manually.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Local rides'),
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 900
                  ? 32.0
                  : 20.0;
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _PageHeading(),
                        const SizedBox(height: 24),
                        const _SectionHeading(
                          eyebrow: 'CHOOSE YOUR RIDE',
                          title: 'Bike, Riksha, or Car',
                          description:
                              'Select a vehicle first, then add your pickup and drop location.',
                        ),
                        const SizedBox(height: 14),
                        _VehiclePicker(
                          selectedVehicle: _controller.selectedVehicle,
                          locationStatus: _controller.locationStatus,
                          onSelected: _chooseVehicle,
                        ),
                        const SizedBox(height: 28),
                        TripPlannerSection(
                          pickup: _controller.pickupLocation,
                          locationStatus: _controller.locationStatus,
                          selectedVehicle: _controller.selectedVehicle,
                          routePlanningService: _routePlanningService,
                          pickupResolver: _pickupResolver,
                          onRequestPickup: () => _retryLocation(),
                           onPickupSelected: _selectPickup,
                           onBookRide: _bookRide,
                           onBookingSaved: _showSavedRideRequest,
                           onCreateRazorpayOrder: _createRazorpayOrder,
                           onVerifyRazorpayPayment: _verifyRazorpayPayment,
                           onPaymentVerified: _showPaymentSuccess,
                           mapTripPlanner: widget.mapTripPlanner,
                           enableGoogleMap: _enableGoogleMap,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading();

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
                'Book a local ride',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.9,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Choose Bike, Riksha, or Car, then enter start and drop points.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.near_me_rounded, size: 17, color: AppColors.secondary),
              SizedBox(width: 6),
              Text(
                '1–100 km',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.05,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _VehiclePicker extends StatelessWidget {
  const _VehiclePicker({
    required this.selectedVehicle,
    required this.locationStatus,
    required this.onSelected,
  });

  final RideVehicleType? selectedVehicle;
  final RideLocationStatus locationStatus;
  final ValueChanged<RideVehicleType> onSelected;

  static const _options = [
    (
      type: RideVehicleType.bike,
      title: 'Bike',
      subtitle: 'Quick solo trips',
      icon: Icons.two_wheeler_rounded,
      color: Color(0xFF2563EB),
    ),
    (
      type: RideVehicleType.auto,
      title: 'Riksha',
      subtitle: 'Easy city travel',
      icon: Icons.electric_rickshaw_rounded,
      color: Color(0xFF0F9F8F),
    ),
    (
      type: RideVehicleType.car,
      title: 'Car',
      subtitle: 'Comfort for up to 4',
      icon: Icons.directions_car_filled_rounded,
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < _options.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(child: _buildCard(_options[index])),
        ],
      ],
    );
  }

  Widget _buildCard(
    ({
      RideVehicleType type,
      String title,
      String subtitle,
      IconData icon,
      Color color,
    })
    option,
  ) {
    final selected = selectedVehicle == option.type;
    return RideOptionCard(
      title: option.title,
      subtitle: option.subtitle,
      icon: option.icon,
      accent: option.color,
      isSelected: selected,
      isBusy: selected && locationStatus == RideLocationStatus.locating,
      onTap: () => onSelected(option.type),
    );
  }
}

class _LocationDialog extends StatelessWidget {
  const _LocationDialog({
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accent, size: 28),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: accent),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
