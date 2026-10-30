// Made by Dr Ali
// Customer submit + SuperAdmin reject reason. Status is never client-set.

import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateMiniAppDto {
  @IsString()
  @MinLength(1)
  @MaxLength(80)
  name!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(400)
  description!: string;

  @IsOptional()
  @IsString()
  @MaxLength(1024)
  iconUrl?: string;
}

export class RejectMiniAppDto {
  @IsString()
  @MinLength(2)
  @MaxLength(500)
  reason!: string;
}
