import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../repositories/subscription_repository.dart';

/// プラットフォームに応じて支払い手段を切り替えるサービス。
/// iOS → Apple In-App Purchase
/// Android / Web / macOS → Stripe Checkout
class SubscriptionService {
  final SubscriptionRepository _repo;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  List<ProductDetails> _products = [];
  bool _initialized = false;

  // 購入完了コールバック（呼び出し元が結果を受け取るため）
  void Function(bool success, String? error)? onPurchaseResult;

  SubscriptionService(this._repo);

  bool get useIAP => !kIsWeb && Platform.isIOS;

  Future<void> initialize() async {
    if (_initialized || !useIAP) return;
    _initialized = true;

    final available = await _iap.isAvailable();
    if (!available) return;

    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onError: (e) => onPurchaseResult?.call(false, e.toString()),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails({AppConstants.appleProProductId});
    _products = response.productDetails;
    if (_products.isEmpty) {
      final notFound = response.notFoundIDs.join(', ');
      final err = response.error?.message ?? 'なし';
      debugPrint('[IAP] 商品が見つかりません。notFoundIDs=[$notFound] error=$err');
    }
  }

  /// PRO プランへのアップグレード。
  /// iOS: StoreKit、それ以外: Stripe Checkout URL を開く。
  Future<void> upgrade() async {
    if (useIAP) {
      await _buyWithIAP();
    } else {
      await _openStripeCheckout();
    }
  }

  /// サブスク管理（解約・変更）。
  /// iOS: App Store のサブスク管理ページ、それ以外: Stripe Portal。
  Future<void> manage() async {
    if (useIAP) {
      await launchUrl(
        Uri.parse('https://apps.apple.com/account/subscriptions'),
        mode: LaunchMode.externalApplication,
      );
    } else {
      await _openStripePortal();
    }
  }

  Future<void> _buyWithIAP() async {
    if (_products.isEmpty) {
      await _loadProducts();
    }
    if (_products.isEmpty) {
      onPurchaseResult?.call(false, '商品情報の取得に失敗しました');
      return;
    }
    final param = PurchaseParam(productDetails: _products.first);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> _openStripeCheckout() async {
    final url = await _repo.createCheckoutSession();
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _openStripePortal() async {
    final url = await _repo.createPortalSession();
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // バックエンドへ JWS トランザクションを送信して PRO を有効化
        try {
          final jws = purchase.verificationData.serverVerificationData;
          final originalTxId =
              (purchase as dynamic).skPaymentTransaction?.transactionIdentifier ??
              purchase.purchaseID ??
              '';
          await _repo.verifyApplePurchase(jws, originalTxId);
          await _iap.completePurchase(purchase);
          onPurchaseResult?.call(true, null);
        } catch (e) {
          onPurchaseResult?.call(false, e.toString());
        }
      } else if (purchase.status == PurchaseStatus.error) {
        onPurchaseResult?.call(false, purchase.error?.message);
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        onPurchaseResult?.call(false, null);
      }
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }
}
