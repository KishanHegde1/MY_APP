class RentalVehicleModel {
  const RentalVehicleModel({
    required this.id,
    required this.name,
    required this.category,
    required this.isSelfDrive,
  });

  final String id;
  final String name;
  final String category;
  final bool isSelfDrive;
}
