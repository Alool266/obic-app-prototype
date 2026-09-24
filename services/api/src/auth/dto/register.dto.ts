// Made by Dr Ali
// Register — email OR phone + password + name (Customer by default).

import {
  IsEmail,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
  ValidateIf,
} from 'class-validator';

export class RegisterDto {
  @ValidateIf((o: RegisterDto) => !o.phone)
  @IsEmail()
  @IsOptional()
  email?: string;

  @ValidateIf((o: RegisterDto) => !o.email)
  @IsString()
  @Matches(/^\+?[0-9]{8,15}$/, {
    message: 'phone must be 8–15 digits, optional leading +',
  })
  @IsOptional()
  phone?: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(120)
  name!: string;
}
