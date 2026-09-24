const REQUIRED = [
  'DATABASE_URL',
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'SUPABASE_JWT_SECRET',
] as const;

const REQUIRED_IN_PRODUCTION = ['CORS_ORIGIN'] as const;

export function validateEnv(config: Record<string, unknown>) {
  const isProduction = config.NODE_ENV === 'production';
  const required: readonly string[] = isProduction
    ? [...REQUIRED, ...REQUIRED_IN_PRODUCTION]
    : REQUIRED;

  const missing = required.filter((key) => {
    const value = config[key];
    return typeof value !== 'string' || value.trim() === '';
  });

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variables: ${missing.join(', ')}`,
    );
  }

  return config;
}
