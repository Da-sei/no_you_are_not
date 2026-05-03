import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { UsageModule } from '../usage/usage.module';
import { MessageController } from './message.controller';
import { MessageService } from './message.service';

@Module({
  imports: [PrismaModule, UsageModule],
  controllers: [MessageController],
  providers: [MessageService],
})
export class MessageModule {}
