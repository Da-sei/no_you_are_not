import { ForbiddenException, Injectable, InternalServerErrorException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UsageService } from '../usage/usage.service';
import { CreateMessageDto } from './dto/create-message.dto';
import OpenAI from 'openai';

type GoalInfo = { content: string; motivation: string | null; deadline: Date | null } | null;
type PastExcuse = { messages: { content: string }[] };
type ChatMessage = { role: 'user' | 'assistant'; content: string };

@Injectable()
export class MessageService {
  private readonly openai: OpenAI;

  constructor(
    private readonly prisma: PrismaService,
    private readonly usageService: UsageService,
  ) {
    this.openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  }

  async sendMessage(conversationId: number, dto: CreateMessageDto, userId: number, plan: string) {
    await this.usageService.checkAndIncrementMessage(userId, plan);

    const [conversation, pastExcuses] = await Promise.all([
      this.prisma.conversation.findUnique({
        where: { id: conversationId },
        include: {
          goal: true,
          messages: { orderBy: { createdAt: 'asc' } },
        },
      }),
      this.prisma.conversation.findMany({
        where: { userId, isArchived: true },
        include: {
          messages: {
            where: { role: 'user' },
            orderBy: { createdAt: 'asc' },
            take: 1,
          },
        },
        take: 5,
        orderBy: { updatedAt: 'desc' },
      }),
    ]);

    if (!conversation) throw new NotFoundException('会話が見つかりません');
    if (conversation.userId !== userId) throw new ForbiddenException();

    const userMessage = await this.prisma.message.create({
      data: { conversationId, role: 'user' as const, content: dto.content },
    });

    const systemPrompt = this.buildSystemPrompt(conversation.goal, pastExcuses);
    const history = await this.buildHistory(conversation.messages);

    let aiContent: string;
    try {
      const completion = await this.openai.chat.completions.create({
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: systemPrompt },
          ...history,
          { role: 'user', content: dto.content },
        ],
      });
      aiContent = completion.choices[0].message.content ?? '';
    } catch {
      await this.prisma.message.delete({ where: { id: userMessage.id } });
      const now = new Date();
      await this.prisma.monthlyUsage.update({
        where: {
          userId_year_month: {
            userId,
            year: now.getFullYear(),
            month: now.getMonth() + 1,
          },
        },
        data: { messageCount: { decrement: 1 } },
      });
      throw new InternalServerErrorException('AI応答の取得に失敗しました。しばらく経ってから再試行してください。');
    }

    const aiMessage = await this.prisma.message.create({
      data: { conversationId, role: 'assistant' as const, content: aiContent },
    });

    await this.prisma.conversation.update({
      where: { id: conversationId },
      data: { updatedAt: new Date() },
    });

    return { userMessage, aiMessage };
  }

  async getMessages(conversationId: number, userId: number) {
    const conversation = await this.prisma.conversation.findUnique({
      where: { id: conversationId },
    });
    if (!conversation) throw new NotFoundException('会話が見つかりません');
    if (conversation.userId !== userId) throw new ForbiddenException();

    return this.prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
    });
  }

  // 10メッセージ超の会話は古い部分を要約して渡す。要約失敗時は全履歴にフォールバック。
  private async buildHistory(messages: { role: string; content: string }[]): Promise<ChatMessage[]> {
    const RECENT_LIMIT = 10;
    if (messages.length <= RECENT_LIMIT) {
      return messages.map((m) => ({ role: m.role as 'user' | 'assistant', content: m.content }));
    }

    const oldMessages = messages.slice(0, messages.length - RECENT_LIMIT);
    const recentMessages = messages.slice(messages.length - RECENT_LIMIT);

    try {
      const summaryCompletion = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: 'ユーザーとAIコーチの会話を3行以内で要約してください。ユーザーの言い訳とAIが指摘した矛盾の要点を簡潔に。',
          },
          {
            role: 'user',
            content: oldMessages
              .map((m) => `${m.role === 'user' ? 'ユーザー' : 'AI'}: ${m.content}`)
              .join('\n'),
          },
        ],
        max_tokens: 200,
      });
      const summary = summaryCompletion.choices[0].message.content ?? '';

      return [
        { role: 'user', content: `[これまでの会話の要約]\n${summary}` },
        { role: 'assistant', content: '了解。続けます。' },
        ...recentMessages.map((m) => ({ role: m.role as 'user' | 'assistant', content: m.content })),
      ];
    } catch {
      return messages.map((m) => ({ role: m.role as 'user' | 'assistant', content: m.content }));
    }
  }

  private buildSystemPrompt(goal: GoalInfo, pastExcuses: PastExcuse[]): string {
    // 改善1: 期限の残り日数を動的に算出して緊急度を伝える
    let goalSection: string;
    if (goal) {
      let deadlineText: string;
      if (goal.deadline) {
        const daysLeft = Math.ceil((goal.deadline.getTime() - Date.now()) / 86400000);
        if (daysLeft < 0) {
          deadlineText = `期限はすでに${Math.abs(daysLeft)}日前に過ぎています。今すぐ行動しなければ手遅れです。`;
        } else if (daysLeft === 0) {
          deadlineText = '期限は本日です。今日が最後のチャンスです。';
        } else if (daysLeft <= 7) {
          deadlineText = `期限まで残り${daysLeft}日です。非常に切迫しています。`;
        } else if (daysLeft <= 30) {
          deadlineText = `期限まで残り${daysLeft}日です。余裕はありません。`;
        } else {
          deadlineText = `期限まで残り${daysLeft}日です。`;
        }
      } else {
        deadlineText = '期限：未設定';
      }

      goalSection = `ユーザーの目標：${goal.content}\n動機：${goal.motivation ?? '未設定'}\n${deadlineText}`;
    } else {
      goalSection = 'ユーザーはまだ目標を設定していません。まず目標を設定するよう促してください。';
    }

    // 改善2: 過去のアーカイブ済み言い訳をプロンプトに注入する
    const validExcuses = pastExcuses.filter((c) => c.messages.length > 0);
    const pastExcusesSection =
      validExcuses.length > 0
        ? `\n【ユーザーの過去の甘えパターン（アーカイブ済み）】\n${validExcuses
            .map((c, i) => `${i + 1}. ${c.messages[0].content}`)
            .join('\n')}\n※同様のパターンが見られた場合は「またこの言い訳か」と明示的に指摘してください。`
        : '';

    return `あなたは「NO, YOU ARE NOT」というセルフマネジメントアプリのAIコーチです。
ユーザーの甘えや言い訳に対し、クリティカルシンキングで論理的に反論し、目標達成を最短距離でサポートします。

${goalSection}${pastExcusesSection}

【行動指針】
- ソクラテス式問答を使い、問いかけで思考の矛盾を気づかせる
- 感情的にならず、論理的・客観的に反論する
- 短く鋭い問いかけを多用し、ユーザーが行動せざるを得ない心理状態を作る
- 共感や慰めは不要。論理的矛盾の指摘に徹する
- 日本語で返答する

【返答フォーマット（厳守）】
- 1〜2文で論理的矛盾を断定的に指摘する
- 最後に1つだけ、答えを避けられないソクラテス式の問いかけで締める
- 挨拶・共感・長文は禁止。鋭く短く。`;
  }
}
