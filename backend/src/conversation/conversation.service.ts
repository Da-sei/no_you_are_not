import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateConversationDto } from './dto/create-conversation.dto';

@Injectable()
export class ConversationService {
  constructor(private readonly prisma: PrismaService) {}

  async createConversation(dto: CreateConversationDto, userId: number) {
    if (dto.goalId !== undefined) {
      const goal = await this.prisma.goal.findUnique({ where: { id: dto.goalId } });
      if (!goal || goal.userId !== userId) {
        throw new BadRequestException('指定された目標が見つかりません');
      }
    }

    return this.prisma.conversation.create({
      data: { userId, goalId: dto.goalId, title: dto.title },
    });
  }

  async getConversations(userId: number, archived?: boolean) {
    return this.prisma.conversation.findMany({
      where: {
        userId,
        ...(archived !== undefined ? { isArchived: archived } : {}),
      },
      orderBy: { updatedAt: 'desc' },
      include: { goal: true, _count: { select: { messages: true } } },
    });
  }

  async getConversation(id: number, userId: number) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id },
      include: { goal: true, messages: { orderBy: { createdAt: 'asc' } } },
    });
    if (!conversation) throw new NotFoundException('会話が見つかりません');
    if (conversation.userId !== userId) throw new ForbiddenException();
    return conversation;
  }

  async archiveConversation(id: number, archived: boolean, userId: number) {
    const conversation = await this.prisma.conversation.findUnique({ where: { id } });
    if (!conversation) throw new NotFoundException('会話が見つかりません');
    if (conversation.userId !== userId) throw new ForbiddenException();
    return this.prisma.conversation.update({ where: { id }, data: { isArchived: archived } });
  }

  async deleteConversation(id: number, userId: number) {
    const conversation = await this.prisma.conversation.findUnique({ where: { id } });
    if (!conversation) throw new NotFoundException('会話が見つかりません');
    if (conversation.userId !== userId) throw new ForbiddenException();
    return this.prisma.conversation.delete({ where: { id } });
  }
}
