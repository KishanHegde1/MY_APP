class RoomModel {
  const RoomModel({
    required this.id,
    required this.title,
    required this.address,
    required this.monthlyRent,
  });

  final String id;
  final String title;
  final String address;
  final double monthlyRent;
}
