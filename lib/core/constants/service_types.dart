enum ServiceType {
  localBikeRide('LOCAL_BIKE_RIDE', 'Bike ride'),
  localAutoRide('LOCAL_AUTO_RIDE', 'Auto-rickshaw ride'),
  localCarRide('LOCAL_CAR_RIDE', 'Local car ride'),
  outstationCarRide('OUTSTATION_CAR_RIDE', 'Outstation car ride'),
  bikeRental('BIKE_RENTAL', 'Bike rental'),
  selfDriveCarRental('SELF_DRIVE_CAR_RENTAL', 'Self-drive car'),
  carWithDriverRental('CAR_WITH_DRIVER_RENTAL', 'Car with driver'),
  roomRental('ROOM_RENTAL', 'Room rental'),
  houseRental('HOUSE_RENTAL', 'House rental'),
  apartmentRental('APARTMENT_RENTAL', 'Apartment rental'),
  shopRental('SHOP_RENTAL', 'Shop rental'),
  officeRental('OFFICE_RENTAL', 'Office rental'),
  warehouseRental('WAREHOUSE_RENTAL', 'Warehouse rental'),
  landRental('LAND_RENTAL', 'Land rental');

  const ServiceType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static ServiceType? tryParse(String value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}
