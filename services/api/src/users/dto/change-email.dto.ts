// Made by Dr Ali
// Change email — requires current password; new email unique; old invalidated.

import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

export class ChangeEmailDto {
  @IsEmail()
  @MaxLength(320)
  email!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  currentPassword!: string;
}
