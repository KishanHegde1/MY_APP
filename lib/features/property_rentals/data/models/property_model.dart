class PropertyModel {
  const PropertyModel({
    required this.id,
    required this.title,
    required this.type,
    required this.address,
    required this.monthlyRent,
  });

  final String id;
  final String title;
  final String type;
  final String address;
  final double monthlyRent;
}
