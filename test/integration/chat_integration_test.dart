import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lms_platform/core/network/api_client.dart';
import 'package:lms_platform/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:lms_platform/features/auth/domain/entities/user_entity.dart';
import 'package:lms_platform/features/direct_chat/presentation/cubit/direct_chat_cubit.dart';
import 'package:lms_platform/features/course_forum/presentation/cubit/forum_chat_cubit.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('DirectChat and ForumChat Cubits integration tests with Laravel backend', () async {
    final apiClient = ApiClient();
    await apiClient.init();

    final authDataSource = AuthRemoteDataSourceImpl(apiClient);

    final uniqueId = DateTime.now().millisecondsSinceEpoch;

    // 1. Register Student A
    print('🔄 Registering Student A...');
    final studentA = await authDataSource.register(
      email: 'student_a_$uniqueId@example.com',
      password: 'secret123',
      name: 'Student A $uniqueId',
      role: UserRole.student,
    );
    expect(studentA, isNotNull);
    final studentAId = studentA.id;
    print('✅ Student A registered.');

    // 2. Register Student B (Wait, we need to register Student B to chat with, but register auto-sets token to Student B)
    print('🔄 Registering Student B...');
    final studentB = await authDataSource.register(
      email: 'student_b_$uniqueId@example.com',
      password: 'secret123',
      name: 'Student B $uniqueId',
      role: UserRole.student,
    );
    expect(studentB, isNotNull);
    final studentBId = studentB.id;
    print('✅ Student B registered.');

    // Currently logged in as Student B. Let's switch back to Student A by logging in.
    print('🔄 Logging back in as Student A...');
    final loggedInA = await authDataSource.login(
      email: 'student_a_$uniqueId@example.com',
      password: 'secret123',
    );
    expect(loggedInA, isNotNull);
    print('✅ Logged in as Student A.');

    // Create DirectChatCubit for Student A talking to Student B
    final directChatCubit = DirectChatCubit(
      apiClient: apiClient,
      currentUserId: studentAId,
      otherUserId: studentBId,
    );

    // 3. Test Direct Chat: Send Message
    print('🔄 Sending direct message...');
    await directChatCubit.sendMessage('Hello Student B! How are you?');
    expect(directChatCubit.state.messages, isNotEmpty);
    final directMsg = directChatCubit.state.messages.first;
    expect(directMsg.messageText, equals('Hello Student B! How are you?'));
    expect(directMsg.senderId, equals(studentAId));
    print('✅ Direct message sent and loaded.');

    // 4. Test Direct Chat: Toggle Reaction
    print('🔄 Toggling reaction on direct message...');
    await directChatCubit.toggleReaction(directMsg.id, '❤️');
    expect(directChatCubit.state.messages.first.reactions, isNotEmpty);
    expect(directChatCubit.state.messages.first.reactions.first.reaction, equals('❤️'));
    print('✅ Direct message reaction verified.');

    // 5. Test Direct Chat: Delete Message
    print('🔄 Deleting direct message...');
    await directChatCubit.deleteMessage(directMsg.id);
    expect(directChatCubit.state.messages, isEmpty);
    print('✅ Direct message deleted.');

    // 6. Test Forum Chat: Create Conversation (via manual ApiClient post since group creation is in dashboard/admin)
    print('🔄 Creating conversation group...');
    final conversationResponse = await apiClient.post(
      '/chat/conversations',
      body: {
        'type': 'multi',
        'title': 'Test Group $uniqueId',
        'participant_ids': [studentAId, studentBId],
      },
    );
    expect(conversationResponse['success'], isTrue);
    final conversationId = conversationResponse['conversation']['id'] as String;
    print('✅ Conversation created with ID: $conversationId');

    // Create ForumChatCubit for Student A in this conversation group
    final forumChatCubit = ForumChatCubit(
      apiClient: apiClient,
      conversationId: conversationId,
      currentUserId: studentAId,
    );

    // 7. Test Forum Chat: Load Messages (should be empty initially)
    print('🔄 Loading group messages...');
    await forumChatCubit.loadMessages();
    expect(forumChatCubit.state.messages, isEmpty);

    // 8. Test Forum Chat: Send Message
    print('🔄 Sending group message...');
    await forumChatCubit.sendMessage('Hello Group!');
    expect(forumChatCubit.state.messages, isNotEmpty);
    final groupMsg = forumChatCubit.state.messages.first;
    expect(groupMsg.messageText, equals('Hello Group!'));
    print('✅ Group message sent.');

    // 9. Test Forum Chat: Toggle Reaction
    print('🔄 Toggling reaction on group message...');
    await forumChatCubit.toggleReaction(groupMsg.id, '👍');
    await forumChatCubit.loadMessages();
    expect(forumChatCubit.state.messages.first.reactions, isNotEmpty);
    expect(forumChatCubit.state.messages.first.reactions.first.reaction, equals('👍'));
    print('✅ Group message reaction verified.');

    // 10. Test Forum Chat: Delete Message
    print('🔄 Deleting group message...');
    await forumChatCubit.deleteMessage(groupMsg.id);
    expect(forumChatCubit.state.messages, isEmpty);
    print('✅ Group message deleted.');
  });
}
