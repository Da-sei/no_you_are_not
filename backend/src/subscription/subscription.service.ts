import { BadRequestException, Injectable, InternalServerErrorException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
// eslint-disable-next-line @typescript-eslint/no-require-imports
const StripeLib = require('stripe');

@Injectable()
export class SubscriptionService {
  private readonly stripe: any;

  constructor(private readonly prisma: PrismaService) {
    this.stripe = new StripeLib(process.env.STRIPE_SECRET_KEY ?? '', {
      apiVersion: '2026-04-22.dahlia',
    });
  }

  // ── Checkout Session ────────────────────────────────────────────────────────

  async createCheckoutSession(userId: number, email: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('ユーザーが見つかりません');

    let customerId: string | undefined = user.stripeCustomerId ?? undefined;
    if (!customerId) {
      const customer = await this.stripe.customers.create({
        email,
        metadata: { userId: String(userId) },
      });
      customerId = customer.id as string;
      await this.prisma.user.update({
        where: { id: userId },
        data: { stripeCustomerId: customerId },
      });
    }

    const session = await this.stripe.checkout.sessions.create({
      mode: 'subscription',
      customer: customerId,
      line_items: [{ price: process.env.STRIPE_PRICE_ID!, quantity: 1 }],
      success_url: process.env.STRIPE_SUCCESS_URL ?? 'https://example.com/success',
      cancel_url: process.env.STRIPE_CANCEL_URL ?? 'https://example.com/cancel',
      metadata: { userId: String(userId) },
    });

    if (!session.url) throw new InternalServerErrorException('Checkout URL の生成に失敗しました');
    return session.url as string;
  }

  // ── Customer Portal ─────────────────────────────────────────────────────────

  async createPortalSession(userId: number): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.stripeCustomerId) throw new NotFoundException('サブスクリプション情報が見つかりません');

    const session = await this.stripe.billingPortal.sessions.create({
      customer: user.stripeCustomerId,
      return_url: process.env.STRIPE_CANCEL_URL ?? 'https://example.com',
    });

    return session.url as string;
  }

  // ── Webhook ─────────────────────────────────────────────────────────────────

  async handleWebhook(rawBody: Buffer, signature: string): Promise<void> {
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!webhookSecret) throw new InternalServerErrorException('Webhook secret が未設定です');

    let event: any;
    try {
      event = this.stripe.webhooks.constructEvent(rawBody, signature, webhookSecret);
    } catch {
      throw new InternalServerErrorException('Webhook 署名の検証に失敗しました');
    }

    switch (event.type) {
      case 'checkout.session.completed':
        await this.onCheckoutCompleted(event.data.object);
        break;
      case 'customer.subscription.updated':
        await this.onSubscriptionUpdated(event.data.object);
        break;
      case 'customer.subscription.deleted':
        await this.onSubscriptionDeleted(event.data.object);
        break;
    }
  }

  // ── Private Event Handlers ──────────────────────────────────────────────────

  private async onCheckoutCompleted(session: any) {
    const userId = session.metadata?.userId ? parseInt(session.metadata.userId as string) : null;
    if (!userId) return;

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        plan: 'PRO',
        subscriptionId: session.subscription as string,
        stripeCustomerId: session.customer as string,
        subscriptionExpiry: null,
      },
    });
  }

  private async onSubscriptionUpdated(subscription: any) {
    const isActive = ['active', 'trialing'].includes(subscription.status as string);
    const user = await this.prisma.user.findFirst({
      where: { subscriptionId: subscription.id as string },
    });
    if (!user) return;

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        plan: isActive ? 'PRO' : 'FREE',
        subscriptionExpiry: isActive
          ? null
          : new Date((subscription.current_period_end as number) * 1000),
      },
    });
  }

  private async onSubscriptionDeleted(subscription: any) {
    const user = await this.prisma.user.findFirst({
      where: { subscriptionId: subscription.id as string },
    });
    if (!user) return;

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        plan: 'FREE',
        subscriptionId: null,
        subscriptionExpiry: new Date((subscription.current_period_end as number) * 1000),
      },
    });
  }

  // ── Apple IAP ────────────────────────────────────────────────────────────────

  /**
   * StoreKit 2 の JWS トランザクションを受け取り PRO を有効化する。
   * iOS クライアントが purchase 完了後に呼び出す。
   */
  async verifyApplePurchase(
    userId: number,
    jwsTransaction: string,
    originalTransactionId: string,
  ): Promise<void> {
    if (!jwsTransaction || !originalTransactionId) {
      throw new BadRequestException('トランザクション情報が不足しています');
    }

    // JWS のペイロード部分を Base64 デコードしてトランザクション情報を取得
    const payload = this.decodeJwsPayload(jwsTransaction);
    const productId: string = (payload?.productId as string | undefined) ?? '';

    if (!productId) throw new BadRequestException('無効なトランザクションです');

    // プロダクト ID が PRO サブスクリプション用であることを確認
    const proPriceIds = (process.env.APPLE_PRODUCT_IDS ?? '').split(',').map((s: string) => s.trim());
    if (proPriceIds.length > 0 && proPriceIds[0] !== '' && !proPriceIds.includes(productId)) {
      throw new BadRequestException('対象外のプロダクトです');
    }

    // App Store Server API で追加検証（オプション: API キーが設定されている場合のみ）
    if (process.env.APPLE_KEY_ID && process.env.APPLE_ISSUER_ID && process.env.APPLE_PRIVATE_KEY) {
      await this.verifyWithAppStoreApi(originalTransactionId);
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        plan: 'PRO',
        appleOriginalTransactionId: originalTransactionId,
        subscriptionExpiry: null,
      },
    });
  }

  /**
   * Apple サーバー通知（App Store Server Notifications V2）を処理する。
   * App Store Connect の「サーバ通知 URL」に `POST /subscription/apple/notify` を設定する。
   */
  async handleAppleNotification(signedPayload: string): Promise<void> {
    const payload = this.decodeJwsPayload(signedPayload);
    if (!payload) return;

    const notificationType: string = (payload.notificationType as string | undefined) ?? '';
    const data = payload.data as Record<string, unknown> | undefined;
    const transactionInfo = data?.signedTransactionInfo
      ? this.decodeJwsPayload(data.signedTransactionInfo as string)
      : null;

    const originalTransactionId: string =
      (transactionInfo?.originalTransactionId as string | undefined) ??
      (data?.originalTransactionId as string | undefined) ?? '';
    if (!originalTransactionId) return;

    const user = await this.prisma.user.findFirst({
      where: { appleOriginalTransactionId: originalTransactionId },
    });
    if (!user) return;

    switch (notificationType) {
      case 'DID_RENEW':
      case 'SUBSCRIBED':
        await this.prisma.user.update({
          where: { id: user.id },
          data: { plan: 'PRO', subscriptionExpiry: null },
        });
        break;
      case 'EXPIRED':
      case 'REVOKE':
      case 'REFUND':
        await this.prisma.user.update({
          where: { id: user.id },
          data: { plan: 'FREE', appleOriginalTransactionId: null },
        });
        break;
    }
  }

  private decodeJwsPayload(jws: string): Record<string, unknown> | null {
    try {
      const parts = jws.split('.');
      if (parts.length < 2) return null;
      const json = Buffer.from(parts[1], 'base64url').toString('utf8');
      return JSON.parse(json) as Record<string, unknown>;
    } catch {
      return null;
    }
  }

  private async verifyWithAppStoreApi(originalTransactionId: string): Promise<void> {
    const { createSign } = await import('crypto');
    const now = Math.floor(Date.now() / 1000);
    const header = Buffer.from(JSON.stringify({ alg: 'ES256', kid: process.env.APPLE_KEY_ID })).toString('base64url');
    const body = Buffer.from(JSON.stringify({
      iss: process.env.APPLE_ISSUER_ID,
      iat: now,
      exp: now + 300,
      aud: 'appstoreconnect-v1',
      bid: process.env.APPLE_BUNDLE_ID,
    })).toString('base64url');
    const signingInput = `${header}.${body}`;
    const sign = createSign('SHA256');
    sign.update(signingInput);
    const sig = sign.sign(
      { key: process.env.APPLE_PRIVATE_KEY!.replace(/\\n/g, '\n'), dsaEncoding: 'ieee-p1363' },
    ).toString('base64url');
    const jwt = `${signingInput}.${sig}`;

    const isSandbox = process.env.NODE_ENV !== 'production';
    const baseUrl = isSandbox
      ? 'https://api.storekit-sandbox.itunes.apple.com'
      : 'https://api.storekit.itunes.apple.com';

    const res = await fetch(`${baseUrl}/inApps/v1/transactions/${originalTransactionId}`, {
      headers: { Authorization: `Bearer ${jwt}` },
    });

    if (!res.ok) throw new BadRequestException('Apple によるトランザクション検証に失敗しました');
  }
}
