import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { type AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { CreateGoalDto } from './dto/create-goal.dto';
import { GoalService } from './goal.service';

@Controller('goals')
export class GoalController {
  constructor(private readonly goalService: GoalService) {}

  @Post()
  createGoal(@Body() dto: CreateGoalDto, @CurrentUser() user: AuthUser) {
    return this.goalService.createGoal(dto, user.id, user.plan);
  }

  @Get()
  getGoals(@CurrentUser() user: AuthUser) {
    return this.goalService.getGoals(user.id);
  }

  @Delete(':id')
  deleteGoal(@Param('id', ParseIntPipe) id: number, @CurrentUser() user: AuthUser) {
    return this.goalService.deleteGoal(id, user.id);
  }
}
