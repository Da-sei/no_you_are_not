import { IsDateString, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateGoalDto {
  @IsString()
  @MinLength(1)
  content: string;

  @IsString()
  @IsOptional()
  motivation?: string;

  @IsDateString()
  @IsOptional()
  deadline?: string;
}
