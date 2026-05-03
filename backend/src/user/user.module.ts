import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { UsageModule } from '../usage/usage.module';
import { UserController } from './user.controller';
import { UserService } from './user.service';

@Module({
  imports: [PrismaModule, UsageModule],
  controllers: [UserController],
  providers: [UserService],
})
export class UserModule {}
