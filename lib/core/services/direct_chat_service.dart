import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles robust creation/opening for 1:1 conversations.
class DirectChatService {
  DirectChatService._();

  static Future<String> getOrCreateSingleConversation({
    required SupabaseClient supabase,
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId == otherUserId) {
      throw ArgumentError('Cannot open direct chat with the same user');
    }

    try {
      final response =
          await supabase.rpc('get_or_create_single_conversation', params: {
        'p_user1_id': currentUserId,
        'p_user2_id': otherUserId,
      });
      return response as String;
    } on PostgrestException catch (e) {
      // Legacy DB function can throw duplicate key on participant insert.
      if (e.code == '23505') {
        final existingConversationId = await _findExistingSingleConversationId(
          supabase: supabase,
          currentUserId: currentUserId,
          otherUserId: otherUserId,
        );
        if (existingConversationId != null) {
          return existingConversationId;
        }
      }
      rethrow;
    }
  }

  static Future<String?> _findExistingSingleConversationId({
    required SupabaseClient supabase,
    required String currentUserId,
    required String otherUserId,
  }) async {
    final mySingles = await supabase
        .from('conversation_participants')
        .select('conversation_id, conversations!inner(type)')
        .eq('user_id', currentUserId)
        .eq('conversations.type', 'single');

    final myConversationIds = (mySingles as List)
        .map((row) => row['conversation_id'] as String?)
        .whereType<String>()
        .toList();

    if (myConversationIds.isEmpty) return null;

    final shared = await supabase
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', otherUserId)
        .inFilter('conversation_id', myConversationIds)
        .limit(1);

    final rows = shared as List;
    if (rows.isEmpty) return null;

    return rows.first['conversation_id'] as String?;
  }
}
