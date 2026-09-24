import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateNoticeDto, UpdateNoticeDto } from './dto/notices.dto';

const NOTICE_SELECT = {
  id: true,
  gymId: true,
  authorUserId: true,
  authorStaffId: true,
  title: true,
  body: true,
  tag: true,
  isPinned: true,
  publishedAt: true,
  createdAt: true,
  updatedAt: true,
  deletedAt: true,
  authorUser: {
    select: { id: true, displayName: true },
  },
  authorStaff: {
    select: { id: true, email: true, role: true },
  },
} as const;

@Injectable()
export class NoticesService {
  constructor(private prisma: PrismaService) {}

  listForMembers(gymId: string, limit = 50, offset = 0) {
    return this.prisma.gymNotice.findMany({
      where: { gymId, deletedAt: null },
      orderBy: [{ isPinned: 'desc' }, { publishedAt: 'desc' }],
      take: Math.min(Math.max(limit, 1), 100),
      skip: Math.max(offset, 0),
      select: NOTICE_SELECT,
    });
  }

  /** Admin list can include soft-deleted rows. */
  listForStaff(
    gymId: string,
    opts: { includeDeleted?: boolean; limit?: number; offset?: number } = {},
  ) {
    const { includeDeleted = false, limit = 50, offset = 0 } = opts;
    return this.prisma.gymNotice.findMany({
      where: {
        gymId,
        ...(includeDeleted ? {} : { deletedAt: null }),
      },
      orderBy: [{ isPinned: 'desc' }, { publishedAt: 'desc' }],
      take: Math.min(Math.max(limit, 1), 100),
      skip: Math.max(offset, 0),
      select: NOTICE_SELECT,
    });
  }

  async getForMember(gymId: string, noticeId: string) {
    const notice = await this.prisma.gymNotice.findFirst({
      where: { id: noticeId, gymId, deletedAt: null },
      select: NOTICE_SELECT,
    });
    if (!notice) throw new NotFoundException('Notice not found');
    return notice;
  }

  async createAsCoach(
    gymId: string,
    authorUserId: string,
    authorStaffId: string | null,
    dto: CreateNoticeDto,
  ) {
    return this.prisma.gymNotice.create({
      data: {
        id: randomUUID(),
        gymId,
        authorUserId,
        authorStaffId,
        title: dto.title.trim(),
        body: dto.body.trim(),
        tag: dto.tag,
        isPinned: dto.isPinned ?? false,
      },
      select: NOTICE_SELECT,
    });
  }

  async createAsStaff(
    gymId: string,
    authorStaffId: string,
    dto: CreateNoticeDto,
  ) {
    return this.prisma.gymNotice.create({
      data: {
        id: randomUUID(),
        gymId,
        authorStaffId,
        title: dto.title.trim(),
        body: dto.body.trim(),
        tag: dto.tag,
        isPinned: dto.isPinned ?? false,
      },
      select: NOTICE_SELECT,
    });
  }

  async update(
    gymId: string,
    noticeId: string,
    dto: UpdateNoticeDto,
  ) {
    await this.requireActiveNotice(gymId, noticeId);
    return this.prisma.gymNotice.update({
      where: { id: noticeId },
      data: {
        ...(dto.title !== undefined ? { title: dto.title.trim() } : {}),
        ...(dto.body !== undefined ? { body: dto.body.trim() } : {}),
        ...(dto.tag !== undefined ? { tag: dto.tag } : {}),
        ...(dto.isPinned !== undefined ? { isPinned: dto.isPinned } : {}),
      },
      select: NOTICE_SELECT,
    });
  }

  async softDelete(gymId: string, noticeId: string) {
    await this.requireActiveNotice(gymId, noticeId);
    return this.prisma.gymNotice.update({
      where: { id: noticeId },
      data: { deletedAt: new Date() },
      select: NOTICE_SELECT,
    });
  }

  async restore(gymId: string, noticeId: string) {
    const notice = await this.prisma.gymNotice.findFirst({
      where: { id: noticeId, gymId },
      select: { id: true, deletedAt: true },
    });
    if (!notice) throw new NotFoundException('Notice not found');
    if (!notice.deletedAt) {
      throw new ForbiddenException('Notice is not deleted');
    }
    return this.prisma.gymNotice.update({
      where: { id: noticeId },
      data: { deletedAt: null },
      select: NOTICE_SELECT,
    });
  }

  private async requireActiveNotice(gymId: string, noticeId: string) {
    const notice = await this.prisma.gymNotice.findFirst({
      where: { id: noticeId, gymId, deletedAt: null },
      select: { id: true },
    });
    if (!notice) throw new NotFoundException('Notice not found');
    return notice;
  }

  /** Resolve gym_staff.id for a coach member when available. */
  async findStaffIdForAuth(
    gymId: string,
    authProviderId: string,
  ): Promise<string | null> {
    const staff = await this.prisma.gymStaff.findFirst({
      where: { gymId, authProviderId },
      select: { id: true },
    });
    return staff?.id ?? null;
  }
}
