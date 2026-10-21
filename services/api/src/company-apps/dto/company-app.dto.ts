// Made by Dr Ali

import { IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class SaveCompanyAppDto {
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;

  @IsString()
  @MinLength(1)
  @MaxLength(200)
  url!: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}
