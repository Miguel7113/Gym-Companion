import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import { PrismaService } from '../prisma/prisma.service';

interface SupabaseJwtPayload {
  sub: string;
  email?: string;
}

@Injectable()
export class StaffAuthGuard implements CanActivate {
  constructor(
    private config: ConfigService,
    private prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization as string | undefined;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing or invalid authorization header');
    }

    const token = authHeader.slice(7);
    const secret = this.config.get<string>('SUPABASE_JWT_SECRET');
    if (!secret) {
      throw new UnauthorizedException('Auth not configured');
    }

    let payload: SupabaseJwtPayload;
    try {
      payload = jwt.verify(token, secret) as SupabaseJwtPayload;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }

    const staff = await this.prisma.gymStaff.findFirst({
      where: { authProviderId: payload.sub },
    });

    if (!staff) {
      throw new UnauthorizedException('Staff account not found');
    }

    request.staff = {
      staffId: staff.id,
      gymId: staff.gymId,
      role: staff.role,
      authProviderId: payload.sub,
    };

    return true;
  }
}
