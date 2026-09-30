// API_URL is read at runtime, so a deployed portal can be pointed at a new API
// without rebuilding. NEXT_PUBLIC_API_URL is inlined at build time.
export const API_BASE_URL = (
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  'http://localhost:3001'
).replace(/\/$/, '');

export async function serverApiFetch(
  path: string,
  options: RequestInit & { token?: string } = {},
) {
  const { token, headers, ...rest } = options;

  return fetch(`${API_BASE_URL}${path}`, {
    ...rest,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    cache: 'no-store',
  });
}
