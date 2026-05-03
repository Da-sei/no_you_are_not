import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../repositories/api_client.dart';
import '../repositories/conversation_repository.dart';
import '../repositories/goal_repository.dart';
import '../repositories/message_repository.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/user_repository.dart';

final apiClientProvider = Provider<ApiClient>((_) {
  return ApiClient(
    baseUrl: AppConstants.baseUrl,
    getToken: () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return user.getIdToken();
    },
  );
});

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(apiClientProvider)),
);

final goalRepositoryProvider = Provider<GoalRepository>(
  (ref) => GoalRepository(ref.watch(apiClientProvider)),
);

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(ref.watch(apiClientProvider)),
);

final messageRepositoryProvider = Provider<MessageRepository>(
  (ref) => MessageRepository(ref.watch(apiClientProvider)),
);

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(ref.watch(apiClientProvider)),
);

// SubscriptionService は初期化が必要なため StateNotifier ではなく手動管理
// PaywallSheet / SettingsScreen から ref.read(subscriptionRepositoryProvider) を
// SubscriptionService に渡して使う（Provider にするとライフサイクル管理が複雑になるため直接生成）
