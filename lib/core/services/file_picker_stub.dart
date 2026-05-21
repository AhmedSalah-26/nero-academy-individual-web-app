import 'app_logger.dart';
import 'file_picker_service.dart';

/// Stub implementation for non-web platforms
Future<PickedFileData?> pickFileWeb() async {
  AppLogger.e(
      '📎 [FilePickerStub] Web file picker not available on this platform');
  return null;
}
