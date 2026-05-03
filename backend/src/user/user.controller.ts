import { Controller, Get } from '@nestjs/common';
import { type AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { UsageService } from '../usage/usage.service';
import { UserService } from './user.service';

@Controller('users')
export class UserController {
  constructor(
    private readonly userService: UserService,
    private readonly usageService: UsageService,
  ) {}

  @Get('me')
  getMe(@CurrentUser() user: AuthUser) {
    return this.userService.getUser(user.id);
  }

  @Get('me/usage')
  getUsage(@CurrentUser() user: AuthUser) {
    return this.usageService.getMonthlyUsage(user.id);
  }
}
