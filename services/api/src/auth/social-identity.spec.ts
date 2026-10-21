// Made by Dr Ali
import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import {
  configuredAudiences,
  identityFromClaims,
  isProviderEmailVerified,
} from './social-identity';
import { SocialTokenVerifier } from './social-token.verifier';

describe('social identity claims', () => {
  it('treats Apple string "true" as verified and anything else as not', () => {
    expect(isProviderEmailVerified(true)).toBe(true);
    expect(isProviderEmailVerified('true')).toBe(true);
    expect(isProviderEmailVerified('TRUE')).toBe(true);
    expect(isProviderEmailVerified('false')).toBe(false);
    expect(isProviderEmailVerified(false)).toBe(false);
    expect(isProviderEmailVerified(undefined)).toBe(false);
    expect(isProviderEmailVerified('yes')).toBe(false);
  });

  it('accepts Hide My Email when the provider marks it verified', () => {
    const identity = identityFromClaims('apple', {
      sub: 'apple-sub-1',
      email: 'xyz@privaterelay.appleid.com',
      email_verified: 'true',
    });
    expect(identity.email).toBe('xyz@privaterelay.appleid.com');
    expect(identity.emailVerified).toBe(true);
  });

  it('does not treat a missing or unverified email as verified', () => {
    expect(
      identityFromClaims('google', {
        sub: 'google-sub-1',
        email: 'person@example.com',
        email_verified: false,
      }).emailVerified,
    ).toBe(false);
    expect(
      identityFromClaims('google', {
        sub: 'google-sub-1',
        email: 'person@example.com',
      }).emailVerified,
    ).toBe(false);
    expect(
      identityFromClaims('apple', { sub: 'apple-sub-1' }).email,
    ).toBeNull();
  });

  it('splits comma-separated client ids', () => {
    expect(
      configuredAudiences(
        ' web-client.apps.googleusercontent.com , com.obic.app.obicMobile ',
      ),
    ).toEqual([
      'web-client.apps.googleusercontent.com',
      'com.obic.app.obicMobile',
    ]);
    expect(configuredAudiences('')).toEqual([]);
    expect(configuredAudiences(null)).toEqual([]);
  });
});

describe('SocialTokenVerifier configuration', () => {
  it('rejects Google and Apple when client ids are unset', async () => {
    const module = await Test.createTestingModule({
      providers: [
        SocialTokenVerifier,
        {
          provide: ConfigService,
          useValue: { get: () => '' },
        },
      ],
    }).compile();
    const verifier = module.get(SocialTokenVerifier);
    const token = 'x'.repeat(40);

    await expect(verifier.verify('google', token)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
    await expect(verifier.verify('apple', token)).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
