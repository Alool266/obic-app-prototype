// Made by Dr Ali
// OBIC API bootstrap — Helmet, global validation, /v1 prefix. Secrets only via env.

import { ClassSerializerInterceptor, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory, Reflector } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { join } from 'path';
import type { NextFunction, Request, Response } from 'express';
import { loadOptionalAiEnvFiles } from './ai/ai-env.loader';
import { loadOptionalAgoraEnvFiles } from './calls/agora-env.loader';
import { AppModule } from './app.module';
import { parseCorsOrigins } from './common/admin-security';
import { UploadsService } from './uploads/uploads.service';

async function bootstrap() {
  loadOptionalAiEnvFiles();
  loadOptionalAgoraEnvFiles();
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const config = app.get(ConfigService);

  if (
    config.get<string>('TRUST_PROXY')?.trim().toLowerCase() === 'true' ||
    config.get<string>('NODE_ENV') === 'production'
  ) {
    app.set('trust proxy', 1);
  }

  // Security headers; allow cross-origin media for Flutter simulator.
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      // Allow Swagger UI at /docs (inline scripts/styles).
      contentSecurityPolicy: {
        directives: {
          defaultSrc: [`'self'`],
          styleSrc: [`'self'`, `'unsafe-inline'`],
          imgSrc: [`'self'`, 'data:', 'validator.swagger.io'],
          scriptSrc: [`'self'`, `'unsafe-inline'`],
        },
      },
    }),
  );

  // Serve Moments / avatar files: disk first, then durable Postgres blobs
  // (Render free disk is ephemeral — redeploy used to 404 /uploads/*).
  const uploads = app.get(UploadsService);
  app.use(
    '/uploads',
    async (req: Request, res: Response, next: NextFunction) => {
      if (req.method !== 'GET' && req.method !== 'HEAD') return next();
      const filename = (req.path || '').replace(/^\//, '');
      if (!filename || filename.includes('..')) return next();
      try {
        const file = await uploads.readBuffer(filename);
        if (!file) return next();
        res.setHeader('Content-Type', file.mime);
        res.setHeader('Cache-Control', 'public, max-age=86400');
        if (req.method === 'HEAD') {
          res.setHeader('Content-Length', String(file.buffer.length));
          return res.status(200).end();
        }
        return res.status(200).send(file.buffer);
      } catch {
        return next();
      }
    },
  );

  // Fallback for empty miss (404) — keep Nest static for local hot paths.
  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads/',
  });

  // All public HTTP under /v1 — matches architecture docs.
  app.setGlobalPrefix('v1');

  // Reject malformed bodies early; strip unknown fields.
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Honors @Exclude() on entities (e.g. passwordHash) if any slip through.
  app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));

  // Staging/prod: set CORS_ORIGINS=https://admin.obicgp.com,https://www.obicgp.com
  // Local/dev with unset CORS_ORIGINS reflects the request origin.
  const corsOrigin = parseCorsOrigins(config);
  app.enableCors({
    origin: corsOrigin === true ? true : corsOrigin.length ? corsOrigin : false,
    credentials: true,
  });

  const swagger = new DocumentBuilder()
    .setTitle('OBIC API')
    .setDescription(
      'OBIC HTTP API. AuthZ is server-side only. Made by Dr Ali. Do not put secrets in examples.',
    )
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swagger);
  SwaggerModule.setup('docs', app, document);

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`OBIC API listening on :${port}  docs: /docs  (Made by Dr Ali)`);
}

void bootstrap();
