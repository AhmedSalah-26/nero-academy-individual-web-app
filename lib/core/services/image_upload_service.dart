import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../network/api_client.dart';
import 'app_logger.dart';

class ImageUploadService {
  final ApiClient _apiClient;
  final ImagePicker _picker = ImagePicker();

  ImageUploadService(this._apiClient);

  /// Compress image bytes
  Future<Uint8List> _compressImage(Uint8List bytes,
      {int quality = 70, int minWidth = 800, int minHeight = 800}) async {
    if (kIsWeb) {
      // Web doesn't support flutter_image_compress, return original
      return bytes;
    }

    try {
      final originalSize = bytes.length;
      AppLogger.d(
          '🗜️ Compressing image... Original size: ${(originalSize / 1024).toStringAsFixed(1)} KB');

      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      final compressedSize = compressedBytes.length;
      final savedPercent =
          ((originalSize - compressedSize) / originalSize * 100)
              .toStringAsFixed(1);

      AppLogger.success('Image compressed', {
        'original': '${(originalSize / 1024).toStringAsFixed(1)} KB',
        'compressed': '${(compressedSize / 1024).toStringAsFixed(1)} KB',
        'saved': '$savedPercent%',
      });

      return compressedBytes;
    } catch (e, stackTrace) {
      AppLogger.e('❌ Compression failed, using original', e, stackTrace);
      return bytes;
    }
  }

  /// Pick image (works on both web and mobile)
  Future<PickedImageData?> pickImage({bool compress = true}) async {
    try {
      AppLogger.i('📷 Picking single image...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        var bytes = await image.readAsBytes();

        // Compress image if enabled
        if (compress) {
          bytes = await _compressImage(bytes);
        }

        AppLogger.success('Image picked', {
          'name': image.name,
          'size': '${(bytes.length / 1024).toStringAsFixed(1)} KB',
        });
        return PickedImageData(
          bytes: bytes,
          name: image.name,
          path: kIsWeb ? null : image.path,
        );
      }
      AppLogger.w('No image selected');
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('❌ Error picking image', e, stackTrace);
      return null;
    }
  }

  /// Pick multiple images (works on both web and mobile)
  Future<List<PickedImageData>> pickMultipleImages(
      {bool compress = true}) async {
    try {
      AppLogger.i('📷 Picking multiple images...');
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      AppLogger.d('Images selected: ${images.length}');
      final List<PickedImageData> results = [];
      for (final image in images) {
        var bytes = await image.readAsBytes();

        // Compress image if enabled
        if (compress) {
          bytes = await _compressImage(bytes);
        }

        AppLogger.d(
            'Loaded: ${image.name} (${(bytes.length / 1024).toStringAsFixed(1)} KB)');
        results.add(PickedImageData(
          bytes: bytes,
          name: image.name,
          path: kIsWeb ? null : image.path,
        ));
      }
      return results;
    } catch (e, stackTrace) {
      AppLogger.e('❌ Error picking images', e, stackTrace);
      return [];
    }
  }

  /// Pick and compress avatar image (smaller size for avatars)
  Future<PickedImageData?> pickAvatarImage() async {
    try {
      AppLogger.i('📷 Picking avatar image...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        var bytes = await image.readAsBytes();

        // Compress avatar with smaller dimensions
        bytes = await _compressImage(bytes,
            quality: 75, minWidth: 256, minHeight: 256);

        AppLogger.success('Avatar picked', {
          'name': image.name,
          'size': '${(bytes.length / 1024).toStringAsFixed(1)} KB',
        });
        return PickedImageData(
          bytes: bytes,
          name: image.name,
          path: kIsWeb ? null : image.path,
        );
      }
      AppLogger.w('No image selected');
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('❌ Error picking avatar', e, stackTrace);
      return null;
    }
  }

  /// Upload image using REST API
  Future<String?> uploadImageBytes(
      Uint8List bytes, String fileName, String bucket, String folder) async {
    try {
      AppLogger.i('☁️ UPLOADING IMAGE TO STORAGE VIA REST API');
      
      // Determine the type parameter for Laravel controller based on bucket/folder
      String type = 'general';
      if (bucket == 'avatars') {
        type = 'avatar';
      } else if (bucket == 'courses') {
        type = 'course';
      } else if (bucket == 'attachments') {
        type = 'attachment';
      }

      final response = await _apiClient.uploadFile(
        '/upload',
        bytes: bytes.toList(),
        fieldName: 'file',
        fileName: fileName,
        fields: {
          'type': type,
        },
      );

      if (response != null && response['success'] == true) {
        final publicUrl = response['url'] as String;
        AppLogger.success('IMAGE UPLOADED SUCCESSFULLY!', {'url': publicUrl});
        return publicUrl;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('❌ UPLOAD FAILED!', e, stackTrace);
      return null;
    }
  }

  /// Upload product image
  Future<String?> uploadProductImage(PickedImageData imageData) async {
    AppLogger.i('🛍️ Uploading PRODUCT image...');
    return uploadImageBytes(
        imageData.bytes, imageData.name, 'products', 'images');
  }

  /// Upload category image
  Future<String?> uploadCategoryImage(PickedImageData imageData) async {
    AppLogger.i('📁 Uploading CATEGORY image...');
    return uploadImageBytes(
        imageData.bytes, imageData.name, 'categories', 'images');
  }

  /// Upload avatar image (deletes old avatar first)
  Future<String?> uploadAvatarImage(PickedImageData imageData, String userId,
      {String? oldAvatarUrl}) async {
    AppLogger.i('👤 Uploading AVATAR image...');

    // Delete old avatar if exists
    if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
      AppLogger.i('🗑️ Deleting old avatar...');
      await deleteImage(oldAvatarUrl, 'avatars');
    }

    return uploadImageBytes(imageData.bytes, imageData.name, 'avatars', userId);
  }

  /// Delete multiple images from storage
  Future<void> deleteImages(List<String> imageUrls, String bucket) async {
    for (final url in imageUrls) {
      await deleteImage(url, bucket);
    }
  }

  /// Delete old product images that were removed
  Future<void> deleteRemovedProductImages(
      List<String> oldImages, List<String> newImages) async {
    final removedImages =
        oldImages.where((url) => !newImages.contains(url)).toList();
    if (removedImages.isNotEmpty) {
      AppLogger.i(
          '🗑️ Deleting ${removedImages.length} removed product images');
      await deleteImages(removedImages, 'products');
    }
  }

  /// Delete image from storage
  Future<bool> deleteImage(String imageUrl, String bucket) async {
    AppLogger.i('🗑️ Mock deleting image: $imageUrl');
    return true;
  }
}

/// Class to hold picked image data (works on both web and mobile)
class PickedImageData {
  final Uint8List bytes;
  final String name;
  final String? path;

  PickedImageData({
    required this.bytes,
    required this.name,
    this.path,
  });
}
