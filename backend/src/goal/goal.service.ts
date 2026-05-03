import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UsageService } from '../usage/usage.service';
import { CreateGoalDto } from './dto/create-goal.dto';

@Injectable()
export class GoalService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly usageService: UsageService,
  ) {}

  async createGoal(dto: CreateGoalDto, userId: number, plan: string) {
    await this.usageService.checkGoalLimit(userId, plan);

    return this.prisma.goal.create({
      data: {
        content: dto.content,
        motivation: dto.motivation,
        deadline: dto.deadline ? new Date(dto.deadline) : undefined,
        userId,
      },
    });
  }

  async getGoals(userId: number) {
    return this.prisma.goal.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async deleteGoal(id: number, userId: number) {
    const goal = await this.prisma.goal.findUnique({ where: { id } });
    if (!goal) throw new NotFoundException('目標が見つかりません');
    if (goal.userId !== userId) throw new ForbiddenException('この目標を削除する権限がありません');
    return this.prisma.goal.delete({ where: { id } });
  }
}
