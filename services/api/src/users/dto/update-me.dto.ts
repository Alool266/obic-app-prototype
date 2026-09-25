// Made by Dr Ali
// Self profile update — name / phone / city / country / OBIC ID.
// Never role, email, or password here.

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

  /**
   * OBIC ID (WeChat-style). First set free; later changes once per 365 days.
   * Cannot be cleared once set. Server normalizes to lowercase.
   */
  @IsOptional()
  @IsString()
  @MinLength(6)
  @MaxLength(20)
  @Matches(/^[a-zA-Z][a-zA-Z0-9_]{5,19}$/, {
    message:
      'OBIC ID must be 6–20 chars, start with a letter, and use letters, digits, or _',
  })
  obicId?: string;
}
