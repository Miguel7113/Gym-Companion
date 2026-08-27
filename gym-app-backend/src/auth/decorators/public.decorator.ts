import { SetMetadata } from '@nestjs/common';

// Mark a route as public — SupabaseAuthGuard will skip token validation.
// Use on read-only endpoints where auth is not required (e.g. exercise library).
export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
