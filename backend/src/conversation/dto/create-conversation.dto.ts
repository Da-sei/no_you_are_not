import { IsInt, IsOptional, IsString } from 'class-validator';

export class CreateConversationDto {
  @IsInt()
  @IsOptional()
  goalId?: number;

  @IsString()
  @IsOptional()
  title?: string;
}
