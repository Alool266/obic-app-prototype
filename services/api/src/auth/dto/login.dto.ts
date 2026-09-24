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
  @Matches(/^\+?[0-9]{8,15}$/, {
    message: 'phone must be 8–15 digits, optional leading +',
  })
  @IsOptional()
  phone?: string;

  @ApiProperty({ example: 'your-password', minLength: 8 })
  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;
}
