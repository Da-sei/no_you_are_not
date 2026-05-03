import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

export const FREE_MESSAGE_LIMIT = 10;
export const FREE_GOAL_LIMIT = 1;

@Injectable()
export class UsageService {
  constructor(private readonly prisma: PrismaService) {}

  async checkAndIncrementMessage(userId: number, plan: string): Promise<void> {
    if (plan === 'PRO') return;

    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;

    const usage = await this.prisma.monthlyUsage.upsert({
      where: { userId_year_month: { userId, year, month } },
      update: {},
      create: { userId, year, month, messageCount: 0 },
    });

    if (usage.messageCount >= FREE_MESSAGE_LIMIT) {
      throw new HttpException(
        {
          code: 'LIMIT_REACHED',
          limitType: 'messages',
          current: usage.messageCount,
          limit: FREE_MESSAGE_LIMIT,
        },
        HttpStatus.PAYMENT_REQUIRED,
      );
    }

    await this.prisma.monthlyUsage.update({
      where: { userId_year_month: { userId, year, month } },
      data: { messageCount: { increment: 1 } },
    });
  }

  async checkGoalLimit(userId: number, plan: string): Promise<void> {
    if (plan === 'PRO') return;

    const count = await this.prisma.goal.count({ where: { userId } });
    if (count >= FREE_GOAL_LIMIT) {
      throw new HttpException(
        {
          code: 'LIMIT_REACHED',
          limitType: 'goals',
          current: count,
          limit: FREE_GOAL_LIMIT,
        },
        HttpStatus.PAYMENT_REQUIRED,
      );
    }
  }

  async getMonthlyUsage(userId: number): Promise<{ messageCount: number; limit: number | null }> {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;

    const usage = await this.prisma.monthlyUsage.findUnique({
      where: { userId_year_month: { userId, year, month } },
    });

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const isPro = user?.plan === 'PRO';

    return {
      messageCount: usage?.messageCount ?? 0,
      limit: isPro ? null : FREE_MESSAGE_LIMIT,
    };
  }
}
