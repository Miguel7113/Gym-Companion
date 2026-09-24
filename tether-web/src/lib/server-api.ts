export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL?.replace(/\/$/, '') ?? 'http://localhost:3001';

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
