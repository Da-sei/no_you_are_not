import 'api_client.dart';

class UserRepository {
  final ApiClient _client;

  const UserRepository(this._client);

  Future<Map<String, dynamic>> syncUser() async {
    final data = await _client.post('/auth/sync', {});
    return data as Map<String, dynamic>;
  }
}
