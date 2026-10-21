// Made by Dr Ali
// Verify Google ID tokens and Apple identity tokens. Never trust a client email.

import {
  Injectable,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';
import {
  APPLE_SIGN_IN_NOT_CONFIGURED,
  configuredAudiences,
  GOOGLE_SIGN_IN_NOT_CONFIGURED,
  identityFromClaims,
  INVALID_SOCIAL_TOKEN,
  SocialProvider,
  VerifiedSocialIdentity,
} from './social-identity';

const APPLE_ISSUER = 'https://appleid.apple.com';

function unreachableSocialProvider(provider: never): never {
  throw new UnauthorizedException(`${INVALID_SOCIAL_TOKEN}:${String(provider)}`);
}

type JoseModule = {
  createRemoteJWKSet: (url: URL) => unknown;
  jwtVerify: (
    token: string,
    key: unknown,
    options: {
      issuer: string;
      audience: string[];
      clockTolerance: number;
    },
  ) => Promise<{
    payload: {
      sub?: unknown;
      email?: unknown;
      email_verified?: unknown;
      name?: unknown;
    };
  }>;
};

@Injectable()
export class SocialTokenVerifier {
  private readonly logger = new Logger(SocialTokenVerifier.name);
  private googleClient: OAuth2Client | null = null;
  private jose: Promise<JoseModule> | null = null;
  private appleJwks: unknown = null;

  constructor(private readonly config: ConfigService) {}

  async verify(
    provider: SocialProvider,
    idToken: string,
  ): Promise<VerifiedSocialIdentity> {
    switch (provider) {
      case 'google':
        return this.verifyGoogle(idToken);
      case 'apple':
        return this.verifyApple(idToken);
      default: {
        return unreachableSocialProvider(provider);
      }
    }
  }

  private googleAudiences(): string[] {
    return configuredAudiences(this.config.get<string>('GOOGLE_CLIENT_ID'));
  }

  private appleAudiences(): string[] {
    return configuredAudiences(this.config.get<string>('APPLE_CLIENT_ID'));
  }

  private async verifyGoogle(idToken: string): Promise<VerifiedSocialIdentity> {
    const audience = this.googleAudiences();
    if (audience.length === 0) {
      throw new ServiceUnavailableException(GOOGLE_SIGN_IN_NOT_CONFIGURED);
    }
    try {
      this.googleClient ??= new OAuth2Client();
      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience,
      });
      const payload = ticket.getPayload();
      if (!payload) throw new Error(INVALID_SOCIAL_TOKEN);
      return identityFromClaims('google', payload);
    } catch (err) {
      if (err instanceof ServiceUnavailableException) throw err;
      this.logger.warn(
        `Google ID token rejected (${err instanceof Error ? err.name : 'error'})`,
      );
      throw new UnauthorizedException(INVALID_SOCIAL_TOKEN);
    }
  }

  private async verifyApple(idToken: string): Promise<VerifiedSocialIdentity> {
    const audience = this.appleAudiences();
    if (audience.length === 0) {
      throw new ServiceUnavailableException(APPLE_SIGN_IN_NOT_CONFIGURED);
    }
    try {
      const jose = await this.loadJose();
      this.appleJwks ??= jose.createRemoteJWKSet(
        new URL('https://appleid.apple.com/auth/keys'),
      );
      const { payload } = await jose.jwtVerify(idToken, this.appleJwks, {
        issuer: APPLE_ISSUER,
        audience,
        clockTolerance: 60,
      });
      return identityFromClaims('apple', payload);
    } catch (err) {
      if (err instanceof ServiceUnavailableException) throw err;
      this.logger.warn(
        `Apple identity token rejected (${err instanceof Error ? err.name : 'error'})`,
      );
      throw new UnauthorizedException(INVALID_SOCIAL_TOKEN);
    }
  }

  /**
   * jose is ESM-only. This API compiles as CommonJS, so a top-level import
   * becomes require() and cannot load the package.
   */
  private loadJose(): Promise<JoseModule> {
    this.jose ??= import('jose') as Promise<JoseModule>;
    return this.jose;
  }
}
