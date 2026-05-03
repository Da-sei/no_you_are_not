import '../models/message.dart';
import 'api_client.dart';

class MessageRepository {
  final ApiClient _client;

  const MessageRepository(this._client);

  Future<List<Message>> getMessages(int conversationId) async {
    final data = await _client
        .get('/conversations/$conversationId/messages') as List<dynamic>;
    return data
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // バックエンドはユーザーメッセージを保存後 OpenAI を呼び出し、
  // アシスタントのレスポンスを返す
  Future<Message> sendMessage(int conversationId, String content) async {
    final data = await _client.post(
      '/conversations/$conversationId/messages',
      {'content': content},
    ) as Map<String, dynamic>;
    return Message.fromJson(data['aiMessage'] as Map<String, dynamic>);
  }
}
