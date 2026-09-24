// Made by Dr Ali
// PATCH /v1/users/me/avatar — set profile photo URL after upload.

import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class UpdateAvatarDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(1024)
  avatarUrl!: string;
}
