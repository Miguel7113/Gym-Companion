import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';

// Deliberately minimal: checks a shared secret header against an env var,
// NOT a full admin auth/RBAC system. This is fine while you're the only
// person reviewing applications — revisit with a real account-based
// super-admin system (its own guard, its own table) if you ever bring
// on staff to help with review. Don't grow this guard's scope past
// "one person with one secret key" — build a proper system instead once
// that's no longer true.
@Injectable()
export class AdminKeyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const key = request.headers['x-admin-key'];
    if (!key || key !== process.env.SUPER_ADMIN_KEY) {
      throw new UnauthorizedException('Invalid admin key');
    }
    return true;
  }
}
