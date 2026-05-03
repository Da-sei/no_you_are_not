import '../models/goal.dart';
import 'api_client.dart';

class GoalRepository {
  final ApiClient _client;

  const GoalRepository(this._client);

  Future<List<Goal>> getGoals() async {
    final data = await _client.get('/goals') as List<dynamic>;
    return data.map((e) => Goal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Goal> createGoal({
    required String content,
    String? motivation,
    DateTime? deadline,
  }) async {
    final data = await _client.post('/goals', {
      'content': content,
      'motivation': motivation,
      'deadline': deadline?.toIso8601String(),
    });
    return Goal.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteGoal(int id) => _client.delete('/goals/$id');
}
