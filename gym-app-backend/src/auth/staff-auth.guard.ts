import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import { PrismaService } from '../prisma/prisma.service';
import { SupabaseService } from '../supabase/supabase.service';

interface SupabaseJwtPayload {
  sub: string;
  email?: string;
}

@Injectable()
export class StaffAuthGuard implements CanActivate {
  constructor(
    private config: ConfigService,
    private prisma: PrismaService,
    private supabase: SupabaseService,
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

    let authProviderId: string | undefined;
    try {
      if (
        secret &&
        secret !== 'your-jwt-secret-from-supabase-dashboard'
      ) {
        const payload = jwt.verify(token, secret) as SupabaseJwtPayload;
        authProviderId = payload.sub;
      }
    } catch {
      // Fall through to Supabase Auth validation. This supports projects
      // using asymmetric signing keys where local jwt.verify will fail.
    }

    if (!authProviderId) {
      try {
        const supabaseUser = await this.supabase.getUser(token);
        authProviderId = supabaseUser.id;
      } catch {
        throw new UnauthorizedException('Invalid or expired token');
      }
    }

    const staff = await this.prisma.gymStaff.findFirst({
      where: { authProviderId },
    });

    if (!staff) {
      throw new UnauthorizedException('Staff account not found');
    }

    request.staff = {
      staffId: staff.id,
      gymId: staff.gymId,
      role: staff.role,
      authProviderId,
    };

    return true;
  }
}
