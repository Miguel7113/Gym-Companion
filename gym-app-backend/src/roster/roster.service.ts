import { Injectable, BadRequestException } from '@nestjs/common';
import { parse } from 'csv-parse/sync';
import { PrismaService } from '../prisma/prisma.service';
import { RosterEntryDto } from './dto/roster-entry.dto';

interface CsvRowResult {
  row: number;
  status: 'ok' | 'error';
  message?: string;
}

@Injectable()
export class RosterService {
  constructor(private prisma: PrismaService) {}

  /**
   * Parses a gym-uploaded CSV and upserts each row into gym_roster.
   * Returns a per-row result so the admin portal can show exactly which
   * rows failed and why, instead of failing the whole upload silently.
   */
  async importCsv(gymId: string, csvContent: string): Promise<CsvRowResult[]> {
    let records: Record<string, string>[];
    try {
      records = parse(csvContent, { columns: true, skip_empty_lines: true, trim: true });
    } catch (err) {
      throw new BadRequestException('Could not parse CSV — check the file format.');
    }

    const results: CsvRowResult[] = [];

    for (let i = 0; i < records.length; i++) {
      const row = records[i];
      const email = row.email?.toLowerCase() || undefined;
      const phone = row.phone || undefined;

      if (!email && !phone) {
        results.push({ row: i + 1, status: 'error', message: 'Missing both email and phone' });
        continue;
      }

      try {
        await this.prisma.gymRoster.upsert({
          where: email
            ? { gymId_email: { gymId, email } }
            : { gymId_phone: { gymId, phone: phone! } },
          update: {
            memberName: row.member_name ?? row.name,
            externalMemberId: row.external_member_id ?? row.member_id,
          },
          create: {
            gymId,
            email,
            phone,
            memberName: row.member_name ?? row.name,
            externalMemberId: row.external_member_id ?? row.member_id,
            status: 'unmatched',
          },
        });
        results.push({ row: i + 1, status: 'ok' });
      } catch (err) {
        results.push({ row: i + 1, status: 'error', message: 'Duplicate or invalid row' });
      }
    }

    return results;
  }

  /** Manually add or update a single roster entry (used by the "add member" form). */
  async addEntry(dto: RosterEntryDto) {
    return this.prisma.gymRoster.upsert({
      where: dto.email
        ? { gymId_email: { gymId: dto.gymId, email: dto.email } }
        : { gymId_phone: { gymId: dto.gymId, phone: dto.phone! } },
      update: {
        memberName: dto.memberName,
        externalMemberId: dto.externalMemberId,
      },
      create: {
        gymId: dto.gymId,
        email: dto.email,
        phone: dto.phone,
        memberName: dto.memberName,
        externalMemberId: dto.externalMemberId,
        status: 'unmatched',
      },
    });
  }

  /**
   * Checks whether an email/phone is authorized for a given gym.
   * This is AUTHORIZATION only — it does not prove the requester owns
   * that email/phone. Auth module handles that separately via OTP.
   */
  async findRosterMatch(gymId: string, email?: string, phone?: string) {
    if (!email && !phone) return null;
    return this.prisma.gymRoster.findFirst({
      where: {
        gymId,
        OR: [
          email ? { email: email.toLowerCase() } : undefined,
          phone ? { phone } : undefined,
        ].filter(Boolean) as any,
      },
    });
  }

  /**
   * Searches ALL gyms for a roster entry matching the given email/phone.
   * Used by /auth/claim-session where we don't know the gymId yet
   * (magic link flow doesn't carry it).
   * Returns the first active match (unmatched or matched — not pending).
   */
  async findRosterMatchAnyGym(email?: string, phone?: string) {
    if (!email && !phone) return null;
    return this.prisma.gymRoster.findFirst({
      where: {
        status: { not: 'pending' },
        OR: [
          email ? { email: email.toLowerCase() } : undefined,
          phone ? { phone } : undefined,
        ].filter(Boolean) as any,
      },
    });
  }

  /** Marks a roster row as matched to a real user once signup completes. */  async markMatched(rosterId: string, userId: string) {
    return this.prisma.gymRoster.update({
      where: { id: rosterId },
      data: { status: 'matched', matchedUserId: userId },
    });
  }

  /** Creates a pending (unmatched) roster row for someone whose email/phone
   * wasn't found — gym staff approve these manually in the admin portal. */
  async createPendingRequest(gymId: string, email?: string, phone?: string, name?: string) {
    return this.prisma.gymRoster.create({
      data: {
        gymId,
        email: email?.toLowerCase(),
        phone,
        memberName: name,
        status: 'pending',
      },
    });
  }

  async listPending(gymId: string) {
    return this.prisma.gymRoster.findMany({
      where: { gymId, status: 'pending' },
      orderBy: { createdAt: 'desc' },
    });
  }

  async approvePending(rosterId: string) {
    return this.prisma.gymRoster.update({
      where: { id: rosterId },
      data: { status: 'unmatched' }, // becomes eligible for normal matching/signup
    });
  }
}
