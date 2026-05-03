# 本番リリース前チェックリスト

## 1. フロントエンド (`frontend/lib/constants/app_constants.dart`)

| 項目 | 現在の値 | 本番で設定すべき値 |
|------|---------|-----------------|
| `baseUrl` | `http://localhost:3000` | 本番バックエンドのURL（例: `https://api.yourapp.com`） |
| `privacyPolicyUrl` | `https://your-privacy-policy-url.com` | 実際のプライバシーポリシーURL |
| `appleProProductId` | `com.yourname.noYouAreNot.premium.monthly` | App Store Connect に登録した正式な商品ID |

---

## 2. バックエンド (`backend/.env`)

| 環境変数 | 現在の値 | 対応内容 |
|---------|---------|---------|
| `STRIPE_PRICE_ID` | `prod_URVPsGSuV9ASUb` | **Product IDではなくPrice IDを設定する**（`price_` で始まる値）。Stripe ダッシュボード → Products → 該当商品 → Pricing で確認 |
| `STRIPE_SECRET_KEY` | テスト用キー (`sk_test_...`) | 本番用キー (`sk_live_...`) に差し替え |
| `STRIPE_WEBHOOK_SECRET` | テスト用シークレット | 本番Webhookのシークレットに差し替え |
| `STRIPE_SUCCESS_URL` | `nyan://subscription/success` | 本番アプリのディープリンクスキームに合わせて確認・修正 |
| `STRIPE_CANCEL_URL` | `nyan://subscription/cancel` | 同上 |
| `APPLE_BUNDLE_ID` | `com.yourname.noYouAreNot` | Xcode / App Store Connect の Bundle ID と一致しているか確認 |
| `APPLE_PRODUCT_IDS` | `com.yourname.noYouAreNot.premium.monthly` | App Store Connect に登録した正式な商品ID |
| `APPLE_PRIVATE_KEY` | `YOUR_PRIVATE_KEY`（プレースホルダー） | App Store Connect で発行したサブスクリプション用秘密鍵を設定（App Store Server API を使う場合） |

---

## 3. App Store Connect

- [ ] サブスクリプション商品 (`com.yourname.noYouAreNot.premium.monthly`) のステータスを **「審査待ち」以上** にする
  - 「作成済み」のままでは実機でも商品情報を取得できない
- [ ] アプリの Bundle ID が `com.yourname.noYouAreNot` で登録されているか確認
- [ ] サブスクリプショングループが作成・設定されているか確認
- [ ] 価格設定（¥980/月）が正しく設定されているか確認

---

## 4. Stripe ダッシュボード

- [ ] 本番モードの Webhook エンドポイントに `POST /subscription/webhook` を登録する
- [ ] Webhook で購読するイベントを確認:
  - `checkout.session.completed`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
- [ ] 本番用 Price ID（`price_` で始まる）を `STRIPE_PRICE_ID` に設定

---

## 5. iOS スキーム（テスト設定の除去）

`ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` の `LaunchAction` にある StoreKit 設定はシミュレーターテスト用。

本番ビルド（Archive）には影響しないが、本番リリース前に設定を確認する:

```xml
<!-- この行はシミュレーターテスト用。本番Archiveには影響しないが念のため確認 -->
<StoreKitConfigurationFileReference
   identifier = "Configuration.storekit">
</StoreKitConfigurationFileReference>
```

`ios/Configuration.storekit` はテスト専用ファイルのため、App Store への提出には含めない（Archiveターゲットには含まれないため通常は問題なし）。

---

## 6. 本番リリース時のディープリンクスキーム確認

`STRIPE_SUCCESS_URL` / `STRIPE_CANCEL_URL` に使っている `nyan://` スキームが、Xcode の **Info.plist** に URL Scheme として登録されているか確認する。
