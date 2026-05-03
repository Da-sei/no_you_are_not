import { Body, Controller, Get, Param, ParseIntPipe, Post } from '@nestjs/common';
import { type AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { CreateMessageDto } from './dto/create-message.dto';
import { MessageService } from './message.service';

@Controller('conversations/:conversationId/messages')
export class MessageController {
  constructor(private readonly messageService: MessageService) {}

  @Post()
  sendMessage(
    @Param('conversationId', ParseIntPipe) conversationId: number,
    @Body() dto: CreateMessageDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.messageService.sendMessage(conversationId, dto, user.id, user.plan);
  }

  @Get()
  getMessages(
    @Param('conversationId', ParseIntPipe) conversationId: number,
    @CurrentUser() user: AuthUser,
  ) {
    return this.messageService.getMessages(conversationId, user.id);
  }
}
