import { createClient } from '@supabase/supabase-js';
import { SupabaseService } from './supabase.service';

jest.mock('@supabase/supabase-js', () => ({ createClient: jest.fn() }));

function fakeClient() {
  return {
    auth: {
      signInWithPassword: jest.fn().mockResolvedValue({
        data: { session: { access_token: 'user-jwt' } },
        error: null,
      }),
      refreshSession: jest.fn().mockResolvedValue({
        data: { session: { access_token: 'user-jwt' } },
        error: null,
      }),
    },
    storage: {
      from: jest.fn().mockReturnValue({
        createSignedUrl: jest
          .fn()
          .mockResolvedValue({ data: { signedUrl: 'signed' }, error: null }),
      }),
    },
  };
}

describe('SupabaseService client isolation', () => {
  const config = { get: (key: string) => `${key}-value` };
  let clients: ReturnType<typeof fakeClient>[];

  beforeEach(() => {
    clients = [];
    (createClient as jest.Mock).mockImplementation(() => {
      const client = fakeClient();
      clients.push(client);
      return client;
    });
  });

  it('never signs users in on the service-role client used for storage', async () => {
    const service = new SupabaseService(config as any);
    const admin = clients[0];

    await service.signInWithPassword('member@gym.com', 'secret');
    await service.refreshSession('refresh-token');
    await service.createPostImageSignedUrl('user/photo.jpeg');

    expect(admin.auth.signInWithPassword).not.toHaveBeenCalled();
    expect(admin.auth.refreshSession).not.toHaveBeenCalled();
    expect(admin.storage.from).toHaveBeenCalledWith('post-images');
    expect(clients.length).toBeGreaterThan(1);
  });
});
