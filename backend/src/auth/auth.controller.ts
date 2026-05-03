import { Controller, Post, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { CurrentUser, type FirebaseTokenUser } from './current-user.decorator';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { SkipDbLookup } from './skip-db-lookup.decorator';

@Controller('auth')
@UseGuards(FirebaseAuthGuard)
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('sync')
  @SkipDbLookup()
  sync(@CurrentUser() user: FirebaseTokenUser) {
    return this.authService.syncUser(user.firebaseUid, user.email, user.name);
  }
}
