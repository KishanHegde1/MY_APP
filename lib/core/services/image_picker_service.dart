import 'dart:typed_data';

import 'package:image_picker/image_picker.dart' as picker;

enum ImageSourceType { camera, gallery }

final class PickedImage {
  const PickedImage({required this.name, required this.bytes, this.mimeType});
  final String name;
  final Uint8List bytes;
  final String? mimeType;
}

abstract interface class ImagePickerService {
  Future<PickedImage?> pickImage({
    ImageSourceType source = ImageSourceType.gallery,
  });
  Future<List<PickedImage>> pickMultipleImages();
}

final class PlaceholderImagePickerService implements ImagePickerService {
  const PlaceholderImagePickerService();

  @override
  Future<PickedImage?> pickImage({
    ImageSourceType source = ImageSourceType.gallery,
  }) async => null;

  @override
  Future<List<PickedImage>> pickMultipleImages() async => const <PickedImage>[];
}

final class DeviceImagePickerService implements ImagePickerService {
  DeviceImagePickerService({picker.ImagePicker? pickerClient})
    : _picker = pickerClient ?? picker.ImagePicker();
  final picker.ImagePicker _picker;

  @override
  Future<PickedImage?> pickImage({
    ImageSourceType source = ImageSourceType.gallery,
  }) async {
    final file = await _picker.pickImage(
      source: source == ImageSourceType.camera
          ? picker.ImageSource.camera
          : picker.ImageSource.gallery,
    );
    return file == null
        ? null
        : PickedImage(
            name: file.name,
            bytes: await file.readAsBytes(),
            mimeType: file.mimeType,
          );
  }

  @override
  Future<List<PickedImage>> pickMultipleImages() async {
    final files = await _picker.pickMultiImage();
    return Future.wait(
      files.map(
        (file) async => PickedImage(
          name: file.name,
          bytes: await file.readAsBytes(),
          mimeType: file.mimeType,
        ),
      ),
    );
  }
}
