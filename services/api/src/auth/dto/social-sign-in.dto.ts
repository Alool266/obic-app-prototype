// Made by Dr Ali
// Social sign-in — server verifies the provider token. No client email field.

import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import type { SocialProvider } from '../social-identity';

export class SocialSignInDto {
  @IsIn(['google', 'apple'])
  provider!: SocialProvider;

  /** Google ID token or Apple identity token. */
  @IsString()
  @MinLength(20)
  @MaxLength(8192)
  idToken!: string;

  /** Display name from the provider sheet (Apple sends it once). Not an identity. */
  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  /**
   * Client region (ISO 3166-1 alpha-2), same source as password register.
   * CN/HK/MO is stored so the existing China phone gate still applies.
   */
  @IsOptional()
  @IsString()
  @MaxLength(8)
  regionCountry?: string;
}
