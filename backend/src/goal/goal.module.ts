import { Module } from '@nestjs/common';
import { PrismaModule } from '../../prisma/prisma.module';
import { UsageModule } from '../usage/usage.module';
import { GoalController } from './goal.controller';
import { GoalService } from './goal.service';

@Module({
  imports: [PrismaModule, UsageModule],
  controllers: [GoalController],
  providers: [GoalService],
})
export class GoalModule {}
