final class ImageModel {
  const ImageModel({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.altText,
    this.isPrimary = false,
  });

  factory ImageModel.fromJson(Map<String, Object?> json) => ImageModel(
    id: json['id'] as String,
    url: json['url'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    altText: json['altText'] as String?,
    isPrimary: json['isPrimary'] as bool? ?? false,
  );

  final String id;
  final String url;
  final String? thumbnailUrl;
  final String? altText;
  final bool isPrimary;
}
