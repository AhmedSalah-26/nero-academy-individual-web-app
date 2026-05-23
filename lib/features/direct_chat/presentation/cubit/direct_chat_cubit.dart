import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/direct_message_model.dart';
import 'direct_chat_state.dart';

class DirectChatCubit extends Cubit<DirectChatState> {
  final ApiClient _apiClient;
  final String otherUserId;
  final String currentUserId;

  DirectChatCubit({
    required ApiClient apiClient,
    required this.currentUserId,
    required this.otherUserId,
  })  : _apiClient = apiClient,
        super(const DirectChatState());

  Future<void> loadMessages() async {
    try {
      emit(state.copyWith(isLoading: true, isError: false));

      final response = await _apiClient.get('/chat/direct/$otherUserId');
      final list = response['messages'] as List;
      final messages = list
          .map((json) => DirectMessageModel.fromJson(json as Map<String, dynamic>))
          .toList();

      emit(state.copyWith(
        isLoading: false,
        messages: messages,
      ));

      // Mark messages as read
      await markAllAsRead();
    } catch (e) {
      debugPrint('❌ [DirectChat] Error loading messages: $e');
      emit(state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> sendMessage(String text, {String? replyToId}) async {
    try {
      final payload = {
        'receiver_id': otherUserId,
        'message_text': text.trim(),
      };

      await _apiClient.post('/chat/direct', body: payload);

      // Reload for safety
      await loadMessages();
    } catch (e) {
      debugPrint('❌ [DirectChat] Error sending message: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _apiClient.delete('/chat/direct/$messageId');

      final updated = state.messages.where((m) => m.id != messageId).toList();
      emit(state.copyWith(messages: updated, forceUpdate: true));
    } catch (e) {
      debugPrint('❌ [DirectChat] Error deleting message: $e');
    }
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    try {
      await _apiClient.post(
        '/chat/direct/messages/$messageId/react',
        body: {'reaction': emoji},
      );
      await loadMessages();
    } catch (e) {
      debugPrint('❌ [DirectChat] Error toggling reaction: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post('/chat/direct/read/$otherUserId');
    } catch (e) {
      debugPrint('❌ [DirectChat] Error marking as read: $e');
    }
  }

}
