import {
  Body,
  Controller,
  Delete,
  ForbiddenException,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { SocialService } from './social.service';
import { SupabaseAuthGuard } from '../auth/supabase-auth.guard';
import { StaffAuthGuard } from '../auth/staff-auth.guard';
import { CurrentMember } from '../auth/decorators/current-user.decorator';
import { CurrentStaff } from '../auth/decorators/current-user.decorator';
import {
  CreateCommentDto,
  CreatePostDto,
  ShareWorkoutDto,
} from './dto/social.dto';

@Controller('social')
@UseGuards(SupabaseAuthGuard)
export class SocialController {
  constructor(private socialService: SocialService) {}

  // ─── Feed (any authenticated member) ──────────────────────────────────────

  @Get('posts')
  getFeed(
    @CurrentMember() member: { userId: string; gymId: string },
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
  ) {
    return this.socialService.getFeed(
      member.gymId,
      member.userId,
      limit ? parseInt(limit, 10) : 20,
      offset ? parseInt(offset, 10) : 0,
    );
  }

  // ─── Staff: create announcement post ──────────────────────────────────────
  // Uses SupabaseAuthGuard but also checks isStaff flag set by the guard.
  // The guard attaches isStaff based on whether the user's email exists in
  // the gym_staff table for their gymId.

  @Post('posts')
  createPost(
    @CurrentMember() member: { userId: string; gymId: string; isStaff: boolean },
    @Body() dto: CreatePostDto,
  ) {
    if (!member.isStaff) {
      // Members share completed workouts via /workout-sessions/:id/share.
      // Standalone PR auto-posts are not created anymore.
      // Direct post creation is staff-only.
      throw new ForbiddenException('Only staff can create posts directly');
    }
    return this.socialService.createStaffPost(member.userId, member.gymId, dto);
  }

  // ─── Member: share a completed workout ────────────────────────────────────

  @Post('workout-sessions/:sessionId/share')
  shareWorkout(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('sessionId') sessionId: string,
    @Body() dto: ShareWorkoutDto,
  ) {
    return this.socialService.shareWorkout(
      member.userId,
      member.gymId,
      sessionId,
      dto,
    );
  }

  @Post('posts/:id/certify')
  certifyWorkout(
    @CurrentMember()
    member: {
      userId: string;
      gymId: string;
      isStaff: boolean;
      staffRole?: string | null;
    },
    @Param('id') postId: string,
  ) {
    const role = member.staffRole?.toLowerCase();
    if (!member.isStaff || role !== 'coach') {
      throw new ForbiddenException('Only a coach can certify workouts');
    }
    return this.socialService.certifyWorkout(
      member.userId,
      member.gymId,
      postId,
    );
  }

  @Get('certify-queue')
  listCertifyQueue(
    @CurrentMember()
    member: {
      userId: string;
      gymId: string;
      isStaff: boolean;
      staffRole?: string | null;
    },
    @Query('limit') limit?: string,
  ) {
    const role = member.staffRole?.toLowerCase();
    if (!member.isStaff || role !== 'coach') {
      throw new ForbiddenException('Only a coach can view the certify queue');
    }
    return this.socialService.listCertifyQueue(
      member.gymId,
      member.userId,
      limit ? parseInt(limit, 10) : 30,
    );
  }

  // ─── Like toggle (any member) ──────────────────────────────────────────────

  @Post('posts/:id/like')
  toggleLike(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') postId: string,
  ) {
    return this.socialService.toggleLike(member.userId, member.gymId, postId);
  }

  // ─── Flag post (any member — queues for moderation) ───────────────────────

  @Post('posts/:id/flag')
  flagPost(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') postId: string,
  ) {
    return this.socialService.flagPost(member.userId, member.gymId, postId);
  }

  // ─── Comments ──────────────────────────────────────────────────────────────

  @Get('posts/:id/comments')
  getComments(
    @CurrentMember() member: { gymId: string },
    @Param('id') postId: string,
  ) {
    return this.socialService.getComments(member.gymId, postId);
  }

  @Post('posts/:id/comments')
  createComment(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('id') postId: string,
    @Body() dto: CreateCommentDto,
  ) {
    return this.socialService.createComment(
      member.userId,
      member.gymId,
      postId,
      dto,
    );
  }

  @Delete('posts/:postId/comments/:commentId')
  deleteComment(
    @CurrentMember() member: { userId: string; gymId: string },
    @Param('commentId') commentId: string,
  ) {
    return this.socialService.deleteComment(
      member.userId,
      member.gymId,
      commentId,
    );
  }
}
