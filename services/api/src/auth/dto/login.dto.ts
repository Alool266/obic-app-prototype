// Made by Dr Ali
// Login — email OR phone + password.

import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

export class LoginDto {
  @ApiPropertyOptional({ example: 'customer@example.com' })
  @ValidateIf((o: LoginDto) => !o.phone)
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiPropertyOptional({ example: '+8613800138000' })
  @ValidateIf((o: LoginDto) => !o.email)
  @IsString()
  @Matches(/^(?:\+?86)?1[3-9]\d{9}$|^\+?[0-9]{8,15}$/, {
    message: 'Phone verification supports China numbers only for now',
  })
  @IsOptional()
  phone?: string;

  @ApiProperty({ example: 'your-password', minLength: 8 })
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;
}
