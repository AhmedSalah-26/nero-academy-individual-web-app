import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/forum_message_model.dart';
import 'forum_chat_state.dart';

class ForumChatCubit extends Cubit<ForumChatState> {
  final ApiClient _apiClient;
  final String conversationId;
  final String currentUserId;

  ForumChatCubit({
    required ApiClient apiClient,
    required this.conversationId,
    required this.currentUserId,
  })  : _apiClient = apiClient,
        super(const ForumChatState());

  Future<void> loadMessages() async {
    try {
      emit(state.copyWith(isLoading: true, isError: false));

      final response = await _apiClient.get('/chat/conversations/$conversationId/messages');
      final list = response['messages'] as List;

      final messages = list.map((json) {
        return ConversationMessageModel.fromJson(json as Map<String, dynamic>);
      }).toList();

      emit(state.copyWith(
        isLoading: false,
        messages: messages,
      ));
    } catch (e, stackTrace) {
      debugPrint('❌ [ForumChat] Error loading messages: $e');
      debugPrint('Stack trace: $stackTrace');
      emit(state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> sendMessage(String text, {String? replyToId}) async {
    try {
      final response = await _apiClient.post(
        '/chat/conversations/$conversationId/messages',
        body: {
          'message_text': text,
          'message_type': 'text',
          'reply_to_message_id': replyToId,
        },
      );

      final realMessage = ConversationMessageModel.fromJson(response['data'] as Map<String, dynamic>);
      emit(state.copyWith(
        messages: [...state.messages.where((m) => !m.id.startsWith('temp_')), realMessage],
      ));
    } catch (e) {
      debugPrint('❌ [ForumChat] Error sending message: $e');
      emit(state.copyWith(
        isError: true,
        errorMessage: 'Failed to send message: ${e.toString()}',
      ));
    }
  }

  /// Toggle reaction on a message
  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      await _apiClient.post(
        '/chat/messages/$messageId/react',
        body: {'reaction': emoji},
      );
      await loadMessages();
    } catch (e) {
      debugPrint('❌ [ForumChat] Error toggling reaction: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiClient.delete('/chat/messages/$messageId');

      final updatedMessages =
          state.messages.where((m) => m.id != messageId).toList();
      emit(state.copyWith(messages: updatedMessages));
    } catch (e) {
      debugPrint('❌ [ForumChat] Error deleting message: $e');
    }
  }
}
