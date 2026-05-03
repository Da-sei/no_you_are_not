import 'api_client.dart';

class SubscriptionRepository {
  final ApiClient _client;

  const SubscriptionRepository(this._client);

  Future<String> createCheckoutSession() async {
    final data = await _client.post('/subscription/checkout', {});
    return (data as Map<String, dynamic>)['url'] as String;
  }

  Future<String> createPortalSession() async {
    final data = await _client.post('/subscription/portal', {});
    return (data as Map<String, dynamic>)['url'] as String;
  }

  // iOS IAP: JWS トランザクションをバックエンドで検証して PRO を有効化
  Future<void> verifyApplePurchase(
    String jwsTransaction,
    String originalTransactionId,
  ) async {
    await _client.post('/subscription/apple/verify', {
      'jwsTransaction': jwsTransaction,
      'originalTransactionId': originalTransactionId,
    });
  }
}
