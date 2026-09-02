import 'dart:typed_data';

final class UploadedFile {
  const UploadedFile({required this.url, this.id});
  final String url;
  final String? id;
}

abstract interface class FileUploadService {
  Future<UploadedFile> upload({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  });
}

final class PlaceholderFileUploadService implements FileUploadService {
  const PlaceholderFileUploadService();

  @override
  Future<UploadedFile> upload({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) {
    throw UnsupportedError('Register a platform file-upload implementation.');
  }
}
