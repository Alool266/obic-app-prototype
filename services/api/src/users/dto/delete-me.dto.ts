// Made by Dr Ali
// Self-delete / deactivate — requires current password.

import { IsString, MaxLength, MinLength } from 'class-validator';

export class DeleteMeDto {
  @IsString()
  @MinLength(6)
  @MaxLength(128)
  currentPassword!: string;
}
