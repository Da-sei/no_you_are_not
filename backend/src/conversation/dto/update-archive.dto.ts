import { IsBoolean } from 'class-validator';

export class UpdateArchiveDto {
  @IsBoolean()
  archived: boolean;
}
