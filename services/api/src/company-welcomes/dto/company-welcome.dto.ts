// Made by Dr Ali

import {
  IsBoolean,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export class SaveWelcomeDto {
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  title!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(500)
  body!: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class AssignWelcomeDto {
  @IsUUID('4')
  userId!: string;

  @IsOptional()
  @IsUUID('4')
  welcomeId?: string | null;
}
