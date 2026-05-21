import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final bytes = File('assets/footer2.png').readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image != null) {
    final pixel = image.getPixel(10, 10);
    // getPixel returns a Pixel object in newer versions
    final r = pixel.r.toInt().toRadixString(16).padLeft(2, '0');
    final g = pixel.g.toInt().toRadixString(16).padLeft(2, '0');
    final b = pixel.b.toInt().toRadixString(16).padLeft(2, '0');
    print('Exact Color: #$r$g$b');
  } else {
    print('Failed to decode');
  }
}
