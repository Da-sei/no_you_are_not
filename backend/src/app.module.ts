import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import * as admin from 'firebase-admin';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { FirebaseAuthGuard } from './auth/firebase-auth.guard';
import { ConversationModule } from './conversation/conversation.module';
import { GoalModule } from './goal/goal.module';
import { MessageModule } from './message/message.module';
import { SubscriptionModule } from './subscription/subscription.module';
import { UserModule } from './user/user.module';

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
admin.initializeApp({
  credential: serviceAccountJson
    ? admin.credential.cert(JSON.parse(serviceAccountJson) as admin.ServiceAccount)
    : admin.credential.applicationDefault(),
  projectId: process.env.FIREBASE_PROJECT_ID,
});

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    UserModule,
    GoalModule,
    ConversationModule,
    MessageModule,
    SubscriptionModule,
  ],
  providers: [
    FirebaseAuthGuard,
    {
      provide: APP_GUARD,
      useClass: FirebaseAuthGuard,
    },
  ],
})
export class AppModule {}
