import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import * as admin from 'firebase-admin';
import { PrismaService } from '../../prisma/prisma.service';
import { SKIP_AUTH_KEY } from './skip-auth.decorator';
import { SKIP_DB_LOOKUP_KEY } from './skip-db-lookup.decorator';

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const skipAuth = this.reflector.getAllAndOverride<boolean>(
      SKIP_AUTH_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (skipAuth) return true;

    const request = context.switchToHttp().getRequest<Record<string, any>>();
    const token = this.extractToken(request);
    if (!token) throw new UnauthorizedException('認証トークンが必要です');

    let decoded: admin.auth.DecodedIdToken;
    try {
      decoded = await admin.auth().verifyIdToken(token);
    } catch {
      throw new UnauthorizedException('無効な認証トークンです');
    }

    const skipDbLookup = this.reflector.getAllAndOverride<boolean>(
      SKIP_DB_LOOKUP_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (skipDbLookup) {
      request.user = {
        firebaseUid: decoded.uid,
        email: decoded.email ?? '',
        name: decoded.name as string | undefined,
      };
    } else {
      const user = await this.prisma.user.findUnique({
        where: { firebaseUid: decoded.uid },
      });
      if (!user) {
        throw new UnauthorizedException(
          'ユーザーが見つかりません。再ログインしてください。',
        );
      }
      request.user = user;
    }

    return true;
  }

  private extractToken(request: Record<string, any>): string | null {
    const auth = request.headers?.['authorization'] as string | undefined;
    if (!auth?.startsWith('Bearer ')) return null;
    return auth.slice(7);
  }
}
