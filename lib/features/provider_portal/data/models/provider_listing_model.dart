class ProviderListingModel {
  const ProviderListingModel({
    required this.id,
    required this.title,
    required this.serviceType,
    required this.isActive,
  });

  final String id;
  final String title;
  final String serviceType;
  final bool isActive;
}
