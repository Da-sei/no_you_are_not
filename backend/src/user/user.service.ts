import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class UserService {
  constructor(private readonly prisma: PrismaService) {}

  async getUser(id: number) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        goals: { orderBy: { createdAt: 'desc' } },
        _count: { select: { conversations: true } },
      },
    });
    if (!user) throw new NotFoundException('ユーザーが見つかりません');
    return user;
  }
}
