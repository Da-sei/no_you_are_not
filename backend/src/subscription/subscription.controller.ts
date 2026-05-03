import {
  Body,
  Controller,
  Headers,
  HttpCode,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { IsNotEmpty, IsString } from 'class-validator';
import { type AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { SkipAuth } from '../auth/skip-auth.decorator';
import { SubscriptionService } from './subscription.service';

class AppleVerifyDto {
  @IsString()
  @IsNotEmpty()
  jwsTransaction: string;

  @IsString()
  @IsNotEmpty()
  originalTransactionId: string;
}

@Controller('subscription')
export class SubscriptionController {
  constructor(private readonly subscriptionService: SubscriptionService) {}

  // Stripe: Checkout Session
  @Post('checkout')
  @UseGuards(FirebaseAuthGuard)
  async createCheckout(@CurrentUser() user: AuthUser): Promise<{ url: string }> {
    const url = await this.subscriptionService.createCheckoutSession(user.id, user.email);
    return { url };
  }

  // Stripe: Customer Portal
  @Post('portal')
  @UseGuards(FirebaseAuthGuard)
  async createPortal(@CurrentUser() user: AuthUser): Promise<{ url: string }> {
    const url = await this.subscriptionService.createPortalSession(user.id);
    return { url };
  }

  // Stripe: Webhook
  @Post('webhook')
  @SkipAuth()
  @HttpCode(200)
  async stripeWebhook(
    @Req() req: any,
    @Headers('stripe-signature') signature: string,
  ): Promise<void> {
    await this.subscriptionService.handleWebhook(req.rawBody!, signature);
  }

  // Apple IAP: トランザクション検証 → PRO 有効化
  @Post('apple/verify')
  @UseGuards(FirebaseAuthGuard)
  @HttpCode(200)
  async appleVerify(
    @Body() dto: AppleVerifyDto,
    @CurrentUser() user: AuthUser,
  ): Promise<void> {
    await this.subscriptionService.verifyApplePurchase(
      user.id,
      dto.jwsTransaction,
      dto.originalTransactionId,
    );
  }

  // Apple: サーバー通知（App Store Server Notifications V2）
  @Post('apple/notify')
  @SkipAuth()
  @HttpCode(200)
  async appleNotify(@Body('signedPayload') signedPayload: string): Promise<void> {
    if (signedPayload) {
      await this.subscriptionService.handleAppleNotification(signedPayload);
    }
  }
}
