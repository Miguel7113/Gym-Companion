import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';
import type { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const logger = new Logger('Bootstrap');

  // Cloud Run sits behind a proxy; rate limiting needs the real client IP.
  app.set('trust proxy', 1);
  app.use(helmet());
  app.enableShutdownHooks();

  // Strips unknown fields and validates every incoming request against
  // its DTO — this is what stops malformed roster CSV rows or auth
  // payloads from ever reaching a service.
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const corsOrigin = process.env.CORS_ORIGIN?.trim();
  app.enableCors(
    corsOrigin && corsOrigin !== '*'
      ? {
          origin: corsOrigin.split(',').map((value) => value.trim()),
          credentials: true,
        }
      : undefined,
  );

  const port = process.env.PORT ?? 3000;
  // Bind on all interfaces so a physical phone can reach the local API.
  await app.listen(port, '0.0.0.0');
  logger.log(`Gym app backend running on port ${port}`);
}
bootstrap();
