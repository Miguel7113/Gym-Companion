import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import { PrismaService } from '../prisma/prisma.service';
import { SupabaseService } from '../supabase/supabase.service';
import { IS_PUBLIC_KEY } from './decorators/public.decorator';

interface SupabaseJwtPayload {
  sub: string;
  email?: string;
  phone?: string;
}

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private config: ConfigService,
    private prisma: PrismaService,
    private supabase: SupabaseService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Skip auth for routes marked @Public() — but still try to populate
    // request.member if a token is present, so public+authenticated routes
    // (e.g. food endpoints in SKIP_LOGIN mode) work for both cases.
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization as string | undefined;

    if (isPublic) {
      // Best-effort auth population — never throws
      if (authHeader?.startsWith('Bearer ')) {
        try {
          const token = authHeader.slice(7);
          const secret = this.config.get<string>('SUPABASE_JWT_SECRET');
          if (secret && secret !== 'your-jwt-secret-from-supabase-dashboard') {
            const payload = jwt.verify(token, secret) as SupabaseJwtPayload;
            const user = await this.prisma.user.findUnique({
              where: { authProviderId: payload.sub },
              select: { id: true, gymId: true, authProviderId: true },
            });
            if (user) {
              const staffRecord = await this.prisma.gymStaff.findFirst({
                where: { authProviderId: payload.sub, gymId: user.gymId },
              });
              request.member = {
                userId: user.id,
                gymId: user.gymId,
                authProviderId: payload.sub,
                isStaff: !!staffRecord,
                staffRole: staffRecord?.role ?? null,
              };
            }
          }
        } catch {
          // Silently ignore — public route, auth is optional
        }
      }
      return true;
    }
    // Protected route — require valid token
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
      // Fall through to Supabase Auth validation. Projects using asymmetric
      // signing keys cannot be verified with the legacy JWT secret locally.
    }

    if (!authProviderId) {
      try {
        const supabaseUser = await this.supabase.getUser(token);
        authProviderId = supabaseUser.id;
      } catch {
        throw new UnauthorizedException('Invalid or expired token');
      }
    }

    const user = await this.prisma.user.findUnique({
      where: { authProviderId },
      select: {
        id: true,
        gymId: true,
        authProviderId: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('User account not found');
    }

    // Check if this user is also a staff member at their gym
    const staffRecord = await this.prisma.gymStaff.findFirst({
      where: {
        authProviderId,
        gymId: user.gymId,
      },
    });

    request.member = {
      userId: user.id,
      gymId: user.gymId,
      authProviderId,
      isStaff: !!staffRecord,
      staffRole: staffRecord?.role ?? null,
    };

    return true;
  }
}
