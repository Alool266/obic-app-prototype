// Made by Dr Ali
// Replace saved addresses on /v1/users/me/addresses.

import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsOptional,
  IsString,
  MaxLength,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class UserAddressDto {
  @IsString()
  @MinLength(1)
  @MaxLength(64)
  id!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(40)
  label!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(200)
  line1!: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  line2?: string;

  @IsString()
  @MinLength(2)
  @MaxLength(80)
  city!: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  district?: string;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  notes?: string;

  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class UpdateAddressesDto {
  @IsArray()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => UserAddressDto)
  addresses!: UserAddressDto[];
}
