import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ApiClient get /courses should succeed and return courses list', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    try {
      final response = await apiClient.get('/courses');
      expect(response, isNotNull);
      expect(response, isMap);
      expect(response['success'], isTrue);
      expect(response['courses'], isList);
      print('✅ ApiClient test succeeded: ${response['courses'].length} courses found.');
    } catch (e) {
      fail('ApiClient GET /courses failed: $e');
    }
  });
}
