import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/parent_dashboard_model.dart';
import '../../../../core/services/app_logger.dart';

abstract class ParentPortalDataSource {
  Future<List<StudentDashboardModel>> getStudentsByParentPhone(String phone);
}

class ParentPortalDataSourceImpl implements ParentPortalDataSource {
  final SupabaseClient client;

  ParentPortalDataSourceImpl({required this.client});

  @override
  Future<List<StudentDashboardModel>> getStudentsByParentPhone(
      String phone) async {
    try {
      AppLogger.i('[ParentPortalDataSource] Checking parent phone: $phone');

      final response =
          await client.rpc('get_parent_dashboard', params: {'p_phone': phone});

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              StudentDashboardModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.e(
          '[ParentPortalDataSource] Error getting parent dashboard: $e');
      rethrow;
    }
  }
}
