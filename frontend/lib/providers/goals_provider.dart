import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import 'repository_providers.dart';
import 'user_provider.dart';

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    await ref.watch(syncedUserProvider.future);
    return ref.read(goalRepositoryProvider).getGoals();
  }

  Future<void> createGoal({
    required String content,
    String? motivation,
    DateTime? deadline,
  }) async {
    await ref.read(goalRepositoryProvider).createGoal(
          content: content,
          motivation: motivation,
          deadline: deadline,
        );
    ref.invalidateSelf();
  }

  Future<void> deleteGoal(int id) async {
    await ref.read(goalRepositoryProvider).deleteGoal(id);
    ref.invalidateSelf();
  }
}

final goalsProvider =
    AsyncNotifierProvider<GoalsNotifier, List<Goal>>(GoalsNotifier.new);
