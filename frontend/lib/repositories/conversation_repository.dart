import '../models/conversation.dart';
import 'api_client.dart';

class ConversationRepository {
  final ApiClient _client;

  const ConversationRepository(this._client);

  Future<List<Conversation>> getConversations({bool? archived}) async {
    var path = '/conversations';
    if (archived != null) path += '?archived=$archived';
    final data = await _client.get(path) as List<dynamic>;
    return data
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> createConversation({int? goalId, String? title}) async {
    final data = await _client.post('/conversations', {
      'goalId': goalId,
      'title': title,
    });
    return Conversation.fromJson(data as Map<String, dynamic>);
  }

  Future<void> archiveConversation(int id, {bool archived = true}) =>
      _client.patch('/conversations/$id/archive', {'archived': archived});

  Future<void> deleteConversation(int id) =>
      _client.delete('/conversations/$id');
}
