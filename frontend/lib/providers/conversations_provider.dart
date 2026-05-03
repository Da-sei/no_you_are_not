import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation.dart';
import 'repository_providers.dart';
import 'user_provider.dart';

class ArchivedConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    await ref.watch(syncedUserProvider.future);
    return ref
        .read(conversationRepositoryProvider)
        .getConversations(archived: true);
  }
}

final archivedConversationsProvider =
    AsyncNotifierProvider<ArchivedConversationsNotifier, List<Conversation>>(
        ArchivedConversationsNotifier.new);
