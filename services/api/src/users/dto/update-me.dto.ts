// Made by Dr Ali
// Self profile update — name / phone / city / country. Never role, email, or password here.

import { IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class UpdateMeDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(120)
  name?: string;

  /** Empty string clears phone. */
  @IsOptional()
  @IsString()
  @MaxLength(32)
  @Matches(/^[0-9+()\-\s]*$/, {
    message: 'Phone may only contain digits and +()- space',
  })
  phone?: string;

  /** Empty string clears city. */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  city?: string;

  /** Empty string clears country. */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  country?: string;
}
