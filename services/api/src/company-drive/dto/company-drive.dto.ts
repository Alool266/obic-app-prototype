// Made by Dr Ali

import { IsBoolean, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class SaveDriveFolderDto {
  @IsString()
  @MinLength(1)
  @MaxLength(40)
  name!: string;

  @IsOptional()
  @IsBoolean()
  active?: boolean;
}

export class SetDriveFileActiveDto {
  @IsBoolean()
  active!: boolean;
}
