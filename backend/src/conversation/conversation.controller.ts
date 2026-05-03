import { Body, Controller, Delete, Get, Param, ParseIntPipe, Patch, Post, Query } from '@nestjs/common';
import { type AuthUser, CurrentUser } from '../auth/current-user.decorator';
import { ConversationService } from './conversation.service';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { UpdateArchiveDto } from './dto/update-archive.dto';

@Controller('conversations')
export class ConversationController {
  constructor(private readonly conversationService: ConversationService) {}

  @Post()
  createConversation(@Body() dto: CreateConversationDto, @CurrentUser() user: AuthUser) {
    return this.conversationService.createConversation(dto, user.id);
  }

  @Get()
  getConversations(@CurrentUser() user: AuthUser, @Query('archived') archived?: string) {
    const archivedBool = archived === 'true' ? true : archived === 'false' ? false : undefined;
    return this.conversationService.getConversations(user.id, archivedBool);
  }

  @Get(':id')
  getConversation(@Param('id', ParseIntPipe) id: number, @CurrentUser() user: AuthUser) {
    return this.conversationService.getConversation(id, user.id);
  }

  @Patch(':id/archive')
  archiveConversation(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateArchiveDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.conversationService.archiveConversation(id, dto.archived, user.id);
  }

  @Delete(':id')
  deleteConversation(@Param('id', ParseIntPipe) id: number, @CurrentUser() user: AuthUser) {
    return this.conversationService.deleteConversation(id, user.id);
  }
}
