import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import 'repository_providers.dart';

// Calls POST /auth/sync and returns the DB user map after Firebase login.
final syncedUserProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final firebaseUser = ref.watch(authStateProvider).valueOrNull;
  if (firebaseUser == null) return null;
  return ref.read(userRepositoryProvider).syncUser();
});
