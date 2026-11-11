/**
 * Onboard a new gym and its first portal admin.
 *
 *   npm run gym:create -- --name "Test Gym B" --admin-email you+gymb@gmail.com \
 *     [--admin-password '...'] [--color '#FF7A00'] [--timezone Africa/Nairobi] \
 *     [--logo-url https://...] [--contact-email front@gym.com]
 *
 * Uses the database and Supabase project in .env. If no password is given a
 * random one is generated and printed once.
 */
import { randomBytes } from 'node:crypto';
import { parseArgs } from 'node:util';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { GymsService } from '../src/gyms/gyms.service';

const usage =
  'Usage: npm run gym:create -- --name "Gym name" --admin-email admin@gym.com ' +
  "[--admin-password '...'] [--color '#RRGGBB'] [--timezone Area/City] " +
  '[--logo-url URL] [--contact-email EMAIL]';

async function main() {
  const { values } = parseArgs({
    options: {
      name: { type: 'string' },
      'admin-email': { type: 'string' },
      'admin-password': { type: 'string' },
      color: { type: 'string' },
      timezone: { type: 'string' },
      'logo-url': { type: 'string' },
      'contact-email': { type: 'string' },
    },
  });

  if (!values.name || !values['admin-email']) {
    console.error(usage);
    process.exit(1);
  }

  const generated = !values['admin-password'];
  const adminPassword =
    values['admin-password'] ?? randomBytes(12).toString('base64url');

  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn'],
  });
  try {
    const { gym, adminEmail } = await app.get(GymsService).createGymWithAdmin({
      name: values.name,
      adminEmail: values['admin-email'],
      adminPassword,
      primaryColor: values.color,
      timezone: values.timezone,
      logoUrl: values['logo-url'],
      contactEmail: values['contact-email'],
    });

    console.log(`\nCreated gym "${gym.name}"`);
    console.log(`  id        ${gym.id}`);
    console.log(`  colour    ${gym.primaryColor ?? '(app default)'}`);
    console.log(`  timezone  ${gym.timezone}`);
    console.log(`\nPortal admin`);
    console.log(`  email     ${adminEmail}`);
    console.log(`  password  ${generated ? adminPassword : '(as given)'}`);
    if (generated) console.log('  Save this password now; it is not stored anywhere else.');
    console.log(
      '\nNext: sign in to the portal as this admin, upload the roster, then ' +
        'members can pick the gym in the app.',
    );
  } catch (error) {
    const message =
      (error as { response?: { message?: unknown } })?.response?.message ??
      (error as Error)?.message ??
      error;
    console.error(`\nCould not create the gym: ${message}`);
    process.exitCode = 1;
  } finally {
    await app.close();
  }
}

void main();
