// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:typed_data';
import 'app_logger.dart';
import 'file_picker_service.dart';

/// Web-specific file picker implementation
Future<PickedFileData?> pickFileWeb() async {
  try {
    AppLogger.i('📎 [FilePickerWeb] Opening file picker...');

    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '*/*';
    uploadInput.click();

    await uploadInput.onChange.first;

    if (uploadInput.files?.isEmpty ?? true) {
      AppLogger.i('📎 [FilePickerWeb] No file selected');
      return null;
    }

    final file = uploadInput.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final bytes = reader.result as Uint8List;
    AppLogger.success(
        '📎 [FilePickerWeb] File picked: ${file.name}, ${bytes.length} bytes');

    return PickedFileData(
      bytes: bytes,
      name: file.name,
      mimeType: file.type,
    );
  } catch (e) {
    AppLogger.e('📎 [FilePickerWeb] Error: $e');
    return null;
  }
}
