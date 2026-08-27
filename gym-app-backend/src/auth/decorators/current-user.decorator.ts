import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface MemberContext {
  userId: string;
  gymId: string;
  authProviderId: string;
  isStaff: boolean;
  staffRole: string | null;
}

export const CurrentMember = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): MemberContext | undefined => {
    const request = ctx.switchToHttp().getRequest();
    return request.member ?? undefined;
  },
);

export interface StaffContext {
  staffId: string;
  gymId: string;
  role: string;
  authProviderId: string;
}

export const CurrentStaff = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): StaffContext => {
    const request = ctx.switchToHttp().getRequest();
    return request.staff;
  },
);
