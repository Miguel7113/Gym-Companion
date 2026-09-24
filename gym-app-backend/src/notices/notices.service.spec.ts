import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { NoticesService } from './notices.service';

describe('NoticesService', () => {
  const gymId = 'gym-1';

  function buildService(prisma: Record<string, unknown>) {
    return new NoticesService(prisma as any);
  }

  it('lists only non-deleted notices for members, pinned first', async () => {
    const findMany = jest.fn().mockResolvedValue([]);
    const service = buildService({ gymNotice: { findMany } });

    await service.listForMembers(gymId, 20, 0);

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { gymId, deletedAt: null },
        orderBy: [{ isPinned: 'desc' }, { publishedAt: 'desc' }],
        take: 20,
        skip: 0,
      }),
    );
  });

  it('staff list can include soft-deleted notices', async () => {
    const findMany = jest.fn().mockResolvedValue([]);
    const service = buildService({ gymNotice: { findMany } });

    await service.listForStaff(gymId, { includeDeleted: true });

    expect(findMany.mock.calls[0][0].where).toEqual({ gymId });
  });

  it('createAsCoach stores author user and optional staff id', async () => {
    const create = jest.fn().mockResolvedValue({ id: 'n1' });
    const service = buildService({ gymNotice: { create } });

    await service.createAsCoach(gymId, 'user-1', 'staff-1', {
      title: 'Hello',
      body: 'World',
      tag: 'ANNOUNCEMENT',
      isPinned: true,
    });

    expect(create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          gymId,
          authorUserId: 'user-1',
          authorStaffId: 'staff-1',
          title: 'Hello',
          body: 'World',
          tag: 'ANNOUNCEMENT',
          isPinned: true,
        }),
      }),
    );
  });

  it('createAsStaff stores staff author without user id', async () => {
    const create = jest.fn().mockResolvedValue({ id: 'n2' });
    const service = buildService({ gymNotice: { create } });

    await service.createAsStaff(gymId, 'staff-9', {
      title: 'Admin note',
      body: 'From portal',
      tag: 'REMINDER',
    });

    expect(create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          authorStaffId: 'staff-9',
          tag: 'REMINDER',
          isPinned: false,
        }),
      }),
    );
    expect(create.mock.calls[0][0].data.authorUserId).toBeUndefined();
  });

  it('softDelete sets deletedAt on an active notice', async () => {
    const findFirst = jest.fn().mockResolvedValue({ id: 'n1' });
    const update = jest.fn().mockResolvedValue({ id: 'n1', deletedAt: new Date() });
    const service = buildService({ gymNotice: { findFirst, update } });

    await service.softDelete(gymId, 'n1');

    expect(findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'n1', gymId, deletedAt: null },
      }),
    );
    expect(update.mock.calls[0][0].data.deletedAt).toBeInstanceOf(Date);
  });

  it('softDelete throws when notice missing or already deleted', async () => {
    const service = buildService({
      gymNotice: { findFirst: jest.fn().mockResolvedValue(null) },
    });

    await expect(service.softDelete(gymId, 'missing')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('restore clears deletedAt', async () => {
    const findFirst = jest
      .fn()
      .mockResolvedValue({ id: 'n1', deletedAt: new Date() });
    const update = jest.fn().mockResolvedValue({ id: 'n1', deletedAt: null });
    const service = buildService({ gymNotice: { findFirst, update } });

    await service.restore(gymId, 'n1');

    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { deletedAt: null },
      }),
    );
  });

  it('restore rejects notices that are not deleted', async () => {
    const service = buildService({
      gymNotice: {
        findFirst: jest.fn().mockResolvedValue({ id: 'n1', deletedAt: null }),
      },
    });

    await expect(service.restore(gymId, 'n1')).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('getForMember hides other-gym or deleted notices', async () => {
    const service = buildService({
      gymNotice: { findFirst: jest.fn().mockResolvedValue(null) },
    });

    await expect(service.getForMember(gymId, 'n1')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });
});
