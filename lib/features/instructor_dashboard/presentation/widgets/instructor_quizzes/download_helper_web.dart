// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

// Web-specific implementation using dart:html
import 'dart:html' as html;
import 'dart:convert';

void downloadFile(String content, String fileName) {
  // Create blob with UTF-8 BOM for Excel
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Create download link
  final anchor = html.AnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
