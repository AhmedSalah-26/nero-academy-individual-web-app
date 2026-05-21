import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_logger.dart';

class ImageUploadService {
  final SupabaseClient _client;
  final ImagePicker _picker = ImagePicker();

  ImageUploadService(this._client);

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

  /// Upload image to Supabase Storage using bytes (works on web and mobile)
  Future<String?> uploadImageBytes(
      Uint8List bytes, String fileName, String bucket, String folder) async {
    try {
      AppLogger.i('═══════════════════════════════════════');
      AppLogger.i('☁️ UPLOADING IMAGE TO STORAGE');
      AppLogger.i('═══════════════════════════════════════');

      AppLogger.d('Upload Details:', {
        'file_name': fileName,
        'bucket': bucket,
        'folder': folder,
        'size': '${bytes.length} bytes',
      });

      final extension = fileName.split('.').last.toLowerCase();
      final uniqueFileName =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      }

      AppLogger.step(1, 'Calling Supabase Storage API...', {
        'path': uniqueFileName,
        'content_type': contentType,
      });

      final response = await _client.storage.from(bucket).uploadBinary(
            uniqueFileName,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: contentType,
            ),
          );

      AppLogger.success('Upload API Response', {'response': response});

      AppLogger.step(2, 'Getting public URL...');
      final publicUrl =
          _client.storage.from(bucket).getPublicUrl(uniqueFileName);

      AppLogger.success('IMAGE UPLOADED SUCCESSFULLY!', {'url': publicUrl});
      AppLogger.i('═══════════════════════════════════════');

      return publicUrl;
    } catch (e, stackTrace) {
      AppLogger.e('═══════════════════════════════════════');
      AppLogger.e('❌ UPLOAD FAILED!', e, stackTrace);
      AppLogger.e('═══════════════════════════════════════');
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
    try {
      AppLogger.i('🗑️ Deleting image: $imageUrl');
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final filePath =
          pathSegments.sublist(pathSegments.indexOf(bucket) + 1).join('/');

      await _client.storage.from(bucket).remove([filePath]);
      AppLogger.success('Image deleted');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('❌ Error deleting image', e, stackTrace);
      return false;
    }
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
