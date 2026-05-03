import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import 'user_provider.dart';

final planProvider = Provider<String>((ref) {
  final user = ref.watch(syncedUserProvider).valueOrNull;
  return user?['plan'] as String? ?? 'FREE';
});

// GET /users/me/usage → { messageCount, limit }
final messageUsageProvider = FutureProvider<({int count, int? limit})>((ref) async {
  await ref.watch(syncedUserProvider.future);
  final data = await ref.read(apiClientProvider).get('/users/me/usage') as Map<String, dynamic>;
  final count = data['messageCount'] as int;
  final limit = data['limit'] as int?;
  return (count: count, limit: limit);
});
