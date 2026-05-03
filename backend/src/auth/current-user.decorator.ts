import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export type AuthUser = {
  id: number;
  firebaseUid: string;
  email: string;
  name: string;
  plan: 'FREE' | 'PRO';
  subscriptionId: string | null;
  subscriptionExpiry: Date | null;
  createdAt: Date;
};

export type FirebaseTokenUser = { firebaseUid: string; email: string; name?: string };

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthUser | FirebaseTokenUser => {
    return ctx.switchToHttp().getRequest().user;
  },
);
