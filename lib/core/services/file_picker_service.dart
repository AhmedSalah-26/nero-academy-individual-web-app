import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'app_logger.dart';

// Conditional import for web
import 'file_picker_stub.dart' if (dart.library.html) 'file_picker_web.dart'
    as file_picker_impl;

/// File Picker Service - Cross-platform file picking
class FilePickerService {
  static final FilePickerService _instance = FilePickerService._();
  factory FilePickerService() => _instance;
  FilePickerService._();

  final ImagePicker _imagePicker = ImagePicker();

  /// Pick a single file (works on web and mobile)
  /// Returns file bytes and file name
  Future<PickedFileData?> pickFile({
    FilePickerType type = FilePickerType.any,
  }) async {
    try {
      AppLogger.i('📎 [FilePickerService] Starting file picker...');

      if (type == FilePickerType.image) {
        // Use ImagePicker for images (more reliable)
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 2048,
          maxHeight: 2048,
        );

        if (image == null) {
          AppLogger.i('📎 [FilePickerService] No image selected');
          return null;
        }

        final bytes = await image.readAsBytes();
        AppLogger.success(
            '📎 [FilePickerService] Image picked: ${image.name}, ${bytes.length} bytes');

        return PickedFileData(
          bytes: bytes,
          name: image.name,
          mimeType: image.mimeType,
        );
      } else {
        // For web, use HTML input element
        if (kIsWeb) {
          return await file_picker_impl.pickFileWeb();
        } else {
          FileType fileType = FileType.any;
          if (type == FilePickerType.document) {
            fileType = FileType.custom;
          }

          final FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: fileType,
            allowedExtensions: type == FilePickerType.document
                ? ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx']
                : null,
            withData: true,
          );

          if (result == null || result.files.isEmpty) {
            AppLogger.i('📎 [FilePickerService] No file selected');
            return null;
          }

          final file = result.files.first;
          if (file.bytes == null) {
            AppLogger.e('📎 [FilePickerService] Picked file has no bytes');
            return null;
          }

          AppLogger.success(
              '📎 [FilePickerService] File picked: ${file.name}, ${file.bytes!.length} bytes');

          return PickedFileData(
            bytes: file.bytes!,
            name: file.name,
            mimeType: null,
          );
        }
      }
    } catch (e) {
      AppLogger.e('📎 [FilePickerService] Error picking file: $e');
      return null;
    }
  }
}

/// Picked file data
class PickedFileData {
  final Uint8List bytes;
  final String name;
  final String? mimeType;

  PickedFileData({
    required this.bytes,
    required this.name,
    this.mimeType,
  });

  /// Get file extension
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Get file size in KB
  double get sizeKB => bytes.length / 1024;

  /// Get file size in MB
  double get sizeMB => bytes.length / (1024 * 1024);
}

/// File picker type
enum FilePickerType {
  any,
  image,
  document,
}
