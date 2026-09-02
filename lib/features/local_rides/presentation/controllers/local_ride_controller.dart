import 'package:flutter/foundation.dart';

import '../../../../core/services/location_service.dart';
import '../../../../shared/models/location_model.dart';
import '../../domain/models/pickup_location_source.dart';

enum LocalRideStage {
  pickupAndDropOff,
  choosingRide,
  searching,
  tracking,
  complete,
}

enum RideVehicleType { bike, auto, car }

enum RideLocationStatus {
  idle,
  locating,
  ready,
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

class LocalRideController extends ChangeNotifier {
  LocalRideController(this._locationService);

  final LocationService _locationService;

  LocalRideStage _stage = LocalRideStage.pickupAndDropOff;
  bool _isLoading = false;
  RideVehicleType? _selectedVehicle;
  RideLocationStatus _locationStatus = RideLocationStatus.idle;
  LocationModel? _pickupLocation;
  PickupLocationSource? _pickupSource;
  int _locationRequestId = 0;

  LocalRideStage get stage => _stage;
  bool get isLoading => _isLoading;
  RideVehicleType? get selectedVehicle => _selectedVehicle;
  RideLocationStatus get locationStatus => _locationStatus;
  LocationModel? get pickupLocation => _pickupLocation;
  PickupLocationSource? get pickupSource => _pickupSource;
  bool get hasPickupLocation => _pickupLocation != null;

  Future<RideLocationStatus> chooseVehicle(RideVehicleType vehicle) async {
    _selectedVehicle = vehicle;
    _stage = LocalRideStage.choosingRide;
    notifyListeners();
    return _locationStatus;
  }

  /// Applies an explicitly confirmed pickup and invalidates any older GPS
  /// request so a late platform response cannot overwrite a typed/map pin.
  void setPickupLocation(
    LocationModel location, {
    required PickupLocationSource source,
  }) {
    _locationRequestId++;
    _pickupLocation = location;
    _pickupSource = source;
    _locationStatus = RideLocationStatus.ready;
    _isLoading = false;
    notifyListeners();
  }

  Future<RideLocationStatus> refreshLocation() async {
    final requestId = ++_locationRequestId;
    _locationStatus = RideLocationStatus.locating;
    _isLoading = true;
    notifyListeners();

    final result = await _locationService.requestCurrentLocation();
    if (requestId != _locationRequestId) return _locationStatus;

    _isLoading = false;
    if (result.isSuccess) {
      _pickupLocation = result.location;
      _pickupSource = PickupLocationSource.gps;
      _locationStatus = RideLocationStatus.ready;
      notifyListeners();
      return _locationStatus;
    }

    _locationStatus = switch (result.issue) {
      LocationAccessIssue.serviceDisabled => RideLocationStatus.serviceDisabled,
      LocationAccessIssue.permissionDenied =>
        RideLocationStatus.permissionDenied,
      LocationAccessIssue.permissionPermanentlyDenied =>
        RideLocationStatus.permissionPermanentlyDenied,
      LocationAccessIssue.positionUnavailable ||
      null => RideLocationStatus.unavailable,
    };
    notifyListeners();
    return _locationStatus;
  }

  Future<bool> openLocationSettings() =>
      _locationService.openLocationSettings();

  Future<bool> openAppSettings() => _locationService.openAppSettings();

  void moveTo(LocalRideStage stage) {
    if (_stage == stage) return;
    _stage = stage;
    notifyListeners();
  }

  void setLoading({required bool value}) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
