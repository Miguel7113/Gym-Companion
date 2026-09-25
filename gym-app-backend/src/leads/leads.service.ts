import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateLeadDto } from './dto/create-lead.dto';

@Injectable()
export class LeadsService {
  private readonly logger = new Logger(LeadsService.name);

  constructor(private prisma: PrismaService) {}

  async create(dto: CreateLeadDto) {
    if (dto.website) {
      // Bots get a normal-looking success so they don't retry.
      return { ok: true };
    }

    const lead = await this.prisma.gymLead.create({
      data: {
        gymName: dto.gymName.trim(),
        contactName: dto.contactName.trim(),
        email: dto.email.trim().toLowerCase(),
        phone: dto.phone?.trim() || null,
        city: dto.city?.trim() || null,
        memberCount: dto.memberCount ?? null,
        message: dto.message?.trim() || null,
      },
      select: { id: true },
    });

    this.logger.log(`New gym lead ${lead.id} (${dto.gymName})`);
    return { ok: true };
  }
}
