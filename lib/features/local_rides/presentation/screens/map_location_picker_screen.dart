import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/models/location_model.dart';

typedef LocationPickerReverseGeocoder =
    Future<String?> Function(double latitude, double longitude);

/// Allows widget tests to replace the native Google Maps platform view while
/// still driving the picker through the same camera callbacks.
typedef LocationPickerMapBuilder =
    Widget Function(
      BuildContext context, {
      required CameraPosition initialCameraPosition,
      required ValueChanged<CameraPosition> onCameraMove,
      required VoidCallback onCameraIdle,
    });

/// A full-screen map that returns the exact coordinate under the fixed pin.
///
/// Moving the camera only updates in-memory preview state. The selected
/// location is returned to the caller, and can be persisted there, only after
/// the user explicitly taps [confirmLabel].
class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({
    this.initialLocation,
    this.title = 'Set pickup location',
    this.confirmLabel = 'Confirm pickup',
    this.initialZoom = 16,
    this.reverseGeocoder,
    this.mapBuilder,
    super.key,
  });

  final LocationModel? initialLocation;
  final String title;
  final String confirmLabel;
  final double initialZoom;
  final LocationPickerReverseGeocoder? reverseGeocoder;
  final LocationPickerMapBuilder? mapBuilder;

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  // A country-level fallback is used only to give a picker without an initial
  // coordinate a valid camera position. The user must move the map before it
  // becomes confirmable.
  static const LatLng _indiaCameraFallback = LatLng(20.5937, 78.9629);
  static const Duration _reverseGeocodeTimeout = Duration(seconds: 6);

  late final CameraPosition _initialCameraPosition;
  late LocationModel _candidate;
  late bool _hasChosenPosition;
  bool _cameraIsMoving = false;
  bool _isResolvingLabel = false;
  int _reverseGeocodeRequestId = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation;
    final target = initial == null
        ? _indiaCameraFallback
        : LatLng(initial.latitude, initial.longitude);
    _initialCameraPosition = CameraPosition(
      target: target,
      zoom: initial == null ? 4.8 : widget.initialZoom,
    );
    _candidate = initial ?? _locationFrom(target);
    _hasChosenPosition = initial != null;

    final initialLabel = initial?.label?.trim();
    if (initial != null && (initialLabel == null || initialLabel.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_resolveCandidateLabel());
      });
    }
  }

  @override
  void dispose() {
    // Invalidates any reverse-geocoding result that completes after disposal.
    _reverseGeocodeRequestId++;
    super.dispose();
  }

  void _onCameraMove(CameraPosition position) {
    _reverseGeocodeRequestId++;
    final movementStarted = !_cameraIsMoving;
    _cameraIsMoving = true;
    _hasChosenPosition = true;
    _candidate = _locationFrom(position.target);
    if (movementStarted && mounted) {
      setState(() => _isResolvingLabel = false);
    }
  }

  void _onCameraIdle() {
    _cameraIsMoving = false;
    if (!_hasChosenPosition) return;
    unawaited(_resolveCandidateLabel());
  }

  Future<void> _resolveCandidateLabel() async {
    final coordinate = _candidate;
    final requestId = ++_reverseGeocodeRequestId;
    if (mounted) {
      setState(() => _isResolvingLabel = true);
    }

    String? resolvedLabel;
    try {
      resolvedLabel = await (widget.reverseGeocoder ?? _reverseGeocode)(
        coordinate.latitude,
        coordinate.longitude,
      ).timeout(_reverseGeocodeTimeout);
    } on Exception {
      // Coordinates remain a safe and exact fallback when reverse geocoding is
      // unavailable or the device is temporarily offline.
    }

    if (!mounted || requestId != _reverseGeocodeRequestId) return;
    final normalizedLabel = resolvedLabel?.trim();
    setState(() {
      _candidate = LocationModel(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        label: normalizedLabel == null || normalizedLabel.isEmpty
            ? _coordinateLabel(coordinate.latitude, coordinate.longitude)
            : normalizedLabel,
      );
      _isResolvingLabel = false;
    });
  }

  void _confirm() {
    if (!_hasChosenPosition || _cameraIsMoving || _isResolvingLabel) return;
    Navigator.of(context).pop<LocationModel>(_candidate);
  }

  void _cancel() => Navigator.of(context).pop<LocationModel>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mapBuilder = widget.mapBuilder;
    final map = mapBuilder == null
        ? GoogleMap(
            key: const Key('location-picker-google-map'),
            initialCameraPosition: _initialCameraPosition,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            compassEnabled: true,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          )
        : KeyedSubtree(
            key: const Key('location-picker-test-map'),
            child: mapBuilder(
              context,
              initialCameraPosition: _initialCameraPosition,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
            ),
          );

    return Scaffold(
      key: const Key('map-location-picker-screen'),
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: IconButton(
          key: const Key('location-picker-cancel'),
          tooltip: 'Cancel location selection',
          onPressed: _cancel,
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(widget.title),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  map,
                  IgnorePointer(
                    child: Center(
                      child: Semantics(
                        label: 'Fixed pickup pin',
                        child: const _FixedCenterPin(
                          key: Key('location-picker-center-pin'),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 16,
                    right: 16,
                    child: IgnorePointer(
                      child: _InstructionPill(
                        message: _hasChosenPosition
                            ? 'Move the map to fine-tune the exact point'
                            : 'Move the map to choose your pickup point',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: colors.surface,
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: 0.18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SELECTED PICKUP',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: _isResolvingLabel
                                    ? Row(
                                        key: const Key(
                                          'location-picker-loading',
                                        ),
                                        children: [
                                          const SizedBox.square(
                                            dimension: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          Expanded(
                                            child: Text(
                                              'Finding this address…',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        colors.onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _hasChosenPosition
                                            ? _displayLabel(_candidate)
                                            : 'Move the map to select a point',
                                        key: const Key('location-picker-label'),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              height: 1.3,
                                            ),
                                      ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _coordinateLabel(
                                  _candidate.latitude,
                                  _candidate.longitude,
                                ),
                                key: const Key('location-picker-coordinate'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    FilledButton.icon(
                      key: const Key('location-picker-confirm'),
                      onPressed:
                          !_hasChosenPosition ||
                              _cameraIsMoving ||
                              _isResolvingLabel
                          ? null
                          : _confirm,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        _isResolvingLabel
                            ? 'Confirming address…'
                            : widget.confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static LocationModel _locationFrom(LatLng coordinate) => LocationModel(
    latitude: coordinate.latitude,
    longitude: coordinate.longitude,
    label: _coordinateLabel(coordinate.latitude, coordinate.longitude),
  );

  static String _displayLabel(LocationModel location) {
    final label = location.label?.trim();
    if (label != null && label.isNotEmpty) return label;
    return _coordinateLabel(location.latitude, location.longitude);
  }

  static String _coordinateLabel(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  static Future<String?> _reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final placemarks = await Geocoding().placemarkFromCoordinates(
      latitude,
      longitude,
    );
    if (placemarks.isEmpty) return null;
    final place = placemarks.first;
    final candidates = <String?>[
      place.name,
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.postalCode,
    ];
    final parts = <String>[];
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty && !parts.contains(value)) {
        parts.add(value);
      }
    }
    return parts.isEmpty ? null : parts.join(', ');
  }
}

class _FixedCenterPin extends StatelessWidget {
  const _FixedCenterPin({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Transform.translate(
      // The marker tip, rather than the icon center, identifies the coordinate.
      offset: const Offset(0, -22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.person_pin_circle_rounded,
              color: colors.onPrimary,
              size: 29,
            ),
          ),
          Container(width: 3, height: 14, color: colors.primary),
          Container(
            width: 13,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionPill extends StatelessWidget {
  const _InstructionPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.open_with_rounded,
              size: 17,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
