// Made by Dr Ali

import { IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class SaveDocumentBodyDto {
  @IsString()
  @MinLength(1)
  @MaxLength(8000)
  body!: string;
}

export class SaveDocumentDto extends SaveDocumentBodyDto {
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  title!: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
