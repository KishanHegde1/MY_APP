import 'location_model.dart';

final class AddressModel {
  const AddressModel({
    required this.id,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.label,
    this.addressLine2,
    this.location,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, Object?> json) {
    final location = json['location'];
    return AddressModel(
      id: json['id'] as String,
      label: json['label'] as String?,
      addressLine1: json['addressLine1'] as String,
      addressLine2: json['addressLine2'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postalCode'] as String,
      country: json['country'] as String,
      location: location is Map<Object?, Object?>
          ? LocationModel.fromJson(
              location.map((key, value) => MapEntry(key.toString(), value)),
            )
          : null,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  final String id;
  final String? label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final LocationModel? location;
  final bool isDefault;

  String get formatted => <String>[
    addressLine1,
    if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
    city,
    state,
    postalCode,
    country,
  ].join(', ');
}
