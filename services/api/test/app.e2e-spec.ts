// Made by Dr Ali
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

describe('Health (e2e)', () => {
  let app: INestApplication<App>;

  beforeAll(async () => {
    // Skip if env not configured — CI will set DATABASE_URL + JWT_SECRET.
    if (!process.env.JWT_SECRET || !process.env.DATABASE_URL) {
      return;
    }
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('v1');
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }),
    );
    await app.init();
  });

  afterAll(async () => {
    if (app) await app.close();
  });

  it('/v1/health (GET)', async () => {
    if (!app) return;
    const res = await request(app.getHttpServer()).get('/v1/health').expect(200);
    expect(res.body.service).toBe('obic-api');
  });
});
