// Made by Dr Ali

import { IsString, MaxLength, MinLength } from 'class-validator';

export class AskCompanyFilesDto {
  @IsString()
  @MinLength(1)
  @MaxLength(300)
  question!: string;
}
