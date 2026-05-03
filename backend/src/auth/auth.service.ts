import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(private readonly prisma: PrismaService) {}

  async syncUser(firebaseUid: string, email: string, name?: string) {
    return this.prisma.user.upsert({
      where: { firebaseUid },
      update: { email },
      create: {
        firebaseUid,
        email,
        name: name ?? email.split('@')[0],
      },
    });
  }
}
